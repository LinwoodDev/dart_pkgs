import 'dart:typed_data';

import 'package:networker/networker.dart';

final class RpcConfig {
  final bool extendedFunctionIdentifiers;
  final bool channelField;

  const RpcConfig({
    this.extendedFunctionIdentifiers = false,
    this.channelField = true,
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
    if (config.channelField) {
      sender = bytes[currentOffset] << 8 | bytes[currentOffset + 1];
      currentOffset += 2;
    }
    final data = bytes.sublist(currentOffset);
    return RpcNetworkerPacket(function: function, data: data, channel: sender);
  }

  Uint8List toBytes(RpcConfig config) {
    final bytes = BytesBuilder();
    if (config.extendedFunctionIdentifiers) {
      bytes.addByte(function >> 8);
    }
    bytes.addByte(function);
    if (config.channelField) {
      bytes.addByte(channel >> 8);
      bytes.addByte(channel);
    }
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

mixin RpcNetworkerPipeMixin on NetworkerPipe<Uint8List, RpcNetworkerPacket> {
  final Map<int, RpcFunction> _functions = {};
  RpcConfig get config;
  bool get isServer;
  Channel? get receiverChannel => null;

  @override
  RpcNetworkerPacket decode(Uint8List data) =>
      RpcNetworkerPacket.fromBytes(config, data);

  @override
  Uint8List encode(RpcNetworkerPacket data) => data.toBytes(config);

  Channel get defaultReceiverChannel =>
      receiverChannel ?? (isServer ? kAuthorityChannel : kAnyChannel);

  RawNetworkerPipe registerFunction(
    int function, {
    bool canRunLocally = false,
    RpcNetworkerMode mode = RpcNetworkerMode.authority,
  }) {
    if (_functions.containsKey(function)) return _functions[function]!.pipe;
    final pipe = RawNetworkerPipe();
    final rpcFunction = RpcFunction(
      canRunLocally: canRunLocally,
      mode: mode,
      pipe: pipe,
    );
    _functions[function] = rpcFunction;
    pipe.write.listen((packet) => sendMessage(
        RpcNetworkerPacket(
          function: function,
          data: packet.data,
          channel: isServer ? defaultReceiverChannel : packet.channel,
        ),
        isServer ? packet.channel : defaultReceiverChannel));
    return pipe;
  }

  void sendFunction(int function, Uint8List data,
          {Channel channel = kAnyChannel,
          Channel? receiver,
          bool forceLocal = false}) =>
      sendMessage(
          RpcNetworkerPacket(
              function: function,
              data: data,
              channel:
                  isServer ? (receiver ?? defaultReceiverChannel) : channel),
          isServer ? channel : (receiver ?? defaultReceiverChannel));

  RawNetworkerPipe? getFunction(int function) => _functions[function]?.pipe;

  bool unregisterFunction(int function) => _functions.remove(function) != null;

  bool runFunction(RpcNetworkerPacket packet,
          {bool forceLocal = false, Channel? channel}) =>
      callFunction(packet.function, packet.data,
          sender: channel ?? packet.channel, forceLocal: forceLocal);

  bool callFunction(
    int function,
    Uint8List data, {
    Channel sender = kAnyChannel,
    bool forceLocal = false,
  }) {
    if (!isValidCall(function, sender)) return false;
    _functions[function]?.pipe.onMessage(data);
    return true;
  }

  bool isValidCall(int function, Channel sender,
      [Channel receiver = kAnyChannel]) {
    final rpcFunction = _functions[function];
    if (rpcFunction == null) return false;
    return rpcFunction.shouldRun(sender, receiver);
  }
}

sealed class RpcNetworkerPipe
    extends NetworkerPipe<Uint8List, RpcNetworkerPacket>
    with RpcNetworkerPipeMixin {
  @override
  final RpcConfig config;
  @override
  final Channel? receiverChannel;

  RpcNetworkerPipe({
    this.config = const RpcConfig(),
    this.receiverChannel,
  });
}

mixin NamedRpcNetworkerPipe<I extends RpcFunctionName,
    O extends RpcFunctionName> on RpcNetworkerPipeMixin {
  RawNetworkerPipe registerNamedFunction(I name) => registerFunction(name.index,
      canRunLocally: name.canRunLocally, mode: name.mode);

  List<RawNetworkerPipe> registerNamedFunctions(List<I> functions) =>
      functions.map((function) {
        return registerNamedFunction(function);
      }).toList();

  RawNetworkerPipe? getNamedFunction(I name) => getFunction(name.index);

  bool unregisterNamedFunction(I name) => unregisterFunction(name.index);

  bool runNamedFunction(RpcNetworkerPacket packet,
          {bool forceLocal = false, Channel? channel}) =>
      runFunction(packet, forceLocal: forceLocal, channel: channel);

  bool callNamedFunction(I name, Uint8List data,
          {Channel sender = kAnyChannel, bool forceLocal = false}) =>
      callFunction(name.index, data, sender: sender, forceLocal: forceLocal);

  bool isValidNamedCall(I name, Channel sender,
          [Channel receiver = kAnyChannel]) =>
      isValidCall(name.index, sender, receiver);

  void sendNamedFunction(O name, Uint8List data,
          {Channel channel = kAnyChannel,
          bool forceLocal = false,
          Channel? receiver}) =>
      sendFunction(name.index, data,
          channel: channel, forceLocal: forceLocal, receiver: receiver);
}

final class RpcClientNetworkerPipe extends RpcNetworkerPipe {
  RpcClientNetworkerPipe({super.config});

  @override
  bool get isServer => false;

  @override
  Future<void> onMessage(Uint8List data,
      [Channel channel = kAnyChannel]) async {
    await super.onMessage(data, channel);
    runFunction(decode(data), channel: config.channelField ? null : channel);
  }
}

final class NamedRpcClientNetworkerPipe<I extends RpcFunctionName,
        O extends RpcFunctionName> extends RpcClientNetworkerPipe
    with NamedRpcNetworkerPipe<I, O> {
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
  Future<void> onMessage(Uint8List data,
      [Channel channel = kAnyChannel]) async {
    await super.onMessage(data);
    final packet = decode(data);
    final receiver = packet.channel.abs();
    final newPacket = packet.withChannel(channel);
    if (validate && !isValidCall(newPacket.function, channel, receiver)) {
      return;
    }
    if (!(filter?.call(newPacket, receiver) ?? true)) {
      return;
    }
    if (receiver == kAuthorityChannel || receiver == kAnyChannel) {
      runFunction(newPacket);
    }
    if (receiver != kAuthorityChannel) {
      sendMessage(newPacket, receiver == kAnyChannel ? -channel : receiver);
    }
  }

  @override
  bool get isServer => true;
}

final class NamedRpcServerNetworkerPipe<I extends RpcFunctionName,
        O extends RpcFunctionName> extends RpcServerNetworkerPipe
    with NamedRpcNetworkerPipe<I, O> {
  NamedRpcServerNetworkerPipe({
    super.config,
    super.filter,
    super.validate,
  });
}
