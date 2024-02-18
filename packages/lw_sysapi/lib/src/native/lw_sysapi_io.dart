import 'dart:io';

import 'lw_sysapi_base.dart';
import 'lw_sysapi_windows.dart';
import 'lw_sysapi_linux.dart';

SysAPIPlatform createInstance() {
  if (Platform.isWindows) {
    return SysAPIWindows();
  } else if (Platform.isLinux) {
    return SysAPILinux();
  } else {
    return SysAPIBase();
  }
}
