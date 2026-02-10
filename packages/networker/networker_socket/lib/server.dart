library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:networker/networker.dart';

class NetworkerSocketInfo extends ConnectionInfo {
  @override
  final Uri address;
  final WebSocket socket;

  NetworkerSocketInfo(this.address, this.socket);

  @override
  void close([int? code, String? reason]) {
    socket.close(code, reason);
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
  FutureOr<bool> Function(HttpRequest event)? filterConnections;
  final bool overrideStatusCode;
  final bool _ownsServer;

  HttpServer? get server => _server;

  NetworkerSocketServer(
    this.serverAddress,
    this.port, {
    this.filterConnections,
    this.securityContext,
    this.overrideStatusCode = true,
  }) : _ownsServer = true;

  /// Creates a [NetworkerSocketServer] that attaches to an existing [HttpServer].
  /// The server will not be closed when [close] is called unless [ownsServer]
  /// is set to true.
  NetworkerSocketServer.fromHttpServer(
    HttpServer server, {
    this.filterConnections,
    this.overrideStatusCode = true,
    bool ownsServer = false,
  }) : _server = server,
       serverAddress = server.address,
       port = server.port,
       securityContext = null,
       _ownsServer = ownsServer;

  final StreamController<void> _onOpen = StreamController<void>.broadcast(),
      _onClosed = StreamController<void>.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  @override
  Future<void> close() async {
    await super.close();
    if (_ownsServer) {
      await _server?.close();
    }
    _server = null;
    _onOpen.close();
    _onClosed.close();
  }

  @override
  bool get isClosed => _server == null;

  @override
  Uri get address =>
      Uri(scheme: 'ws', host: _server?.address.host, port: _server?.port);

  void _run() {
    _server?.listen(
      (request) async {
        try {
          await handleRequest(request);
        } catch (_) {}
      },
      onDone: () {
        _onClosed.add(null);
      },
      onError: (error) {
        _onClosed.addError(error);
      },
      cancelOnError: true,
    );
  }

  /// Handles an incoming [HttpRequest].
  ///
  /// Override this method to customize request handling, such as adding
  /// REST endpoints alongside WebSocket support, custom authentication,
  /// or request logging.
  ///
  /// The default implementation filters connections using [filterConnections],
  /// then upgrades the request to a WebSocket via [handleWebSocketUpgrade].
  @protected
  Future<void> handleRequest(HttpRequest request) async {
    if (await filterConnections?.call(request) == false) {
      if (overrideStatusCode) {
        request.response.statusCode = HttpStatus.forbidden;
      }
      request.response.close();
      return;
    }
    await handleWebSocketUpgrade(request);
  }

  /// Upgrades an [HttpRequest] to a WebSocket connection and registers it.
  ///
  /// Override this method to customize the WebSocket upgrade process,
  /// for example to inspect or modify the socket before registering.
  @protected
  Future<void> handleWebSocketUpgrade(HttpRequest request) async {
    request.response.statusCode = HttpStatus.switchingProtocols;
    final socket = await WebSocketTransformer.upgrade(request);
    final info = request.connectionInfo;
    final connectionInfo = NetworkerSocketInfo(
      Uri(host: info?.remoteAddress.address, port: info?.remotePort),
      socket,
    );
    final id = addClientConnection(connectionInfo);
    // No free space
    if (id == kAnyChannel) {
      socket.close();
      return;
    }
    handleWebSocketConnection(id, connectionInfo, socket);
  }

  /// Sets up listeners for a WebSocket connection.
  ///
  /// Override this method to customize how messages from the socket are
  /// processed, or to add custom error handling per connection.
  @protected
  void handleWebSocketConnection(
    Channel id,
    NetworkerSocketInfo info,
    WebSocket socket,
  ) {
    socket.listen(
      (event) {
        try {
          if (event is String) {
            event = Uint8List.fromList(event.codeUnits);
          }
          handleData(event, id);
        } catch (_) {}
      },
      onDone: () {
        removeConnection(id);
      },
    );
  }

  /// Processes incoming data from a client.
  ///
  /// Override this method to add custom message processing, logging,
  /// or filtering before the standard [onMessage] pipeline.
  @protected
  void handleData(Uint8List data, Channel channel) {
    onMessage(data, channel);
  }

  @override
  Future<void> init() async {
    if (isOpen) {
      return;
    }
    final context = securityContext;
    _server = context == null
        ? await HttpServer.bind(serverAddress, port)
        : await HttpServer.bindSecure(serverAddress, port, context);
    _run();
    _onOpen.add(null);
  }
}
