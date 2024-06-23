import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:networker/networker.dart';

final class RpcConfig {
  final bool extendedFunctionIdentifiers;

  const RpcConfig({
    this.extendedFunctionIdentifiers = false,
  });
}

class RpcNetworkerPacket {
  final int function;
  final Channel channel;
  final Uint8List data;

  RpcNetworkerPacket({
    required this.function,
    required this.data,
    this.channel = kAnyChannel,
  });

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

enum RpcNetworkerMode { authority, any, disabled }

final class RpcFunction {
  final bool canRunLocally;
  final RpcNetworkerMode mode;
  final RawNetworkerPipe pipe;

  const RpcFunction({
    this.canRunLocally = false,
    this.mode = RpcNetworkerMode.authority,
    required this.pipe,
  });

  bool shouldRun(Channel sender, {bool forceLocal = false}) {
    if (!forceLocal && !canRunLocally && sender != kAnyChannel) return false;
    return switch (mode) {
      RpcNetworkerMode.authority => sender == kAuthorityChannel,
      RpcNetworkerMode.any => true,
      RpcNetworkerMode.disabled => false,
    };
  }
}

class RpcNetworkerPipe extends NetworkerPipe<Uint8List, RpcNetworkerPacket> {
  final RpcConfig config;
  final Map<int, RpcFunction> functions = {};
  final Set<(int, String)> _functionNames = {};

  RpcNetworkerPipe({this.config = const RpcConfig()}) {
    read.listen(onData);
  }

  @override
  RpcNetworkerPacket decode(Uint8List data) =>
      RpcNetworkerPacket.fromBytes(config, data);

  @override
  Uint8List encode(RpcNetworkerPacket data) => data.toBytes(config);

  RawNetworkerPipe registerFunction(
    int function, {
    String? name,
    bool canRunLocally = false,
    RpcNetworkerMode mode = RpcNetworkerMode.authority,
  }) {
    if (_functionNames.contains((function, name))) {
      throw ArgumentError('Function $function already registered');
    }
    final pipe = RawNetworkerPipe();
    final rpcFunction = RpcFunction(
      canRunLocally: canRunLocally,
      mode: mode,
      pipe: pipe,
    );
    functions[function] = rpcFunction;
    if (name != null) {
      _functionNames.add((function, name));
    }
    pipe.write.listen((packet) => sendMessage(RpcNetworkerPacket(
          function: function,
          data: packet.data,
          channel: packet.channel,
        )));
    return pipe;
  }

  bool unregisterFunction(int function) {
    final removed = functions.remove(function);
    if (removed == null) return false;
    _functionNames.removeWhere((pair) => pair.$1 == function);
    return true;
  }

  bool unregisterNamedFunction(String name) {
    final pair = _functionNames.firstWhereOrNull((pair) => pair.$2 == name);
    if (pair == null) return false;
    return unregisterFunction(pair.$1);
  }

  bool runFunction(RpcNetworkerPacket packet, {bool forceLocal = false}) {
    return callFunction(packet.function, packet.data, sender: packet.channel);
  }

  bool callFunction(
    int function,
    Uint8List data, {
    Channel sender = kAnyChannel,
    bool forceLocal = false,
  }) {
    final rpcFunction = functions[function];
    if (rpcFunction == null) return false;
    if (!rpcFunction.shouldRun(sender, forceLocal: forceLocal)) return false;
    rpcFunction.pipe.sendMessage(data);
    return true;
  }

  bool callNamedFunction(
    String name,
    Uint8List data, {
    Channel sender = kAnyChannel,
    bool forceLocal = false,
  }) {
    final pair = _functionNames.firstWhereOrNull((pair) => pair.$2 == name);
    if (pair == null) return false;
    return callFunction(pair.$1, data, sender: sender, forceLocal: forceLocal);
  }

  void onData(NetworkerPacket<RpcNetworkerPacket> event) {}
}

final class RpcClientNetworkerPipe extends RpcNetworkerPipe {
  RpcClientNetworkerPipe({super.config});

  @override
  void onData(NetworkerPacket<RpcNetworkerPacket> event) {
    runFunction(event.data);
  }
}

final class RpcServerNetworkerPipe extends RpcNetworkerPipe {
  final bool Function(RpcNetworkerPacket, Channel)? filter;
  RpcServerNetworkerPipe({super.config, this.filter});

  @override
  void onData(NetworkerPacket<RpcNetworkerPacket> event) {
    final receiver = event.data.channel;
    final newPacket = event.data.withChannel(event.channel);
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
