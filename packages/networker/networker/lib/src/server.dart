part of 'connection.dart';

abstract class ConnectionInfo {
  FutureOr<void> close();
  FutureOr<void> sendMessage(Uint8List data);
  bool get isClosed;
  bool get isOpen => !isClosed;
  Uri get address;
}

/// The server abstraction of the networker library
/// Please note that connection ids can only be between 2 and 2^16
mixin NetworkerServerMixin<T extends ConnectionInfo, O> on NetworkerBase<O> {
  final Map<Channel, T> _connections = {};
  final StreamController<(Channel, ConnectionInfo)> _connectController =
      StreamController.broadcast();
  final StreamController<(Channel, ConnectionInfo)> _disconnectController =
      StreamController.broadcast();
  final StreamController<Set<Channel>> _changeController =
      StreamController.broadcast();
  Future<void>? _closeFuture;

  Stream<(Channel, ConnectionInfo)> get clientConnect =>
      _connectController.stream;
  Stream<(Channel, ConnectionInfo)> get clientDisconnect =>
      _disconnectController.stream;
  Stream<Set<Channel>> get clientChange => _changeController.stream;

  Set<Channel> get clientConnections => _connections.keys.toSet();

  T? getConnectionInfo(Channel channel) => _connections[channel];

  static const int _maxChannel = 65536;

  Channel _findAvailableChannel() {
    final keys = _connections.keys.toSet();
    for (var i = 2; i < _maxChannel; i++) {
      if (!keys.contains(i)) {
        return i;
      }
    }
    return kAnyChannel;
  }

  @protected
  Channel addClientConnection(T info, [Channel? id]) {
    if (id != null) {
      closeConnection(id).ignore();
    }
    final current = id ?? _findAvailableChannel();
    if (current == kAnyChannel) return current;
    _connections[current] = info;
    onClientConnected(current, info);
    _connectController.add((current, info));
    _changeController.add(clientConnections);
    return current;
  }

  @protected
  Future<bool> removeConnection(Channel id) async {
    final info = _connections.remove(id);
    if (info == null) return false;
    onClientDisconnected(id, info);
    _disconnectController.add((id, info));
    _changeController.add(clientConnections);
    await info.close();
    return true;
  }

  /// Called when a new client connection is added.
  /// Override this to perform custom logic on connection.
  @protected
  void onClientConnected(Channel id, T info) {}

  /// Called when a client disconnects.
  /// Override this to perform custom logic on disconnection.
  @protected
  void onClientDisconnected(Channel id, T info) {}

  Future<bool> closeConnection(Channel id) => removeConnection(id);

  void _sendMessage(Uint8List data, Channel channel) =>
      getConnectionInfo(channel)?.sendMessage(data);

  @override
  @protected
  FutureOr<void> sendPacket(Uint8List data, Channel channel) async {
    if (channel == kAnyChannel || channel < 0) {
      for (final id in _connections.keys) {
        if (id == -channel) continue;
        _sendMessage(data, id);
      }
    } else {
      _sendMessage(data, channel);
    }
  }

  @protected
  Future<void> clearConnections() async =>
      Future.wait(clientConnections.map(removeConnection));

  @override
  @mustCallSuper
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    try {
      await clearConnections();
    } finally {
      await _connectController.close();
      await _disconnectController.close();
      await _changeController.close();
    }
  }
}

abstract class NetworkerServer<T extends ConnectionInfo>
    extends RawNetworkerPipe
    with NetworkerBase<Uint8List>, NetworkerServerMixin<T, Uint8List> {}
