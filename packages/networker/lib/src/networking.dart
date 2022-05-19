import 'dart:async';

import 'package:collection/collection.dart';

abstract class NetworkingConnection {
  String get identifier;
  Set<String> get rooms;
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
  FutureOr<bool> joinRoom(String room);
  FutureOr<bool> leaveRoom(String room);
}

abstract class NetworkingServer extends NetworkingConnection {
  NetworkingServer();

  List<NetworkingConnection> get clients;

  NetworkingConnection? getClient(String identifier) =>
      clients.firstWhereOrNull((client) => client.identifier == identifier);

  @override
  Set<String> get rooms => clients.expand((client) => client.rooms).toSet();

  List<NetworkingConnection> getClientsInRoom(String room) =>
      clients.where((client) => client.rooms.contains(room)).toList();

  void broadcastAll(String service, String event, String data) {
    clients
        .where((client) => client.identifier != identifier)
        .forEach((client) => client.send(service, event, data));
  }

  void broadcastRoom(String room, String event, String data) {
    clients
        .where((client) =>
            client.rooms.contains(room) && client.identifier != identifier)
        .forEach((client) => client.send(identifier, event, data));
  }

  void broadcast(String service, String event, String data) {
    clients
        .where((client) => client.identifier != identifier)
        .where(
            (client) => client.rooms.any((element) => rooms.contains(element)))
        .forEach((client) => client.send(identifier, event, data));
  }

  @override
  FutureOr<bool> joinRoom(String room, [List<String>? clients]) async {
    final currentClients = this
        .clients
        .where((client) => clients?.contains(client.identifier) ?? true);
    var success = false;
    for (var client in currentClients) {
      if (await client.joinRoom(room)) {
        success = true;
      }
    }
    return success;
  }

  @override
  FutureOr<bool> leaveRoom(String room, [List<String>? clients]) async {
    final currentClients = this
        .clients
        .where((client) => clients?.contains(client.identifier) ?? true);
    var success = false;
    for (var client in currentClients) {
      if (await client.leaveRoom(room)) {
        success = true;
      }
    }
    return success;
  }
}

abstract class NetworkingClient extends NetworkingConnection {
  NetworkingClient();
  NetworkingConnection get server;
}

abstract class NetworkingClientConnection extends NetworkingConnection {
  final Set<String> _rooms = {};
  @override
  FutureOr<bool> joinRoom(String room) {
    return _rooms.add(room);
  }

  @override
  FutureOr<bool> leaveRoom(String room) {
    return _rooms.remove(room);
  }

  @override
  Set<String> get rooms => Set.unmodifiable(_rooms);
}

class NetworkingMessage {
  final NetworkingConnection connection;
  final String service, event, data;

  NetworkingMessage(this.connection, this.service, this.event, this.data);

  void reply(String data) {
    connection.send(service, event, data);
  }
}

class RoomEvent {
  final List<NetworkingConnection> clients;
  final String roomName;

  const RoomEvent({required this.clients, required this.roomName});
}

class NetworkingService {
  final String name;
  final Map<String, StreamController<NetworkingMessage>> _eventStreams = {};
  final StreamController<RoomEvent> _roomOpenedController = StreamController();
  final StreamController<RoomEvent> _roomClosedController = StreamController();

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

  Stream<RoomEvent> get roomOpenedStream => _roomOpenedController.stream;
  Stream<RoomEvent> get roomClosedStream => _roomClosedController.stream;
}
