import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel constructWebSocketChannel(
  Uri url, {
  Iterable<String>? protocols,
  Duration? pingInterval,
}) {
  return IOWebSocketChannel.connect(
    url,
    protocols: protocols,
    pingInterval: pingInterval,
  );
}
