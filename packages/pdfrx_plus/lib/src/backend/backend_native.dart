import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:pdfium_dart/pdfium_dart.dart' as f;

import '../models.dart';

void configureBackend({String? wasmModulesUrl}) {}
Future<void> initializeBackend() async {}

Future<Object?> execute(
  PdfDocument document,
  Map<String, Object?> request,
) async {
  final modulePath = Pdfrx.pdfiumModulePath;
  late Future<Object?> result;
  await document.useNativeDocumentHandle((handle) {
    // Queue on pdfrx's own worker so its font/file callbacks stay in their
    // originating isolate. Do NOT await inside this callback: the worker is
    // suspended until useNativeDocumentHandle returns and would deadlock.
    final message = {...request, 'handle': handle, 'modulePath': modulePath};
    result = PdfrxEntryFunctions.instance.compute(_dispatch, message);
  });
  return result;
}

Object? _dispatch(Map<String, Object?> m) => using((arena) {
  final api = f.getPdfium(modulePath: m['modulePath'] as String?);
  final doc = f.FPDF_DOCUMENT.fromAddress(m['handle'] as int);
  final c = _NativeContext(api, arena, doc);
  try {
    if (m['action'] == 'addPage') {
      final page = api.FPDFPage_New(
        doc,
        api.FPDF_GetPageCount(doc),
        (m['width'] as num).toDouble(),
        (m['height'] as num).toDouble(),
      );
      c.check(page != nullptr, 'Create page');
      try {
        c.check(api.FPDFPage_GenerateContent(page) != 0, 'Generate page');
      } finally {
        api.FPDF_ClosePage(page);
      }
      return null;
    }
    final index = m['pageIndex'] as int;
    if (index < 0 || index >= api.FPDF_GetPageCount(doc)) {
      throw RangeError('PDF page index $index');
    }
    final page = api.FPDF_LoadPage(doc, index);
    c.check(page != nullptr, 'Load page');
    try {
      switch (m['action']) {
        case 'geometry':
          return c.geometry(page);
        case 'annotations':
          return c.annotations(page);
        case 'listObjects':
          return c.objects(page);
        case 'objects':
          try {
            for (final command in m['commands'] as List) {
              c.draw(page, command as Map);
            }
          } finally {
            c.check(
              api.FPDFPage_GenerateContent(page) != 0,
              'Generate content',
            );
          }
        case 'annotation':
          c.writeAnnotation(
            page,
            m['spec'] as Map,
            index: m['index'] as int?,
            preserveAppearance: m['preserveAppearance'] == true,
          );
        case 'removeAnnotation':
          final annotIndex = m['index'] as int;
          c.check(
            annotIndex >= 0 && annotIndex < api.FPDFPage_GetAnnotCount(page),
            'Annotation index',
          );
          c.check(
            api.FPDFPage_RemoveAnnot(page, annotIndex) != 0,
            'Remove annotation',
          );
        default:
          throw UnsupportedError('Unknown pdfrx_plus action ${m['action']}');
      }
      return null;
    } finally {
      api.FPDF_ClosePage(page);
    }
  } finally {
    c.dispose();
  }
});

class _NativeContext {
  _NativeContext(this.api, this.arena, this.doc);
  final f.PDFium api;
  final Arena arena;
  final f.FPDF_DOCUMENT doc;
  final fonts = <String, f.FPDF_FONT>{};
  void dispose() {
    for (final font in fonts.values) {
      api.FPDFFont_Close(font);
    }
  }

  f.FPDF_FONT font(Map m) =>
      fonts.putIfAbsent(m['fontKey'] as String? ?? m['fontName'] as String, () {
        final data = m['font'] as Uint8List?;
        final font = data == null
            ? api.FPDFText_LoadStandardFont(doc, utf8(m['fontName'] as String))
            : api.FPDFText_LoadFont(
                doc,
                (arena<Uint8>(data.length)
                  ..asTypedList(data.length).setAll(0, data)),
                data.length,
                2,
                1,
              );
        check(font != nullptr, 'Load font');
        return font;
      });
  void check(bool ok, String action) {
    if (!ok) {
      throw StateError('$action failed (PDFium ${api.FPDF_GetLastError()})');
    }
  }

