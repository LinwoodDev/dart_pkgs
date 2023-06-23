part of 'connection.dart';

abstract class NetworkerServer<T extends NetworkerConnection> {
  final Map<ConnectionId, (T, StreamSubscription<RawData>)> _connections = {};

  List<ConnectionId> get connectionIds => _connections.keys.toList();

  T? getConnection(ConnectionId id) => _connections[id]?.$1;

  @protected
  bool addConnection(ConnectionId id, T connection) {
    if (_connections.containsKey(id)) return false;
    _connections[id] = (
      connection,
      connection.write.listen((data) {
        sendMessage(id, data);
      })
    );
    return true;
  }

  @protected
  bool removeConnection(ConnectionId id, T connection) {
    if (_connections.containsKey(id)) return false;
    _connections.remove(id)?.$2.cancel();
    return true;
  }

  void onMessage(ConnectionId id, RawData data) {
    getConnection(id)?.onMessage(data);
  }

  void sendMessage(ConnectionId id, RawData data) {
    getConnection(id)?.sendMessage(data);
  }
}
