import 'dart:typed_data';

import 'plugin/plugin.dart';

part 'client.dart';
part 'server.dart';

typedef ConnectionId = int;
typedef RawData = Uint8List;
typedef MessageDetails<T> = (ConnectionId, T data);

sealed class NetworkerConnection extends NetworkerMessenger<RawData> {
  NetworkerConnection() {
    write.listen((data) {
      if (isClosed) {
        throw StateError('Connection is closed');
      }
      send(data.$1, data.$2);
    });
  }
  bool get isClosed;
  void close();
  Future<void> send(ConnectionId id, RawData data);
}