  Pointer<Char> utf8(String text) => text.toNativeUtf8(allocator: arena).cast();
  Pointer<UnsignedShort> utf16(String text) =>
      text.toNativeUtf16(allocator: arena).cast();
  Map<String, Object?> geometry(f.FPDF_PAGE page) {
    final r = arena<f.FS_RECTF>();
    check(api.FPDF_GetPageBoundingBox(page, r) != 0, 'Page box');
    return {
      'rect': [r.ref.left, r.ref.top, r.ref.right, r.ref.bottom],
      'rotation': api.FPDFPage_GetRotation(page),
    };
  }

  String? string(f.FPDF_ANNOTATION annot, String key) {
    final size = api.FPDFAnnot_GetStringValue(annot, utf8(key), nullptr, 0);
    if (size < 2) return null;
    final buffer = arena<UnsignedShort>((size + 1) ~/ 2);
    api.FPDFAnnot_GetStringValue(annot, utf8(key), buffer, size);
    final value = buffer.cast<Utf16>().toDartString();
    return value.isEmpty ? null : value;
  }

  String? linkedId(f.FPDF_ANNOTATION annot, String key) {
    final linked = api.FPDFAnnot_GetLinkedAnnot(annot, utf8(key));
    if (linked == nullptr) return null;
    try {
      return string(linked, 'NM');
    } finally {
      api.FPDFPage_CloseAnnot(linked);
    }
  }

  List<Map<String, Object?>> annotations(
    f.FPDF_PAGE page, {
    f.FPDF_DOCUMENT? sourceDoc,
  }) {
    final result = <Map<String, Object?>>[];
    for (var i = 0; i < api.FPDFPage_GetAnnotCount(page); i++) {
      final annot = api.FPDFPage_GetAnnot(page, i);
      check(annot != nullptr, 'Read annotation');
      try {
        final r = arena<f.FS_RECTF>();
        check(api.FPDFAnnot_GetRect(annot, r) != 0, 'Annotation rectangle');
        final color = arena<UnsignedInt>(4);
        final hasColor =
            api.FPDFAnnot_GetColor(
              annot,
              f.FPDFANNOT_COLORTYPE.FPDFANNOT_COLORTYPE_Color,
              color,
              color + 1,
              color + 2,
              color + 3,
            ) !=
            0;
        final quads = <List<List<double>>>[];
        for (var q = 0; q < api.FPDFAnnot_CountAttachmentPoints(annot); q++) {
          final points = arena<f.FS_QUADPOINTSF>();
          if (api.FPDFAnnot_GetAttachmentPoints(annot, q, points) != 0) {
            quads.add([
              [points.ref.x1, points.ref.y1],
              [points.ref.x2, points.ref.y2],
              [points.ref.x3, points.ref.y3],
              [points.ref.x4, points.ref.y4],
            ]);
          }
        }
        final ink = <List<List<double>>>[];
        for (var s = 0; s < api.FPDFAnnot_GetInkListCount(annot); s++) {
          final count = api.FPDFAnnot_GetInkListPath(annot, s, nullptr, 0);
          final points = arena<f.FS_POINTF>(count);
          api.FPDFAnnot_GetInkListPath(annot, s, points, count);
          ink.add(List.generate(count, (p) => [points[p].x, points[p].y]));
        }
        String? uri;
        final link = api.FPDFAnnot_GetLink(annot);
        if (link != nullptr) {
          final action = api.FPDFLink_GetAction(link);
          if (action != nullptr && api.FPDFAction_GetType(action) == 3) {
            final size = api.FPDFAction_GetURIPath(
              sourceDoc ?? doc,
              action,
              nullptr,
              0,
            );
            final buffer = arena<Char>(size);
            api.FPDFAction_GetURIPath(
              sourceDoc ?? doc,
              action,
              buffer.cast(),
              size,
            );
            uri = buffer.cast<Utf8>().toDartString();
          }
        }
        result.add({
          'index': i,
          'subtype': api.FPDFAnnot_GetSubtype(annot),
          'rect': [r.ref.left, r.ref.top, r.ref.right, r.ref.bottom],
          'color': hasColor
              ? [color[0], color[1], color[2], color[3]]
              : [255, 255, 0, 255],
          'colorAvailable': hasColor,
          'hasAppearance': api.FPDFAnnot_GetAP(annot, 0, nullptr, 0) > 0,
          'flags': api.FPDFAnnot_GetFlags(annot),
          'quads': quads,
          'ink': ink,
          'id': string(annot, 'NM'),
          'title': string(annot, 'T'),
          'content': string(annot, 'Contents'),
          'subject': string(annot, 'Subj'),
          'modified': string(annot, 'M'),
          'created': string(annot, 'CreationDate'),
          'replyTo': linkedId(annot, 'IRT'),
          'popupId': linkedId(annot, 'Popup'),
          'uri': uri,
        });
      } finally {
        api.FPDFPage_CloseAnnot(annot);
      }
    }
    return result;
  }

