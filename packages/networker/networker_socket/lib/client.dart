import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkerSocketClient extends NetworkerClient {
  final WebSocketChannel channel;

  NetworkerSocketClient(Uri url, {Iterable<String>? protocols})
      : this.fromChannel(WebSocketChannel.connect(url, protocols: protocols));

  NetworkerSocketClient.fromChannel(this.channel) {
    channel.stream.listen((event) {
      onMessage(event);
    });
  }

  @override
  void close() {
    channel.sink.close();
  }

  @override
  bool get isClosed => channel.closeReason == null;

  @override
  Future<void> sendMessage(RawData data) {
    super.sendMessage(data);
    channel.sink.add(data);
    return channel.sink.done;
  }
}
