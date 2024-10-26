library;
/*
import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NetworkerSocketClient extends NetworkerClient {
  final WebSocketChannel channel;

  NetworkerSocketClient(Uri url, {Iterable<String>? protocols})
      : this.fromChannel(WebSocketChannel.connect(url, protocols: protocols));

  NetworkerSocketClient.fromChannel(this.channel);

  @override
  void close() {
    channel.sink.close();
  }

  @override
  bool get isClosed => channel.closeReason != null;

  @override
  Future<void> send(RawData data) {
    channel.sink.add(data);
    return channel.sink.done;
  }
}
*/
