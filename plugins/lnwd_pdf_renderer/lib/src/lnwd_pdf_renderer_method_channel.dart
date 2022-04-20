import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lnwd_pdf_renderer/lnwd_pdf_renderer.dart';

import 'lnwd_pdf_renderer_platform_interface.dart';

/// An implementation of [LnwdPdfRendererPlatform] that uses method channels.
class MethodChannelLnwdPdfRenderer extends LnwdPdfRendererPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lnwd_pdf_renderer');

  @override
  Future<PdfDocument> render(Uint8List data) async {
    final document =
        await methodChannel.invokeMethod<PdfDocument>('render', data);
    if (document == null) {
      throw PlatformException(
        code: 'lnwd_pdf_renderer_error',
        message: 'Failed to render PDF document.',
      );
    }
    return document;
  }
}
