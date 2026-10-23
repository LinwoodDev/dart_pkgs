import 'dart:async';

import 'package:flutter/services.dart';

import 'drop_models.dart';

Stream<SystemDropEvent> createDropEvents() {
  const channel = MethodChannel('linwood.dev/lw_sysapi/drop');
  late final StreamController<SystemDropEvent> controller;
  Future<void> setEnabled(bool enabled) async {
    try {
      await channel.invokeMethod<bool>('setEnabled', enabled);
    } on MissingPluginException {
      // Hosts without drop support keep working normally.
    }
  }

  controller = StreamController<SystemDropEvent>.broadcast(
    onListen: () {
      channel.setMethodCallHandler((call) async {
        if (call.method != 'dropEvent' || call.arguments is! Map) return;
        controller.add(SystemDropEvent.fromMap(call.arguments as Map));
      });
      unawaited(setEnabled(true));
    },
    onCancel: () {
      channel.setMethodCallHandler(null);
      unawaited(setEnabled(false));
    },
  );
  return controller.stream;
}
