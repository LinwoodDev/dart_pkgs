import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

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

  @override
  ClipboardManager getClipboardManager() => WebClipboardManager();
}

bool isCustomClipboardType(String type) => type.startsWith('application/x-');

bool supportsClipboardItemType(String type) {
  final constructor = html.window.getProperty<JSObject?>('ClipboardItem'.toJS);
  return constructor?.hasProperty('supports'.toJS).toDart == true &&
      html.ClipboardItem.supports(type);
}

String? clipboardTextFallbackPrefix(String type) =>
    isCustomClipboardType(type) && !supportsClipboardItemType('web $type')
    ? 'data:$type;base64,'
    : null;

Uint8List? decodeClipboardTextFallback(String text, String prefix) {
  if (!text.startsWith(prefix)) return null;
  try {
    return base64Decode(text.substring(prefix.length));
  } on FormatException {
    return null;
  }
}

class WebClipboardManager implements ClipboardManager {
  @override
  Future<ClipboardContent?> getContent({Iterable<String>? types}) async {
    final navigator = html.window.navigator;
    if (!navigator.hasProperty('clipboard'.toJS).toDart) return null;

    try {
      final requestedTypes = types?.toList() ?? ClipboardMimeTypes.defaultTypes;
      final clipboard = navigator.clipboard;
      if (clipboard.hasProperty('read'.toJS).toDart) {
        final items = await clipboard.read().toDart;
        for (final item in items.toDart) {
          final available = item.types.toDart.map((e) => e.toDart).toSet();
          String? fallbackText;
          for (final type in requestedTypes) {
            final itemType = available.contains(type) ? type : 'web $type';
            if (available.contains(itemType)) {
              final blob = await item.getType(itemType).toDart;
              final buffer = await blob.arrayBuffer().toDart;
              return (type: type, data: Uint8List.view(buffer.toDart));
            }
            final prefix = clipboardTextFallbackPrefix(type);
            if (prefix == null ||
                !available.contains(ClipboardMimeTypes.text)) {
              continue;
            }
            if (fallbackText == null) {
              final blob = await item.getType(ClipboardMimeTypes.text).toDart;
              fallbackText = (await blob.text().toDart).toDart;
            }
            final data = decodeClipboardTextFallback(fallbackText, prefix);
            if (data != null) return (type: type, data: data);
          }
        }
        return null;
      }

      final textTypes = requestedTypes.where(
        (type) =>
            type == ClipboardMimeTypes.text ||
            clipboardTextFallbackPrefix(type) != null,
      );
      if (textTypes.isEmpty) return null;
      final text = (await clipboard.readText().toDart).toDart;
      if (text.isEmpty) return null;
      for (final type in textTypes) {
        if (type == ClipboardMimeTypes.text) {
          return (type: type, data: utf8.encode(text));
        }
        final prefix = clipboardTextFallbackPrefix(type);
        if (prefix == null) continue;
        final data = decodeClipboardTextFallback(text, prefix);
        if (data != null) return (type: type, data: data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> setContent(ClipboardContent content) async {
    final navigator = html.window.navigator;
    if (!navigator.hasProperty('clipboard'.toJS).toDart) return false;

    try {
      if (content.type == ClipboardMimeTypes.text) {
        await navigator.clipboard
            .writeText(utf8.decode(content.data, allowMalformed: true))
            .toDart;
        return true;
      }
      final prefix = clipboardTextFallbackPrefix(content.type);
      if (prefix != null) {
        await navigator.clipboard
            .writeText('$prefix${base64Encode(content.data)}')
            .toDart;
        return true;
      }
      final itemType = isCustomClipboardType(content.type)
          ? 'web ${content.type}'
          : content.type;
      if (!supportsClipboardItemType(itemType)) return false;
      final itemData = JSObject();
      itemData[itemType] = html.Blob(
        [content.data.toJS].toJS,
        html.BlobPropertyBag(type: content.type),
      );
      final item = html.ClipboardItem(itemData);
      await navigator.clipboard.write([item].toJS).toDart;
      return true;
    } catch (_) {
      return false;
    }
  }
}
