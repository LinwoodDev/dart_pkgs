import 'dart:io';

import 'package:networker/networker.dart';

class NetworkerSocketServerConnection extends NetworkerConnection {
  final WebSocket socket;
  @override
  final Uri address;

  NetworkerSocketServerConnection(this.socket, this.address);

  @override
  void close() {
    socket.close();
  }

  @override
  bool get isClosed => socket.closeReason != null;
}

class NetworkerSocketServer
    extends NetworkerServer<NetworkerSocketServerConnection> {
  final HttpServer server;
  bool _isClosed = false;
  bool Function(HttpRequest event)? filterConnections;

  NetworkerSocketServer(this.server, [this.filterConnections]);

  @override
  void close() {
    server.close();
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  Uri get address => Uri(
        scheme: 'ws',
        host: server.address.host,
        port: server.port,
      );

  Future<void> init() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        addConnection(socket.hashCode,
            NetworkerSocketServerConnection(socket, request.requestedUri));
        socket.listen((event) {
          onMessage(socket.hashCode, event);
        }, onDone: () {
          removeConnection(socket.hashCode);
        });
      } catch (_) {}
    }
    _isClosed = true;
  }

  @override
  void sendMessage(ConnectionId id, RawData data) {
    getConnection(id)?.socket.add(data);
  }
}
