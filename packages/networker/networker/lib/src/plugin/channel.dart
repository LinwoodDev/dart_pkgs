import 'dart:typed_data';

import 'package:networker/networker.dart';

class InternalChannelPipe extends RawNetworkerPipe {
  InternalChannelPipe();

  static NetworkerPipe<Uint8List, Uint8List> reversed() {
    return ReversedNetworkerPipe(InternalChannelPipe());
  }

  @override
  (Uint8List, Channel) decodeChannel(Uint8List data, Channel channel) {
    if (data.isEmpty) {
      return (data, channel);
    }
    final rawChannel = data.first;
    final rawData = data.sublist(1);
    return (rawData, rawChannel);
  }

  @override
  (Uint8List, Channel) encodeChannel(Uint8List data, Channel channel) {
    final builder = BytesBuilder();
    builder.addByte(channel);
    builder.add(data);
    return (builder.toBytes(), channel);
  }
}

class ChannelFilterPipe<T> extends SimpleNetworkerPipe<T> {
  final Channel channel;
  final bool filterEncoded, filterDecoded;
  final bool allowAnyChannel;

  ChannelFilterPipe({
    required this.channel,
    this.filterEncoded = true,
    this.filterDecoded = true,
    this.allowAnyChannel = true,
  });

  @override
  (T, Channel)? decodeChannel(T data, Channel channel) {
    if (channel != this.channel &&
        filterDecoded &&
        (!allowAnyChannel || channel != kAnyChannel)) {
      return null;
    }
    return (data, channel);
  }

  @override
  (T, Channel)? encodeChannel(T data, Channel channel) {
    if (channel != this.channel &&
        filterEncoded &&
        (!allowAnyChannel || channel != kAnyChannel)) {
      return null;
    }
    return (data, channel);
  }
}
