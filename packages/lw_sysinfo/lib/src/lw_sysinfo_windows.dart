import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import './lw_sysinfo_base.dart';

final _fontNames = <String>[];

class SysInfoWindows extends SysInfoPlatform {
  static int _enumerateFonts(
      Pointer<LOGFONT> logFont, Pointer<TEXTMETRIC> _, int __, int ___) {
    // Get extended information from the font
    final logFontEx = logFont.cast<ENUMLOGFONTEX>();

    _fontNames.add(logFontEx.ref.elfFullName);
    return TRUE; // continue enumeration
  }

  @override
  List<String> getFonts() {
    final hDC = GetDC(NULL);
    final searchFont = calloc<LOGFONT>()..ref.lfCharSet = ANSI_CHARSET;
    final callback =
        Pointer.fromFunction<EnumFontFamExProc>(_enumerateFonts, 0);

    EnumFontFamiliesEx(hDC, searchFont, callback, 0, 0);
    _fontNames.sort();
    free(searchFont);
    return _fontNames;
  }
}
