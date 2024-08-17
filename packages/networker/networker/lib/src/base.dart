part of 'connection.dart';

sealed class NetworkerBase extends RawNetworkerPipe {
  Stream<void> get onOpen;
  Stream<void> get onClosed;
  FutureOr<void> init();
  bool get isClosed;
  bool get isOpen => !isClosed;
  void close();
  Uri get address;
}
