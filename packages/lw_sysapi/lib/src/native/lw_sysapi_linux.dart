import 'dart:ffi' as ffi;
import 'dart:typed_data';

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
typedef _GdkAtomInternNative =
    ffi.Pointer Function(ffi.Pointer<Utf8> atomName, ffi.Int32 onlyIfExists);
typedef _GdkAtomInternDart =
    ffi.Pointer Function(ffi.Pointer<Utf8> atomName, int onlyIfExists);
typedef _GtkClipboardGetNative = ffi.Pointer Function(ffi.Pointer selection);
typedef _GtkClipboardGetDart = ffi.Pointer Function(ffi.Pointer selection);
typedef _GtkClipboardWaitForContentsNative =
    ffi.Pointer Function(ffi.Pointer clipboard, ffi.Pointer target);
typedef _GtkClipboardWaitForContentsDart =
    ffi.Pointer Function(ffi.Pointer clipboard, ffi.Pointer target);
typedef _GtkSelectionDataGetDataNative =
    ffi.Pointer<ffi.Uint8> Function(ffi.Pointer selectionData);
typedef _GtkSelectionDataGetDataDart =
    ffi.Pointer<ffi.Uint8> Function(ffi.Pointer selectionData);
typedef _GtkSelectionDataGetLengthNative =
    ffi.Int32 Function(ffi.Pointer selectionData);
typedef _GtkSelectionDataGetLengthDart =
    int Function(ffi.Pointer selectionData);
typedef _GtkSelectionDataFreeNative = ffi.Void Function(ffi.Pointer data);
typedef _GtkSelectionDataFreeDart = void Function(ffi.Pointer data);
typedef _GtkClipboardStoreNative = ffi.Void Function(ffi.Pointer clipboard);
typedef _GtkClipboardStoreDart = void Function(ffi.Pointer clipboard);
typedef _GtkClipboardSetWithDataNative =
    ffi.Int32 Function(
      ffi.Pointer clipboard,
      ffi.Pointer<_GtkTargetEntry> targets,
      ffi.Uint32 targetCount,
      ffi.Pointer<ffi.NativeFunction<_GtkClipboardGetFuncNative>> getFunc,
      ffi.Pointer<ffi.NativeFunction<_GtkClipboardClearFuncNative>> clearFunc,
      ffi.Pointer userData,
    );
typedef _GtkClipboardSetWithDataDart =
    int Function(
      ffi.Pointer clipboard,
      ffi.Pointer<_GtkTargetEntry> targets,
      int targetCount,
      ffi.Pointer<ffi.NativeFunction<_GtkClipboardGetFuncNative>> getFunc,
      ffi.Pointer<ffi.NativeFunction<_GtkClipboardClearFuncNative>> clearFunc,
      ffi.Pointer userData,
    );
typedef _GtkSelectionDataSetNative =
    ffi.Void Function(
      ffi.Pointer selectionData,
      ffi.Pointer type,
      ffi.Int32 format,
      ffi.Pointer<ffi.Uint8> data,
      ffi.Int32 length,
    );
typedef _GtkSelectionDataSetDart =
    void Function(
      ffi.Pointer selectionData,
      ffi.Pointer type,
      int format,
      ffi.Pointer<ffi.Uint8> data,
      int length,
    );
typedef _GtkClipboardGetFuncNative =
    ffi.Void Function(
      ffi.Pointer clipboard,
      ffi.Pointer selectionData,
      ffi.Uint32 info,
      ffi.Pointer userData,
    );
typedef _GtkClipboardClearFuncNative =
    ffi.Void Function(ffi.Pointer clipboard, ffi.Pointer userData);

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

final class _GtkTargetEntry extends ffi.Struct {
  external ffi.Pointer<Utf8> target;

  @ffi.Uint32()
  external int flags;

  @ffi.Uint32()
  external int info;
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

  @override
  ClipboardManager getClipboardManager() {
    try {
      return LinuxGtkClipboardManager();
    } catch (_) {
      return UnsupportedClipboardManager();
    }
  }
}

