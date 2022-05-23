import 'dart:async';

import 'package:collection/collection.dart';

abstract class NetworkingConnection {
  String get identifier;
  Set<String> get rooms;

  final List<NetworkingService> _services = [];
  NetworkingConnection();

  List<NetworkingService> get services => List.unmodifiable(_services);

  FutureOr<void> start();

  FutureOr<void> stop();

  bool isConnected();

  FutureOr<bool> _handleData(NetworkingConnection connection, dynamic data) {
    if (data is! Map) {
      return false;
    }
    final Map dataMap = data;
    if (dataMap['service'] is! String ||
        dataMap['event'] is! String ||
        dataMap['data'] is! String) {
      return false;
    }
    final serviceName = dataMap['service'] as String;
    final event = dataMap['event'] as String;
    final eventData = dataMap['data'] as String;
    final networkingService = getService(serviceName);
    var success = false;
    if (networkingService != null) {
      success = true;
    }
    final message =
        NetworkingMessage(connection, serviceName, event, eventData);
    networkingService?.emitEvent(event, message);
    // Add client event
    final connectionService = connection.getService(serviceName);
    if (networkingService == connectionService) return success;
    if (connectionService != null) {
      success = true;
    }
    connectionService?.emitEvent(event, message);
    return success;
  }

  void registerService(NetworkingService service) {
    _services.add(service);
  }

  void unregisterService(String serviceName) {
    _services.removeWhere((service) => service.name == serviceName);
  }

  NetworkingService? getService(String serviceName) =>
      _services.firstWhereOrNull((service) => service.name == serviceName);

  FutureOr<void> send(String service, String event, String data);
  FutureOr<void> joinRoom(String room);
  FutureOr<void> leaveRoom(String room);
}

abstract class NetworkingServer extends NetworkingConnection {
  NetworkingServer();

  List<NetworkingClientConnection> get clients;

  NetworkingClientConnection? getClient(String identifier) =>
      clients.firstWhereOrNull((client) => client.identifier == identifier);

  @override
  Set<String> get rooms => clients.expand((client) => client.rooms).toSet();

  List<NetworkingClientConnection> getClientsInRoom(String room) =>
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
    final newRoom = !rooms.contains(room);
    var success = false;
    for (var client in currentClients) {
      if (await client.joinRoom(room)) {
        success = true;
      }
    }
    if (newRoom) {
      for (var element in services) {
        element._roomOpenedController.add(room);
      }
    }
    return success;
  }

  FutureOr<bool> handleData(String client, dynamic data) {
    final connection = getClient(client);
    if (connection == null) {
      return false;
    }
    return _handleData(connection, data);
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
    if (getClientsInRoom(room).isEmpty) {
      for (var element in services) {
        element._roomClosedController.add(room);
      }
    }
    return success;
  }
}

abstract class NetworkingIdentity extends NetworkingConnection {
  @override
  final Set<String> rooms = {};

  bool addRoom(String room) {
    final success = rooms.add(room);
    if (!success) return false;
    for (var element in services) {
      element._roomOpenedController.add(room);
    }
    return true;
  }

  bool removeRoom(String room) {
    final success = rooms.remove(room);
    if (!success) return false;
    for (var element in services) {
      element._roomClosedController.add(room);
    }
    return true;
  }

  FutureOr<bool> handle(dynamic data) => _handleData(this, data);
}

abstract class NetworkingClient extends NetworkingIdentity {
  NetworkingClient({bool registerRoomService = true}) {
    if (registerRoomService) _registerRoomService();
  }

  void _registerRoomService() {
    final roomService = NetworkingService('room');
    roomService.registerEvent('joined').listen((event) {
      addRoom(event.data);
    });
    roomService.registerEvent('left').listen((event) {
      removeRoom(event.data);
    });
  }

  @override
  FutureOr<void> joinRoom(String room) => send('room', 'join', room);

  @override
  FutureOr<void> leaveRoom(String room) => send('room', 'leave', room);
}

abstract class NetworkingClientConnection extends NetworkingIdentity {
  final Set<String> _rooms = {};
  final NetworkingServer server;

  NetworkingClientConnection(this.server, {bool registerRoomService = true}) {
    if (registerRoomService) _registerRoomService();
  }

  void _registerRoomService() {
    final roomService = NetworkingService('room');
    roomService.registerEvent('join').listen((event) {
      addRoom(event.data);
    });
    roomService.registerEvent('leave').listen((event) {
      removeRoom(event.data);
    });
  }

  @override
  FutureOr<bool> joinRoom(String room) async {
    final success = addRoom(room);
    if (success) {
      await send('room', 'joined', room);
    }
    return success;
  }

  @override
  FutureOr<bool> leaveRoom(String room) async {
    final success = removeRoom(room);
    if (success) {
      await send('room', 'left', room);
    }
    return success;
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

class NetworkingService {
  final String name;
  final Map<String, StreamController<NetworkingMessage>> _eventStreams = {};
  final StreamController<String> _roomOpenedController = StreamController();
  final StreamController<String> _roomClosedController = StreamController();

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

  bool emitEvent(String eventName, NetworkingMessage message) {
    if (_eventStreams.containsKey(eventName)) {
      _eventStreams[eventName]!.add(message);
      return true;
    }
    return false;
  }

  Stream<String> get roomOpenedStream => _roomOpenedController.stream;
  Stream<String> get roomClosedStream => _roomClosedController.stream;
}
