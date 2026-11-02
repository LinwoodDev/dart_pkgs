import 'dart:math' as math;
import 'dart:typed_data';

import 'package:pdfrx_engine/pdfrx_engine.dart';

/// An affine matrix in PDF user space: x'=a*x+c*y+e, y'=b*x+d*y+f.
class PdfAffineTransform {
  const PdfAffineTransform(this.a, this.b, this.c, this.d, this.e, this.f);
  const PdfAffineTransform.identity() : this(1, 0, 0, 1, 0, 0);
  const PdfAffineTransform.translation(double x, double y)
    : this(1, 0, 0, 1, x, y);
  const PdfAffineTransform.scale(double x, double y) : this(x, 0, 0, y, 0, 0);
  factory PdfAffineTransform.rotation(double radians) => PdfAffineTransform(
    math.cos(radians),
    math.sin(radians),
    -math.sin(radians),
    math.cos(radians),
    0,
    0,
  );
  final double a, b, c, d, e, f;
  List<double> get values => [a, b, c, d, e, f];
  PdfPoint apply(PdfPoint p) =>
      PdfPoint(a * p.x + c * p.y + e, b * p.x + d * p.y + f);

  /// Composition: applies [other] first, then this matrix.
  PdfAffineTransform multiply(PdfAffineTransform other) => PdfAffineTransform(
    a * other.a + c * other.b,
    b * other.a + d * other.b,
    a * other.c + c * other.d,
    b * other.c + d * other.d,
    a * other.e + c * other.f + e,
    b * other.e + d * other.f + f,
  );
  PdfAffineTransform inverse() {
    final det = a * d - b * c;
    if (!det.isFinite || det.abs() < 1e-12) {
      throw StateError('Singular PDF transform');
    }
    return PdfAffineTransform(
      d / det,
      -b / det,
      -c / det,
      a / det,
      (c * f - d * e) / det,
      (b * e - a * f) / det,
    );
  }

  PdfRect transformRect(PdfRect r) {
    final points = [
      r.topLeft,
      r.topRight,
      r.bottomLeft,
      r.bottomRight,
    ].map(apply).toList();
    return PdfRect(
      points.map((p) => p.x).reduce(math.min),
      points.map((p) => p.y).reduce(math.max),
      points.map((p) => p.x).reduce(math.max),
      points.map((p) => p.y).reduce(math.min),
    );
  }
}

/// Raw page box and inherited clockwise rotation, including CropBox offsets.
class PdfPageGeometry {
  const PdfPageGeometry(this.box, this.rotation);
  final PdfRect box;
  final int rotation;
  double get width => rotation.isOdd ? box.height : box.width;
  double get height => rotation.isOdd ? box.width : box.height;

  /// Raw PDF coordinates to the visible, rotated page's top-left coordinates.
  PdfAffineTransform get toTopLeft => switch (rotation % 4) {
    0 => PdfAffineTransform(1, 0, 0, -1, -box.left, box.top),
    1 => PdfAffineTransform(0, 1, 1, 0, -box.bottom, -box.left),
    2 => PdfAffineTransform(-1, 0, 0, 1, box.right, -box.bottom),
    _ => PdfAffineTransform(0, -1, -1, 0, box.top, box.right),
  };
}

/// Integer RGBA components. No Flutter dependency.
class PdfRgba {
  const PdfRgba(this.red, this.green, this.blue, [this.alpha = 255])
    : assert(red >= 0 && red <= 255),
      assert(green >= 0 && green <= 255),
      assert(blue >= 0 && blue <= 255),
      assert(alpha >= 0 && alpha <= 255);
  const PdfRgba.black() : this(0, 0, 0);
  const PdfRgba.yellow() : this(255, 255, 0);
  final int red, green, blue, alpha;
  List<int> get values => [red, green, blue, alpha];
  factory PdfRgba.fromValues(List<dynamic> v) =>
      PdfRgba(v[0] as int, v[1] as int, v[2] as int, v[3] as int);
}