class _LinuxClipboardEntry {
  _LinuxClipboardEntry(this.content, this.targets, this.targetNames);

  final ClipboardContent content;
  final ffi.Pointer<_GtkTargetEntry> targets;
  final List<ffi.Pointer<Utf8>> targetNames;

  void dispose() {
    for (final targetName in targetNames) {
      calloc.free(targetName);
    }
    calloc.free(targets);
  }
}

class LinuxGtkClipboardManager implements ClipboardManager {
  static final _contents = <int, _LinuxClipboardEntry>{};
  static int _nextContentId = 1;

  late final ffi.DynamicLibrary _gtk;
  late final _GdkAtomInternDart _gdkAtomIntern;
  late final _GtkClipboardGetDart _gtkClipboardGet;
  late final _GtkClipboardWaitForContentsDart _gtkClipboardWaitForContents;
  late final _GtkSelectionDataGetDataDart _gtkSelectionDataGetData;
  late final _GtkSelectionDataGetLengthDart _gtkSelectionDataGetLength;
  late final _GtkSelectionDataFreeDart _gtkSelectionDataFree;
  late final _GtkClipboardStoreDart _gtkClipboardStore;
  late final _GtkClipboardSetWithDataDart _gtkClipboardSetWithData;

  static late _GtkSelectionDataSetDart _gtkSelectionDataSet;

  LinuxGtkClipboardManager() {
    _gtk = ffi.DynamicLibrary.open('libgtk-3.so.0');
    _gdkAtomIntern = _gtk
        .lookupFunction<_GdkAtomInternNative, _GdkAtomInternDart>(
          'gdk_atom_intern',
        );
    _gtkClipboardGet = _gtk
        .lookupFunction<_GtkClipboardGetNative, _GtkClipboardGetDart>(
          'gtk_clipboard_get',
        );
    _gtkClipboardWaitForContents = _gtk
        .lookupFunction<
          _GtkClipboardWaitForContentsNative,
          _GtkClipboardWaitForContentsDart
        >('gtk_clipboard_wait_for_contents');
    _gtkSelectionDataGetData = _gtk
        .lookupFunction<
          _GtkSelectionDataGetDataNative,
          _GtkSelectionDataGetDataDart
        >('gtk_selection_data_get_data');
    _gtkSelectionDataGetLength = _gtk
        .lookupFunction<
          _GtkSelectionDataGetLengthNative,
          _GtkSelectionDataGetLengthDart
        >('gtk_selection_data_get_length');
    _gtkSelectionDataFree = _gtk
        .lookupFunction<_GtkSelectionDataFreeNative, _GtkSelectionDataFreeDart>(
          'gtk_selection_data_free',
        );
    _gtkClipboardStore = _gtk
        .lookupFunction<_GtkClipboardStoreNative, _GtkClipboardStoreDart>(
          'gtk_clipboard_store',
        );
    _gtkClipboardSetWithData = _gtk
        .lookupFunction<
          _GtkClipboardSetWithDataNative,
          _GtkClipboardSetWithDataDart
        >('gtk_clipboard_set_with_data');
    _gtkSelectionDataSet = _gtk
        .lookupFunction<_GtkSelectionDataSetNative, _GtkSelectionDataSetDart>(
          'gtk_selection_data_set',
        );
  }

  @override
  ClipboardContent? getContent({Iterable<String>? types}) {
    final clipboard = _clipboard;
    if (clipboard == ffi.nullptr) return null;
    for (final type in types ?? ClipboardMimeTypes.defaultTypes) {
      for (final targetName in _targetNamesForType(type)) {
        final target = _atom(targetName);
        if (target == ffi.nullptr) continue;
        final selectionData = _gtkClipboardWaitForContents(clipboard, target);
        if (selectionData == ffi.nullptr) continue;
        try {
          final length = _gtkSelectionDataGetLength(selectionData);
          if (length <= 0) continue;
          final data = _gtkSelectionDataGetData(selectionData);
          if (data == ffi.nullptr) continue;
          return (
            type: type,
            data: Uint8List.fromList(data.asTypedList(length)),
          );
        } finally {
          _gtkSelectionDataFree(selectionData);
        }
      }
    }
    return null;
  }

