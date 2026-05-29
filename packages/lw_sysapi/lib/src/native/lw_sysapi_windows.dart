import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'lw_sysapi_base.dart';

final _fontNames = <String>{};

class SysAPIWindows extends SysAPIPlatform {
  static int _enumerateFonts(
    Pointer<LOGFONT> logFont,
    Pointer<TEXTMETRIC> _,
    int fontType,
    int _,
  ) {
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
    final hDC = GetDC(null);
    final searchFont = calloc<LOGFONT>()..ref.lfCharSet = DEFAULT_CHARSET;
    final callback = Pointer.fromFunction<FONTENUMPROC>(_enumerateFonts, 0);

    EnumFontFamiliesEx(hDC, searchFont, callback, const LPARAM(0), 0);
    free(searchFont);
    return _fontNames.toList();
  }

  @override
  ClipboardManager getClipboardManager() => WindowsClipboardManager();
}

class WindowsClipboardManager implements ClipboardManager {
  @override
  ClipboardContent? getContent({Iterable<String>? types}) {
    if (!OpenClipboard(null).value) return null;
    try {
      for (final type in types ?? ClipboardMimeTypes.defaultTypes) {
        for (final format in _formatsForType(type, forWriting: false)) {
          if (!IsClipboardFormatAvailable(format).value) continue;
          final handle = GetClipboardData(format).value;
          if (!handle.isValid) continue;
          final data = _readData(HGLOBAL(handle), format, type);
          if (data != null) return (type: type, data: data);
        }
      }
      return null;
    } finally {
      CloseClipboard();
    }
  }

  @override
  bool setContent(ClipboardContent content) {
    final formats = _formatsForType(content.type);
    if (formats.isEmpty || !OpenClipboard(null).value) return false;
    final memories = <HGLOBAL>[];
    var clipboardOwnsMemory = false;
    try {
      if (!EmptyClipboard().value) return false;
      for (final format in formats) {
        final memory = _writeData(content, format);
        if (memory == null) continue;
        memories.add(memory);
        final result = SetClipboardData(format, HANDLE(memory)).value;
        if (!result.isValid) continue;
        memories.remove(memory);
        clipboardOwnsMemory = true;
      }
      return clipboardOwnsMemory;
    } finally {
      for (final memory in memories) {
        GlobalFree(memory);
      }
      CloseClipboard();
    }
  }

  static Uint8List? _readData(HGLOBAL handle, int format, String type) {
    if (format == CF_UNICODETEXT) {
      final pointer = GlobalLock(handle).value;
      if (pointer == nullptr) return null;
      try {
        return Uint8List.fromList(
          utf8.encode(pointer.cast<Utf16>().toDartString()),
        );
      } finally {
        GlobalUnlock(handle);
      }
    }
    final data = _readGlobalMemory(handle);
    if (data == null) return null;
    if (type == ClipboardMimeTypes.html &&
        format == _registerFormat('HTML Format')) {
      return _windowsHtmlToHtml(data);
    }
    if (type == ClipboardMimeTypes.bmp &&
        (format == CF_DIB || format == CF_DIBV5)) {
      return _dibToBmp(data);
    }
    return data;
  }

  static Uint8List? _readGlobalMemory(HGLOBAL handle) {
    final size = GlobalSize(handle).value;
    if (size <= 0) return null;
    final pointer = GlobalLock(handle).value;
    if (pointer == nullptr) return null;
    try {
      return Uint8List.fromList(pointer.cast<Uint8>().asTypedList(size));
    } finally {
      GlobalUnlock(handle);
    }
  }

  static HGLOBAL? _writeData(ClipboardContent content, int format) {
    if (format == CF_UNICODETEXT) {
      return _writeUtf16Text(utf8.decode(content.data, allowMalformed: true));
    }
    if (content.type == ClipboardMimeTypes.html &&
        format == _registerFormat('HTML Format')) {
      return _writeGlobalMemory(_htmlToWindowsHtml(content.data));
    }
    if (content.type == ClipboardMimeTypes.bmp && format == CF_DIB) {
      return _writeGlobalMemory(_bmpToDib(content.data));
    }
    return _writeGlobalMemory(content.data);
  }

