
import 'input_leap_platform_interface.dart';

class InputLeap {
  Future<String?> getPlatformVersion() {
    return InputLeapPlatform.instance.getPlatformVersion();
  }
}
