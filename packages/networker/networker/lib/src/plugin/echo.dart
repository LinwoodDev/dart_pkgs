import 'dart:async';

import 'package:networker/src/connection.dart';
import 'package:networker/src/plugin/plugin.dart';

class EchoNetworkerPlugin extends NetworkerMessenger<RawData> {
  final NetworkerServer server;
  StreamSubscription<ConnectionId>? _connectSub;

  EchoNetworkerPlugin._(this.server) {
    register();
  }

  @override
  void onMessage(RawData data) {
    super.onMessage(data);

    for (final connection in server.connectionIds) {
      server.sendMessage(connection, data);
    }
  }

  void register() {
    if (_connectSub != null) return;
    _connectSub = server.connect.listen(_onConnect);
  }

  void _onConnect(ConnectionId id) => server.getConnection(id)?.addPlugin(this);

  void unregister() {
    _connectSub?.cancel();
    _connectSub = null;
  }

  static EchoNetworkerPlugin add(NetworkerServer server) {
    return EchoNetworkerPlugin._(server);
  }
}
