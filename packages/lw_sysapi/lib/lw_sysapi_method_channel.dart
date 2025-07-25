import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'lw_sysapi_platform_interface.dart';

/// An implementation of [LwSysapiPlatform] that uses method channels.
class MethodChannelLwSysapi extends LwSysapiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('lw_sysapi');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
