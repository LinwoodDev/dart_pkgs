import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../networker.dart';

final class RpcRequest {
  final Map<String, dynamic> data;

  RpcRequest(this.data);

  dynamic get message => data['message'];
  String get function => data['function'];
  ConnectionId get receiver => data['receiver'];
}

final class RpcMessage extends RpcRequest {
  RpcMessage(super.data);

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

  RpcMessage Function(RpcMessage request)? _onRequest;

  set onRequest(RpcMessage Function(RpcMessage request) onRequest) {
    _onRequest = onRequest;
  }

  @override
  void onConnect(NetworkerServer server, ConnectionId id) {
    final sub = server.getConnection(id)?.read.listen((event) {
      var message =
          RpcMessage({...jsonDecode(utf8.decode(event)), 'client': id});
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
    });
    if (sub != null) {
      _subscriptions[(server, id)] = sub;
    }
  }

  @override
  void onDisconnect(NetworkerServer server, ConnectionId id) {
    _subscriptions.remove((server, id))?.cancel();
  }
}

class RpcNetworkerPlugin extends NetworkerMessenger<Map<String, dynamic>>
    with RpcPlugin {
  @override
  void onMessage(data) {
    super.onMessage(data);
    final message = decode(data);
    runFunction(RpcMessage(message));
  }
}
