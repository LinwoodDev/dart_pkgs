part of 'connection.dart';

mixin NetworkerClientMixin<O> implements NetworkerBase<O> {}

abstract class NetworkerClient extends RawNetworkerPipe
    with NetworkerBase<Uint8List>, NetworkerClientMixin<Uint8List> {}
