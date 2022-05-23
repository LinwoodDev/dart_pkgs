import 'dart:async';
import 'dart:convert';

import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketClient extends NetworkingClient {
  WebSocketChannel? _channel;
  final Uri uri;

  @override
  String get identifier => uri.toString();

  SocketClient(this.uri);

  @override
  bool isConnected() => _channel != null && _channel?.closeCode == null;

  @override
  FutureOr<bool> joinRoom(String room) async {
    if (_channel == null) return false;
    _channel?.sink.add(json.encode({
      'service': 'room',
      'data': room,
      'event': 'join',
    }));
    await _channel?.sink.done;
    return true;
  }

  @override
  FutureOr<void> send(String service, String event, String data) {
    _channel?.sink
        .add(json.encode({'service': service, 'event': event, 'data': data}));
  }

  @override
  FutureOr<void> start() async {
    await stop();
    _channel = WebSocketChannel.connect(uri);
  }

  @override
  FutureOr<void> stop() {
    _channel?.sink.close(0, "disconnect");
    _channel = null;
  }
}
