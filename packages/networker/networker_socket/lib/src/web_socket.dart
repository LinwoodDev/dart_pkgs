import 'package:web_socket_channel/web_socket_channel.dart';

import 'web_socket_stub.dart'
    if (dart.library.js_interop) 'web_socket_html.dart'
    if (dart.library.io) 'web_socket_io.dart' as ws;

WebSocketChannel constructWebSocketChannel(Uri uri,
    {Iterable<String>? protocols, Duration? pingInterval}) {
  return ws.constructWebSocketChannel(uri,
      protocols: protocols, pingInterval: pingInterval);
}
