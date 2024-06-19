part of 'connection.dart';

abstract class ConnectionInfo {}

abstract class NetworkerServer<T extends ConnectionInfo> extends NetworkerBase {
  final Set<Channel> _connections = {};
  final StreamController<Channel> _connectController =
      StreamController.broadcast();
  final StreamController<Channel> _disconnectController =
      StreamController.broadcast();

  Stream<Channel> get clientConnect => _connectController.stream;
  Stream<Channel> get clientDisconnect => _disconnectController.stream;

  List<Channel> get connections => List.unmodifiable(_connections);

  T? getConnectionInfo();

  @protected
  bool addClientConnection(Channel id) {
    if (!_connections.add(id)) return false;
    _connectController.add(id);
    return true;
  }

  @protected
  bool removeConnection(Channel id) {
    if (!_connections.remove(id)) return false;
    _disconnectController.add(id);
    return true;
  }
}
