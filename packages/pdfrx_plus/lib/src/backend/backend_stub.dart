import 'package:pdfrx_engine/pdfrx_engine.dart';

void configureBackend({String? wasmModulesUrl}) {}
Future<void> initializeBackend() async {}
Future<Object?> execute(PdfDocument document, Map<String, Object?> request) =>
    Future.error(
      UnsupportedError('pdfrx_plus needs PDFium (native or WebAssembly)'),
    );
