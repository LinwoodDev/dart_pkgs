import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:networker/networker.dart';

class NetworkerSocketInfo extends ConnectionInfo {
  final Uri address;
  final WebSocket socket;

  NetworkerSocketInfo(this.address, this.socket);

  @override
  void close() {
    socket.close();
  }

  @override
  bool get isClosed => socket.closeReason != null;

  @override
  void sendMessage(Uint8List data) {
    socket.add(data);
  }
}

class NetworkerSocketServer extends NetworkerServer<NetworkerSocketInfo> {
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

  @override
  Future<void> init() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      try {
        final socket = await WebSocketTransformer.upgrade(request);
        final id = addClientConnection(
            NetworkerSocketInfo(request.requestedUri, socket));
        // No free space
        if (id == kAnyChannel) socket.close();
        socket.listen((event) {
          onMessage(event, id);
        }, onDone: () {
          removeConnection(id);
        });
      } catch (_) {}
    }
    _isClosed = true;
  }
}
