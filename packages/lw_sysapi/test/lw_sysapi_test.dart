import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';
import 'package:lw_sysapi/lw_sysapi_platform_interface.dart';
import 'package:lw_sysapi/lw_sysapi_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLwSysapiPlatform
    with MockPlatformInterfaceMixin
    implements LwSysapiPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LwSysapiPlatform initialPlatform = LwSysapiPlatform.instance;

  test('$MethodChannelLwSysapi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLwSysapi>());
  });

  test('getPlatformVersion', () async {
    LwSysapi lwSysapiPlugin = LwSysapi();
    MockLwSysapiPlatform fakePlatform = MockLwSysapiPlatform();
    LwSysapiPlatform.instance = fakePlatform;

    expect(await lwSysapiPlugin.getPlatformVersion(), '42');
  });
}
