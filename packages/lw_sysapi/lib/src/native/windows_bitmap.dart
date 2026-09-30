import 'dart:typed_data';

/// Adds a BMP file header to a Windows clipboard DIB.
Uint8List? dibToBmp(Uint8List dib) {
  if (dib.length < 12) return null;
  final data = ByteData.sublistView(dib);
  final headerSize = data.getUint32(0, Endian.little);
  if ((headerSize != 12 && headerSize < 40) || headerSize > dib.length) {
    return null;
  }

  final pixelOffset = _pixelOffset(dib, headerSize);
  if (pixelOffset > dib.length) return null;

  final bmp = Uint8List(14 + dib.length);
  final header = ByteData.sublistView(bmp);
  bmp[0] = 0x42;
  bmp[1] = 0x4d;
  header.setUint32(2, bmp.length, Endian.little);
  header.setUint32(10, 14 + pixelOffset, Endian.little);
  bmp.setRange(14, bmp.length, dib);
  return bmp;
}

int _pixelOffset(Uint8List dib, int headerSize) {
  final data = ByteData.sublistView(dib);
  if (headerSize == 12) {
    final bitCount = data.getUint16(10, Endian.little);
    return 12 + (bitCount <= 8 ? 1 << bitCount : 0) * 3;
  }

  final bitCount = data.getUint16(14, Endian.little);
  final compression = data.getUint32(16, Endian.little);
  final imageSize = data.getUint32(20, Endian.little);
  final colorsUsed = data.getUint32(32, Endian.little);
  final colorCount = colorsUsed != 0
      ? colorsUsed
      : bitCount <= 8
      ? 1 << bitCount
      : 0;
  final paletteSize = colorCount * 4;
  final maskSize = compression == 3
      ? 12
      : compression == 6
      ? 16
      : 0;

  // BI_BITFIELDS stores masks after a 40-byte header. Extended headers also
  // contain mask fields, but packed clipboard DIBs can include the mask array
  // after the header. Use the declared image size and matching mask fields to
  // distinguish that array from the first image pixels.
  if (headerSize > 40 &&
      maskSize > 0 &&
      headerSize >= 40 + maskSize &&
      imageSize > 0 &&
      dib.length == headerSize + maskSize + paletteSize + imageSize) {
    var repeated = true;
    for (var i = 0; i < maskSize; i++) {
      if (dib[40 + i] != dib[headerSize + i]) {
        repeated = false;
        break;
      }
    }
    if (repeated) return headerSize + maskSize + paletteSize;
  }

  return headerSize + (headerSize == 40 ? maskSize : 0) + paletteSize;
}
