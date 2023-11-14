import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import 'plugin/plugin.dart';

part 'base.dart';
part 'client.dart';
part 'server.dart';

typedef ConnectionId = int;
typedef RawData = Uint8List;

const kNetworkerConnectionIdAuthority = -1;
const kNetworkerConnectionIdAny = -2;

extension NetworkerConnectionId on ConnectionId {
  bool get isServer => this == kNetworkerConnectionIdAny;
  bool get isAuthority => this == kNetworkerConnectionIdAuthority;
}

abstract class NetworkerConnection extends NetworkerMessenger<RawData>
    implements NetworkerBase {
  NetworkerConnection() {
    write.listen((data) {
      if (isClosed) {
        throw StateError('Connection is closed');
      }
      send(data);
    });
  }
  Future<void> send(RawData data);
}
