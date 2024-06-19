import 'dart:typed_data';

import 'plugin.dart';

final class StringNetworkerPlugin extends NetworkerPipe<Uint8List, String> {
  @override
  String decode(Uint8List data) => String.fromCharCodes(data);

  @override
  Uint8List encode(String data) => Uint8List.fromList(data.codeUnits);
}
