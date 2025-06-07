import 'dart:ffi' as ffi;

import 'package:ffi/ffi.dart';
import 'package:lw_sysapi/src/native/lw_sysapi_base.dart';

typedef _FcInitNative = ffi.Void Function();
typedef _FcInitDart = void Function();
typedef _FcPatternCreateNative = ffi.Pointer Function();
typedef _FcObjectSetBuildNative =
    ffi.Pointer Function(ffi.Pointer<Utf8> object, ffi.Int32 first);
typedef _FcObjectSetBuildDart =
    ffi.Pointer Function(ffi.Pointer<Utf8> object, int first);
typedef _FcPatternGetStringNative =
    ffi.Int32 Function(
      ffi.Pointer pattern,
      ffi.Pointer<Utf8> object,
      ffi.Int32 n,
      ffi.Pointer<ffi.Pointer<ffi.Int8>> value,
    );
typedef _FcPatternGetStringDart =
    int Function(
      ffi.Pointer pattern,
      ffi.Pointer<Utf8> object,
      int n,
      ffi.Pointer<ffi.Pointer<ffi.Int8>> value,
    );
typedef _FcFontSetDestroyNative = ffi.Void Function(ffi.Pointer fontSet);
typedef _FcFontSetDestroyDart = void Function(ffi.Pointer fontSet);

// typedef struct _FcFontSet {
//         int nfont;
//         int sfont;
//         FcPattern **fonts;
// } FcFontSet;

final class _FcFontSet extends ffi.Struct {
  @ffi.Int32()
  external int nfont;

  @ffi.Int32()
  external int sfont;

  external ffi.Pointer<ffi.Pointer> fonts;
}

typedef _FcFontListNative =
    ffi.Pointer<_FcFontSet> Function(
      ffi.Pointer config,
      ffi.Pointer pattern,
      ffi.Pointer objectSet,
    );

class SysAPILinux extends SysAPIPlatform {
  static const String _libPath = 'libfontconfig.so.1';
  final ffi.DynamicLibrary _dylib;
  late final _FcInitDart _fcInit;
  late final _FcPatternCreateNative _fcPatternCreate;
  late final _FcObjectSetBuildDart _fcObjectSetBuild;
  late final _FcFontListNative _fcFontList;
  late final _FcPatternGetStringDart _fcPatternGetString;
  late final _FcFontSetDestroyDart _fcFontSetDestroy;

  SysAPILinux() : _dylib = ffi.DynamicLibrary.open(_libPath) {
    _fcInit = _dylib.lookupFunction<_FcInitNative, _FcInitDart>('FcInit');
    _fcPatternCreate = _dylib
        .lookupFunction<_FcPatternCreateNative, _FcPatternCreateNative>(
          'FcPatternCreate',
        );
    _fcObjectSetBuild = _dylib
        .lookupFunction<_FcObjectSetBuildNative, _FcObjectSetBuildDart>(
          'FcObjectSetBuild',
        );
    _fcFontList = _dylib.lookupFunction<_FcFontListNative, _FcFontListNative>(
      'FcFontList',
    );
    _fcPatternGetString = _dylib
        .lookupFunction<_FcPatternGetStringNative, _FcPatternGetStringDart>(
          'FcPatternGetString',
        );
    _fcFontSetDestroy = _dylib
        .lookupFunction<_FcFontSetDestroyNative, _FcFontSetDestroyDart>(
          'FcFontSetDestroy',
        );
  }

  @override
  List<String> getFonts() {
    final fcFamily = 'family'.toNativeUtf8();
    _fcInit();
    final pattern = _fcPatternCreate();
    final objectSet = _fcObjectSetBuild(fcFamily, 0);
    final fontList = _fcFontList(ffi.nullptr, pattern, objectSet);
    if (fontList == ffi.nullptr) {
      return [];
    }
    final count = fontList.ref.nfont;
    final fonts = <String>{};
    for (var i = 0; i < count; i++) {
      final font = fontList.ref.fonts[i];
      final fontName = calloc<ffi.Pointer<ffi.Int8>>();
      final result = _fcPatternGetString(font, fcFamily, 0, fontName);
      if (result == 0 && fontName.value != ffi.nullptr) {
        fonts.add(fontName.value.cast<Utf8>().toDartString());
      }
    }
    _fcFontSetDestroy(fontList);
    calloc.free(fcFamily);

    return fonts.toList();
  }
}
