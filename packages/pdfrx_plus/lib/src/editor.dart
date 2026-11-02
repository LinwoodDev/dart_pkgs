import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:synchronized/synchronized.dart';

import 'backend/backend_stub.dart'
    if (dart.library.io) 'backend/backend_native.dart'
    if (dart.library.js_interop) 'backend/backend_web.dart'
    as backend;
import 'models.dart';

/// Call before pdfrxFlutterInitialize on web. Native needs no configuration.
void configurePdfrxPlus({String? wasmModulesUrl}) =>
    backend.configureBackend(wasmModulesUrl: wasmModulesUrl);

/// Call after pdfrx initialization and before opening documents on web.
Future<void> initializePdfrxPlus() => backend.initializeBackend();

final _documentLocks = Expando<Lock>('pdfrx_plus document editing');

/// Adds editing APIs to an existing pdfrx document without owning its lifetime.
class PdfEditSession {
  PdfEditSession(this.document);
  final PdfDocument document;
  Lock get _lock => _documentLocks[document] ??= Lock();
  Future<Object?> _run(
    Map<String, Object?> request, {
    int? changedPage,
    bool newPage = false,
  }) => _lock.synchronized(() async {
    if (PdfrxEntryFunctions.instance.backendType == PdfrxBackendType.pdfKit) {
      throw UnsupportedError('pdfrx_plus editing requires the PDFium backend');
    }
    await document.assemble();
    final pageIndex = request['pageIndex'] as int?;
    if (pageIndex != null &&
        (pageIndex < 0 || pageIndex >= document.pages.length)) {
      throw RangeError.index(pageIndex, document.pages, 'pageIndex');
    }
    try {
      return await backend.execute(document, request);
    } finally {
      // Batches are not transactional. Keep pdfrx's page cache consistent even
      // when a later command fails after earlier objects were inserted.
      if (newPage) {
        await document.reloadPages();
      } else if (changedPage != null) {
        await document.reloadPages(pageNumbersToReload: [changedPage + 1]);
      }
    }
  });
  Future<PdfPage> addPage({
    required double width,
    required double height,
  }) async {
    if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
      throw ArgumentError('Page dimensions must be finite and positive');
    }
    await _run({
      'action': 'addPage',
      'width': width,
      'height': height,
    }, newPage: true);
    return document.pages.last;
  }

  Future<void> apply(int pageIndex, Iterable<PdfObjectCommand> commands) async {
    final messages = commands.map((c) => c.toMessage()).toList();
    if (messages.isEmpty) return;
    await _run({
      'action': 'objects',
      'pageIndex': pageIndex,
      'commands': messages,
    }, changedPage: pageIndex);
  }

  Future<PdfPageGeometry> geometry(int pageIndex) async {
    final result =
        await _run({'action': 'geometry', 'pageIndex': pageIndex}) as Map;
    final r = result['rect'] as List;
    return PdfPageGeometry(
      PdfRect(
        (r[0] as num).toDouble(),
        (r[1] as num).toDouble(),
        (r[2] as num).toDouble(),
        (r[3] as num).toDouble(),
      ),
      result['rotation'] as int,
    );
  }

  Future<List<PdfAnnotationDetails>> loadAnnotations(int pageIndex) async =>
      (await _run({'action': 'annotations', 'pageIndex': pageIndex}) as List)
          .map((m) => PdfAnnotationDetails.fromMessage(m as Map))
          .toList(growable: false);
  Future<List<PdfPageObjectInfo>> loadObjects(int pageIndex) async =>
      (await _run({'action': 'listObjects', 'pageIndex': pageIndex}) as List)
          .map((m) => PdfPageObjectInfo.fromMessage(m as Map))
          .toList(growable: false);
  Future<void> addAnnotation(int pageIndex, PdfAnnotationSpec spec) async {
    await _run({
      'action': 'annotation',
      'pageIndex': pageIndex,
      'spec': spec.toMessage(),
    }, changedPage: pageIndex);
  }

  Future<void> updateAnnotation(
    int pageIndex,
    int index,
    PdfAnnotationSpec spec, {
    bool preserveAppearance = false,
  }) async {
    await _run({
      'action': 'annotation',
      'pageIndex': pageIndex,
      'index': index,
      'spec': spec.toMessage(),
      'preserveAppearance': preserveAppearance,
    }, changedPage: pageIndex);
  }

  Future<void> removeAnnotation(int pageIndex, int index) async {
    await _run({
      'action': 'removeAnnotation',
      'pageIndex': pageIndex,
      'index': index,
    }, changedPage: pageIndex);
  }
}

extension PdfDocumentEditing on PdfDocument {
  PdfEditSession get editor => PdfEditSession(this);
}

extension PdfPageEditing on PdfPage {
  Future<List<PdfAnnotationDetails>> loadAnnotationDetails() =>
      document.editor.loadAnnotations(pageNumber - 1);
  Future<List<PdfPageObjectInfo>> loadPageObjects() =>
      document.editor.loadObjects(pageNumber - 1);
  Future<PdfPageGeometry> loadGeometry() =>
      document.editor.geometry(pageNumber - 1);
  Future<void> addObjects(Iterable<PdfObjectCommand> commands) =>
      document.editor.apply(pageNumber - 1, commands);
  Future<void> addAnnotation(PdfAnnotationSpec spec) =>
      document.editor.addAnnotation(pageNumber - 1, spec);
}
