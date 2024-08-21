part of 'connection.dart';

abstract class ConnectionInfo {
  void close();
  void sendMessage(Uint8List data);
  bool get isClosed;
  bool get isOpen => !isClosed;
  Uri get address;
}

/// The server abstraction of the networker library
/// Please note that connection ids can only be between 2 and 2^16
abstract class NetworkerServer<T extends ConnectionInfo> extends NetworkerBase {
  final Map<Channel, T> _connections = {};
  final StreamController<Channel> _connectController =
      StreamController.broadcast();
  final StreamController<Channel> _disconnectController =
      StreamController.broadcast();
  final StreamController<Set<Channel>> _changeController =
      StreamController.broadcast();

  Stream<Channel> get clientConnect => _connectController.stream;
  Stream<Channel> get clientDisconnect => _disconnectController.stream;
  Stream<Set<Channel>> get clientChange => _changeController.stream;

  Set<Channel> get clientConnections => _connections.keys.toSet();

  T? getConnectionInfo(Channel channel) => _connections[channel];

  Channel _findAvailableChannel() {
    final keys = _connections.keys.toList();
    for (var i = 2; i < 2 ^ 16; i++) {
      if (!keys.contains(i)) {
        return i;
      }
    }
    return kAnyChannel;
  }

  @protected
  Channel addClientConnection(T info) {
    final id = _findAvailableChannel();
    if (id == kAnyChannel) return id;
    _connections[id] = info;
    _connectController.add(id);
    _changeController.add(clientConnections);
    return id;
  }

  @protected
  bool removeConnection(Channel id) {
    if (_connections.remove(id) == null) return false;
    _disconnectController.add(id);
    _changeController.add(clientConnections);
    return true;
  }

  void closeConnection(Channel id) {
    getConnectionInfo(id)?.close();
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
