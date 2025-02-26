import 'package:networker/networker.dart';

class EchoPipe<T> extends SimpleNetworkerPipe<T> {
  final Channel? toChannel;

  EchoPipe({this.toChannel});

  @override
  Future<void> onMessage(T data, [Channel channel = kAnyChannel]) async {
    await super.onMessage(data, channel);
    return super.sendMessage(data, toChannel ?? channel);
  }
}
