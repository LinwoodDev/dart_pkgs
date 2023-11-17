part of 'connection.dart';

sealed class NetworkerBase {
  bool get isClosed;
  void close();
  Uri get address;
}
