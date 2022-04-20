@JS()
library pdf.js;

import 'dart:html';
import 'dart:typed_data';

import 'package:js/js.dart';

@JS('pdfjsLib')
class PdfJsLib {
  external static PdfJsDocumentLoader getDocument(Uint8List data);
}

@JS()
@anonymous
class PdfJsDocumentLoader {
  external Future<PdfJsDocument> get promise;
}

@JS()
@anonymous
class PdfJsDocument {
  external int get numPages;
  external Future<PdfJsPage> getPage(int pageNumber);
}

@JS()
@anonymous
class PdfJsPage {
  external PdfJsViewport getViewport(PdfJsViewportOptions options);
  external PdfJsRenderTask render(PdfJsRenderOptions options);
}

@JS()
@anonymous
class PdfJsRenderTask {
  external Future<void> promise;
}

@JS()
@anonymous
class PdfJsRenderOptions {
  external CanvasRenderingContext2D get canvasContext;
  external PdfJsViewport get viewport;

  external factory PdfJsRenderOptions({
    CanvasRenderingContext2D canvasContext,
    PdfJsViewport viewport,
  });
}

@JS()
@anonymous
class PdfJsViewportOptions {
  external int get scale;

  external factory PdfJsViewportOptions({
    int scale,
  });
}

@JS()
@anonymous
class PdfJsViewport {
  external int get width;
  external int get height;
}
