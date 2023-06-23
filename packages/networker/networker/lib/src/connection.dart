import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'plugin/plugin.dart';

part 'client.dart';
part 'server.dart';

typedef ConnectionId = int;
typedef RawData = Uint8List;

abstract class NetworkerConnection extends NetworkerMessenger<RawData> {
  NetworkerConnection() {
    write.listen((data) {
      if (isClosed) {
        throw StateError('Connection is closed');
      }
      send(data);
    });
  }
  bool get isClosed;
  void close();
  Future<void> send(RawData data);
}
