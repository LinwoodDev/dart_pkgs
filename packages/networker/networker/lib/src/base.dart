part of 'connection.dart';

sealed class NetworkerBase<O> extends NetworkerPipe<Uint8List, O> {
  Stream<void> get onOpen;
  Stream<void> get onClosed;
  FutureOr<void> init();
  bool get isClosed;
  bool get isOpen => !isClosed;
  FutureOr<void> close();
  Uri get address;
}
