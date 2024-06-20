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

final class ReversedNetworkerPipe<I, O> extends NetworkerPipe<I, O> {
  final NetworkerPipe<O, I> pipe;

  ReversedNetworkerPipe(this.pipe);

  @override
  O decode(I data) => pipe.encode(data);

  @override
  I encode(O data) => pipe.decode(data);
}
