import 'package:flutter/services.dart';

import '../display_metrics.dart';

const _channel = MethodChannel('linwood.dev/lw_sysapi');

Future<DisplayMetrics?> getNativeDisplayMetrics() async {
  try {
    final data = await _channel.invokeMapMethod<String, Object?>(
      'getDisplayMetrics',
    );
    if (data == null) return null;
    final dpiX = data['dpiX'];
    final dpiY = data['dpiY'];
    if (dpiX is! num || dpiY is! num) return null;
    if (!dpiX.isFinite || !dpiY.isFinite || dpiX <= 0 || dpiY <= 0) {
      return null;
    }
    return DisplayMetrics(
      dpiX: dpiX.toDouble(),
      dpiY: dpiY.toDouble(),
      displayId: data['displayId'] is String
          ? data['displayId'] as String
          : null,
      name: data['name'] is String ? data['name'] as String : null,
    );
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  }
}