  List<Map<String, Object?>> objects(f.FPDF_PAGE page) =>
      List.generate(api.FPDFPage_CountObjects(page), (i) {
        final obj = api.FPDFPage_GetObject(page, i);
        final r = arena<Float>(4), matrix = arena<f.FS_MATRIX>();
        check(
          api.FPDFPageObj_GetBounds(obj, r, r + 1, r + 2, r + 3) != 0,
          'Object bounds',
        );
        check(api.FPDFPageObj_GetMatrix(obj, matrix) != 0, 'Object matrix');
        return {
          'index': i,
          'type': api.FPDFPageObj_GetType(obj),
          'rect': [r[0], r[3], r[2], r[1]],
          'matrix': [
            matrix.ref.a,
            matrix.ref.b,
            matrix.ref.c,
            matrix.ref.d,
            matrix.ref.e,
            matrix.ref.f,
          ],
        };
      });
  void transform(f.FPDF_PAGEOBJECT obj, List matrix) {
    if (matrix.length != 6 || matrix.any((v) => v is! num || !v.isFinite)) {
      throw ArgumentError('PDF transform must contain six finite values');
    }
    api.FPDFPageObj_Transform(
      obj,
      (matrix[0] as num).toDouble(),
      (matrix[1] as num).toDouble(),
      (matrix[2] as num).toDouble(),
      (matrix[3] as num).toDouble(),
      (matrix[4] as num).toDouble(),
      (matrix[5] as num).toDouble(),
    );
  }

  void paint(f.FPDF_PAGEOBJECT obj, Map m) {
    final fill = m['fill'] as List?, stroke = m['stroke'] as List?;
    if (fill != null) {
      check(
        api.FPDFPageObj_SetFillColor(
              obj,
              fill[0] as int,
              fill[1] as int,
              fill[2] as int,
              fill[3] as int,
            ) !=
            0,
        'Fill color',
      );
    }
    if (stroke != null) {
      check(
        api.FPDFPageObj_SetStrokeColor(
              obj,
              stroke[0] as int,
              stroke[1] as int,
              stroke[2] as int,
              stroke[3] as int,
            ) !=
            0,
        'Stroke color',
      );
      check(
        api.FPDFPageObj_SetStrokeWidth(
              obj,
              (m['strokeWidth'] as num? ?? 1).toDouble(),
            ) !=
            0,
        'Stroke width',
      );
      api.FPDFPageObj_SetLineCap(obj, m['lineCap'] as int? ?? 1);
      api.FPDFPageObj_SetLineJoin(obj, m['lineJoin'] as int? ?? 1);
      final dashes = m['dashes'] as List? ?? [];
      if (dashes.isNotEmpty) {
        final array = arena<Float>(dashes.length);
        for (var i = 0; i < dashes.length; i++) {
          array[i] = (dashes[i] as num).toDouble();
        }
        check(
          api.FPDFPageObj_SetDashArray(obj, array, dashes.length, 0) != 0,
          'Dash array',
        );
      }
    }
    api.FPDFPageObj_SetBlendMode(
      obj,
      utf8(m['blendMode'] as String? ?? 'Normal'),
    );
  }

