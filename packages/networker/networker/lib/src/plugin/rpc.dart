import 'package:networker/networker.dart';

class RpcCommand {
  final String command;
  final ConnectionId id;
  final dynamic data;

  RpcCommand(this.command, this.id, this.data);
  factory RpcCommand.fromJson(Map<String, dynamic> json) =>
      RpcCommand(json['command'], json['id'], json['data']);

  Map<String, dynamic> toJson() => {'command': command, 'id': id, 'data': data};
}

class RpcNetworkerPlugin extends NetworkerPlugin<dynamic, RpcCommand> {
  @override
  RpcCommand decode(data) => RpcCommand.fromJson(data);

  @override
  encode(RpcCommand data) => data.toJson();
}
