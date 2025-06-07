import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'input_leap_platform_interface.dart';

/// An implementation of [InputLeapPlatform] that uses method channels.
class MethodChannelInputLeap extends InputLeapPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('input_leap');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
