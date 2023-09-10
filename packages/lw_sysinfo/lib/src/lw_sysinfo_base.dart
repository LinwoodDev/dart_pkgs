import 'dart:async';
import 'dart:typed_data';

import 'lw_sysinfo_stub.dart'
    if (dart.library.io) 'lw_sysinfo_io.dart'
    if (dart.library.html) 'lw_sysinfo_web.dart';

abstract class SysInfoPlatform {
  FutureOr<List<String>?> getFonts();
}

typedef ClipboardContent = ({String type, Uint8List data});

abstract class ClipboardManager {
  ClipboardContent? getContent();
  void setContent(ClipboardContent content);
}

class SysInfoBase implements SysInfoPlatform {
  @override
  List<String>? getFonts() {
    return null;
  }
}

class InternalClipboardManager implements ClipboardManager {
  ClipboardContent? _content;

  @override
  ClipboardContent? getContent() => _content;

  @override
  void setContent(ClipboardContent content) => _content = content;
}

SysInfoPlatform _instance = createInstance();

/// Base class for getting system information
class SysInfo {
  ///Get all system fonts
  ///Available on Windows, Linux and Web
  ///
  ///Returns null on error
  static FutureOr<List<String>?> getFonts() => _instance.getFonts();

  static FutureOr<ClipboardManager> getClipboardManager(
          {bool internal = false}) =>
      InternalClipboardManager();
}
