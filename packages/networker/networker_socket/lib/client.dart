library;

import 'dart:async';
import 'dart:typed_data';

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
    final channel = _channel = constructWebSocketChannel(address,
        protocols: protocols, pingInterval: pingInterval);
    channel.stream.listen((event) {
      onMessage(event);
    }, onDone: () {
      _onClosed.add(null);
    }, onError: (error) {
      _onClosed.addError(error);
    }, cancelOnError: true);
    await channel.ready;
    _onOpen.add(null);
  }

  @override
  Future<void> close() async {
    await _channel?.sink.close();
    _channel = null;
  }

  @override
  bool get isClosed => _channel == null || _channel?.closeCode != null;

  @override
  void sendPacket(Uint8List data, [Channel channel = kAnyChannel]) =>
      _channel?.sink.add(data);
}
