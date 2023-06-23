import 'dart:convert';
import 'dart:typed_data';

import '../connection.dart';
import 'plugin.dart';

class JsonNetworkerPlugin extends NetworkerPlugin<String, dynamic> {
  @override
  decode(String data) => jsonDecode(data);

  @override
  String encode(data) => jsonEncode(data);
}

class JsonRawNetworkerPlugin extends NetworkerPlugin<RawData, dynamic> {
  @override
  decode(RawData data) => jsonDecode(utf8.decode(data));

  @override
  RawData encode(data) => Uint8List.fromList(utf8.encode(jsonEncode(data)));
}
