import 'package:networker/networker.dart';

class EchoPipe<T> extends SimpleNetworkerPipe<T> {
  final int? toChannel;

  EchoPipe({this.toChannel});

  @override
  void onMessage(T data, [Channel channel = kAnyChannel]) {
    super.onMessage(data, channel);
    super.sendMessage(data, toChannel ?? channel);
  }
}
