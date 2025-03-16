import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'input_leap_method_channel.dart';

abstract class InputLeapPlatform extends PlatformInterface {
  /// Constructs a InputLeapPlatform.
  InputLeapPlatform() : super(token: _token);

  static final Object _token = Object();

  static InputLeapPlatform _instance = MethodChannelInputLeap();

  /// The default instance of [InputLeapPlatform] to use.
  ///
  /// Defaults to [MethodChannelInputLeap].
  static InputLeapPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [InputLeapPlatform] when
  /// they register themselves.
  static set instance(InputLeapPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
