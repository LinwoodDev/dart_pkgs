import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:networker/networker.dart';

class NetworkerSocketInfo extends ConnectionInfo {
  @override
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
  Future<void> sendMessage(Uint8List data) {
    socket.add(data);
    return socket.done;
  }
}

class NetworkerSocketServer extends NetworkerServer<NetworkerSocketInfo> {
  HttpServer? _server;
  final SecurityContext? securityContext;
  final dynamic serverAddress;
  final int port;
  bool Function(HttpRequest event)? filterConnections;

  HttpServer? get server => _server;

  NetworkerSocketServer(
    this.serverAddress,
    this.port, {
    this.filterConnections,
    this.securityContext,
  });

  final StreamController<void> _onOpen = StreamController<void>.broadcast(),
      _onClosed = StreamController<void>.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  @override
  void close() {
    _server?.close();
    _server = null;
  }

  @override
  bool get isClosed => _server == null;

  @override
  Uri get address => Uri(
        scheme: 'ws',
        host: _server?.address.host,
        port: _server?.port,
      );

  void _run() {
    _server?.where(filterConnections ?? (e) => true).listen((request) async {
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
    }, onDone: () {
      _onClosed.add(null);
    }, onError: (error) {
      _onClosed.addError(error);
    }, cancelOnError: true);
  }

  @override
  Future<void> init() async {
    if (isOpen) {
      return;
    }
    final context = securityContext;
    _server = context == null
        ? await HttpServer.bind(
            serverAddress,
            port,
          )
        : await HttpServer.bindSecure(
            serverAddress,
            port,
            context,
          );
    _run();
    _onOpen.add(null);
  }
}
