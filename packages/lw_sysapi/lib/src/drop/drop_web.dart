import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import '../native/lw_sysapi_base.dart';
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
          (type: type, data: Uint8List.fromList(utf8.encode(value))),
    ];
    final files = [
      for (var i = 0; i < transfer.files.length; i++) transfer.files.item(i)!,
    ];
    final items = <SystemDropItem>[];
    try {
      for (final file in files) {
        final buffer = await file.arrayBuffer().toDart;
        items.add(
          SystemDropItem(
            name: file.name,
            contents: [
              (
                type: file.type.isEmpty
                    ? 'application/octet-stream'
                    : file.type,
                data: Uint8List.view(buffer.toDart),
              ),
            ],
          ),
        );
      }
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
