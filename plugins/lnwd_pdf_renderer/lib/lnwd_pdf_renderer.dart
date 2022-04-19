import 'lnwd_pdf_renderer_platform_interface.dart';

class LnwdPdfRenderer {
  Future<String?> getPlatformVersion() {
    return LnwdPdfRendererPlatform.instance.getPlatformVersion();
  }
}
