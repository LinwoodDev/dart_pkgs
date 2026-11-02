import 'package:pdfrx_plus/pdfrx_plus.dart';
import 'package:test/test.dart';

void main() {
  test('affine inverse and CropBox rotation round trip', () {
    const box = PdfRect(15, 90, 115, 10);
    for (var rotation = 0; rotation < 4; rotation++) {
      final geometry = PdfPageGeometry(box, rotation);
      for (final point in [box.topLeft, box.bottomRight, box.center]) {
        final restored = geometry.toTopLeft.inverse().apply(
          geometry.toTopLeft.apply(point),
        );
        expect(restored.x, closeTo(point.x, 1e-9));
        expect(restored.y, closeTo(point.y, 1e-9));
      }
    }
    expect(
      () => const PdfAffineTransform.scale(0, 1).inverse(),
      throwsStateError,
    );
  });
}
