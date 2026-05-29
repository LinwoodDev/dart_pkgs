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

class WebClipboardManager implements ClipboardManager {
  @override
  Future<ClipboardContent?> getContent({Iterable<String>? types}) async {
    final navigator = html.window.navigator;
    if (!navigator.hasProperty('clipboard'.toJS).toDart) return null;

    try {
      final requestedTypes = types?.toList() ?? ClipboardMimeTypes.defaultTypes;
      final items = await navigator.clipboard.read().toDart;
      for (final item in items.toDart) {
        final availableTypes = item.types.toDart.map((e) => e.toDart).toSet();
        for (final type in requestedTypes) {
          if (!availableTypes.contains(type)) continue;
          final blob = await item.getType(type).toDart;
          final buffer = await blob.arrayBuffer().toDart;
          return (type: type, data: Uint8List.view(buffer.toDart));
        }
      }
      if (requestedTypes.contains(ClipboardMimeTypes.text)) {
        final text = await navigator.clipboard.readText().toDart;
        return (
          type: ClipboardMimeTypes.text,
          data: Uint8List.fromList(utf8.encode(text.toDart)),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
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
      if (!html.ClipboardItem.supports(content.type)) return false;
      final blob = html.Blob(
        [content.data].jsify() as JSArray<html.BlobPart>,
        html.BlobPropertyBag(type: content.type),
      );
      final itemData = {content.type: blob}.jsify()! as JSObject;
      final item = html.ClipboardItem(itemData);
      await navigator.clipboard.write([item].toJS).toDart;
      return true;
    } catch (_) {
      return false;
    }
  }
}
