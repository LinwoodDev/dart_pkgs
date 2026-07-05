library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meta/meta.dart';
import 'package:networker/networker.dart';

import 'config.dart';

export 'config.dart';

class NetworkerRtcConnectionInfo extends ConnectionInfo {
  @override
  final Uri address;
  final RTCPeerConnection peerConnection;
  RTCDataChannel? dataChannel;
  StreamSubscription<RTCDataChannelMessage>? messageSubscription;
  StreamSubscription<RTCDataChannelState>? stateSubscription;
  final List<NetworkerRtcSignal> pendingSignals = [];
  bool signalingReady = false;
  bool _closed = false;

  NetworkerRtcConnectionInfo({
    required this.address,
    required this.peerConnection,
    this.dataChannel,
  });

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await messageSubscription?.cancel();
    await stateSubscription?.cancel();
    await dataChannel?.close();
    await peerConnection.close();
    await peerConnection.dispose();
  }

  @override
  Future<void> sendMessage(Uint8List data) async {
    await dataChannel?.send(RTCDataChannelMessage.fromBinary(data));
  }
}

class NetworkerRtcServer extends NetworkerServer<NetworkerRtcConnectionInfo> {
  final Uri _address;
  final NetworkerRtcConfiguration configuration;
  final Map<String, dynamic> constraints;
  final String dataChannelLabel;
  final RTCDataChannelInit Function()? createDataChannelInit;

  Future<void> _signalQueue = Future.value();
  bool _closed = true;

  final StreamController<void> _onOpen = StreamController<void>.broadcast();
  final StreamController<void> _onClosed = StreamController<void>.broadcast();
  final StreamController<NetworkerRtcSignal> _onSignal =
      StreamController<NetworkerRtcSignal>.broadcast();
  final StreamController<Channel> _dataChannelOpen =
      StreamController<Channel>.broadcast();

  Stream<NetworkerRtcSignal> get onSignal => _onSignal.stream;
  Stream<Channel> get dataChannelOpen => _dataChannelOpen.stream;

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  @override
  Uri get address => _address;

  NetworkerRtcServer({
    Uri? address,
    this.configuration = const NetworkerRtcConfiguration(),
    this.constraints = const {},
    this.dataChannelLabel = 'networker',
    this.createDataChannelInit,
  }) : _address = address ?? Uri(scheme: 'rtc', host: 'server');

  @override
  Future<void> init() async {
    if (isOpen) return;
    _closed = false;
    if (!_onOpen.isClosed) {
      _onOpen.add(null);
    }
  }

  Future<Channel> addPeer({Channel? channel, Uri? address}) async {
    if (isClosed) {
      await init();
    }
    final connection = await createRtcPeerConnection();
    final dataChannel = await createRtcDataChannel(connection);
    final info = NetworkerRtcConnectionInfo(
      address: address ?? Uri(scheme: 'rtc', host: 'peer'),
      peerConnection: connection,
      dataChannel: dataChannel,
    );
    configurePeerConnection(connection, info);
    final id = addClientConnection(info, channel);
    if (id == kAnyChannel) {
      await info.close();
      return id;
    }
    setDataChannel(id, info, dataChannel);
    final offer = await connection.createOffer();
    await connection.setLocalDescription(offer);
    addSignal(NetworkerRtcSignal.offer(offer, channel: id));
    info.signalingReady = true;
    for (final signal in info.pendingSignals) {
      addSignal(signal);
    }
    info.pendingSignals.clear();
    return id;
  }

  @protected
  Future<RTCPeerConnection> createRtcPeerConnection() {
    return createPeerConnection(configuration.toMap(), constraints);
  }

  @protected
  Future<RTCDataChannel> createRtcDataChannel(RTCPeerConnection connection) {
    return connection.createDataChannel(
      dataChannelLabel,
      createDataChannelInit?.call() ?? RTCDataChannelInit(),
    );
  }

