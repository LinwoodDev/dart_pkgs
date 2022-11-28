import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:lw_sysinfo/src/lw_sysinfo_base.dart';

typedef _FcInitLoadConfigAndFontsNative = ffi.Pointer Function();
typedef _FcPatternCreateNative = ffi.Pointer Function();
typedef _FcObjectSetBuildNative = ffi.Pointer Function(
  ffi.Pointer<Utf8> object,
);
typedef _FcPatternGetStringNative = ffi.Int32 Function(
  ffi.Pointer pattern,
  ffi.Pointer<Utf8> object,
  ffi.Int32 n,
  ffi.Pointer<ffi.Pointer<ffi.Int8>> value,
);
typedef _FcPatternGetStringDart = int Function(ffi.Pointer pattern,
    ffi.Pointer<Utf8> object, int n, ffi.Pointer<ffi.Pointer<ffi.Int8>> value);

// typedef struct _FcFontSet {
//         int nfont;
//         int sfont;
//         FcPattern **fonts;
// } FcFontSet;

class _FcFontSet extends ffi.Struct {
  @ffi.Int32()
  external int nfont;

  @ffi.Int32()
  external int sfont;

  external ffi.Pointer<ffi.Pointer> fonts;
}

typedef _FcFontListNative = ffi.Pointer<_FcFontSet> Function(
    ffi.Pointer config, ffi.Pointer pattern, ffi.Pointer objectSet);

class SysInfoLinux extends SysInfoPlatform {
  static const String _libPath = 'libfontconfig.so.1';
  final ffi.DynamicLibrary _dylib;
  late final _FcInitLoadConfigAndFontsNative _fcInitLoadConfigAndFonts;
  late final _FcPatternCreateNative _fcPatternCreate;
  late final _FcObjectSetBuildNative _fcObjectSetBuild;
  late final _FcFontListNative _fcFontList;
  late final _FcPatternGetStringDart _fcPatternGetString;

  SysInfoLinux() : _dylib = ffi.DynamicLibrary.open(_libPath) {
    _fcInitLoadConfigAndFonts = _dylib.lookupFunction<
        _FcInitLoadConfigAndFontsNative,
        _FcInitLoadConfigAndFontsNative>('FcInitLoadConfigAndFonts');
    _fcPatternCreate =
        _dylib.lookupFunction<_FcPatternCreateNative, _FcPatternCreateNative>(
            'FcPatternCreate');
    _fcObjectSetBuild =
        _dylib.lookupFunction<_FcObjectSetBuildNative, _FcObjectSetBuildNative>(
            'FcObjectSetBuild');
    _fcFontList = _dylib
        .lookupFunction<_FcFontListNative, _FcFontListNative>('FcFontList');
    _fcPatternGetString = _dylib.lookupFunction<_FcPatternGetStringNative,
        _FcPatternGetStringDart>('FcPatternGetString');
  }

  @override
  List<String> getFonts() {
    final fcFamily = 'family'.toNativeUtf8();
    final config = _fcInitLoadConfigAndFonts();
    final pattern = _fcPatternCreate();
    final objectSet = _fcObjectSetBuild(fcFamily);
    final fontList = _fcFontList(config, pattern, objectSet);
    final count = fontList.ref.nfont;
    final fonts = <String>{};
    for (var i = 0; i < count; i++) {
      final font = fontList.ref.fonts[i];
      final fontName = calloc<ffi.Pointer<ffi.Int8>>();
      final result = _fcPatternGetString(font, fcFamily, 0, fontName);
      if (result == 0) {
        fonts.add(fontName.value.cast<Utf8>().toDartString());
      }
    }
    return fonts.toList();
  }
}
