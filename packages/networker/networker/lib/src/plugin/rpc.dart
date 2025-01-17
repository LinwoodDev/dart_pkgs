import 'dart:typed_data';

import 'package:networker/networker.dart';

final class RpcConfig {
  final bool extendedFunctionIdentifiers;

  const RpcConfig({
    this.extendedFunctionIdentifiers = false,
  });
}

mixin RpcFunctionName on Enum {
  RpcNetworkerMode get mode => RpcNetworkerMode.authority;
  bool get canRunLocally => false;
}

final class RpcNetworkerPacket {
  final int function;
  final Channel channel;
  final Uint8List data;

  RpcNetworkerPacket({
    required this.function,
    required this.data,
    this.channel = kAnyChannel,
  });

  RpcNetworkerPacket.named({
    required RpcFunctionName name,
    required this.data,
    this.channel = kAnyChannel,
  }) : function = name.index;

  factory RpcNetworkerPacket.fromBytes(RpcConfig config, Uint8List bytes) {
    var function = bytes[0];
    int currentOffset = 1;
    if (config.extendedFunctionIdentifiers) {
      function |= bytes[currentOffset] << 8;
      currentOffset++;
    }
    Channel sender = kAnyChannel;
    sender = bytes[currentOffset] << 8 | bytes[currentOffset + 1];
    currentOffset += 2;
    final data = bytes.sublist(sender);
    return RpcNetworkerPacket(function: function, data: data, channel: sender);
  }

  Uint8List toBytes(RpcConfig config) {
    final bytes = BytesBuilder();
    if (config.extendedFunctionIdentifiers) {
      bytes.addByte(function >> 8);
    }
    bytes.addByte(function);
    bytes.addByte(channel >> 8);
    bytes.addByte(channel);
    bytes.add(data);
    return bytes.toBytes();
  }

  RpcNetworkerPacket withChannel(Channel channel) =>
      RpcNetworkerPacket(function: function, data: data, channel: channel);
}

enum RpcNetworkerMode { authority, selected, any, disabled }

final class RpcFunction {
  final bool canRunLocally;
  final RpcNetworkerMode mode;
  final RawNetworkerPipe pipe;

  const RpcFunction({
    this.canRunLocally = false,
    this.mode = RpcNetworkerMode.authority,
    required this.pipe,
  });

  bool shouldRun(Channel sender, Channel receiver, {bool forceLocal = false}) {
    if (!forceLocal && !canRunLocally && sender == kAnyChannel) return false;
    return switch (mode) {
      RpcNetworkerMode.authority => sender == kAuthorityChannel,
      RpcNetworkerMode.selected => true,
      RpcNetworkerMode.any => receiver == kAnyChannel,
      RpcNetworkerMode.disabled => false,
    };
  }
}

final class RpcNetworkerPipe
    extends NetworkerPipe<Uint8List, RpcNetworkerPacket> {
  final RpcConfig config;
  final Map<int, RpcFunction> functions = {};

  RpcNetworkerPipe({this.config = const RpcConfig()});

  @override
  RpcNetworkerPacket decode(Uint8List data) =>
      RpcNetworkerPacket.fromBytes(config, data);

  @override
  Uint8List encode(RpcNetworkerPacket data) => data.toBytes(config);

  RawNetworkerPipe registerFunction(
    int function, {
    bool canRunLocally = false,
    RpcNetworkerMode mode = RpcNetworkerMode.authority,
  }) {
    if (functions.containsKey(function)) return functions[function]!.pipe;
    final pipe = RawNetworkerPipe();
    final rpcFunction = RpcFunction(
      canRunLocally: canRunLocally,
      mode: mode,
      pipe: pipe,
    );
    functions[function] = rpcFunction;
    pipe.write.listen((packet) => sendMessage(RpcNetworkerPacket(
          function: function,
          data: packet.data,
          channel: packet.channel,
        )));
    return pipe;
  }

  void sendFunction(int function, Uint8List data,
          {Channel channel = kAnyChannel, bool forceLocal = false}) =>
      getFunction(function)?.sendMessage(data, channel);

  RawNetworkerPipe? getFunction(int function) => functions[function]?.pipe;

  bool unregisterFunction(int function) => functions.remove(function) != null;

  bool runFunction(RpcNetworkerPacket packet, {bool forceLocal = false}) =>
      callFunction(packet.function, packet.data,
          sender: packet.channel, forceLocal: forceLocal);

  bool callFunction(
    int function,
    Uint8List data, {
    Channel sender = kAnyChannel,
    bool forceLocal = false,
  }) {
    if (!isValidCall(function, sender)) return false;
    functions[function]?.pipe.sendMessage(data);
    return true;
  }

  bool isValidCall(int function, Channel sender,
      [Channel receiver = kAnyChannel]) {
    final rpcFunction = functions[function];
    if (rpcFunction == null) return false;
    return rpcFunction.shouldRun(sender, receiver);
  }
}

