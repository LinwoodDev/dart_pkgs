import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel constructWebSocketChannel(
  Uri url, {
  Iterable<String>? protocols,
  Duration? pingInterval,
}) {
  return HtmlWebSocketChannel.connect(url, protocols: protocols);
}
