import 'dart:typed_data';

import 'package:lnwd_pdf_renderer/src/document.dart';

import 'src/lnwd_pdf_renderer_platform_interface.dart';
export 'src/document.dart';
export 'src/page.dart';

class LnwdPdfRenderer {
  Future<PdfDocument> render(Uint8List data) {
    return LnwdPdfRendererPlatform.instance.render(data);
  }
}