  void insert(f.FPDF_PAGE page, f.FPDF_PAGEOBJECT obj) {
    if (api.FPDFPage_InsertObject(page, obj) == 0) {
      throw StateError('Insert PDF object failed');
    }
  }

  void insertForm(
    f.FPDF_PAGE page,
    f.FPDF_XOBJECT xobject,
    List<double> matrix,
  ) {
    final obj = api.FPDF_NewFormObjectFromXObject(xobject);
    check(obj != nullptr, 'Create PDF form');
    var pageOwnsObject = false;
    try {
      transform(obj, matrix);
      insert(page, obj);
      pageOwnsObject = true;
    } finally {
      if (!pageOwnsObject) api.FPDFPageObj_Destroy(obj);
    }
  }

  void draw(f.FPDF_PAGE page, Map m) {
    switch (m['type']) {
      case 'transformObject':
        final obj = objectAt(page, m['index'] as int);
        transform(obj, m['matrix'] as List);
        return;
      case 'removeObject':
        final obj = objectAt(page, m['index'] as int);
        check(api.FPDFPage_RemoveObject(page, obj) != 0, 'Remove object');
        api.FPDFPageObj_Destroy(obj);
        return;
      case 'page':
        place(page, m);
        return;
    }
    f.FPDF_PAGEOBJECT obj = nullptr;
    try {
      switch (m['type']) {
        case 'path':
          final commands = m['commands'] as List;
          if (commands.isEmpty) return;
          final start = commands.first as List;
          if (start[0] != 0 || start.length != 3) {
            throw ArgumentError('Path must start with moveTo');
          }
          obj = api.FPDFPageObj_CreateNewPath(
            (start[1] as num).toDouble(),
            (start[2] as num).toDouble(),
          );
          check(obj != nullptr, 'Create path');
          for (final raw in commands.skip(1)) {
            final cmd = raw as List;
            final v = cmd.map((e) => (e as num).toDouble()).toList();
            final result = switch (v[0].toInt()) {
              0 => api.FPDFPath_MoveTo(obj, v[1], v[2]),
              1 => api.FPDFPath_LineTo(obj, v[1], v[2]),
              2 => api.FPDFPath_BezierTo(
                obj,
                v[1],
                v[2],
                v[3],
                v[4],
                v[5],
                v[6],
              ),
              3 => api.FPDFPath_Close(obj),
              _ => throw ArgumentError('Unknown path command'),
            };
            check(result != 0, 'Path command');
          }
          paint(obj, m);
          check(
            api.FPDFPath_SetDrawMode(
                  obj,
                  m['fill'] == null
                      ? 0
                      : m['evenOdd'] == true
                      ? 1
                      : 2,
                  m['stroke'] == null ? 0 : 1,
                ) !=
                0,
            'Path draw mode',
          );
        case 'image':
          final width = m['width'] as int,
              height = m['height'] as int,
              data = m['data'] as Uint8List;
          if (width <= 0 || height <= 0 || data.length != width * height * 4) {
            throw ArgumentError('Invalid RGBA bitmap');
          }
          final pixels = arena<Uint8>(data.length);
          for (var i = 0; i < data.length; i += 4) {
            pixels[i] = data[i + 2];
            pixels[i + 1] = data[i + 1];
            pixels[i + 2] = data[i];
            pixels[i + 3] = data[i + 3];
          }
          final bitmap = api.FPDFBitmap_CreateEx(
            width,
            height,
            4,
            pixels.cast(),
            width * 4,
          );
          check(bitmap != nullptr, 'Create bitmap');
          try {
            obj = api.FPDFPageObj_NewImageObj(doc);
            check(obj != nullptr, 'Create image');
            check(
              api.FPDFImageObj_SetBitmap(nullptr, 0, obj, bitmap) != 0,
              'Set bitmap',
            );
          } finally {
            api.FPDFBitmap_Destroy(bitmap);
          }
        case 'text':
          final font = this.font(m);
          obj = api.FPDFPageObj_CreateTextObj(
            doc,
            font,
            (m['fontSize'] as num).toDouble(),
          );
          check(obj != nullptr, 'Create text');
          check(
            api.FPDFText_SetText(obj, utf16(m['text'] as String)) != 0,
            'Set text',
          );
          paint(obj, m);
          if (m['stroke'] != null) {
            check(
              api.FPDFTextObj_SetTextRenderMode(
                    obj,
                    f.FPDF_TEXT_RENDERMODE.FPDF_TEXTRENDERMODE_FILL_STROKE,
                  ) !=
                  0,
              'Text render mode',
            );
          }
        default:
          throw UnsupportedError('PDF object ${m['type']}');
      }
      transform(obj, m['matrix'] as List);
      insert(page, obj);
      obj = nullptr; // Page owns it now.
    } finally {
      if (obj != nullptr) api.FPDFPageObj_Destroy(obj);
    }
  }

