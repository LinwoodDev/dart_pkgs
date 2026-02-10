import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

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

  FutureOr<O> decode(I data);
  FutureOr<(O, Channel)?> decodeChannel(I data, Channel channel) async =>
      (await decode(data), channel);

  FutureOr<I> encode(O data);
  FutureOr<(I, Channel)?> encodeChannel(O data, Channel channel) async =>
      (await encode(data), channel);

  void connect(NetworkerPipe<O, dynamic> pipe) {
    _pipes[pipe] = pipe._writeController.stream.listen(_sendMessagePacket);
  }

  void disconnect(NetworkerPipe<O, dynamic> pipe) {
    _pipes.remove(pipe)?.cancel();
  }

  Future<void> onMessage(I data, [Channel channel = kAnyChannel]) async {
    try {
      final result = await decodeChannel(data, channel);
      if (result == null) return;
      final (rawData, rawChannel) = result;
      _readController.add(NetworkerPacket(rawData, rawChannel));
      for (final plugin in _pipes.keys) {
        try {
          plugin.onMessage(rawData, rawChannel);
        } catch (_) {}
      }
    } catch (_) {}
  }

  void _sendMessagePacket(NetworkerPacket packet) =>
      sendMessage(packet.data, packet.channel);

  Future<void> sendMessage(O data, [Channel channel = kAnyChannel]) async {
    final result = await encodeChannel(data, channel);
    if (result == null) return;
    final (rawData, rawChannel) = result;
    _writeController.add(NetworkerPacket(rawData, rawChannel));
    await sendPacket(rawData, rawChannel);
  }

  @protected
  FutureOr<void> sendPacket(I data, Channel channel) {}

  /// Disposes all stream controllers and disconnects all connected pipes.
  @mustCallSuper
  void dispose() {
    for (final subscription in _pipes.values) {
      subscription.cancel();
    }
    _pipes.clear();
    _readController.close();
    _writeController.close();
  }
}

class SimpleNetworkerPipe<T> extends NetworkerPipe<T, T> {
  @override
  T decode(T data) => data;

  @override
  T encode(T data) => data;
}
