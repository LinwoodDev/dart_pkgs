part of 'connection.dart';

sealed class NetworkerBase {
  FutureOr<void> init();
  bool get isClosed;
  void close();
  Uri get address;
}
