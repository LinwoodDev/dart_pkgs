import 'lnwd_pdf_renderer_platform_interface.dart';
export 'src/document.dart';
export 'src/page.dart';

class LnwdPdfRenderer {
  Future<String?> getPlatformVersion() {
    return LnwdPdfRendererPlatform.instance.getPlatformVersion();
  }
}
