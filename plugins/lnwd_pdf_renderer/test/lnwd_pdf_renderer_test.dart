import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lnwd_pdf_renderer/lnwd_pdf_renderer.dart';
import 'package:lnwd_pdf_renderer/src/lnwd_pdf_renderer_platform_interface.dart';
import 'package:lnwd_pdf_renderer/src/lnwd_pdf_renderer_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLnwdPdfRendererPlatform
    with MockPlatformInterfaceMixin
    implements LnwdPdfRendererPlatform {
  @override
  Future<PdfDocument> render(Uint8List data) =>
      Future.value(const PdfDocument());
}

void main() {
  final LnwdPdfRendererPlatform initialPlatform =
      LnwdPdfRendererPlatform.instance;

  test('$MethodChannelLnwdPdfRenderer is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLnwdPdfRenderer>());
  });

  test('getPlatformVersion', () async {
    LnwdPdfRenderer lnwdPdfRendererPlugin = LnwdPdfRenderer();
    MockLnwdPdfRendererPlatform fakePlatform = MockLnwdPdfRendererPlatform();
    LnwdPdfRendererPlatform.instance = fakePlatform;

    expect(
        await lnwdPdfRendererPlugin
            .render(Uint8List.fromList([]))
            .then((value) => value.pages.length),
        0);
  });
}
