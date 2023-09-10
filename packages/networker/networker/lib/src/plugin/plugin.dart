import 'dart:async';

import '../connection.dart';

typedef BaseNetworkerPlugin = NetworkerPlugin<RawData, RawData>;

abstract class NetworkerPlugin<I, O> {
  final Map<NetworkerPlugin<O, dynamic>, StreamSubscription<O>> _plugins = {};
  final StreamController<O> _readController = StreamController<O>.broadcast();
  final StreamController<I> _writeController = StreamController<I>.broadcast();

  Stream<O> get read => _readController.stream;
  Stream<I> get write => _writeController.stream;

  O decode(I data);
  I encode(O data);

  void _onPluginMessage(O data) {
    _writeController.add(encode(data));
  }

  void addPlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins[plugin] = plugin._writeController.stream.listen(_onPluginMessage);
  }

  void removePlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins.remove(plugin)?.cancel();
  }

  void onMessage(I data) {
    final rawData = decode(data);
    _readController.add(rawData);
    for (final plugin in _plugins.keys) {
      plugin.onMessage(rawData);
    }
  }

  void sendMessage(O data) {
    final rawData = encode(data);
    _writeController.add(rawData);
  }
}

class NetworkerMessenger<T> extends NetworkerPlugin<T, T> {
  @override
  T decode(T data) => data;

  @override
  T encode(T data) => data;
}

abstract class NetworkerServerPlugin {
  final Map<NetworkerServer, StreamSubscription<ConnectionId>>
      _connectListeners = {}, _disconnectListeners = {};
  void init(NetworkerServer server) {
    _connectListeners[server] =
        server.connect.listen((event) => onConnect(server, event));
    _disconnectListeners[server] =
        server.disconnect.listen((event) => onDisconnect(server, event));
  }

  void dispose(NetworkerServer server) {
    _connectListeners.remove(server)?.cancel();
    _disconnectListeners.remove(server)?.cancel();
  }

  void onConnect(NetworkerServer server, ConnectionId id) {}
  void onDisconnect(NetworkerServer server, ConnectionId id) {}
}
