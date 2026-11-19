import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../native/lw_sysapi_base.dart';
import '../native/lw_sysapi_web.dart'
    show
        WebClipboardManager,
        clipboardTextFallbackPrefix,
        decodeClipboardTextFallback,
        isCustomClipboardType,
        supportsClipboardItemType;
import 'drop_models.dart';

Stream<SystemDropEvent> createDropEvents() {
  late final StreamController<SystemDropEvent> controller;
  final listeners = <String, JSFunction>{};
  void emit(
    web.DragEvent event,
    SystemDropPhase phase, [
    List<SystemDropItem> items = const [],
  ]) {
    if (!controller.hasListener) return;
    controller.add(
      SystemDropEvent(
        phase: phase,
        position: Offset(event.clientX.toDouble(), event.clientY.toDouble()),
        items: items,
      ),
    );
  }

  Future<void> drop(web.DragEvent event) async {
    event.preventDefault();
    final transfer = event.dataTransfer;
    if (transfer == null) return;
    // Read string representations before returning to the browser event loop.
    final contents = <ClipboardContent>[
      for (final type in [
        ClipboardMimeTypes.html,
        ClipboardMimeTypes.uriList,
        ClipboardMimeTypes.text,
      ])
        if (transfer.getData(type) case final value when value.isNotEmpty)
          (type: type, data: utf8.encode(value)),
    ];
    try {
      final items = await _readFiles(transfer.files);
      if (items.isEmpty && contents.isNotEmpty) {
        items.add(SystemDropItem(contents: contents));
      }
      emit(event, SystemDropPhase.drop, items);
    } catch (error, stack) {
      controller.addError(error, stack);
      emit(event, SystemDropPhase.exit);
    }
  }

  controller = StreamController<SystemDropEvent>.broadcast(
    onListen: () {
      void listen(String type, void Function(web.DragEvent) callback) {
        final listener = ((web.Event event) => callback(
          event as web.DragEvent,
        )).toJS;
        listeners[type] = listener;
        web.window.addEventListener(type, listener);
      }

      for (final type in ['dragenter', 'dragover']) {
        listen(type, (event) {
          event.preventDefault();
          event.dataTransfer?.dropEffect = 'copy';
          emit(event, SystemDropPhase.hover);
        });
      }
      listen('dragleave', (event) {
        if (event.relatedTarget == null) emit(event, SystemDropPhase.exit);
      });
      listen('drop', (event) => unawaited(drop(event)));
    },
    onCancel: () {
      for (final entry in listeners.entries) {
        web.window.removeEventListener(entry.key, entry.value);
      }
      listeners.clear();
    },
  );
  return controller.stream;
}

/// Listens for user-initiated browser paste and returns a function that detaches
/// the listener. Native platforms leave clipboard handling to their callers.
/// Files take priority over string representations. [types] orders the string
/// representations to try. Editable DOM targets retain their normal paste.
void Function() listenForBrowserPaste({
  required Iterable<String> types,
  required bool Function() canPaste,
  required void Function(Future<List<SystemDropItem>>) onPaste,
}) {
  final listener = ((web.ClipboardEvent event) {
    final transfer = event.clipboardData;
    if (transfer == null || event.defaultPrevented || !canPaste()) return;
    final target = event.composedPath().toDart.firstOrNull;
    if (target.isA<web.HTMLElement>()) {
      final element = target as web.HTMLElement;
      if (element.isContentEditable || element.matches('input, textarea')) {
        return;
      }
    }
    event.preventDefault();
    onPaste(_readContents(transfer, types, trusted: event.isTrusted));
  }).toJS;
  web.window.addEventListener('paste', listener);
  return () => web.window.removeEventListener('paste', listener);
}

Future<List<SystemDropItem>> _readContents(
  web.DataTransfer transfer,
  Iterable<String> types, {
  required bool trusted,
}) async {
  if (transfer.files.length > 0) return _readFiles(transfer.files);
  final plainText = transfer.getData(ClipboardMimeTypes.text);
  for (final type in types) {
    final value = transfer.getData(type);
    if (value.isNotEmpty) {
      return [
        SystemDropItem(contents: [(type: type, data: utf8.encode(value))]),
      ];
    }
    final prefix = clipboardTextFallbackPrefix(type);
    if (prefix != null) {
      final data = decodeClipboardTextFallback(plainText, prefix);
      if (data != null) {
        return [
          SystemDropItem(contents: [(type: type, data: data)]),
        ];
      }
    }
  }
  if (!trusted) return [];
  // Some browsers expose typed ClipboardItems only via the async clipboard API.
  final customTypes = types
      .where(
        (type) =>
            isCustomClipboardType(type) &&
            supportsClipboardItemType('web $type'),
      )
      .toList();
  if (customTypes.isEmpty) return [];
  final content = await WebClipboardManager().getContent(types: customTypes);
  return content == null
      ? []
      : [
          SystemDropItem(contents: [content]),
        ];
}

Future<List<SystemDropItem>> _readFiles(web.FileList files) async {
  // Take a snapshot while the browser event still gives access to the files.
  final snapshot = [for (var i = 0; i < files.length; i++) files.item(i)!];
  return [
    for (final file in snapshot)
      SystemDropItem(
        name: file.name,
        contents: [
          (
            type: file.type.isEmpty ? 'application/octet-stream' : file.type,
            data: (await file.arrayBuffer().toDart).toDart.asUint8List(),
          ),
        ],
      ),
  ];
}
