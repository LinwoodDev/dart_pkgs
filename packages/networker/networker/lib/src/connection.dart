import 'dart:typed_data';

typedef ConnectionId = int;
typedef RawData = Uint8List;
typedef MessageDetails<T> = (ConnectionId, T data);

sealed class NetworkerConnection extends Stream<Uint8List> {
  bool get isClosed;
  void close();
  Future<void> send(ConnectionId id, Uint8List data);
}
