@JS()
library pdf.js;

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
  external Future<PdfJsPage> render();
}
