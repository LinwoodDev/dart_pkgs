import 'dart:async';
import 'dart:convert';
import 'dart:io';

class RtcExampleSignalingServer {
  final StreamController<String> _events = StreamController.broadcast();
  final Map<String, _SignalRoom> _rooms = {};

  HttpServer? _server;
  Uri? _url;
  Uri? _localUrl;
  StreamSubscription<HttpRequest>? _requestSubscription;
  int _nextPeerId = 0;

  Stream<String> get events => _events.stream;
  Uri? get url => _url;
  Uri? get localUrl => _localUrl;

  Future<Uri> start({
    String host = '0.0.0.0',
    String? advertisedHost,
    String room = 'demo',
    int port = 0,
  }) async {
    final server = _server = await HttpServer.bind(host, port);
    final displayHost = await _findDisplayHost();
    _localUrl = Uri(
      scheme: 'ws',
      host: displayHost,
      port: server.port,
      path: 'rtc',
      queryParameters: {'room': room},
    );
    _url = _localUrl!.replace(
      host: advertisedHost?.trim().isEmpty ?? true
          ? displayHost
          : advertisedHost!.trim(),
    );
    _requestSubscription = server.listen(_handleRequest);
    _events.add('signaling server started at $_url');
    return _url!;
  }

  Future<String> _findDisplayHost() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        return address.address;
      }
    }
    return InternetAddress.loopbackIPv4.address;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path != '/rtc') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }
    final roomName = request.uri.queryParameters['room']?.trim().isEmpty ?? true
        ? 'demo'
        : request.uri.queryParameters['room']!.trim();
    final room = _rooms.putIfAbsent(roomName, () => _SignalRoom(roomName));
    if (room.peers.length >= 2) {
      request.response.statusCode = HttpStatus.conflict;
      await request.response.close();
      _events.add('room $roomName is full');
      return;
    }

    final socket = await WebSocketTransformer.upgrade(request);
    final peer = _SignalPeer('peer-${++_nextPeerId}', socket);
    room.peers.add(peer);
    _events.add('${peer.id} joined room $roomName');
    _send(peer, {
      'type': 'joined',
      'peerId': peer.id,
      'room': roomName,
      'peers': room.peers.length,
    });

    socket.listen(
      (message) => _handleMessage(room, peer, message),
      onDone: () => _removePeer(room, peer),
      onError: (error) {
        _events.add('signaling error for ${peer.id}: $error');
        _removePeer(room, peer);
      },
      cancelOnError: true,
    );

    _maybeStartRoom(room);
  }

  void _handleMessage(_SignalRoom room, _SignalPeer peer, dynamic message) {
    if (message is! String) return;
    final decoded = jsonDecode(message);
    if (decoded is! Map) return;
    if (decoded['type'] != 'signal') return;
    final other = room.otherPeer(peer);
    if (other == null) return;
    _send(other, {
      'type': 'signal',
      'from': peer.id,
      'signal': decoded['signal'],
    });
  }

  void _maybeStartRoom(_SignalRoom room) {
    if (room.peers.length != 2) return;
    for (var i = 0; i < room.peers.length; i++) {
      _send(room.peers[i], {
        'type': 'ready',
        'room': room.name,
        'initiator': i == 0,
      });
    }
    _events.add('room ${room.name} matched two peers');
  }

  void _removePeer(_SignalRoom room, _SignalPeer peer) {
    if (!room.peers.remove(peer)) return;
    _events.add('${peer.id} left room ${room.name}');
    for (final remaining in room.peers) {
      _send(remaining, {'type': 'peer-left'});
    }
    if (room.peers.isEmpty) {
      _rooms.remove(room.name);
    }
  }

  void _send(_SignalPeer peer, Map<String, Object?> message) {
    peer.socket.add(jsonEncode(message));
  }

  Future<void> close() async {
    await _requestSubscription?.cancel();
    for (final room in _rooms.values) {
      for (final peer in room.peers) {
        await peer.socket.close();
      }
    }
    _rooms.clear();
    await _server?.close(force: true);
    await _events.close();
  }
}

class _SignalRoom {
  final String name;
  final List<_SignalPeer> peers = [];

  _SignalRoom(this.name);

  _SignalPeer? otherPeer(_SignalPeer peer) {
    for (final candidate in peers) {
      if (candidate != peer) return candidate;
    }
    return null;
  }
}

class _SignalPeer {
  final String id;
  final WebSocket socket;

  _SignalPeer(this.id, this.socket);
}