/// Compact PDF path commands. Quadratic curves are converted to cubic curves.
class PdfVectorPath {
  final List<List<double>> _commands = [];
  double _x = 0, _y = 0, _startX = 0, _startY = 0;
  List<List<double>> get commands =>
      _commands.map(List<double>.unmodifiable).toList(growable: false);
  PdfVectorPath moveTo(double x, double y) {
    _commands.add([0, x, y]);
    _x = _startX = x;
    _y = _startY = y;
    return this;
  }

  PdfVectorPath lineTo(double x, double y) {
    _commands.add([1, x, y]);
    _x = x;
    _y = y;
    return this;
  }

  PdfVectorPath cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x,
    double y,
  ) {
    _commands.add([2, x1, y1, x2, y2, x, y]);
    _x = x;
    _y = y;
    return this;
  }

  PdfVectorPath quadraticTo(double cx, double cy, double x, double y) =>
      cubicTo(
        _x + (cx - _x) * 2 / 3,
        _y + (cy - _y) * 2 / 3,
        x + (cx - x) * 2 / 3,
        y + (cy - y) * 2 / 3,
        x,
        y,
      );
  PdfVectorPath close() {
    _commands.add([3]);
    _x = _startX;
    _y = _startY;
    return this;
  }

  PdfVectorPath addRect(double x, double y, double width, double height) =>
      moveTo(x, y)
          .lineTo(x + width, y)
          .lineTo(x + width, y + height)
          .lineTo(x, y + height)
          .close();
  PdfVectorPath addEllipse(double x, double y, double width, double height) {
    const k = .5522847498307936;
    final rx = width / 2, ry = height / 2, cx = x + rx, cy = y + ry;
    return moveTo(cx + rx, cy)
        .cubicTo(cx + rx, cy + k * ry, cx + k * rx, cy + ry, cx, cy + ry)
        .cubicTo(cx - k * rx, cy + ry, cx - rx, cy + k * ry, cx - rx, cy)
        .cubicTo(cx - rx, cy - k * ry, cx - k * rx, cy - ry, cx, cy - ry)
        .cubicTo(cx + k * rx, cy - ry, cx + rx, cy - k * ry, cx + rx, cy)
        .close();
  }
}

sealed class PdfObjectCommand {
  const PdfObjectCommand();
  Map<String, Object?> toMessage();
}

class PdfDrawPath extends PdfObjectCommand {
  PdfDrawPath(
    this.path, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1,
    this.evenOdd = false,
    this.blendMode = 'Normal',
    this.dashes = const [],
    this.lineCap = 1,
    this.lineJoin = 1,
    this.transform = const PdfAffineTransform.identity(),
  });
  final PdfVectorPath path;
  final PdfRgba? fill, stroke;
  final double strokeWidth;
  final bool evenOdd;
  final String blendMode;
  final List<double> dashes;

  /// PDF line caps: butt=0, round=1, square=2; joins: miter=0, round=1, bevel=2.
  final int lineCap, lineJoin;
  final PdfAffineTransform transform;
  @override
  Map<String, Object?> toMessage() => {
    'type': 'path',
    'commands': path.commands,
    'fill': fill?.values,
    'stroke': stroke?.values,
    'strokeWidth': strokeWidth,
    'evenOdd': evenOdd,
    'blendMode': blendMode,
    'dashes': dashes,
    'lineCap': lineCap,
    'lineJoin': lineJoin,
    'matrix': transform.values,
  };
}

/// A bitmap with RGBA pixels. Matrix maps its unit square to PDF user space.
class PdfDrawImage extends PdfObjectCommand {
  const PdfDrawImage(
    this.rgba, {
    required this.width,
    required this.height,
    required this.transform,
  });
  final Uint8List rgba;
  final int width, height;
  final PdfAffineTransform transform;
  @override
  Map<String, Object?> toMessage() => {
    'type': 'image',
    'data': rgba,
    'width': width,
    'height': height,
    'matrix': transform.values,
  };
}

class PdfDrawText extends PdfObjectCommand {
  const PdfDrawText(
    this.text, {
    this.fontData,
    this.fontName = 'Helvetica',
    this.fontSize = 12,
    this.color = const PdfRgba.black(),
    this.strokeWidth = 0,
    this.transform = const PdfAffineTransform.identity(),
  });
  final String text, fontName;
  final Uint8List? fontData;
  final double fontSize;
  final PdfRgba color;