  f.FPDF_PAGEOBJECT objectAt(f.FPDF_PAGE page, int index) {
    if (index < 0 || index >= api.FPDFPage_CountObjects(page)) {
      throw RangeError('PDF object index $index');
    }
    return api.FPDFPage_GetObject(page, index);
  }

  void writeAnnotation(
    f.FPDF_PAGE page,
    Map m, {
    int? index,
    bool preserveAppearance = false,
  }) {
    final subtype = m['subtype'] as int;
    if (!{1, 2, 3, 5, 6, 9, 10, 11, 12, 15}.contains(subtype)) {
      throw UnsupportedError(
        'Writing PDF annotation subtype $subtype is not supported',
      );
    }
    if (index != null &&
        (index < 0 || index >= api.FPDFPage_GetAnnotCount(page))) {
      throw RangeError('PDF annotation index $index');
    }
    final annot = index == null
        ? api.FPDFPage_CreateAnnot(page, subtype)
        : api.FPDFPage_GetAnnot(page, index);
    check(annot != nullptr, 'Create/open annotation');
    try {
      if (api.FPDFAnnot_GetSubtype(annot) != subtype) {
        throw ArgumentError('Annotation subtype cannot change');
      }
      final quads = m['quads'] as List? ?? [];
      if (index != null &&
          api.FPDFAnnot_CountAttachmentPoints(annot) != quads.length) {
        throw UnsupportedError(
          'Updating the number of highlight quads requires replacing the annotation',
        );
      }
      if (subtype == 2 && m['uri'] == null) {
        throw UnsupportedError('Only URI link annotations can be written');
      }
      final r = m['rect'] as List;
      final rect = arena<f.FS_RECTF>();
      rect.ref
        ..left = (r[0] as num).toDouble()
        ..top = (r[1] as num).toDouble()
        ..right = (r[2] as num).toDouble()
        ..bottom = (r[3] as num).toDouble();
      check(api.FPDFAnnot_SetRect(annot, rect) != 0, 'Annotation rectangle');
      // A stale appearance would hide updated color/geometry. Let PDFium regenerate it.
      if (!preserveAppearance) api.FPDFAnnot_SetAP(annot, 0, nullptr);
      final color = m['color'] as List;
      if (!preserveAppearance) {
        check(
          api.FPDFAnnot_SetColor(
                annot,
                f.FPDFANNOT_COLORTYPE.FPDFANNOT_COLORTYPE_Color,
                color[0] as int,
                color[1] as int,
                color[2] as int,
                color[3] as int,
              ) !=
              0,
          'Annotation color',
        );
      }
      check(
        api.FPDFAnnot_SetFlags(annot, m['flags'] as int? ?? 4) != 0,
        'Annotation flags',
      );
      for (final (key, field) in [
        ('NM', 'id'),
        ('T', 'title'),
        ('Contents', 'content'),
        ('Subj', 'subject'),
        ('M', 'modified'),
      ]) {
        final value = m[field] as String?;
        if (value != null) {
          check(
            api.FPDFAnnot_SetStringValue(annot, utf8(key), utf16(value)) != 0,
            'Annotation $key',
          );
        }
      }
      if (index == null) {
        final created = m['created'] as String? ?? m['modified'] as String?;
        if (created != null) {
          api.FPDFAnnot_SetStringValue(
            annot,
            utf8('CreationDate'),
            utf16(created),
          );
        }
      }
      for (var i = 0; i < quads.length; i++) {
        final q = quads[i] as List, p = arena<f.FS_QUADPOINTSF>();
        p.ref
          ..x1 = (q[0][0] as num).toDouble()
          ..y1 = (q[0][1] as num).toDouble()
          ..x2 = (q[1][0] as num).toDouble()
          ..y2 = (q[1][1] as num).toDouble()
          ..x3 = (q[2][0] as num).toDouble()
          ..y3 = (q[2][1] as num).toDouble()
          ..x4 = (q[3][0] as num).toDouble()
          ..y4 = (q[3][1] as num).toDouble();
        check(
          (index == null
                  ? api.FPDFAnnot_AppendAttachmentPoints(annot, p)
                  : api.FPDFAnnot_SetAttachmentPoints(annot, i, p)) !=
              0,
          'Highlight quad',
        );
      }
      if (subtype == 15) {
        if (index != null) api.FPDFAnnot_RemoveInkList(annot);
        for (final raw in m['ink'] as List? ?? []) {
          final list = raw as List, points = arena<f.FS_POINTF>(list.length);
          for (var i = 0; i < list.length; i++) {
            points[i]
              ..x = (list[i][0] as num).toDouble()
              ..y = (list[i][1] as num).toDouble();
          }
          check(
            api.FPDFAnnot_AddInkStroke(annot, points, list.length) >= 0,
            'Ink stroke',
          );
        }
      }
      if (subtype == 2) {
        if (m['uri'] == null) {
          throw UnsupportedError('Only URI link annotations can be written');
        }
        check(
          api.FPDFAnnot_SetURI(annot, utf8(m['uri'] as String)) != 0,
          'Link URI',
        );
      }
      if (m['blankAppearance'] == true) {
        check(
          api.FPDFAnnot_SetAP(annot, 0, utf16('')) != 0,
          'Preserve annotation appearance layer',
        );
      }
    } catch (_) {
      if (index == null) {
        api.FPDFPage_RemoveAnnot(page, api.FPDFPage_GetAnnotIndex(page, annot));
      }
      rethrow;
    } finally {
      api.FPDFPage_CloseAnnot(annot);
    }
  }

