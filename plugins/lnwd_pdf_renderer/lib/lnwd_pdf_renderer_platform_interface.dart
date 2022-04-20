import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lnwd_pdf_renderer_method_channel.dart';

abstract class LnwdPdfRendererPlatform extends PlatformInterface {
  /// Constructs a LnwdPdfRendererPlatform.
  LnwdPdfRendererPlatform() : super(token: _token);

  static final Object _token = Object();

  static LnwdPdfRendererPlatform _instance = MethodChannelLnwdPdfRenderer();

  /// The default instance of [LnwdPdfRendererPlatform] to use.
  ///
  /// Defaults to [MethodChannelLnwdPdfRenderer].
  static LnwdPdfRendererPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LnwdPdfRendererPlatform] when
  /// they register themselves.
  static set instance(LnwdPdfRendererPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
