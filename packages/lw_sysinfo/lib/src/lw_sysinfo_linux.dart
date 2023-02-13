import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:lw_sysinfo/src/lw_sysinfo_base.dart';

typedef _FcInitLoadConfigAndFontsNative = ffi.Pointer Function();
typedef _FcConfigDestroyNative = ffi.Void Function(ffi.Pointer config);
typedef _FcConfigDestroyDart = void Function(ffi.Pointer config);
typedef _FcPatternCreateNative = ffi.Pointer Function();
typedef _FcPatternDestroyNative = ffi.Void Function(ffi.Pointer pattern);
typedef _FcPatternDestroyDart = void Function(ffi.Pointer pattern);
typedef _FcObjectSetBuildNative = ffi.Pointer Function(
  ffi.Pointer<Utf8> object,
);
typedef _FcObjectSetDestroyNative = ffi.Void Function(ffi.Pointer fontSet);
typedef _FcObjectSetDestroyDart = void Function(ffi.Pointer fontSet);
typedef _FcPatternGetStringNative = ffi.Int32 Function(
  ffi.Pointer pattern,
  ffi.Pointer<Utf8> object,
  ffi.Int32 n,
  ffi.Pointer<ffi.Pointer<ffi.Int8>> value,
);
typedef _FcPatternGetStringDart = int Function(ffi.Pointer pattern,
    ffi.Pointer<Utf8> object, int n, ffi.Pointer<ffi.Pointer<ffi.Int8>> value);
typedef _FcFontSetDestroyNative = ffi.Void Function(ffi.Pointer fontSet);
typedef _FcFontSetDestroyDart = void Function(ffi.Pointer fontSet);

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
  late final _FcConfigDestroyDart _fcConfigDestroy;
  late final _FcPatternCreateNative _fcPatternCreate;
  late final _FcPatternDestroyDart _fcPatternDestroy;
  late final _FcObjectSetBuildNative _fcObjectSetBuild;
  late final _FcObjectSetDestroyDart _fcObjectSetDestroy;
  late final _FcFontListNative _fcFontList;
  late final _FcPatternGetStringDart _fcPatternGetString;
  late final _FcFontSetDestroyDart _fcFontSetDestroy;

  SysInfoLinux() : _dylib = ffi.DynamicLibrary.open(_libPath) {
    _fcInitLoadConfigAndFonts = _dylib.lookupFunction<
        _FcInitLoadConfigAndFontsNative,
        _FcInitLoadConfigAndFontsNative>('FcInitLoadConfigAndFonts');
    _fcConfigDestroy =
        _dylib.lookupFunction<_FcConfigDestroyNative, _FcConfigDestroyDart>(
            'FcConfigDestroy');
    _fcPatternCreate =
        _dylib.lookupFunction<_FcPatternCreateNative, _FcPatternCreateNative>(
            'FcPatternCreate');
    _fcPatternDestroy =
        _dylib.lookupFunction<_FcPatternDestroyNative, _FcPatternDestroyDart>(
            'FcPatternDestroy');
    _fcObjectSetBuild =
        _dylib.lookupFunction<_FcObjectSetBuildNative, _FcObjectSetBuildNative>(
            'FcObjectSetBuild');
    _fcObjectSetDestroy = _dylib.lookupFunction<_FcObjectSetDestroyNative,
        _FcObjectSetDestroyDart>('FcObjectSetDestroy');
    _fcFontList = _dylib
        .lookupFunction<_FcFontListNative, _FcFontListNative>('FcFontList');
    _fcPatternGetString = _dylib.lookupFunction<_FcPatternGetStringNative,
        _FcPatternGetStringDart>('FcPatternGetString');
    _fcFontSetDestroy =
        _dylib.lookupFunction<_FcFontSetDestroyNative, _FcFontSetDestroyDart>(
            'FcFontSetDestroy');
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
      calloc.free(fontName);
    }
    _fcFontSetDestroy(fontList);
    _fcObjectSetDestroy(objectSet);
    _fcPatternDestroy(pattern);
    _fcConfigDestroy(config);
    calloc.free(fcFamily);

    return fonts.toList();
  }
}
