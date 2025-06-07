import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel constructWebSocketChannel(
  Uri uri, {
  Iterable<String>? protocols,
  Duration? pingInterval,
}) {
  throw UnsupportedError(
    'WebSocketChannel is not supported in this environment. Please use a different implementation.',
  );
}
