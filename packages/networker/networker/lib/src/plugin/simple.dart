import 'plugin.dart';

final class SimpleNetworkerPlugin<I, O> extends NetworkerPlugin<I, O> {
  final O Function(I) _decode;
  final I Function(O) _encode;

  SimpleNetworkerPlugin(this._decode, this._encode);

  @override
  O decode(I data) => _decode(data);

  @override
  I encode(O data) => _encode(data);
}

final class ReversedNetworkerPlugin<I, O> extends NetworkerPlugin<I, O> {
  final NetworkerPlugin<O, I> plugin;

  ReversedNetworkerPlugin(this.plugin);

  @override
  O decode(I data) => plugin.encode(data);

  @override
  I encode(O data) => plugin.decode(data);
}