  /// Optional outline for synthetic bold when embedding a variable font.
  final double strokeWidth;
  final PdfAffineTransform transform;
  @override
  Map<String, Object?> toMessage() => {
    'type': 'text',
    'text': text,
    'font': fontData,
    'fontName': fontName,
    'fontKey': fontData == null
        ? fontName
        : (_fontKeys[fontData!] ??= PdfAnnotationSpec._newId()),
    'fontSize': fontSize,
    'fill': color.values,
    'stroke': strokeWidth > 0 ? color.values : null,
    'strokeWidth': strokeWidth,
    'matrix': transform.values,
  };
}

final _fontKeys = Expando<String>('PDF font resources');

/// Places a source page without changing its bytes. Matrix operates on the
/// source page's visible top-left coordinates (rotation and CropBox normalized).
class PdfPlacePage extends PdfObjectCommand {
  const PdfPlacePage(
    this.data, {
    required this.pageIndex,
    required this.transform,
    this.copyAnnotations = true,
    this.password,
  });
  final Uint8List data;
  final int pageIndex;
  final PdfAffineTransform transform;
  final bool copyAnnotations;
  final String? password;
  @override
  Map<String, Object?> toMessage() => {
    'type': 'page',
    'data': data,
    'pageIndex': pageIndex,
    'matrix': transform.values,
    'copyAnnotations': copyAnnotations,
    'password': password,
  };
}

class PdfTransformObject extends PdfObjectCommand {
  const PdfTransformObject(this.index, this.transform);
  final int index;
  final PdfAffineTransform transform;
  @override
  Map<String, Object?> toMessage() => {
    'type': 'transformObject',
    'index': index,
    'matrix': transform.values,
  };
}

class PdfRemoveObject extends PdfObjectCommand {
  const PdfRemoveObject(this.index);
  final int index;
  @override
  Map<String, Object?> toMessage() => {'type': 'removeObject', 'index': index};
}

enum PdfAnnotationType {
  unknown(0),
  text(1),
  link(2),
  freeText(3),
  line(4),
  square(5),
  circle(6),
  polygon(7),
  polyline(8),
  highlight(9),
  underline(10),
  squiggly(11),
  strikeout(12),
  stamp(13),
  caret(14),
  ink(15),
  popup(16),
  fileAttachment(17),
  sound(18),
  movie(19),
  widget(20),
  screen(21),
  printerMark(22),
  trapNet(23),
  watermark(24),
  threeD(25),
  richMedia(26),
  xfaWidget(27),
  redact(28);

  const PdfAnnotationType(this.value);
  final int value;
  static PdfAnnotationType fromValue(int value) =>
      values.where((t) => t.value == value).firstOrNull ?? unknown;
}

/// Independent annotation snapshot. Indices are only valid until the next edit.
class PdfAnnotationDetails {
  const PdfAnnotationDetails({
    required this.index,
    required this.type,
    required this.bounds,
    required this.metadata,
    this.id,
    this.color = const PdfRgba.yellow(),
    this.flags = 0,
    this.quadPoints = const [],
    this.inkStrokes = const [],
    this.replyTo,
    this.popupId,
    this.uri,
    this.colorAvailable = true,
    this.hasAppearance = false,
  });
  final int index, flags;
  final PdfAnnotationType type;
  final PdfRect bounds;
  final PdfAnnotation metadata;
  final String? id, replyTo, popupId, uri;
  final PdfRgba color;

