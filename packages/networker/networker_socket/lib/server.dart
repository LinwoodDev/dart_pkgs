import 'dart:io';

import 'package:networker/networker.dart';

class NetworkerSocketServerConnection extends NetworkerConnection {
  final WebSocket socket;

  NetworkerSocketServerConnection(this.socket);

  @override
  void close() {
    socket.close();
  }

  @override
  bool get isClosed => socket.closeReason != null;

  @override
  Future<void> send(RawData data) {
    socket.add(data);
    return socket.done;
  }
}

class NetworkerSocketServer
    extends NetworkerServer<NetworkerSocketServerConnection> {
  final HttpServer server;
  bool _isClosed = false;
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

  Future<void> waitForConnections() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        addConnection(socket.hashCode, NetworkerSocketServerConnection(socket));
        socket.listen((event) {
          onMessage(socket.hashCode, event);
        }, onDone: () {
          removeConnection(socket.hashCode);
        });
      } catch (_) {}
    }
    _isClosed = true;
  }
}
