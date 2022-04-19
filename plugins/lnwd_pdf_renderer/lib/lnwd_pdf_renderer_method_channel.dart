import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lnwd_pdf_renderer_platform_interface.dart';

/// An implementation of [LnwdPdfRendererPlatform] that uses method channels.
class MethodChannelLnwdPdfRenderer extends LnwdPdfRendererPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lnwd_pdf_renderer');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
