import 'dart:async';

import 'package:networker/src/connection.dart';

typedef BaseNetworkerPlugin = NetworkerPlugin<RawData, RawData>;

abstract class NetworkerPlugin<I, O> {
  final Map<NetworkerPlugin<O, dynamic>, StreamSubscription<MessageDetails<O>>>
      _plugins = {};
  final StreamController<MessageDetails<O>> _readController =
      StreamController<MessageDetails<O>>.broadcast();
  final StreamController<MessageDetails<I>> _writeController =
      StreamController<MessageDetails<I>>.broadcast();

  O decode(I data);
  I encode(O data);

  void _onPluginMessage(MessageDetails data) {
    _writeController.add((data.$1, encode(data.$2)));
  }

  void addPlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins[plugin] = plugin._writeController.stream.listen(_onPluginMessage);
  }

  void removePlugin(NetworkerPlugin<O, dynamic> plugin) {
    _plugins.remove(plugin)?.cancel();
  }

  void onMessage(ConnectionId id, I data) {
    final rawData = decode(data);
    _readController.add((id, rawData));
    for (final plugin in _plugins.keys) {
      plugin.onMessage(id, rawData);
    }
  }

  void sendMessage(ConnectionId id, O data) {
    final rawData = encode(data);
    _writeController.add((id, rawData));
    for (final plugin in _plugins.keys) {
      plugin.sendMessage(id, rawData);
    }
  }
}

class NetworkerMessenger<T> extends NetworkerPlugin<T, T> {
  @override
  T decode(T data) => data;

  @override
  T encode(T data) => data;
}
