import 'dart:async';

import 'lw_sysinfo_stub.dart'
    if (dart.library.io) 'lw_sysinfo_io.dart'
    if (dart.library.html) 'lw_sysinfo_web.dart';

abstract class SysInfoPlatform {
  FutureOr<List<String>?> getFonts();
}

class SysInfoBase implements SysInfoPlatform {
  @override
  List<String>? getFonts() {
    return null;
  }
}

SysInfoPlatform _instance = createInstance();

class SysInfo {
  static FutureOr<List<String>?> getFonts() => _instance.getFonts();
}
