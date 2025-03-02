part of 'connection.dart';

mixin NetworkerBase<O> on NetworkerPipe<Uint8List, O> {
  Stream<void> get onOpen;
  Stream<void> get onClosed;
  FutureOr<void> init();
  bool get isClosed;
  bool get isOpen => !isClosed;
  FutureOr<void> close();
  Uri get address;
}
