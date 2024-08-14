import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart';

void setupFullScreen() {}

bool isFullScreen() {
  return document.fullscreenElement != null;
}

Future<void> setFullScreen(bool fullScreen) async {
  try {
    final state = isFullScreen();
    if (fullScreen && !state) {
      await document.body?.requestFullscreen().toDart;
    } else if (state) {
      await document.exitFullscreen().toDart;
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
}
