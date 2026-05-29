import 'dart:async';
import 'dart:typed_data';

import 'lw_sysapi_stub.dart'
    if (dart.library.io) 'lw_sysapi_io.dart'
    if (dart.library.js_interop) 'lw_sysapi_web.dart';

abstract class SysAPIPlatform {
  FutureOr<List<String>?> getFonts();

  FutureOr<ClipboardManager> getClipboardManager() =>
      UnsupportedClipboardManager();
}

typedef ClipboardContent = ({String type, Uint8List data});

abstract final class ClipboardMimeTypes {
  static const text = 'text/plain';
  static const html = 'text/html';
  static const png = 'image/png';
  static const jpeg = 'image/jpeg';
  static const gif = 'image/gif';
  static const webp = 'image/webp';
  static const tiff = 'image/tiff';
  static const bmp = 'image/bmp';
  static const ico = 'image/x-icon';
  static const heic = 'image/heic';
  static const heif = 'image/heif';
  static const avif = 'image/avif';
  static const pdf = 'application/pdf';
  static const svg = 'image/svg+xml';
  static const json = 'application/json';
  static const csv = 'text/csv';
  static const rtf = 'application/rtf';
  static const zip = 'application/zip';
  static const gzip = 'application/gzip';
  static const tar = 'application/x-tar';
  static const sevenZip = 'application/x-7z-compressed';
  static const mp3 = 'audio/mpeg';
  static const wav = 'audio/wav';
  static const mp4 = 'video/mp4';
  static const webm = 'video/webm';

  static const defaultTypes = [
    png,
    jpeg,
    gif,
    webp,
    tiff,
    bmp,
    svg,
    pdf,
    text,
    html,
    json,
    csv,
    rtf,
    zip,
    gzip,
    tar,
    sevenZip,
    ico,
    heic,
    heif,
    avif,
    mp3,
    wav,
    mp4,
    webm,
  ];
}

abstract class ClipboardManager {
  FutureOr<ClipboardContent?> getContent({Iterable<String>? types});
  FutureOr<bool> setContent(ClipboardContent content);
}

class SysAPIBase implements SysAPIPlatform {
  @override
  List<String>? getFonts() {
    return null;
  }

  @override
  ClipboardManager getClipboardManager() => UnsupportedClipboardManager();
}

class InternalClipboardManager implements ClipboardManager {
  ClipboardContent? _content;

  @override
  ClipboardContent? getContent({Iterable<String>? types}) {
    final content = _content;
    if (content == null) return null;
    if (types != null && !types.contains(content.type)) return null;
    return content;
  }

  @override
  bool setContent(ClipboardContent content) {
    _content = content;
    return true;
  }
}

class UnsupportedClipboardManager implements ClipboardManager {
  @override
  ClipboardContent? getContent({Iterable<String>? types}) => null;

  @override
  bool setContent(ClipboardContent content) => false;
}

SysAPIPlatform _instance = createInstance();

/// Base class for getting system information
class SysAPI {
  ///Get all system fonts
  ///Available on Windows, Linux and Web
  ///
  ///Returns null on error
  static FutureOr<List<String>?> getFonts() => _instance.getFonts();

  static FutureOr<ClipboardManager> getClipboardManager({
    bool internal = false,
  }) {
    if (internal) return InternalClipboardManager();
    return _instance.getClipboardManager();
  }
}
