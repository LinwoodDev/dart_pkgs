import 'dart:async';
import 'dart:typed_data';

import 'lw_sysapi_stub.dart'
    if (dart.library.io) 'lw_sysapi_io.dart'
    if (dart.library.js_interop) 'lw_sysapi_web.dart';

abstract class SysAPIPlatform {
  FutureOr<List<String>?> getFonts();
}

typedef ClipboardContent = ({String type, Uint8List data});

abstract class ClipboardManager {
  ClipboardContent? getContent();
  void setContent(ClipboardContent content);
}

class SysAPIBase implements SysAPIPlatform {
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

SysAPIPlatform _instance = createInstance();

/// Base class for getting system information
class SysAPI {
  ///Get all system fonts
  ///Available on Windows, Linux and Web
  ///
  ///Returns null on error
  static FutureOr<List<String>?> getFonts() => _instance.getFonts();

  static FutureOr<ClipboardManager> getClipboardManager(
          {bool internal = false}) =>
      InternalClipboardManager();
}
