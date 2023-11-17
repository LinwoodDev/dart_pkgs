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

  void addPlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins[plugin] = plugin._writeController.stream.listen(sendMessage);
  }

  void removePlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins.remove(plugin)?.cancel();
  }

  void onMessage(I data) {
    final rawData = decode(data);
    _readController.add(rawData);
    for (final plugin in _plugins.keys) {
      try {
        plugin.onMessage(rawData);
      } catch (_) {}
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
  void onAdd(NetworkerServer server) {}
  void onRemove(NetworkerServer server) {}
  void onConnect(NetworkerServer server, ConnectionId id) {}
  void onDisconnect(NetworkerServer server, ConnectionId id) {}
}
