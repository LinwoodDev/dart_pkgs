part of 'connection.dart';

mixin NetworkerClientMixin<O> on NetworkerBase<O> {}

abstract class NetworkerClient extends NetworkerBase<Uint8List>
    with NetworkerClientMixin<Uint8List> {}
