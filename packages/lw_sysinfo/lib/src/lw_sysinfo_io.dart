import 'dart:io';

import 'lw_sysinfo_base.dart';
import 'lw_sysinfo_windows.dart';
import 'lw_sysinfo_linux.dart';

SysInfoPlatform createInstance() {
  if (Platform.isWindows) {
    return SysInfoWindows();
  } else if (Platform.isLinux) {
    return SysInfoLinux();
  } else {
    return SysInfoBase();
  }
}
