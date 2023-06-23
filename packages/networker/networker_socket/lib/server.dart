import 'dart:io';

import 'package:networker/networker.dart';

class NetworkerSocketServer extends NetworkerServer {
  final HttpServer server;
  bool _isClosed = false;
  final Map<ConnectionId, WebSocket> _sockets = {};
  bool Function(HttpRequest event)? filterConnections;

  NetworkerSocketServer(this.server, [this.filterConnections]) {
    waitForConnections();
  }

  @override
  void close() {
    server.close();
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  Future<void> sendMessage(ConnectionId id, RawData data) {
    final socket = _sockets[id];
    if (socket == null) return Future.value();
    socket.add(data);
    return socket.done;
  }

  Future<void> waitForConnections() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _sockets[socket.hashCode] = socket;
    }
    _isClosed = true;
  }
}
