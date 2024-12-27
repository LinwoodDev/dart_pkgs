// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:material_leap/helpers.dart';

extension IntColorHelper on int {
  String toHexColor(
      {bool leadingHash = true, bool alpha = true, bool useArgb = false}) {
    final color = Color(this);
    var hex = '';
    if (leadingHash) {
      hex += '#';
    }
    if (alpha && useArgb) hex += color.alpha.toRadixString(16).padLeft(2, '0');
    hex += color.red.toRadixString(16).padLeft(2, '0');
    hex += color.green.toRadixString(16).padLeft(2, '0');
    hex += color.blue.toRadixString(16).padLeft(2, '0');
    if (alpha && !useArgb) hex += color.alpha.toRadixString(16).padLeft(2, '0');
    return hex;
  }
}

extension SRGBColorHelper on SRGBColor {
  Color toColor() => Color.from(
        red: r / 255,
        green: g / 255,
        blue: b / 255,
        alpha: a / 255,
      );
}

extension ColorHelper on Color {
  SRGBColor toSRGB() {
    final color = withValues(colorSpace: ColorSpace.sRGB);
    final red = (color.r * 255).round();
    final green = (color.g * 255).round();
    final blue = (color.b * 255).round();
    final alpha = (color.a * 255).round();
    return SRGBColor.from(r: red, g: green, b: blue, a: alpha);
  }

  bool isDark({
    double threshold = 0.5,
  }) =>
      computeLuminance() < threshold;
}

extension StringColorHelper on String {
  int? toColorValue() {
    var value = trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3) {
      value = '${value}f';
    } else if (value.length == 6) {
      value = '${value}ff';
    }
    if (value.length == 4) {
      value = value[0] +
          value[0] +
          value[1] +
          value[1] +
          value[2] +
          value[2] +
          value[3] +
          value[3];
    }
    if (value.length != 8) {
      return null;
    }
    // RGBA to ARGB
    value = value.substring(6) + value.substring(0, 6);
    return int.tryParse(value, radix: 16);
  }
}
