import 'dart:convert';

import 'plugin.dart';

class JsonNetworkerPlugin extends NetworkerPlugin<String, dynamic> {
  @override
  decode(String data) => jsonDecode(data);

  @override
  String encode(data) => jsonEncode(data);
}
