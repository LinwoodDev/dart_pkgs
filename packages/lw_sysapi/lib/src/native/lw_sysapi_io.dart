import 'dart:io';

import 'package:flutter/services.dart';

import 'lw_sysapi_base.dart';
import 'lw_sysapi_windows.dart';
import 'lw_sysapi_linux.dart';

SysAPIPlatform createInstance() {
  if (Platform.isWindows) {
    return SysAPIWindows();
  } else if (Platform.isLinux) {
    return SysAPILinux();
  } else if (Platform.isAndroid) {
    return SysAPIAndroid();
  } else if (Platform.isIOS || Platform.isMacOS) {
    return SysAPIApple();
  } else {
    return SysAPIBase();
  }
}

class SysAPIAndroid extends SysAPIBase {
  @override
  ClipboardManager getClipboardManager() => AndroidClipboardManager();
}

class AndroidClipboardManager implements ClipboardManager {
  static const _platform = MethodChannel('linwood.dev/lw_sysapi');

  @override
  Future<ClipboardContent?> getContent({Iterable<String>? types}) async {
    final result = await _platform.invokeMapMethod<String, Object?>(
      'readClipboard',
      {'types': types?.toList()},
    );
    if (result == null) return null;
    final type = result['type'];
    final data = result['data'];
    if (type is! String || data is! Uint8List) return null;
    return (type: type, data: data);
  }

  @override
  Future<bool> setContent(ClipboardContent content) async {
    final result = await _platform.invokeMethod<bool>('writeClipboard', {
      'type': content.type,
      'data': content.data,
    });
    return result ?? false;
  }
}

class SysAPIApple extends SysAPIBase {
  @override
  ClipboardManager getClipboardManager() => AppleClipboardManager();
}

class AppleClipboardManager implements ClipboardManager {
  static const _platform = MethodChannel('linwood.dev/lw_sysapi');

  @override
  Future<ClipboardContent?> getContent({Iterable<String>? types}) async {
    final result = await _platform.invokeMapMethod<String, Object?>(
      'readClipboard',
      {'types': types?.toList()},
    );
    if (result == null) return null;
    final type = result['type'];
    final data = result['data'];
    if (type is! String || data is! Uint8List) return null;
    return (type: type, data: data);
  }

  @override
  Future<bool> setContent(ClipboardContent content) async {
    final result = await _platform.invokeMethod<bool>('writeClipboard', {
      'type': content.type,
      'data': content.data,
    });
    return result ?? false;
  }
}
