import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../networking.dart';

class SocketServer extends NetworkingServer {
  final int port;
  HttpServer? _server;

  @override
  String get identifier => port.toString();

  final List<SocketServerConnection> _clients = [];

  SocketServer(this.port);

  @override
  FutureOr<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    _server?.listen((request) {
      WebSocketTransformer.upgrade(request).then((ws) {
        _clients.add(SocketServerConnection(ws));
        ws.listen((data) {
          final message = json.decode(data);
          if (message is! Map) {
            ws.close(WebSocketStatus.protocolError);
            return;
          }
          final serviceName = message['service'];
          getService(serviceName)?.emitEvent(message['event'], message['data']);
        });
      });
    });
  }

  @override
  void stop() {
    _server?.close();
    _server = null;
  }

  @override
  bool isConnected() {
    return _server != null;
  }

  @override
  List<NetworkingConnection> get clients => List.unmodifiable(_clients);

  @override
  FutureOr<void> send(String service, String event, String data) {
    for (var client in _clients) {
      client.send(service, event, data);
    }
  }

  @override
  // TODO: implement rooms
  List<String> get rooms => throw UnimplementedError();
}

class SocketServerConnection extends NetworkingConnection {
  final WebSocket _socket;

  SocketServerConnection(this._socket);

  @override
  String get identifier => _socket.hashCode.toString();

  @override
  bool isConnected() => _socket.readyState == WebSocket.open;

  @override
  FutureOr<void> start() {}

  @override
  FutureOr<void> stop() {}

  @override
  FutureOr<void> send(String service, String event, String data) async {
    _socket
        .add(json.encode({'service': service, 'data': data, 'event': event}));
    await _socket.done;
  }
}