  @override
  bool setContent(ClipboardContent content) {
    final clipboard = _clipboard;
    if (clipboard == ffi.nullptr) return false;
    final id = _nextContentId++;
    final targetNames = _targetNamesForType(
      content.type,
    ).map((targetName) => targetName.toNativeUtf8()).toList();
    final targets = calloc<_GtkTargetEntry>(targetNames.length);
    for (var i = 0; i < targetNames.length; i++) {
      targets[i]
        ..target = targetNames[i]
        ..flags = 0
        ..info = id;
    }
    _contents[id] = _LinuxClipboardEntry(content, targets, targetNames);
    final result = _gtkClipboardSetWithData(
      clipboard,
      targets,
      targetNames.length,
      ffi.Pointer.fromFunction<_GtkClipboardGetFuncNative>(_getClipboardData),
      ffi.Pointer.fromFunction<_GtkClipboardClearFuncNative>(
        _clearClipboardData,
      ),
      ffi.Pointer.fromAddress(id),
    );
    if (result == 0) {
      _contents.remove(id)?.dispose();
      return false;
    }
    _gtkClipboardStore(clipboard);
    return true;
  }

  ffi.Pointer get _clipboard {
    final atom = _atom('CLIPBOARD');
    if (atom == ffi.nullptr) return ffi.nullptr;
    return _gtkClipboardGet(atom);
  }

  ffi.Pointer _atom(String name) {
    final pointer = name.toNativeUtf8();
    try {
      return _gdkAtomIntern(pointer, 0);
    } finally {
      calloc.free(pointer);
    }
  }

  static void _getClipboardData(
    ffi.Pointer clipboard,
    ffi.Pointer selectionData,
    int info,
    ffi.Pointer userData,
  ) {
    final entry = _contents[info] ?? _contents[userData.address];
    final content = entry?.content;
    if (content == null) return;
    final type = content.type.toNativeUtf8();
    final data = calloc<ffi.Uint8>(content.data.length);
    try {
      data.asTypedList(content.data.length).setAll(0, content.data);
      final atom = ffi.DynamicLibrary.open('libgtk-3.so.0')
          .lookupFunction<_GdkAtomInternNative, _GdkAtomInternDart>(
            'gdk_atom_intern',
          )(type, 0);
      _gtkSelectionDataSet(selectionData, atom, 8, data, content.data.length);
    } finally {
      calloc.free(data);
      calloc.free(type);
    }
  }

  static void _clearClipboardData(ffi.Pointer clipboard, ffi.Pointer userData) {
    _contents.remove(userData.address)?.dispose();
  }

  static List<String> _targetNamesForType(String type) {
    switch (type) {
      case ClipboardMimeTypes.text:
        return [ClipboardMimeTypes.text, 'UTF8_STRING', 'TEXT', 'STRING'];
      case ClipboardMimeTypes.html:
        return [ClipboardMimeTypes.html, 'text/html;charset=utf-8'];
      case ClipboardMimeTypes.jpeg:
        return [ClipboardMimeTypes.jpeg, 'image/jpg'];
      case ClipboardMimeTypes.bmp:
        return [ClipboardMimeTypes.bmp, 'image/x-bmp', 'image/x-MS-bmp'];
      case ClipboardMimeTypes.tiff:
        return [ClipboardMimeTypes.tiff, 'image/tiff'];
      case ClipboardMimeTypes.svg:
        return [ClipboardMimeTypes.svg, 'image/svg'];
      case ClipboardMimeTypes.rtf:
        return [ClipboardMimeTypes.rtf, 'text/rtf'];
      case ClipboardMimeTypes.tar:
        return [ClipboardMimeTypes.tar, 'application/tar'];
      default:
        return [type];
    }
  }
}
