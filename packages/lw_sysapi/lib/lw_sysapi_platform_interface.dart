import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'lw_sysapi_method_channel.dart';

abstract class LwSysapiPlatform extends PlatformInterface {
  /// Constructs a LwSysapiPlatform.
  LwSysapiPlatform() : super(token: _token);

  static final Object _token = Object();

  static LwSysapiPlatform _instance = MethodChannelLwSysapi();

  /// The default instance of [LwSysapiPlatform] to use.
  ///
  /// Defaults to [MethodChannelLwSysapi].
  static LwSysapiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LwSysapiPlatform] when
  /// they register themselves.
  static set instance(LwSysapiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
