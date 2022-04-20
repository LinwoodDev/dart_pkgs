import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lnwd_pdf_renderer/lnwd_pdf_renderer.dart';
import 'package:lnwd_pdf_renderer/src/lnwd_pdf_renderer_method_channel.dart';

void main() {
  MethodChannelLnwdPdfRenderer platform = MethodChannelLnwdPdfRenderer();
  const MethodChannel channel = MethodChannel('lnwd_pdf_renderer');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return const PdfDocument();
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(
        await platform
            .render(Uint8List.fromList([]))
            .then((value) => value.pages.length),
        0);
  });
}
