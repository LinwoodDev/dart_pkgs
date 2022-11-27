import 'dart:io';

import './lw_sysinfo_base.dart';
import './lw_sysinfo_windows.dart';

SysInfoPlatform createInstance() {
  if (Platform.isWindows) {
    return SysInfoWindows();
  } else {
    return SysInfoBase();
  }
}
