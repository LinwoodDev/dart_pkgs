import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as html;

import 'lw_sysapi_base.dart';

SysAPIPlatform createInstance() {
  return SysAPIWeb();
}

@JS('window.queryLocalFonts')
external JSPromise<JSArray<FontData>> queryLocalFonts();

@JS('FontData')
extension type FontData._(JSObject _) implements JSObject {
  external FontData();
  external String get family;
}

class SysAPIWeb extends SysAPIPlatform {
  @override
  Future<List<String>?> getFonts() async {
    if (!html.window.hasProperty('queryLocalFonts'.toJS).toDart) {
      return null;
    }
    final data = await queryLocalFonts().toDart;
    return data.toDart.map((e) => e.family).toSet().toList();
  }
}
