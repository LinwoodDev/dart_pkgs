part of 'connection.dart';

abstract class ConnectionInfo {
  void close();
  void sendMessage(Uint8List data);
  bool get isClosed;
}

abstract class NetworkerServer<T extends ConnectionInfo> extends NetworkerBase {
  final Map<Channel, T> _connections = {};
  final StreamController<Channel> _connectController =
      StreamController.broadcast();
  final StreamController<Channel> _disconnectController =
      StreamController.broadcast();

  Stream<Channel> get clientConnect => _connectController.stream;
  Stream<Channel> get clientDisconnect => _disconnectController.stream;

  List<Channel> get clientConnections => _connections.keys.toList();

  T? getConnectionInfo(Channel channel) => _connections[channel];

  @protected
  bool addClientConnection(Channel id, T info) {
    if (_connections.containsKey(id)) return false;
    _connections[id] = info;
    _connectController.add(id);
    return true;
  }

  @protected
  bool removeConnection(Channel id) {
    if (_connections.remove(id) == null) return false;
    _disconnectController.add(id);
    return true;
  }

  void _sendMessage(Uint8List data, Channel channel) =>
      getConnectionInfo(channel)?.sendMessage(data);

  @override
  void sendMessage(Uint8List data, [Channel channel = kAnyChannel]) {
    if (channel == kAnyChannel) {
      for (final id in _connections.keys) {
        _sendMessage(data, id);
      }
    } else {
      _sendMessage(data, channel);
    }
  }
}