base mixin NamedRpcNetworkerPipe<T extends RpcFunctionName>
    on RpcNetworkerPipe {
  RawNetworkerPipe registerNamedFunction(T name) => registerFunction(name.index,
      canRunLocally: name.canRunLocally, mode: name.mode);

  List<RawNetworkerPipe> registerNamedFunctions(List<T> functions) =>
      functions.map((function) {
        return registerNamedFunction(function);
      }).toList();

  RawNetworkerPipe? getNamedFunction(T name) => getFunction(name.index);

  bool unregisterNamedFunction(T name) => unregisterFunction(name.index);

  bool runNamedFunction(RpcNetworkerPacket packet, {bool forceLocal = false}) =>
      runFunction(packet, forceLocal: forceLocal);

  bool callNamedFunction(T name, Uint8List data,
          {Channel sender = kAnyChannel, bool forceLocal = false}) =>
      callFunction(name.index, data, sender: sender, forceLocal: forceLocal);

  bool isValidNamedCall(T name, Channel sender,
          [Channel receiver = kAnyChannel]) =>
      isValidCall(name.index, sender, receiver);

  void sendNamedFunction(T name, Uint8List data,
          {Channel channel = kAnyChannel, bool forceLocal = false}) =>
      getNamedFunction(name)?.sendMessage(data, channel);
}

final class RpcClientNetworkerPipe extends RpcNetworkerPipe {
  RpcClientNetworkerPipe({super.config});

  @override
  void onMessage(Uint8List data, [Channel channel = kAnyChannel]) {
    super.onMessage(data, channel);
    runFunction(decode(data));
  }
}

final class NamedRpcClientNetworkerPipe<T extends RpcFunctionName>
    extends RpcClientNetworkerPipe with NamedRpcNetworkerPipe<T> {
  NamedRpcClientNetworkerPipe({super.config});
}

final class RpcServerNetworkerPipe extends RpcNetworkerPipe {
  final bool Function(RpcNetworkerPacket, Channel)? filter;
  final bool validate;

  RpcServerNetworkerPipe({
    super.config,
    this.filter,
    this.validate = true,
  });

  @override
  void onMessage(Uint8List data, [Channel channel = kAnyChannel]) {
    super.onMessage(data);
    final packet = decode(data);
    final receiver = packet.channel;
    final newPacket = packet.withChannel(channel);
    if (validate &&
        !isValidCall(newPacket.function, receiver, newPacket.channel)) {
      return;
    }
    if (!(filter?.call(newPacket, receiver) ?? false)) {
      return;
    }
    if (newPacket.channel == kAuthorityChannel) {
      runFunction(newPacket);
      return;
    }
    sendMessage(newPacket);
  }
}

final class NamedRpcServerNetworkerPipe<T extends RpcFunctionName>
    extends RpcServerNetworkerPipe with NamedRpcNetworkerPipe<T> {
  NamedRpcServerNetworkerPipe({
    super.config,
    super.filter,
    super.validate,
  });
}