  static HGLOBAL? _writeUtf16Text(String text) {
    final textPointer = text.toNativeUtf16();
    final size = (text.length + 1) * sizeOf<Uint16>();
    final handle = GlobalAlloc(GMEM_MOVEABLE, size).value;
    if (!handle.isValid) {
      calloc.free(textPointer);
      return null;
    }
    final pointer = GlobalLock(handle).value;
    if (pointer == nullptr) {
      calloc.free(textPointer);
      GlobalFree(handle);
      return null;
    }
    try {
      pointer
          .cast<Uint8>()
          .asTypedList(size)
          .setAll(0, textPointer.cast<Uint8>().asTypedList(size));
    } finally {
      GlobalUnlock(handle);
      calloc.free(textPointer);
    }
    return handle;
  }

  static HGLOBAL? _writeGlobalMemory(Uint8List data) {
    final handle = GlobalAlloc(GMEM_MOVEABLE, data.length).value;
    if (!handle.isValid) return null;
    final pointer = GlobalLock(handle).value;
    if (pointer == nullptr) {
      GlobalFree(handle);
      return null;
    }
    try {
      pointer.cast<Uint8>().asTypedList(data.length).setAll(0, data);
    } finally {
      GlobalUnlock(handle);
    }
    return handle;
  }

  static List<int> _formatsForType(String type, {bool forWriting = true}) {
    switch (type) {
      case ClipboardMimeTypes.text:
        return forWriting
            ? [CF_UNICODETEXT, _registerFormat(ClipboardMimeTypes.text)]
            : [CF_UNICODETEXT, _registerFormat(ClipboardMimeTypes.text)];
      case ClipboardMimeTypes.html:
        return [_registerFormat('HTML Format'), _registerFormat(type)];
      case ClipboardMimeTypes.png:
        return [_registerFormat('PNG'), _registerFormat(type)];
      case ClipboardMimeTypes.jpeg:
        return [_registerFormat('JFIF'), _registerFormat(type)];
      case ClipboardMimeTypes.gif:
        return [_registerFormat('GIF'), _registerFormat(type)];
      case ClipboardMimeTypes.tiff:
        return [CF_TIFF, _registerFormat('TIFF'), _registerFormat(type)];
      case ClipboardMimeTypes.bmp:
        return forWriting
            ? [CF_DIB, _registerFormat(type), _registerFormat('BMP')]
            : [CF_DIBV5, CF_DIB, _registerFormat(type), _registerFormat('BMP')];
      case ClipboardMimeTypes.pdf:
        return [
          _registerFormat('Portable Document Format'),
          _registerFormat(type),
        ];
      case ClipboardMimeTypes.svg:
        return [_registerFormat(type), _registerFormat('SVG')];
      case ClipboardMimeTypes.rtf:
        return [_registerFormat('Rich Text Format'), _registerFormat(type)];
      default:
        return [_registerFormat(type)];
    }
  }

  static Uint8List? _dibToBmp(Uint8List dib) {
    if (dib.length < 4) return null;
    final dibData = ByteData.sublistView(dib);
    final headerSize = dibData.getUint32(0, Endian.little);
    if (headerSize > dib.length || headerSize < 12) return null;
    final bitsOffset = 14 + _dibBitsOffset(dib, headerSize);
    final fileSize = 14 + dib.length;
    final result = Uint8List(fileSize);
    final resultData = ByteData.sublistView(result);
    result[0] = 0x42;
    result[1] = 0x4d;
    resultData.setUint32(2, fileSize, Endian.little);
    resultData.setUint32(10, bitsOffset, Endian.little);
    result.setRange(14, result.length, dib);
    return result;
  }

