library;

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:networker/networker.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'src/web_socket.dart';

export 'src/web_socket.dart';

class NetworkerSocketClient extends NetworkerClient {
  static List<String> supportedSchemes = List.unmodifiable(['ws', 'wss']);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  bool _isOpen = false;
  bool _isDisposed = false;
  bool _closedNotified = false;
  Future<void>? _initFuture;
  Future<void>? _closeFuture;

  @override
  final Uri address;
  final Iterable<String>? protocols;
  final Duration? pingInterval;

  WebSocketChannel? get channel => _channel;

  final StreamController<void> _onOpen = StreamController<void>.broadcast(),
      _onClosed = StreamController<void>.broadcast();

  @override
  Stream<void> get onClosed => _onClosed.stream;

  @override
  Stream<void> get onOpen => _onOpen.stream;

  NetworkerSocketClient(this.address, {this.protocols, this.pingInterval});

  @override
  Future<void> init() {
    if (_isDisposed) {
      return Future.error(
        StateError('A closed NetworkerSocketClient cannot be reused.'),
      );
    }
    if (isOpen) {
      return Future.value();
    }
    return _initFuture ??= _init().whenComplete(() => _initFuture = null);
  }

  Future<void> _init() async {
    await _subscription?.cancel();
    _closedNotified = false;
    final channel = _channel = createWebSocketChannel();
    _subscription = channel.stream.listen(
      (event) {
        handleData(event);
      },
      onDone: () {
        _notifyClosed();
      },
      onError: (error) {
        _notifyClosed(error);
      },
      cancelOnError: false,
    );
    try {
      await channel.ready;
      _isOpen = true;
      _onOpen.add(null);
    } catch (error, stackTrace) {
      _notifyClosed(error, stackTrace);
      rethrow;
    }
  }

  void _notifyClosed([Object? error, StackTrace? stackTrace]) {
    _isOpen = false;
    if (_closedNotified || _onClosed.isClosed) return;
    _closedNotified = true;
    if (error != null) {
      _onClosed.addError(error, stackTrace);
    } else {
      _onClosed.add(null);
    }
  }

  /// Creates the [WebSocketChannel] used for the connection.
  ///
  /// Override this method to customize channel creation, such as
  /// providing custom headers or a different WebSocket implementation.
  @protected
  WebSocketChannel createWebSocketChannel() {
    return constructWebSocketChannel(
      address,
      protocols: protocols,
      pingInterval: pingInterval,
    );
  }

  /// Processes incoming data from the server.
  ///
  /// Override this method to add custom message processing, logging,
  /// or filtering before the standard [onMessage] pipeline.
  @protected
  void handleData(dynamic event) {
    if (event is String) {
      onMessage(Uint8List.fromList(event.codeUnits));
    } else if (event is Uint8List) {
      onMessage(event);
    } else if (event is List<int>) {
      onMessage(Uint8List.fromList(event));
    }
  }

  @override
  Future<void> close() => _closeFuture ??= _close();

  Future<void> _close() async {
    _isDisposed = true;
    final channel = _channel;
    _channel = null;
    try {
      await channel?.sink.close();
      _notifyClosed();
    } finally {
      await _subscription?.cancel();
      _subscription = null;
      await _onOpen.close();
      await _onClosed.close();
    }
  }

  @override
  bool get isClosed => !_isOpen;

  int? get closeCode => _channel?.closeCode;
  String? get closeReason => _channel?.closeReason;

  @override
  void sendPacket(Uint8List data, [Channel channel = kAnyChannel]) =>
      _channel?.sink.add(data);
}
