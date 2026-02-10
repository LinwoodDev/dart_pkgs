library;

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'src/web_socket.dart';

export 'src/web_socket.dart';

class NetworkerSocketClient extends NetworkerClient {
  static List<String> supportedSchemes = List.unmodifiable(['ws', 'wss']);

  WebSocketChannel? _channel;

  @override
  final Uri address;
  final Iterable<String>? protocols;
  final Duration? pingInterval;

  WebSocketChannel? get channel => _channel;

  final StreamController<void> _onOpen = StreamController<void>.broadcast(),
      _onClosed = StreamController<void>.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  NetworkerSocketClient(this.address, {this.protocols, this.pingInterval});

  @override
  Future<void> init() async {
    if (isOpen) {
      return;
    }
    final channel = _channel = createWebSocketChannel();
    channel.stream.listen(
      (event) {
        handleData(event);
      },
      onDone: () {
        _onClosed.add(null);
      },
      onError: (error) {
        _onClosed.addError(error);
      },
      cancelOnError: true,
    );
    await channel.ready;
    _onOpen.add(null);
  }

  /// Creates the [WebSocketChannel] used for the connection.
  ///
  /// Override this method to customize channel creation, such as
  /// providing custom headers or a different WebSocket implementation.
  @protected
  WebSocketChannel createWebSocketChannel() {
    return constructWebSocketChannel(
      address,
      protocols: protocols,
      pingInterval: pingInterval,
    );
  }

  /// Processes incoming data from the server.
  ///
  /// Override this method to add custom message processing, logging,
  /// or filtering before the standard [onMessage] pipeline.
  @protected
  void handleData(dynamic event) {
    onMessage(event);
  }

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
    _onOpen.close();
    _onClosed.close();
  }

  @override
  bool get isClosed => _channel == null || _channel?.closeCode != null;

  int? get closeCode => _channel?.closeCode;
  String? get closeReason => _channel?.closeReason;

  @override
  void sendPacket(Uint8List data, [Channel channel = kAnyChannel]) =>
      _channel?.sink.add(data);
}