  @protected
  void configurePeerConnection(
    RTCPeerConnection connection,
    NetworkerRtcConnectionInfo info,
  ) {
    connection.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      final channel = _channelOf(info);
      if (channel == null) return;
      final signal = NetworkerRtcSignal.candidate(candidate, channel: channel);
      if (info.signalingReady) {
        addSignal(signal);
      } else {
        info.pendingSignals.add(signal);
      }
    };
    connection.onDataChannel = (dataChannel) {
      final channel = _channelOf(info);
      if (channel == null) return;
      setDataChannel(channel, info, dataChannel);
    };
    connection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        final channel = _channelOf(info);
        if (channel != null) {
          removeConnection(channel);
        }
      }
    };
  }

  Future<void> acceptAnswer(
    Channel channel,
    NetworkerRtcSessionDescription description,
  ) {
    final connection = getConnectionInfo(channel)?.peerConnection;
    if (connection == null) return Future.value();
    return connection.setRemoteDescription(description.toRtc());
  }

  Future<void> addCandidate(
    Channel channel,
    NetworkerRtcIceCandidate candidate,
  ) {
    final connection = getConnectionInfo(channel)?.peerConnection;
    if (connection == null) return Future.value();
    return connection.addCandidate(candidate.toRtc());
  }

  Future<void> handleSignal(NetworkerRtcSignal signal) {
    _signalQueue = _signalQueue.then((_) => _handleSignal(signal));
    return _signalQueue;
  }

  Future<void> _handleSignal(NetworkerRtcSignal signal) async {
    switch (signal.type) {
      case NetworkerRtcSignalType.offer:
        throw UnsupportedError('NetworkerRtcServer does not accept offers.');
      case NetworkerRtcSignalType.answer:
        final description = signal.description;
        if (description == null) return;
        await acceptAnswer(signal.channel, description);
      case NetworkerRtcSignalType.candidate:
        final candidate = signal.candidate;
        if (candidate == null) return;
        await addCandidate(signal.channel, candidate);
    }
  }

  @protected
  @override
  void onClientDisconnected(Channel id, NetworkerRtcConnectionInfo info) {
    unawaited(info.close());
  }

  @protected
  void setDataChannel(
    Channel channel,
    NetworkerRtcConnectionInfo info,
    RTCDataChannel dataChannel,
  ) {
    info.dataChannel = dataChannel;
    info.messageSubscription?.cancel();
    info.stateSubscription?.cancel();
    info.messageSubscription = dataChannel.messageStream.listen(
      (message) => handleData(message, channel),
    );
    info.stateSubscription = dataChannel.stateChangeStream.listen((state) {
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _dataChannelOpen.add(channel);
      }
      if (state == RTCDataChannelState.RTCDataChannelClosed ||
          state == RTCDataChannelState.RTCDataChannelClosing) {
        removeConnection(channel);
      }
    });
    if (dataChannel.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannelOpen.add(channel);
    }
  }

  @protected
  void handleData(RTCDataChannelMessage message, Channel channel) {
    if (message.isBinary) {
      onMessage(message.binary, channel);
    } else {
      onMessage(Uint8List.fromList(message.text.codeUnits), channel);
    }
  }

  @protected
  void addSignal(NetworkerRtcSignal signal) {
    if (!_onSignal.isClosed) {
      _onSignal.add(signal);
    }
  }

  Channel? _channelOf(NetworkerRtcConnectionInfo info) {
    for (final channel in clientConnections) {
      if (getConnectionInfo(channel) == info) {
        return channel;
      }
    }
    return null;
  }

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    final connections = clientConnections
        .map(getConnectionInfo)
        .whereType<NetworkerRtcConnectionInfo>()
        .toList();
    for (final connection in connections) {
      await connection.close();
    }
    await super.close();
    _closed = true;
    if (!_onClosed.isClosed) {
      _onClosed.add(null);
    }
    await _onSignal.close();
    await _dataChannelOpen.close();
    await _onOpen.close();
    await _onClosed.close();
  }
}
