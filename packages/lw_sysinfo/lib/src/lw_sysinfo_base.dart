import 'dart:async';
import 'dart:typed_data';

import 'lw_sysinfo_stub.dart'
    if (dart.library.io) 'lw_sysinfo_io.dart'
    if (dart.library.html) 'lw_sysinfo_web.dart';

abstract class SysInfoPlatform {
  FutureOr<List<String>?> getFonts();
}

abstract class ClipboardManagerPlatform {
  FutureOr<Uint8List?> read();
}

class SysInfoBase implements SysInfoPlatform {
  @override
  List<String>? getFonts() {
    return null;
  }
}

SysInfoPlatform _instance = createInstance();

/// Base class for getting system information
class SysInfo {
  ///Get all system fonts
  ///Available on Windows, Linux and Web
  ///
  ///Returns null on error
  static FutureOr<List<String>?> getFonts() => _instance.getFonts();
}
