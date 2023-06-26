import '../../networker.dart';

final class RpcMessage<T> {
  final Map<String, dynamic> data;

  const RpcMessage(this.data);

  String get client => data['client'];
  T get message => data['message'];
  dynamic getAttribute(String key) => data[key];
}

enum RpcType { authority, any, disabled }

final class RpcFunction {
  final RpcType type;
  final void Function(RpcMessage message) onMessage;

  RpcFunction(this.type, this.onMessage);
}

class RpcNetworkerPlugin extends NetworkerMessenger {
  final Map<String, RpcFunction> _functions = {};

  @override
  void onMessage(data) {
    super.onMessage(data);
    final message = RpcMessage(data);
    _functions[message.client]?.onMessage(message);
  }

  void addFunction(String client, RpcFunction function) {
    _functions[client] = function;
  }

  void removeFunction(String client) {
    _functions.remove(client);
  }
}
