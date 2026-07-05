import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:networker/networker.dart';
import 'package:networker_rtc/client.dart';

class RtcExamplePeer {
  final StreamController<String> _events = StreamController.broadcast();

  NetworkerRtcClient? _transport;
  WebSocket? _signalingSocket;
  StreamSubscription<NetworkerRtcSignal>? _signalSubscription;
  StreamSubscription<NetworkerPacket<Uint8List>>? _readSubscription;
  StreamSubscription<void>? _openSubscription;
  StreamSubscription<void>? _closedSubscription;
  bool _connected = false;
  bool _offerCreated = false;
  String? _peerId;

  Stream<String> get events => _events.stream;
  bool get isConnected => _connected;

  NetworkerRtcClient get transport {
    final transport = _transport;
    if (transport == null) {
      throw StateError('Peer has not joined a signaling room.');
    }
    return transport;
  }

  Future<void> join(
    Uri signalingUrl, {
    NetworkerRtcConfiguration configuration = const NetworkerRtcConfiguration(),
  }) async {
    _transport = NetworkerRtcClient(
      Uri.parse('rtc://example-peer'),
      configuration: configuration,
    );
    _readSubscription ??= transport.read.listen((packet) {
      final text = utf8.decode(packet.data);
      _events.add('peer: $text');
    });
    _openSubscription ??= transport.onOpen.listen((_) {
      _connected = true;
      _events.add('data channel opened');
    });
    _closedSubscription ??= transport.onClosed.listen((_) {
      _connected = false;
      _events.add('data channel closed');
    });
    _signalSubscription ??= transport.onSignal.listen(_sendSignal);

    await transport.init();
    final socket = _signalingSocket = await WebSocket.connect(
      signalingUrl.toString(),
    );
    _events.add('joined signaling room');
    socket.listen(
      _handleSignalingMessage,
      onDone: () => _events.add('signaling server disconnected'),
      onError: (error) => _events.add('signaling error: $error'),
      cancelOnError: true,
    );
  }

  void _handleSignalingMessage(dynamic message) {
    if (message is! String) return;
    final decoded = jsonDecode(message);
    if (decoded is! Map) return;
    final payload = Map<String, dynamic>.from(decoded);
    switch (payload['type']) {
      case 'joined':
        _peerId = payload['peerId'] as String?;
        _events.add('waiting for another peer');
      case 'ready':
        final initiator = payload['initiator'] == true;
        _events.add(
          initiator ? 'matched peer, creating offer' : 'matched peer',
        );
        if (initiator && !_offerCreated) {
          _offerCreated = true;
          unawaited(transport.createOffer());
        }
      case 'signal':
        final signal = payload['signal'];
        if (signal is! Map) return;
        unawaited(
          transport.handleSignal(
            NetworkerRtcSignal.fromMap(Map<String, dynamic>.from(signal)),
          ),
        );
      case 'peer-left':
        _events.add('peer left the room');
      default:
        break;
    }
  }

  void _sendSignal(NetworkerRtcSignal signal) {
    _signalingSocket?.add(
      jsonEncode({
        'type': 'signal',
        if (_peerId != null) 'from': _peerId,
        'signal': signal.toMap(),
      }),
    );
  }

  Future<void> send(String message) async {
    await transport.sendMessage(Uint8List.fromList(utf8.encode(message)));
    _events.add('me: $message');
  }

  Future<void> close() async {
    final rtcTransport = _transport;
    await _signalSubscription?.cancel();
    await _readSubscription?.cancel();
    await _openSubscription?.cancel();
    await _closedSubscription?.cancel();
    await _signalingSocket?.close();
    await rtcTransport?.close();
    await _events.close();
  }
}
