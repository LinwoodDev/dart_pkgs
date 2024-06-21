import 'dart:typed_data';

import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkerSocketClient extends NetworkerClient {
  final WebSocketChannel webSocketChannel;
  @override
  final Uri address;

  NetworkerSocketClient(Uri address, {Iterable<String>? protocols})
      : this.fromChannel(
            address, WebSocketChannel.connect(address, protocols: protocols));

  NetworkerSocketClient.fromChannel(this.address, this.webSocketChannel);

  @override
  void init() {
    webSocketChannel.stream.listen((event) {
      onMessage(event);
    });
  }

  @override
  void close() {
    webSocketChannel.sink.close();
  }

  @override
  bool get isClosed => webSocketChannel.closeReason == null;

  @override
  Future<void> sendMessage(Uint8List data, [Channel channel = kAnyChannel]) {
    super.sendMessage(data);
    webSocketChannel.sink.add(data);
    return webSocketChannel.sink.done;
  }
}
