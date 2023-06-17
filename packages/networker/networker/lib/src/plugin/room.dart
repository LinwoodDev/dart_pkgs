import 'package:networker/src/connection.dart';

import 'plugin.dart';

class RoomNetworkerPlugin<T> extends NetworkerMessenger {
  final Map<String, NetworkerMessenger<T>> _rooms = {};
  @override
  void onMessage(ConnectionId id, data) {
    super.onMessage(id, data);
    final room = data['room'] as String?;
    final roomData = data['data'] as T;
    _rooms[room]?.onMessage(id, roomData);
  }

  void addRoom(String room) {
    _rooms[room] ??= NetworkerMessenger<T>();
  }

  void removeRoom(String room) {
    _rooms.remove(room);
  }

  bool hasRoom(String room) => _rooms.containsKey(room);
}
