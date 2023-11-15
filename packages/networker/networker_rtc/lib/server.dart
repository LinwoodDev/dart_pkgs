/*
import 'dart:io';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:networker/networker.dart';
import 'package:networker_rtc/config.dart';
class NetworkerRtcServerConnection extends NetworkerConnection {
  final String id;

  NetworkerRtcServerConnection(this.id);

  @override
  void close() {}

  @override
  bool get isClosed => false;

  @override
  Future<void> send(RawData data) => throw UnimplementedError();
}

class NetworkerSocketServer
    extends NetworkerServer<NetworkerRtcServerConnection> {
  final NetworkerRtcConfiguration configuration;
  bool _isClosed = false;
  bool Function(HttpRequest event)? filterConnections;
  final RTCPeerConnection connection;

  NetworkerSocketServer(this.connection, [this.filterConnections]) {
    connection.createDataChannel('data', RTCDataChannelInit());
    connection.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex))
    waitForConnections();
  }

  @override
  void close() {
    server.close();
    _isClosed = true;
  }

  @override
  bool get isClosed => _isClosed;

  Future<void> waitForConnections() async {
    await for (var request in server.where(filterConnections ?? (e) => true)) {
      final socket = await WebSocketTransformer.upgrade(request);
      addConnection(socket.hashCode, NetworkerSocketServerConnection(socket));
    }
    _isClosed = true;
  }
}
*/
