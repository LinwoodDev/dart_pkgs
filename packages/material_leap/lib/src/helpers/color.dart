// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

bool isDarkColor(Color color) {
  // Berechne die Helligkeit der Farbe basierend auf dem relativen Luminanzwert.
  double luminance = color.computeLuminance();
  // Definiere einen Schwellenwert, der angibt, ab welchem Luminanzwert eine Farbe als "dunkel" gilt.
  const double threshold = 0.5;
  // Wenn die Helligkeit der Farbe unter dem Schwellenwert liegt, geben wir true zurück (die Farbe ist dunkel).
  // Andernfalls geben wir false zurück (die Farbe ist hell).
  return luminance < threshold;
}

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

extension ColorHelper on Color {
  String toHexColor({bool leadingHash = true, bool alpha = true}) =>
      value.toHexColor(leadingHash: leadingHash, alpha: alpha);
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
