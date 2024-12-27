import 'dart:ui';

import 'package:flutter/rendering.dart';
import 'package:material_leap/helpers.dart';

extension SRGBColorHelper on SRGBColor {
  Color toColor() => Color.from(
        red: r / 255,
        green: g / 255,
        blue: b / 255,
        alpha: a / 255,
      );
}

extension HSVColorHelper on HSVColor {
  SRGBColor toSRGB() {
    final color = toColor();
    final red = (color.r * 255).round();
    final green = (color.g * 255).round();
    final blue = (color.b * 255).round();
    final alpha = (color.a * 255).round();
    return SRGBColor.from(r: red, g: green, b: blue, a: alpha);
  }
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
