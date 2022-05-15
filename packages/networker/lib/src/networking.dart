import 'dart:async';

import 'package:collection/collection.dart';

abstract class NetworkingConnection {
  NetworkingConnection();


  final List<NetworkingService> _services = [];

  List<NetworkingService> get services => List.unmodifiable(_services);

  FutureOr<void> start();

  FutureOr<void> stop();

  bool isConnected();

  void registerService(NetworkingService service) {
    _services.add(service);
  }

  void unregisterService(String serviceName) {
    _services.removeWhere((service) => service.name == serviceName);
  }

  NetworkingService? getService(String serviceName) =>
      _services.firstWhereOrNull((service) => service.name == serviceName);

  FutureOr<void> send(String service, String event, String data);
}

abstract class NetworkingServer extends NetworkingConnection {
  NetworkingServer();
  List<NetworkingConnection> get clients;
}

abstract class NetworkingClient extends NetworkingConnection {
  NetworkingClient();
  NetworkingConnection get server;
}

class NetworkingMessage {
  final NetworkingConnection connection;
  final String service, event, data;

  NetworkingMessage(this.connection, this.service, this.event, this.data);

  void reply(String data) {
    connection.send(service, event, data);
  }
}

class NetworkingService {
  final String name;
  final Map<String, StreamController<NetworkingMessage>> _eventStreams = {};

  NetworkingService(this.name);

  Stream? getEvent(String eventName) {
    return _eventStreams[eventName]?.stream;
  }

  Stream<NetworkingMessage> registerEvent(String eventName) {
    if (_eventStreams.containsKey(eventName)) {
      return _eventStreams[eventName]!.stream;
    }
    final stream = StreamController<NetworkingMessage>();
    _eventStreams[eventName] = stream;
    return stream.stream;
  }

  bool hasEvent(String eventName) {
    return _eventStreams.containsKey(eventName);
  }

  void unregisterEvent(String eventName) {
    _eventStreams.remove(eventName);
  }

  void emitEvent(String eventName, NetworkingMessage message) {
    _eventStreams[eventName]?.add(message);
  }
}