  static int _dibBitsOffset(Uint8List dib, int headerSize) {
    if (headerSize == 12 && dib.length >= 12) {
      final bitCount = ByteData.sublistView(dib).getUint16(10, Endian.little);
      final colorTableEntries = bitCount <= 8 ? 1 << bitCount : 0;
      return headerSize + colorTableEntries * 3;
    }
    if (headerSize < 40 || dib.length < 40) return headerSize;
    final data = ByteData.sublistView(dib);
    final bitCount = data.getUint16(14, Endian.little);
    final compression = data.getUint32(16, Endian.little);
    final colorsUsed = data.getUint32(32, Endian.little);
    final colorTableEntries = colorsUsed != 0
        ? colorsUsed
        : bitCount <= 8
        ? 1 << bitCount
        : 0;
    final bitFieldsSize = compression == 3 && headerSize == 40 ? 12 : 0;
    return headerSize + bitFieldsSize + colorTableEntries * 4;
  }

  static Uint8List _bmpToDib(Uint8List bmp) {
    if (bmp.length < 14 || bmp[0] != 0x42 || bmp[1] != 0x4d) return bmp;
    return Uint8List.sublistView(bmp, 14);
  }

  static Uint8List _htmlToWindowsHtml(Uint8List htmlBytes) {
    final html = utf8.decode(htmlBytes, allowMalformed: true);
    final document = html.contains('<html') && html.contains('<body')
        ? html
        : '<html><body>$html</body></html>';
    final fragmentStart = '<!--StartFragment-->';
    final fragmentEnd = '<!--EndFragment-->';
    final htmlWithFragment = document.contains(fragmentStart)
        ? document
        : _addHtmlFragmentMarkers(document, fragmentStart, fragmentEnd);
    const headerTemplate =
        'Version:1.0\r\n'
        'StartHTML:0000000000\r\n'
        'EndHTML:0000000000\r\n'
        'StartFragment:0000000000\r\n'
        'EndFragment:0000000000\r\n';
    final headerLength = utf8.encode(headerTemplate).length;
    final htmlData = utf8.encode(htmlWithFragment);
    final htmlText = utf8.decode(htmlData);
    final startFragment =
        headerLength +
        utf8.encode(htmlText.split(fragmentStart).first).length +
        utf8.encode(fragmentStart).length;
    final endFragment =
        headerLength + utf8.encode(htmlText.split(fragmentEnd).first).length;
    final endHtml = headerLength + htmlData.length;
    final header =
        'Version:1.0\r\n'
        'StartHTML:${_offset(headerLength)}\r\n'
        'EndHTML:${_offset(endHtml)}\r\n'
        'StartFragment:${_offset(startFragment)}\r\n'
        'EndFragment:${_offset(endFragment)}\r\n';
    return Uint8List.fromList([...utf8.encode(header), ...htmlData]);
  }

  static Uint8List _windowsHtmlToHtml(Uint8List data) {
    final text = utf8.decode(data, allowMalformed: true);
    final start = _htmlOffset(text, 'StartFragment');
    final end = _htmlOffset(text, 'EndFragment');
    if (start == null || end == null || start < 0 || end <= start) {
      return data;
    }
    final bytes = Uint8List.fromList(utf8.encode(text));
    if (end > bytes.length) return data;
    return Uint8List.sublistView(bytes, start, end);
  }

  static int? _htmlOffset(String text, String name) {
    final match = RegExp('$name:(\\d+)').firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String _offset(int value) => value.toString().padLeft(10, '0');

  static String _addHtmlFragmentMarkers(
    String document,
    String fragmentStart,
    String fragmentEnd,
  ) {
    final bodyStart = RegExp(
      r'<body[^>]*>',
      caseSensitive: false,
    ).firstMatch(document);
    final bodyEnds = RegExp(
      r'</body>',
      caseSensitive: false,
    ).allMatches(document).toList();
    if (bodyStart == null || bodyEnds.isEmpty) {
      return '<html><body>$fragmentStart$document$fragmentEnd</body></html>';
    }
    final bodyEnd = bodyEnds.last;
    return document
        .replaceRange(bodyEnd.start, bodyEnd.start, fragmentEnd)
        .replaceRange(bodyStart.end, bodyStart.end, fragmentStart);
  }

  static int _registerFormat(String name) {
    final pointer = name.toNativeUtf16();
    try {
      return RegisterClipboardFormat(PCWSTR(pointer)).value;
    } finally {
      calloc.free(pointer);
    }
  }
}
