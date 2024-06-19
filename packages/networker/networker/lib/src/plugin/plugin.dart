import 'dart:async';
import 'dart:typed_data';

import '../connection.dart';

typedef RawNetworkerPipe = SimpleNetworkerPipe<Uint8List>;

final class NetworkerPacket<T> {
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
  I encode(O data);

  void connect(NetworkerPipe<O, dynamic> pipe) {
    _pipes[pipe] = pipe._writeController.stream.listen(_sendMessagePacket);
  }

  void disconnect(NetworkerPipe<O, dynamic> pipe) {
    _pipes.remove(pipe)?.cancel();
  }

  void onMessage(I data, [Channel channel = kAnyChannel]) {
    final rawData = decode(data);
    _readController.add(NetworkerPacket(rawData, channel));
    for (final plugin in _pipes.keys) {
      try {
        plugin.onMessage(rawData, channel);
      } catch (_) {}
    }
  }

  void _sendMessagePacket(NetworkerPacket packet) =>
      sendMessage(packet.data, packet.channel);

  void sendMessage(O data, [Channel channel = kAnyChannel]) {
    final rawData = encode(data);
    _writeController.add(NetworkerPacket(rawData, channel));
  }
}

class SimpleNetworkerPipe<T> extends NetworkerPipe<T, T> {
  @override
  T decode(T data) => data;

  @override
  T encode(T data) => data;
}
