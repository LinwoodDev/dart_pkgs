// Encoded as argb

const _alphaOffset = 24;
const _redOffset = 16;
const _greenOffset = 8;
const _blueOffset = 0;

extension type const SRGBColor(int value) {
  factory SRGBColor.from({
    required int r,
    required int g,
    required int b,
    int a = 0xFF,
  }) {
    // Combine to ARGB
    int argb = (a << _alphaOffset) |
        (r << _redOffset) |
        (g << _greenOffset) |
        (b << _blueOffset);
    return SRGBColor(argb);
  }

  factory SRGBColor.fromRGBA(int rgba) {
    int r = (rgba >> 24) & 0xFF;
    int g = (rgba >> 16) & 0xFF;
    int b = (rgba >> 8) & 0xFF;
    int a = rgba & 0xFF;

    // Combine to ARGB
    int argb = (a << _alphaOffset) |
        (r << _redOffset) |
        (g << _greenOffset) |
        (b << _blueOffset);
    return SRGBColor(argb);
  }

  factory SRGBColor.parse(String value, {bool isRGBA = true}) {
    value = value.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3) {
      if (isRGBA) {
        value = '${value}f';
      } else {
        value = 'f$value';
      }
    } else if (value.length == 6) {
      if (isRGBA) {
        value = '${value}ff';
      } else {
        value = 'ff$value';
      }
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
      throw Exception('Invalid color value');
    }
    // RGBA to ARGB
    if (isRGBA) {
      value = value.substring(6) + value.substring(0, 6);
    }
    return SRGBColor(int.parse(value, radix: 16));
  }

  static SRGBColor? tryParse(String value, {bool isRGBA = true}) {
    try {
      return SRGBColor.parse(value, isRGBA: isRGBA);
    } catch (e) {
      return null;
    }
  }

  int get r => (value >> _redOffset) & 0xFF;
  int get g => (value >> _greenOffset) & 0xFF;
  int get b => (value >> _blueOffset) & 0xFF;
  int get a => (value >> _alphaOffset) & 0xFF;

  double get opacity => a / 255.0;

  int get rgba => (r << 24) | (g << 16) | (b << 8) | a;

  SRGBColor withValues({
    int? r,
    int? g,
    int? b,
    int? a,
  }) =>
      SRGBColor.from(
        r: r ?? this.r,
        g: g ?? this.g,
        b: b ?? this.b,
        a: a ?? this.a,
      );

  SRGBColor withOpacity(double opacity) =>
      withValues(a: (opacity * 255).round());

  String toHexString(
      {bool leadingHash = true, bool alpha = true, bool useRGBA = true}) {
    var hex = '';
    if (leadingHash) {
      hex += '#';
    }
    if (alpha && !useRGBA) hex += a.toRadixString(16).padLeft(2, '0');
    hex += a.toRadixString(16).padLeft(2, '0');
    hex += a.toRadixString(16).padLeft(2, '0');
    hex += a.toRadixString(16).padLeft(2, '0');
    if (alpha && useRGBA) hex += a.toRadixString(16).padLeft(2, '0');
    return hex;
  }

  static const transparent = SRGBColor(0x00000000);
  static const red = SRGBColor(0xFFFF0000);
  static const yellow = SRGBColor(0xFFFFFF00);
  static const green = SRGBColor(0xFF00FF00);
  static const blue = SRGBColor(0xFF0000FF);
  static const white = SRGBColor(0xFFFFFFFF);
  static const black = SRGBColor(0xFF000000);
}
