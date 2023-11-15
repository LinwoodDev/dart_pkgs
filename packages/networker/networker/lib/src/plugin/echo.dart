import 'dart:async';

import 'package:networker/src/connection.dart';
import 'package:networker/src/plugin/plugin.dart';

class EchoNetworkerPlugin extends NetworkerMessenger<RawData> {
  final NetworkerServer server;
  StreamSubscription<ConnectionId>? _connectSub;

  EchoNetworkerPlugin._add(this.server) {
    register();
  }

  @override
  void onMessage(RawData data) {
    super.onMessage(data);

    for (final connection in server.connectionIds) {
      server.sendMessage(connection, _buildData(connection, data));
    }
  }

  RawData _buildData(ConnectionId connection, RawData data) => data;

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
    return EchoNetworkerPlugin._add(server);
  }
}

class JsonEchoNetworkerPlugin extends EchoNetworkerPlugin {
  JsonEchoNetworkerPlugin._add(super.server) : super._add();

  static JsonEchoNetworkerPlugin add(NetworkerServer server) {
    return JsonEchoNetworkerPlugin._add(server);
  }
}
