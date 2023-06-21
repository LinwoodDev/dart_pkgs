import 'dart:io';

import 'package:networker/networker.dart';

class NetworkerSocketServer extends NetworkerServer {
  final HttpServer server;
  bool _isClosed = false;
  final List<WebSocket> _sockets = [];
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
  Future<void> send(ConnectionId id, RawData data) {
    final socket = _sockets.firstWhere((e) => e.hashCode == id.hashCode);
    socket.add(data);
    return socket.done;
  }

  Future<void> waitForConnections() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      final socket = await WebSocketTransformer.upgrade(request);
      _sockets.add(socket);
      socket.listen((event) {
        onMessage(socket.hashCode, event);
      }, onDone: () {
        _sockets.remove(socket);
      });
    }
    _isClosed = true;
  }

  @override
  List<ConnectionId> get connections =>
      _sockets.map((e) => e.hashCode).toList();
}
