import 'package:networker/networker.dart';

class EchoPipe<T> extends SimpleNetworkerPipe<T> {
  final Channel? toChannel;
  final T? Function(T data)? transform;

  EchoPipe({
    this.toChannel,
    this.transform,
  });

  @override
  void onMessage(T data, [Channel channel = kAnyChannel]) {
    super.onMessage(data, channel);
    if (transform != null) {
      final transformed = transform?.call(data);
      if (transformed == null) return;
      data = transformed;
    }
    sendMessage(data, toChannel ?? channel);
  }
}
