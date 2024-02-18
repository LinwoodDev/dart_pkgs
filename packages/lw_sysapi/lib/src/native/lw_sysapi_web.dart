// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

import 'lw_sysapi_base.dart';

SysAPIPlatform createInstance() {
  return SysAPIWeb();
}

@JS()
@staticInterop
class JSWindow {}

extension JSWindowExtension on JSWindow {
  external Object? queryLocalFonts();
}

@JS()
@staticInterop
class JSFontData {}

extension JSFontDataExtension on JSFontData {
  external String get family;
}

class SysAPIWeb extends SysAPIPlatform {
  @override
  Future<List<String>?> getFonts() async {
    final jsWindow = window as JSWindow;
    if (!hasProperty(jsWindow, 'queryLocalFonts')) {
      return null;
    }
    final promise = jsWindow.queryLocalFonts();
    if (promise == null) {
      return null;
    }
    final fontNames = await promiseToFuture(promise) as List?;
    if (fontNames == null) {
      return null;
    }
    final data = fontNames.cast<JSFontData>();
    return data.map((e) => e.family).toSet().toList();
  }
}
