import 'json.dart';
import 'plugin.dart';

final class RoomMessage<T> {
  final Map<String, dynamic> data;

  const RoomMessage(this.data);

  String get room => data['room'];
  T get message => data['message'];
  dynamic getAttribute(String key) => data[key];
}

final class RoomNetworkerPlugin<T> extends NetworkerMessenger {
  final Map<String, NetworkerMessenger<T>> _rooms = {};
  @override
  void onMessage(data) {
    super.onMessage(data);
    final message = RoomMessage(data);
    _rooms[message.room]?.onMessage(message.message);
  }

  void addRoom(String room) {
    _rooms[room] ??= NetworkerMessenger<T>();
  }

  void removeRoom(String room) {
    _rooms.remove(room);
  }

  bool hasRoom(String room) => _rooms.containsKey(room);
}
