@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';
import 'package:lw_sysapi/src/drop/drop_web.dart' show listenForBrowserPaste;
import 'package:lw_sysapi/src/native/lw_sysapi_web.dart'
    show WebClipboardManager, supportsClipboardItemType;
import 'package:web/web.dart' as web;

@JS('Object.defineProperty')
external void _defineProperty(JSObject object, String key, JSObject descriptor);

@JS('Reflect.deleteProperty')
external bool _deleteProperty(JSObject object, String key);

void main() {
  const customType = 'application/x-test-page';
  const textType = ClipboardMimeTypes.text;
  const lookalikeText = 'data:$customType;base64,AA==';

  web.ClipboardEvent paste(web.EventTarget target, web.DataTransfer data) {
    final event = web.ClipboardEvent(
      'paste',
      web.ClipboardEventInit(
        clipboardData: data,
        bubbles: true,
        cancelable: true,
      ),
    );
    target.dispatchEvent(event);
    return event;
  }

  void disableCustomFormats() {
    final constructor = web.window.getProperty<JSObject>('ClipboardItem'.toJS);
    final originalSupports = constructor['supports'];
    constructor['supports'] = ((JSString _) => false.toJS).toJS;
    addTearDown(() => constructor['supports'] = originalSupports);
  }

  test('clipboard items are interpreted by their reported types', () async {
    const webType = 'web $customType';
    late JSArray<web.ClipboardItem> items;
    String? fallbackText;
    final clipboard =
        {
              'write': ((JSArray<web.ClipboardItem> value) {
                items = value;
                return Future<void>.value().toJS;
              }).toJS,
              'read': (() => Future.value(items).toJS).toJS,
              'writeText': ((JSString value) {
                fallbackText = value.toDart;
                return Future<void>.value().toJS;
              }).toJS,
            }.jsify()!
            as JSObject;
    final navigator = web.window.navigator;
    _defineProperty(
      navigator,
      'clipboard',
      {'value': clipboard, 'configurable': true}.jsify()! as JSObject,
    );
    addTearDown(() => _deleteProperty(navigator, 'clipboard'));

    final manager = WebClipboardManager();
    final content = (type: customType, data: Uint8List.fromList([0, 255, 128]));
    expect(await manager.setContent(content), isTrue);
    final item = items.toDart.single;
    expect(item.types.toDart.map((type) => type.toDart), [webType]);
    final read = await manager.getContent(types: [customType, textType]);
    expect(read?.type, customType);
    expect(read?.data, content.data);

    final text = web.Blob(
      [lookalikeText.toJS].toJS,
      web.BlobPropertyBag(type: textType),
    );
    items = [
      web.ClipboardItem({textType: text}.jsify()! as JSObject),
    ].toJS;
    expect(await manager.getContent(types: [customType]), isNull);
    final literal = await manager.getContent(types: [customType, textType]);
    expect(literal?.type, textType);
    expect(literal?.data, utf8.encode(lookalikeText));

    disableCustomFormats();
    final fallback = (type: customType, data: Uint8List.fromList([0]));
    expect(await manager.setContent(fallback), isTrue);
    expect(fallbackText, lookalikeText);
    final restored = await manager.getContent(types: [customType, textType]);
    expect(restored?.type, customType);
    expect(restored?.data, fallback.data);
  }, skip: !supportsClipboardItemType('web $customType'));

  for (final customFormats in [true, false]) {
    test(
      'paste handles the text fallback with custom formats $customFormats',
      () async {
        if (!customFormats) disableCustomFormats();
        final contents = <Future<List<SystemDropItem>>>[];
        final stop = listenForBrowserPaste(
          types: [customType, textType],
          canPaste: () => true,
          onPaste: contents.add,
        );
        addTearDown(stop);

        final data = web.DataTransfer()..setData(textType, lookalikeText);
        final event = paste(web.window, data);
        expect(event.defaultPrevented, isTrue);
        final result = (await contents.single).single.contents.single;
        expect(result.type, customFormats ? textType : customType);
        expect(result.data, customFormats ? utf8.encode(lookalikeText) : [0]);

        stop();
        expect(paste(web.window, data).defaultPrevented, isFalse);
        expect(contents, hasLength(1));
      },
      skip: customFormats && !supportsClipboardItemType('web $customType'),
    );
  }

  test(
    'paste files take precedence and editable fields keep browser paste',
    () async {
      final contents = <Future<List<SystemDropItem>>>[];
      final input = web.HTMLInputElement();
      web.document.body!.append(input);
      addTearDown(() => input.remove());
      final stop = listenForBrowserPaste(
        types: [textType],
        canPaste: () => true,
        onPaste: contents.add,
      );
      addTearDown(stop);

      final data = web.DataTransfer()..setData(textType, 'fallback');
      expect(paste(input, data).defaultPrevented, isFalse);
      expect(contents, isEmpty);

      final file = web.File(
        ['image bytes'.toJS].toJS,
        'copy.png',
        web.FilePropertyBag(type: ClipboardMimeTypes.png),
      );
      data.items.add(file);
      expect(paste(web.window, data).defaultPrevented, isTrue);
      final result = (await contents.single).single;
      expect(result.name, 'copy.png');
      expect(result.contents.single.type, ClipboardMimeTypes.png);
      expect(utf8.decode(result.contents.single.data), 'image bytes');
    },
  );

  testWidgets('a paste target uses its local position and preserves URL text', (
    tester,
  ) async {
    final received = <SystemDropDetails>[];
    var editable = true;
    const position = Offset(15, 30);
    const url = 'https://example.test/test.png';
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SystemDropTarget(
          paste: (
            types: const [textType],
            enabled: () => editable,
            localPosition: () => position,
          ),
          onDrop: received.add,
          child: const SizedBox.expand(),
        ),
      ),
    );

    final data = web.DataTransfer()..setData(textType, url);
    expect(paste(web.window, data).defaultPrevented, isTrue);
    expect(paste(web.window, data).defaultPrevented, isFalse);
    await tester.pump();
    final details = received.single;
    expect(details.localPosition, position);
    final pasted = await details.readContents(safeMode: false);
    expect(utf8.decode(pasted.contents.single.content.data), url);
    expect(pasted.errors, isEmpty);
    final limited = await details.readContents(maxBytes: 1);
    expect(limited.contents, isEmpty);
    expect(limited.errors.single, isA<FormatException>());

    editable = false;
    expect(paste(web.window, data).defaultPrevented, isFalse);
    expect(received, hasLength(1));
  });
}
