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

class ChannelFilterPipe extends RawNetworkerPipe {
  final Channel channel;
  final bool filterEncoded;

  ChannelFilterPipe({required this.channel, this.filterEncoded = false});

  @override
  (Uint8List, Channel)? decodeChannel(Uint8List data, Channel channel) {
    if (channel != this.channel) {
      return null;
    }
    return (data, channel);
  }

  @override
  (Uint8List, Channel)? encodeChannel(Uint8List data, Channel channel) {
    if (channel != this.channel && filterEncoded) {
      return null;
    }
    return (data, channel);
  }
}
