import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../networker.dart';

final class RpcRequest {
  final Map<String, dynamic> data;

  RpcRequest(ConnectionId receiver, String function, dynamic message)
      : data = {
          'receiver': receiver,
          'function': function,
          'message': message,
        };

  RpcRequest.fromData(this.data);

  dynamic get message => data['message'];
  String get function => data['function'];
  ConnectionId get receiver => data['receiver'];
}

final class RpcMessage extends RpcRequest {
  RpcMessage(super.data) : super.fromData();

  ConnectionId get client => data['client'];
}

enum RpcType { authority, any, disabled }

final class RpcFunction {
  final RpcType type;
  final void Function(RpcMessage message) onMessage;

  RpcFunction(this.type, this.onMessage);

  bool shouldRun(ConnectionId id) {
    switch (type) {
      case RpcType.authority:
        return id.isAuthority;
      case RpcType.any:
        return true;
      case RpcType.disabled:
        return false;
    }
  }
}

mixin RpcPlugin {
  final Map<String, RpcFunction> _functions = {};

  void sendMessage(RpcRequest request);

  void addFunction(String name, RpcFunction function) {
    _functions[name] = function;
  }

  void containsFunction(String name) => _functions.containsKey(name);

  void removeFunction(String name) {
    _functions.remove(name);
  }

  void runFunction(RpcMessage message) {
    final function = _functions[message.function];
    if (function != null && function.shouldRun(message.client)) {
      function.onMessage(message);
    }
  }
}

class RpcNetworkerServerPlugin extends NetworkerServerPlugin with RpcPlugin {
  final Map<(NetworkerServer server, ConnectionId connection),
      StreamSubscription> _subscriptions = {};
  final Set<NetworkerServer> _servers = {};

  RpcMessage Function(RpcMessage request)? _onRequest;

  set onRequest(RpcMessage Function(RpcMessage request) onRequest) {
    _onRequest = onRequest;
  }

  @override
  void sendMessage(RpcRequest request) {
    for (final server in _servers) {
      _send(server, kNetworkerConnectionIdAuthority, request.data);
    }
  }

  void _send(
      NetworkerServer server, ConnectionId id, Map<String, dynamic> event) {
    var message = RpcMessage({...event, 'client': id});
    message = _onRequest?.call(message) ?? message;
    final receiver = message.receiver;
    final data = Uint8List.fromList(utf8.encode(jsonEncode(message.data)));
    switch (receiver) {
      case kNetworkerConnectionIdAny:
        for (final element in server.connectionIds) {
          server.getConnection(element)?.sendMessage(data);
        }
        runFunction(message);
        break;
      case kNetworkerConnectionIdAuthority:
        runFunction(message);
        break;
      default:
        server.getConnection(id)?.sendMessage(data);
        break;
    }
  }

  @override
  void onAdd(NetworkerServer<NetworkerConnection> server) {
    _servers.add(server);
  }

  @override
  void onRemove(NetworkerServer<NetworkerConnection> server) {
    _servers.remove(server);
  }

  @override
  void onConnect(NetworkerServer server, ConnectionId id) {
    final sub = server
        .getConnection(id)
        ?.read
        .listen((event) => _send(server, id, jsonDecode(utf8.decode(event))));
    if (sub != null) {
      _subscriptions[(server, id)] = sub;
    }
  }

  @override
  void onDisconnect(NetworkerServer server, ConnectionId id) {
    _subscriptions.remove((server, id))?.cancel();
  }
}

class RpcNetworkerPlugin
    extends NetworkerPlugin<Map<String, dynamic>, RpcRequest> with RpcPlugin {
  @override
  void onMessage(data) {
    super.onMessage(data);
    runFunction(RpcMessage(data));
  }

  @override
  RpcRequest decode(Map<String, dynamic> data) => RpcRequest.fromData(data);

  @override
  Map<String, dynamic> encode(RpcRequest data) => data.data;
}
