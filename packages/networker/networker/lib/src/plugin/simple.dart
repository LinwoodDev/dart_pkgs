import 'dart:async';

import 'package:networker/networker.dart';

final class NetworkerPipeTransformer<I, O> extends NetworkerPipe<I, O> {
  final O Function(I) _decode;
  final I Function(O) _encode;

  NetworkerPipeTransformer(this._decode, this._encode);

  @override
  O decode(I data) => _decode(data);

  @override
  I encode(O data) => _encode(data);
}

final class AdvancedNetworkerPipeTransformer<I, O> extends NetworkerPipe<I, O> {
  final (O, Channel)? Function(I, Channel) _decode;
  final (I, Channel)? Function(O, Channel) _encode;

  AdvancedNetworkerPipeTransformer(this._decode, this._encode);

  @override
  (O, Channel)? decodeChannel(I data, Channel channel) =>
      _decode(data, channel);

  // Not in use, but required to implement the interface
  @override
  O decode(I data) => _decode(data, kAnyChannel)!.$1;

  @override
  (I, Channel)? encodeChannel(O data, Channel channel) =>
      _encode(data, channel);

  // Not in use, but required to implement the interface
  @override
  I encode(O data) => _encode(data, kAnyChannel)!.$1;
}

final class ReversedNetworkerPipe<I, O> extends NetworkerPipe<I, O> {
  final NetworkerPipe<O, I> pipe;

  ReversedNetworkerPipe(this.pipe);

  @override
  FutureOr<O> decode(I data) => pipe.encode(data);

  @override
  FutureOr<I> encode(O data) => pipe.decode(data);
}

final class FilteredNetworkerPipe<T> extends SimpleNetworkerPipe<T> {
  final bool Function(T, Channel)? filterEncoded;
  final bool Function(T, Channel)? filterDecoded;

  FilteredNetworkerPipe({
    this.filterEncoded,
    this.filterDecoded,
  });

  @override
  FutureOr<(T, Channel)?> decodeChannel(T data, Channel channel) {
    if (!(filterDecoded?.call(data, channel) ?? true)) {
      return null;
    }
    return super.decodeChannel(data, channel);
  }

  @override
  FutureOr<(T, Channel)?> encodeChannel(T data, Channel channel) {
    if (!(filterEncoded?.call(data, channel) ?? true)) {
      return null;
    }
    return super.encodeChannel(data, channel);
  }
}
