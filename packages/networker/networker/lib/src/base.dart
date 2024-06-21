part of 'connection.dart';

sealed class NetworkerBase extends RawNetworkerPipe {
  FutureOr<void> init();
  bool get isClosed;
  void close();
  Uri get address;
}
