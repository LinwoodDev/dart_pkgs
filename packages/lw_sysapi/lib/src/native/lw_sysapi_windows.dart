import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'lw_sysapi_base.dart';

final _fontNames = <String>{};

class SysAPIWindows extends SysAPIPlatform {
  static int _enumerateFonts(
      Pointer<LOGFONT> logFont, Pointer<TEXTMETRIC> _, int fontType, int ___) {
    // Get extended information from the font
    final logFontEx = logFont.cast<ENUMLOGFONTEX>();
    final name = logFontEx.ref.elfFullName;
    // Dont add fonts starts with '@'
    if (name.codeUnitAt(0) != 0x40 && fontType == 4) {
      _fontNames.add(name);
    }
    return TRUE; // continue enumeration
  }

  @override
  List<String> getFonts() {
    final hDC = GetDC(NULL);
    final searchFont = calloc<LOGFONT>()
      ..ref.lfCharSet = FONT_CHARSET.DEFAULT_CHARSET;
    final callback = Pointer.fromFunction<FONTENUMPROC>(_enumerateFonts, 0);

    EnumFontFamiliesEx(hDC, searchFont, callback, 0, 0);
    free(searchFont);
    return _fontNames.toList();
  }
}
