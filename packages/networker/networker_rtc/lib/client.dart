library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:meta/meta.dart';
import 'package:networker/networker.dart';

import 'config.dart';

export 'config.dart';

class NetworkerRtcClient extends NetworkerClient {
  @override
  final Uri address;
  final NetworkerRtcConfiguration configuration;
  final Map<String, dynamic> constraints;
  final String dataChannelLabel;
  final RTCDataChannelInit Function()? createDataChannelInit;
  final bool offerOnInit;

  RTCPeerConnection? _connection;
  RTCDataChannel? _dataChannel;
  StreamSubscription<RTCDataChannelMessage>? _messageSubscription;
  StreamSubscription<RTCDataChannelState>? _stateSubscription;
  Future<void> _signalQueue = Future.value();
  final List<NetworkerRtcSignal> _pendingSignals = [];
  Channel _signalChannel = kAnyChannel;
  bool _signalingReady = false;
  bool _closed = true;

  final StreamController<void> _onOpen = StreamController<void>.broadcast();
  final StreamController<void> _onClosed = StreamController<void>.broadcast();
  final StreamController<NetworkerRtcSignal> _onSignal =
      StreamController<NetworkerRtcSignal>.broadcast();

  RTCPeerConnection? get connection => _connection;
  RTCDataChannel? get dataChannel => _dataChannel;
  Stream<NetworkerRtcSignal> get onSignal => _onSignal.stream;

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  NetworkerRtcClient(
    this.address, {
    this.configuration = const NetworkerRtcConfiguration(),
    this.constraints = const {},
    this.dataChannelLabel = 'networker',
    this.createDataChannelInit,
    this.offerOnInit = false,
  });

  @override
  Future<void> init() async {
    if (isOpen) return;
    _closed = false;
    _signalingReady = false;
    _pendingSignals.clear();
    final connection = _connection = await createRtcPeerConnection();
    configurePeerConnection(connection);
    if (offerOnInit) {
      await createOffer();
    }
  }

  @protected
  Future<RTCPeerConnection> createRtcPeerConnection() {
    return createPeerConnection(configuration.toMap(), constraints);
  }

  @protected
  void configurePeerConnection(RTCPeerConnection connection) {
    connection.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      final signal = NetworkerRtcSignal.candidate(
        candidate,
        channel: _signalChannel,
      );
      if (_signalingReady) {
        addSignal(signal);
      } else {
        _pendingSignals.add(signal);
      }
    };
    connection.onDataChannel = setDataChannel;
    connection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        markClosed();
      }
    };
  }

  @protected
  Future<RTCDataChannel> createRtcDataChannel() {
    return _connection!.createDataChannel(
      dataChannelLabel,
      createDataChannelInit?.call() ?? RTCDataChannelInit(),
    );
  }

  Future<NetworkerRtcSignal> createOffer() async {
    final connection = _requireConnection();
    setDataChannel(await createRtcDataChannel());
    final offer = await connection.createOffer();
    await connection.setLocalDescription(offer);
    final signal = NetworkerRtcSignal.offer(offer);
    addSignal(signal);
    _signalingReady = true;
    for (final signal in _pendingSignals) {
      addSignal(signal);
    }
    _pendingSignals.clear();
    return signal;
  }

  Future<NetworkerRtcSignal> acceptOffer(
    NetworkerRtcSessionDescription description, {
    Channel channel = kAnyChannel,
  }) async {
    _signalChannel = channel;
    final connection = _requireConnection();
    await connection.setRemoteDescription(description.toRtc());
    final answer = await connection.createAnswer();
    await connection.setLocalDescription(answer);
    final signal = NetworkerRtcSignal.answer(answer, channel: channel);
    addSignal(signal);
    _signalingReady = true;
    for (final signal in _pendingSignals) {
      addSignal(signal);
    }
    _pendingSignals.clear();
    return signal;
  }

  Future<void> acceptAnswer(NetworkerRtcSessionDescription description) {
    return _requireConnection().setRemoteDescription(description.toRtc());
  }

  Future<void> addCandidate(NetworkerRtcIceCandidate candidate) {
    return _requireConnection().addCandidate(candidate.toRtc());
  }

  Future<void> handleSignal(NetworkerRtcSignal signal) {
    _signalQueue = _signalQueue.then((_) => _handleSignal(signal));
    return _signalQueue;
  }

  Future<void> _handleSignal(NetworkerRtcSignal signal) async {
    if (_connection == null) {
      await init();
    }
    switch (signal.type) {
      case NetworkerRtcSignalType.offer:
        final description = signal.description;
        if (description == null) return;
        await acceptOffer(description, channel: signal.channel);
      case NetworkerRtcSignalType.answer:
        final description = signal.description;
        if (description == null) return;
        await acceptAnswer(description);
      case NetworkerRtcSignalType.candidate:
        final candidate = signal.candidate;
        if (candidate == null) return;
        await addCandidate(candidate);
    }
  }

  @protected
  void addSignal(NetworkerRtcSignal signal) {
    if (!_onSignal.isClosed) {
      _onSignal.add(signal);
    }
  }

  @protected
  void setDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    _messageSubscription = channel.messageStream.listen(handleData);
    _stateSubscription = channel.stateChangeStream.listen(handleStateChange);
    if (channel.state == RTCDataChannelState.RTCDataChannelOpen) {
      markOpen();
    }
  }

  @protected
  void handleStateChange(RTCDataChannelState state) {
    switch (state) {
      case RTCDataChannelState.RTCDataChannelOpen:
        markOpen();
      case RTCDataChannelState.RTCDataChannelClosed:
      case RTCDataChannelState.RTCDataChannelClosing:
        markClosed();
      case RTCDataChannelState.RTCDataChannelConnecting:
        break;
    }
  }

  @protected
  void handleData(RTCDataChannelMessage message) {
    if (message.isBinary) {
      onMessage(message.binary);
    } else {
      onMessage(Uint8List.fromList(message.text.codeUnits));
    }
  }

  @protected
  void markOpen() {
    if (!_onOpen.isClosed) {
      _onOpen.add(null);
    }
  }

  @protected
  void markClosed() {
    if (_closed) return;
    _closed = true;
    if (!_onClosed.isClosed) {
      _onClosed.add(null);
    }
  }

  RTCPeerConnection _requireConnection() {
    final connection = _connection;
    if (connection == null) {
      throw StateError('NetworkerRtcClient.init must be called first.');
    }
    return connection;
  }

  @override
  bool get isClosed => _closed;

  @override
  Future<void> close() async {
    await _messageSubscription?.cancel();
    await _stateSubscription?.cancel();
    _messageSubscription = null;
    _stateSubscription = null;
    await _dataChannel?.close();
    await _connection?.close();
    await _connection?.dispose();
    _dataChannel = null;
    _connection = null;
    _signalingReady = false;
    _pendingSignals.clear();
    markClosed();
    await _onSignal.close();
    await _onOpen.close();
    await _onClosed.close();
  }

  @override
  Future<void> sendPacket(
    Uint8List data, [
    Channel channel = kAnyChannel,
  ]) async {
    final dataChannel = _dataChannel;
    if (dataChannel == null) return;
    await dataChannel.send(RTCDataChannelMessage.fromBinary(data));
  }
}
