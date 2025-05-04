import 'package:web_socket_channel/web_socket_channel.dart';

import 'web_socket_stub.dart' as ws
    if (dart.library.html) 'web_socket_html.dart'
    if (dart.library.io) 'web_socket_io.dart';

WebSocketChannel constructWebSocketChannel(Uri uri,
    {Iterable<String>? protocols, Duration? pingInterval}) {
  return ws.constructWebSocketChannel(uri,
      protocols: protocols, pingInterval: pingInterval);
}
