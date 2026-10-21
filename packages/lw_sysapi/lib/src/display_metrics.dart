import 'dart:ui';

/// Physical pixel density reported by the display's native platform.
///
/// These values describe pixels per inch, not the operating system's UI scale
/// or Flutter's device pixel ratio. Hardware and driver reports can be rounded
/// or inaccurate; they are not a substitute for physical calibration.
class DisplayMetrics {
  DisplayMetrics({
    required this.dpiX,
    required this.dpiY,
    this.displayId,
    this.name,
  }) {
    _checkPositive(dpiX, 'dpiX');
    _checkPositive(dpiY, 'dpiY');
  }

  /// Horizontal physical pixels per inch.
  final double dpiX;

  /// Vertical physical pixels per inch.
  final double dpiY;

  /// A native, session-local identifier, unrelated to `dart:ui.Display.id`.
  final String? displayId;

  /// The display's model or name, when available.
  final String? name;

  /// Converts canvas units to their displayed physical size in millimeters.
  ///
  /// One canvas unit is one Flutter logical pixel before the camera zoom.
  /// Pass the current view's device pixel ratio and zoom as a factor (1 = 100%).
  Size canvasUnitsToMillimeters(
    Size size, {
    required double devicePixelRatio,
    double zoom = 1,
  }) {
    _checkPositive(devicePixelRatio, 'devicePixelRatio');
    _checkPositive(zoom, 'zoom');
    return Size(
      size.width * zoom * devicePixelRatio * 25.4 / dpiX,
      size.height * zoom * devicePixelRatio * 25.4 / dpiY,
    );
  }

  /// Converts a displayed physical size in millimeters to canvas units.
  Size millimetersToCanvasUnits(
    Size size, {
    required double devicePixelRatio,
    double zoom = 1,
  }) {
    _checkPositive(devicePixelRatio, 'devicePixelRatio');
    _checkPositive(zoom, 'zoom');
    return Size(
      size.width * dpiX / (25.4 * zoom * devicePixelRatio),
      size.height * dpiY / (25.4 * zoom * devicePixelRatio),
    );
  }

  static void _checkPositive(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(value, name, 'Must be finite and positive');
    }
  }
}
