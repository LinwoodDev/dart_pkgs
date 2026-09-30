import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/src/native/windows_bitmap.dart';

Uint8List bitfieldsDib({required int headerSize, required bool repeatedMasks}) {
  const pixels = [0x25, 0x28, 0x2e, 0xff, 0x10, 0x14, 0x1c, 0xff];
  final masks = <int>[0, 0, 0xff, 0, 0, 0xff, 0, 0, 0xff, 0, 0, 0];
  final dib = Uint8List(headerSize + (repeatedMasks ? 12 : 0) + pixels.length);
  final data = ByteData.sublistView(dib);
  data.setUint32(0, headerSize, Endian.little);
  data.setInt32(4, 2, Endian.little);
  data.setInt32(8, 1, Endian.little);
  data.setUint16(12, 1, Endian.little);
  data.setUint16(14, 32, Endian.little);
  data.setUint32(16, 3, Endian.little);
  data.setUint32(20, pixels.length, Endian.little);
  dib.setRange(40, 52, masks);
  if (repeatedMasks) dib.setRange(headerSize, headerSize + 12, masks);
  dib.setRange(dib.length - pixels.length, dib.length, pixels);
  return dib;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('skips masks after an extended BI_BITFIELDS header', () async {
    final bmp = dibToBmp(bitfieldsDib(headerSize: 124, repeatedMasks: true))!;
    expect(ByteData.sublistView(bmp).getUint32(10, Endian.little), 150);

    final codec = await ui.instantiateImageCodec(bmp);
    final image = (await codec.getNextFrame()).image;
    final pixels = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    expect(pixels, [0x2e, 0x28, 0x25, 0xff, 0x1c, 0x14, 0x10, 0xff]);
    image.dispose();
    codec.dispose();
  });

  test('keeps the normal V5 offset when masks are not repeated', () {
    final bmp = dibToBmp(bitfieldsDib(headerSize: 124, repeatedMasks: false))!;
    expect(ByteData.sublistView(bmp).getUint32(10, Endian.little), 138);
  });

  test('keeps masks after a 40-byte DIB header', () {
    final bmp = dibToBmp(bitfieldsDib(headerSize: 40, repeatedMasks: true))!;
    expect(ByteData.sublistView(bmp).getUint32(10, Endian.little), 66);
  });

  test('rejects truncated headers and color tables', () {
    expect(dibToBmp(Uint8List(8)), isNull);
    final dib = Uint8List(40);
    final data = ByteData.sublistView(dib);
    data.setUint32(0, 40, Endian.little);
    data.setUint16(14, 8, Endian.little);
    expect(dibToBmp(dib), isNull);
  });
}