  void place(f.FPDF_PAGE page, Map m) {
    final data = m['data'] as Uint8List;
    final buffer = arena<Uint8>(data.length)
      ..asTypedList(data.length).setAll(0, data);
    final source = api.FPDF_LoadMemDocument64(
      buffer.cast(),
      data.length,
      m['password'] == null ? nullptr : utf8(m['password'] as String),
    );
    check(source != nullptr, 'Open source PDF');
    try {
      final index = m['pageIndex'] as int;
      if (index < 0 || index >= api.FPDF_GetPageCount(source)) {
        throw RangeError('Source page index $index');
      }
      final sourcePage = api.FPDF_LoadPage(source, index);
      check(sourcePage != nullptr, 'Load source page');
      try {
        final g = geometry(sourcePage), r = g['rect'] as List;
        final geom = PdfPageGeometry(
          PdfRect(
            r[0] as double,
            r[1] as double,
            r[2] as double,
            r[3] as double,
          ),
          g['rotation'] as int,
        );
        final a = (m['matrix'] as List)
            .map((v) => (v as num).toDouble())
            .toList();
        final placement = PdfAffineTransform(
          a[0],
          a[1],
          a[2],
          a[3],
          a[4],
          a[5],
        );
        final matrix = placement.multiply(geom.toTopLeft);
        // PDFium's page exporter already applies CropBox and /Rotate inside
        // the form. Its coordinates are normalized bottom-left page space.
        final formMatrix = placement.multiply(
          PdfAffineTransform(1, 0, 0, -1, 0, geom.height),
        );
        final annotationsToCopy = m['copyAnnotations'] == true
            ? annotations(sourcePage, sourceDoc: source)
            : <Map<String, Object?>>[];
        for (final annotation in annotationsToCopy) {
          final type = annotation['subtype'] as int;
          if (type == 16) {
            continue; // Popup contents belong to their parent note.
          }
          if (!{1, 2, 3, 5, 6, 9, 10, 11, 12, 15}.contains(type) ||
              (type == 2 && annotation['uri'] == null) ||
              annotation['replyTo'] != null) {
            throw UnsupportedError(
              'Cannot preserve annotation subtype $type on a placed PDF page',
            );
          }
        }
        final xobject = api.FPDF_NewXObjectFromPage(doc, source, index);
        check(xobject != nullptr, 'Import PDF page');
        try {
          insertForm(page, xobject, formMatrix.values);
        } finally {
          api.FPDF_CloseXObject(xobject);
        }
        final preserveAppearance = annotationsToCopy.any(
          (a) => a['hasAppearance'] == true,
        );
        if (preserveAppearance) {
          // Keep original AP resources as a vector form. Only this disposable
          // copy is flattened; the source bytes and source content form stay intact.
          final appearanceDoc = api.FPDF_LoadMemDocument64(
            buffer.cast(),
            data.length,
            m['password'] == null ? nullptr : utf8(m['password'] as String),
          );
          check(appearanceDoc != nullptr, 'Open annotation appearance copy');
          final appearancePage = api.FPDF_LoadPage(appearanceDoc, index);
          try {
            check(appearancePage != nullptr, 'Load annotation appearance page');
            for (
              var i = api.FPDFPage_CountObjects(appearancePage) - 1;
              i >= 0;
              i--
            ) {
              final obj = api.FPDFPage_GetObject(appearancePage, i);
              check(
                api.FPDFPage_RemoveObject(appearancePage, obj) != 0,
                'Isolate annotation appearance',
              );
              api.FPDFPageObj_Destroy(obj);
            }
            check(
              api.FPDFPage_GenerateContent(appearancePage) != 0,
              'Generate appearance page',
            );
            final bitmap = api.FPDFBitmap_Create(1, 1, 1);
            check(bitmap != nullptr, 'Create annotation appearance bitmap');
            try {
              api.FPDF_RenderPageBitmap(
                bitmap,
                appearancePage,
                0,
                0,
                1,
                1,
                0,
                1,
              );
            } finally {
              api.FPDFBitmap_Destroy(bitmap);
            }
            final status = api.FPDFPage_Flatten(appearancePage, 0);
            check(status != 0, 'Flatten annotation appearance copy');
            if (status == 1) {
              final appearance = api.FPDF_NewXObjectFromPage(
                doc,
                appearanceDoc,
                index,
              );
              check(appearance != nullptr, 'Import annotation appearance');
              try {
                insertForm(page, appearance, formMatrix.values);
              } finally {
                api.FPDF_CloseXObject(appearance);
              }
            }
          } finally {
            if (appearancePage != nullptr) api.FPDF_ClosePage(appearancePage);
            api.FPDF_CloseDocument(appearanceDoc);
          }
        }
        for (final annotation in annotationsToCopy) {
          if (annotation['subtype'] == 16) continue;
          final spec = PdfAnnotationSpec.fromMessage(annotation);
          final bounds = matrix.transformRect(spec.bounds);
          final transformed = {
            ...annotation,
            'rect': [bounds.left, bounds.top, bounds.right, bounds.bottom],
            'blankAppearance': preserveAppearance,
            'quads': spec.quadPoints
                .map((q) => q.map(matrix.apply).map((p) => [p.x, p.y]).toList())
                .toList(),
            'ink': spec.inkStrokes
                .map((s) => s.map(matrix.apply).map((p) => [p.x, p.y]).toList())
                .toList(),
          };
          writeAnnotation(page, transformed);
        }
      } finally {
        api.FPDF_ClosePage(sourcePage);
      }
    } finally {
      api.FPDF_CloseDocument(source);
    }
  }
}
