import 'dart:typed_data';

import '../connection.dart';
import 'plugin.dart';

final class StringNetworkerPlugin extends NetworkerPlugin<RawData, String> {
  @override
  String decode(RawData data) => String.fromCharCodes(data);

  @override
  RawData encode(String data) => Uint8List.fromList(data.codeUnits);
}
