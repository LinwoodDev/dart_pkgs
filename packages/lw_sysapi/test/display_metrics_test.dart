import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';
import 'package:lw_sysapi/src/native/lw_sysapi_base.dart';

void main() {
  test('converts a known five-millimeter span at 127.7 physical DPI', () {
    final metrics = DisplayMetrics(dpiX: 127.7, dpiY: 127.7);
    final size = metrics.canvasUnitsToMillimeters(
      const Size(25.13779527559055, 25.13779527559055),
      devicePixelRatio: 1,
    );

    expect(size.width, closeTo(5, 1e-9));
    expect(size.height, closeTo(5, 1e-9));
  });

  test('uses the current DPR and each axis physical density independently', () {
    final metrics = DisplayMetrics(dpiX: 254, dpiY: 508);
    expect(
      metrics.canvasUnitsToMillimeters(
        const Size(100, 100),
        devicePixelRatio: 2,
      ),
      const Size(20, 10),
    );
    expect(
      metrics.millimetersToCanvasUnits(const Size(20, 10), devicePixelRatio: 2),
      const Size(100, 100),
    );
  });

  test('keeps A4 physically sized when device pixel ratio changes', () {
    final metrics = DisplayMetrics(dpiX: 144, dpiY: 144);
    final normal = metrics.millimetersToCanvasUnits(
      const Size(210, 297),
      devicePixelRatio: 1,
    );
    final scaled = metrics.millimetersToCanvasUnits(
      const Size(210, 297),
      devicePixelRatio: 2,
    );

    expect(normal.width, closeTo(1190.5511811023623, 1e-9));
    expect(normal.height, closeTo(1683.7795275590552, 1e-9));
    expect(scaled, normal / 2);
  });

  test('applies canvas zoom in both conversion directions', () {
    final metrics = DisplayMetrics(dpiX: 254, dpiY: 508);
    expect(
      metrics.canvasUnitsToMillimeters(
        const Size(100, 100),
        devicePixelRatio: 2,
        zoom: 1.5,
      ),
      const Size(30, 15),
    );
    final restored = metrics.millimetersToCanvasUnits(
      const Size(30, 15),
      devicePixelRatio: 2,
      zoom: 1.5,
    );
    expect(restored.width, closeTo(100, 1e-9));
    expect(restored.height, closeTo(100, 1e-9));
  });

  test('round-trips sizes at fractional and high device pixel ratios', () {
    final metrics = DisplayMetrics(dpiX: 141.7, dpiY: 142.1);
    for (final ratio in [0.75, 1.0, 1.25, 1.5, 2.0, 3.5]) {
      const original = Size(210, 297);
      final logical = metrics.millimetersToCanvasUnits(
        original,
        devicePixelRatio: ratio,
      );
      final restored = metrics.canvasUnitsToMillimeters(
        logical,
        devicePixelRatio: ratio,
      );
      expect(restored.width, closeTo(original.width, 1e-9));
      expect(restored.height, closeTo(original.height, 1e-9));
    }
  });

  test('rejects invalid physical density and device pixel ratios', () {
    final metrics = DisplayMetrics(dpiX: 144, dpiY: 144);
    for (final invalid in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => DisplayMetrics(dpiX: invalid, dpiY: 144),
        throwsArgumentError,
      );
      expect(
        () => DisplayMetrics(dpiX: 144, dpiY: invalid),
        throwsArgumentError,
      );
      expect(
        () => metrics.canvasUnitsToMillimeters(
          const Size(1, 1),
          devicePixelRatio: invalid,
        ),
        throwsArgumentError,
      );
      expect(
        () => metrics.millimetersToCanvasUnits(
          const Size(1, 1),
          devicePixelRatio: invalid,
        ),
        throwsArgumentError,
      );
      expect(
        () => metrics.canvasUnitsToMillimeters(
          const Size(1, 1),
          devicePixelRatio: 1,
          zoom: invalid,
        ),
        throwsArgumentError,
      );
      expect(
        () => metrics.millimetersToCanvasUnits(
          const Size(1, 1),
          devicePixelRatio: 1,
          zoom: invalid,
        ),
        throwsArgumentError,
      );
    }
  });

  test('unsupported platforms do not invent a physical DPI', () async {
    expect(await SysAPIBase().getDisplayMetrics(), isNull);
  });
}
