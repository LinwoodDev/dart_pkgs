import 'dart:io';
import 'dart:typed_data';

import 'package:networker/networker.dart';
import 'package:networker_socket/client.dart';
import 'package:networker_socket/server.dart';
import 'package:test/test.dart';

void main() {
  test('fromHttpServer accepts websocket clients after init', () async {
    final httpServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final server = NetworkerSocketServer.fromHttpServer(httpServer);
    final client = NetworkerSocketClient(server.address);

    addTearDown(client.close);
    addTearDown(server.close);
    addTearDown(() => httpServer.close(force: true));

    await server.init();
    final connected = expectLater(server.clientConnect, emits(anything));
    final initializing = client.init();
    expect(identical(initializing, client.init()), isTrue);
    await initializing;
    await connected;

    final message = expectLater(
      server.read,
      emits(
        isA<NetworkerPacket<Uint8List>>().having(
          (packet) => packet.data,
          'data',
          [1, 2, 3],
        ),
      ),
    );

    await client.sendMessage(Uint8List.fromList([1, 2, 3]));
    await message;

    final response = expectLater(
      client.read,
      emits(
        isA<NetworkerPacket<Uint8List>>().having(
          (packet) => packet.data,
          'data',
          [4, 5, 6],
        ),
      ),
    );

    await server.sendMessage(
      Uint8List.fromList([4, 5, 6]),
      server.clientConnections.single,
    );
    await response;
  });

  test('closing a server disconnects its websocket clients', () async {
    final server = NetworkerSocketServer(InternetAddress.loopbackIPv4, 0);
    await server.init();
    final client = NetworkerSocketClient(server.address);

    addTearDown(client.close);
    addTearDown(server.close);

    final connected = expectLater(server.clientConnect, emits(anything));
    await client.init();
    await connected;
    final disconnected = expectLater(client.onClosed, emits(null));

    await server.close();

    await disconnected;
    expect(client.isClosed, isTrue);
    expect(server.clientConnections, isEmpty);
  });
}
