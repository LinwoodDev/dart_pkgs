// In order to *not* need this ignore, consider extracting the "web" version
// of your plugin as a separate package, instead of inlining it in the same
// package as the core of your plugin.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html show window, CanvasElement, CanvasRenderingContext2D;
import 'dart:typed_data';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:lnwd_pdf_renderer/lnwd_pdf_renderer.dart';
import 'package:lnwd_pdf_renderer/src/web/pdf_js.dart';

import 'src/lnwd_pdf_renderer_platform_interface.dart';

/// A web implementation of the LnwdPdfRendererPlatform of the LnwdPdfRenderer plugin.
class LnwdPdfRendererWeb extends LnwdPdfRendererPlatform {
  /// Constructs a LnwdPdfRendererWeb
  LnwdPdfRendererWeb();

  static void registerWith(Registrar registrar) {
    LnwdPdfRendererPlatform.instance = LnwdPdfRendererWeb();
  }

  /// Returns a [String] containing the version of the platform.
  @override
  Future<PdfDocument> render(Uint8List data) async {
    final document = await PdfJsLib.getDocument(data).promise;
    final pages = <PdfPage>[];
    for (int i = 0; i < document.numPages; i++) {
      final page = await document.getPage(i + 1);
      final viewport = page.getViewport(PdfJsViewportOptions(scale: 1));
      final canvas =
          html.window.document.createElement('canvas') as html.CanvasElement;
      canvas.width = viewport.width;
      canvas.height = viewport.height;
      final context = canvas.getContext('2d') as html.CanvasRenderingContext2D;
      await page
          .render(
            PdfJsRenderOptions(
              canvasContext: context,
              viewport: viewport,
            ),
          )
          .promise;
      final pageData =
          (canvas.getContext("2d") as html.CanvasRenderingContext2D?)
              ?.getImageData(0, 0, canvas.width ?? 0, canvas.height ?? 0)
              .data;
      if (pageData != null) {
        pages.add(PdfPage(
          width: viewport.width,
          height: viewport.height,
          data: Uint8List.fromList(pageData),
        ));
      }
    }
    return PdfDocument(pages: pages);
  }
}
