import 'dart:async';
import 'dart:typed_data';

import '../connection.dart';

typedef RawNetworkerPipe = SimpleNetworkerPipe<Uint8List>;

class NetworkerPacket<T> {
  final T data;
  final Channel channel;

  NetworkerPacket(this.data, [this.channel = kAnyChannel]);

  bool get isServer => channel == kAuthorityChannel;
  bool get isAny => channel == kAnyChannel;
}

abstract class NetworkerPipe<I, O> {
  final Map<NetworkerPipe<O, dynamic>, StreamSubscription<NetworkerPacket<O>>>
      _pipes = {};
  final StreamController<NetworkerPacket<O>> _readController =
      StreamController<NetworkerPacket<O>>.broadcast();
  final StreamController<NetworkerPacket<I>> _writeController =
      StreamController<NetworkerPacket<I>>.broadcast();

  Stream<NetworkerPacket<O>> get read => _readController.stream;
  Stream<NetworkerPacket<I>> get write => _writeController.stream;

  O decode(I data);
  (O, Channel)? decodeChannel(I data, Channel channel) =>
      (decode(data), channel);
  I encode(O data);
  (I, Channel)? encodeChannel(O data, Channel channel) =>
      (encode(data), channel);

  void connect(NetworkerPipe<O, dynamic> pipe) {
    _pipes[pipe] = pipe._writeController.stream.listen(_sendMessagePacket);
  }

  void disconnect(NetworkerPipe<O, dynamic> pipe) {
    _pipes.remove(pipe)?.cancel();
  }

  void onMessage(I data, [Channel channel = kAnyChannel]) {
    final result = decodeChannel(data, channel);
    if (result == null) return;
    final (rawData, rawChannel) = result;
    _readController.add(NetworkerPacket(rawData, rawChannel));
    for (final plugin in _pipes.keys) {
      try {
        plugin.onMessage(rawData, rawChannel);
      } catch (_) {}
    }
  }

  void _sendMessagePacket(NetworkerPacket packet) =>
      sendMessage(packet.data, packet.channel);

  void sendMessage(O data, [Channel channel = kAnyChannel]) {
    final result = encodeChannel(data, channel);
    if (result == null) return;
    final (rawData, rawChannel) = result;
    _writeController.add(NetworkerPacket(rawData, rawChannel));
  }
}

class SimpleNetworkerPipe<T> extends NetworkerPipe<T, T> {
  @override
  T decode(T data) => data;

  @override
  T encode(T data) => data;
}
