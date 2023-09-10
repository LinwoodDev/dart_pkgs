import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../networker.dart';

final class RpcMessage<T> {
  final Map<String, dynamic> data;

  RpcMessage.fromData(ConnectionId client, T message)
      : data = {'client': client, 'message': message};
  const RpcMessage(this.data);

  ConnectionId get client => data['client'];
  T get message => data['message'];
}

enum RpcType { authority, any, disabled }

final class RpcFunction {
  final String client;
  final RpcType type;
  final void Function(RpcMessage message) onMessage;

  RpcFunction(this.client, this.type, this.onMessage);
}

class RpcNetworkerServerPlugin extends NetworkerServerPlugin {
  final Map<(NetworkerServer server, ConnectionId connection),
      StreamSubscription> _functions = {};

  @override
  void onConnect(NetworkerServer server, ConnectionId id) {
    final sub = server.getConnection(id)?.read.listen((event) {
      for (var element in server.connectionIds) {
        server.getConnection(element)?.sendMessage(
                Uint8List.fromList(utf8.encode(jsonEncode(RpcMessage.fromData(
              id,
              event,
            )))));
      }
    });
    if (sub != null) {
      _functions[(server, id)] = sub;
    }
  }

  @override
  void onDisconnect(NetworkerServer server, ConnectionId id) {
    _functions.remove((server, id))?.cancel();
  }
}

class RpcNetworkerPlugin extends NetworkerPlugin<dynamic, RpcMessage> {
  final Map<String, RpcFunction> _functions = {};

  @override
  void onMessage(data) {
    super.onMessage(data);
    final message = decode(data);
    _functions[message.client]?.onMessage(message);
  }

  void addFunction(String client, RpcFunction function) {
    _functions[client] = function;
  }

  void containsFunction(String client) => _functions.containsKey(client);

  void removeFunction(String client) {
    _functions.remove(client);
  }

  @override
  RpcMessage decode(data) => RpcMessage(data);

  @override
  encode(RpcMessage data) => data.data;
}
