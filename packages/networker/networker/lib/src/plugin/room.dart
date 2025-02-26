import 'package:networker/networker.dart';

final class RoomMessage<T> {
  final Map<String, dynamic> data;

  const RoomMessage(this.data);

  String get room => data['room'];
  T get message => data['message'];
  dynamic getAttribute(String key) => data[key];
}

final class RoomNetworkerPlugin<T> extends SimpleNetworkerPipe {
  final Map<String, SimpleNetworkerPipe<T>> _rooms = {};

  @override
  Future<void> onMessage(data, [Channel channel = kAnyChannel]) async {
    await super.onMessage(data, channel);
    final message = RoomMessage(data);
    await _rooms[message.room]?.onMessage(message.message, channel);
  }

  void addRoom(String room) {
    _rooms[room] ??= SimpleNetworkerPipe<T>();
  }

  void removeRoom(String room) {
    _rooms.remove(room);
  }

  bool hasRoom(String room) => _rooms.containsKey(room);
}
