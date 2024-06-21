import 'dart:convert';
import 'dart:typed_data';

import 'plugin.dart';

final class JsonNetworkerPlugin extends NetworkerPipe<String, dynamic> {
  @override
  decode(String data) => jsonDecode(data);

  @override
  String encode(data) => jsonEncode(data);
}

final class RawJsonNetworkerPlugin extends NetworkerPipe<Uint8List, dynamic> {
  @override
  decode(Uint8List data) => jsonDecode(utf8.decode(data));

  @override
  Uint8List encode(data) => Uint8List.fromList(utf8.encode(jsonEncode(data)));
}
