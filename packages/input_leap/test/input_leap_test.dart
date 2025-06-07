import 'package:flutter_test/flutter_test.dart';
import 'package:input_leap/input_leap.dart';
import 'package:input_leap/input_leap_platform_interface.dart';
import 'package:input_leap/input_leap_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInputLeapPlatform
    with MockPlatformInterfaceMixin
    implements InputLeapPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final InputLeapPlatform initialPlatform = InputLeapPlatform.instance;

  test('$MethodChannelInputLeap is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInputLeap>());
  });

  test('getPlatformVersion', () async {
    InputLeap inputLeapPlugin = InputLeap();
    MockInputLeapPlatform fakePlatform = MockInputLeapPlatform();
    InputLeapPlatform.instance = fakePlatform;

    expect(await inputLeapPlugin.getPlatformVersion(), '42');
  });
}
