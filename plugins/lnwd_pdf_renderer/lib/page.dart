import 'dart:typed_data';

class Page {
  final int width;
  final int height;
  final Uint8List data;

  Page(this.width, this.height, this.data);
}