  /// PDFium cannot read the dictionary color when an appearance stream exists.
  final bool colorAvailable, hasAppearance;
  final List<List<PdfPoint>> quadPoints;
  final List<List<PdfPoint>> inkStrokes;
  factory PdfAnnotationDetails.fromMessage(Map<dynamic, dynamic> m) =>
      PdfAnnotationDetails(
        index: m['index'] as int,
        type: PdfAnnotationType.fromValue(m['subtype'] as int),
        bounds: _rect(m['rect'] as List),
        id: m['id'] as String?,
        flags: m['flags'] as int? ?? 0,
        color: PdfRgba.fromValues(m['color'] as List? ?? [255, 255, 0, 255]),
        metadata: PdfAnnotation(
          title: m['title'] as String?,
          content: m['content'] as String?,
          subject: m['subject'] as String?,
          modificationDate: PdfDateTime.fromPdfDateString(
            m['modified'] as String?,
          ),
          creationDate: PdfDateTime.fromPdfDateString(m['created'] as String?),
        ),
        quadPoints: _points(m['quads']),
        inkStrokes: _points(m['ink']),
        replyTo: m['replyTo'] as String?,
        popupId: m['popupId'] as String?,
        uri: m['uri'] as String?,
        colorAvailable: m['colorAvailable'] as bool? ?? true,
        hasAppearance: m['hasAppearance'] as bool? ?? false,
      );
}

PdfRect _rect(List v) => PdfRect(
  (v[0] as num).toDouble(),
  (v[1] as num).toDouble(),
  (v[2] as num).toDouble(),
  (v[3] as num).toDouble(),
);
List<List<PdfPoint>> _points(dynamic v) => List.unmodifiable(
  (v as List? ?? []).map(
    (row) => List<PdfPoint>.unmodifiable(
      (row as List).map(
        (p) => PdfPoint((p[0] as num).toDouble(), (p[1] as num).toDouble()),
      ),
    ),
  ),
);

/// Semantic PDF annotation. Geometry is in raw PDF page coordinates.
class PdfAnnotationSpec {
  PdfAnnotationSpec({
    required this.type,
    required this.bounds,
    this.content = '',
    this.title = '',
    this.subject = '',
    String? id,
    this.color = const PdfRgba.yellow(),
    this.flags = 4,
    this.quadPoints = const [],
    this.inkStrokes = const [],
    this.uri,
  }) : id = id ?? _newId();
  final PdfAnnotationType type;
  final PdfRect bounds;
  final String content, title, subject, id;
  final PdfRgba color;
  final int flags;
  final List<List<PdfPoint>> quadPoints, inkStrokes;
  final String? uri;
  Map<String, Object?> toMessage() => {
    'subtype': type.value,
    'rect': [bounds.left, bounds.top, bounds.right, bounds.bottom],
    'content': content,
    'title': title,
    'subject': subject,
    'id': id,
    'color': color.values,
    'flags': flags,
    'quads': quadPoints.map((q) => q.map((p) => [p.x, p.y]).toList()).toList(),
    'ink': inkStrokes.map((s) => s.map((p) => [p.x, p.y]).toList()).toList(),
    'uri': uri,
    'modified': PdfDateTime.fromDateTime(DateTime.now().toUtc()).pdfDateString,
  };
  factory PdfAnnotationSpec.fromMessage(Map<dynamic, dynamic> m) =>
      PdfAnnotationSpec(
        type: PdfAnnotationType.fromValue(m['subtype'] as int),
        bounds: _rect(m['rect'] as List),
        content: m['content'] as String? ?? '',
        title: m['title'] as String? ?? '',
        subject: m['subject'] as String? ?? '',
        id: m['id'] as String?,
        color: PdfRgba.fromValues(m['color'] as List? ?? [255, 255, 0, 255]),
        flags: m['flags'] as int? ?? 4,
        quadPoints: _points(m['quads']),
        inkStrokes: _points(m['ink']),
        uri: m['uri'] as String?,
      );
  static String _newId() {
    final random = math.Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

class PdfPageObjectInfo {
  const PdfPageObjectInfo({
    required this.index,
    required this.type,
    required this.bounds,
    required this.transform,
  });
  final int index, type;
  final PdfRect bounds;
  final PdfAffineTransform transform;
  factory PdfPageObjectInfo.fromMessage(Map<dynamic, dynamic> m) {
    final a = (m['matrix'] as List).map((n) => (n as num).toDouble()).toList();
    return PdfPageObjectInfo(
      index: m['index'] as int,
      type: m['type'] as int,
      bounds: _rect(m['rect'] as List),
      transform: PdfAffineTransform(a[0], a[1], a[2], a[3], a[4], a[5]),
    );
  }
}
