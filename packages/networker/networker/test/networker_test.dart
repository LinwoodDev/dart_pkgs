import 'package:networker/networker.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

const secondPluginPrefix = 'secondPlugin';

(
  SimpleNetworkerPipe,
  SimpleNetworkerPipe,
  NetworkerPipeTransformer<String, String>,
)
_buildTestMessenger() {
  final messenger = SimpleNetworkerPipe();
  final plugin = SimpleNetworkerPipe();
  final secondTranslator = NetworkerPipeTransformer<String, String>(
    (data) {
      return secondPluginPrefix + data;
    },
    (data) {
      if (data.startsWith(secondPluginPrefix)) {
        return data.substring(secondPluginPrefix.length);
      }
      return data;
    },
  );
  final simple = NetworkerPipeTransformer<Map<String, dynamic>, ClientEvents>(
    ClientEvents.fromJson,
    (data) => data.toJson(),
  );
  final json = JsonNetworkerPlugin();
  json.connect(simple);
  plugin.connect(json);
  messenger.connect(plugin);
  plugin.connect(secondTranslator);
  return (messenger, plugin, secondTranslator);
}

void main() {
  test('plugin calls global sendMessage', () {
    final (messenger, plugin, _) = _buildTestMessenger();
    messenger.write.listen(
      expectAsync1((data) {
        expect(data.data, 'test');
      }),
    );
    plugin.sendMessage('test');
  });
  test('onMessage calls plugin reader', () {
    final (messenger, plugin, _) = _buildTestMessenger();
    plugin.read.listen(
      expectAsync1((data) {
        expect(data.data, 'test');
      }),
    );
    messenger.onMessage('test');
  });
  test('plugin calls nested reader', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    secondPlugin.read.listen(
      expectAsync1((data) {
        expect(data.data, '${secondPluginPrefix}test');
      }),
    );
    messenger.onMessage('test');
  });
  test('plugin calls nested sendMessage', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    messenger.write.listen(
      expectAsync1((data) {
        expect(data.data, 'test');
      }),
    );
    secondPlugin.sendMessage('${secondPluginPrefix}test');
  });

  test('reconnecting the same plugin does not duplicate messages', () async {
    final messenger = SimpleNetworkerPipe<String>();
    final plugin = SimpleNetworkerPipe<String>();
    final messages = <String>[];
    messenger.write.listen((data) => messages.add(data.data));

    messenger.connect(plugin);
    messenger.connect(plugin);
    plugin.sendMessage('test');

    await pumpEventQueue();
    expect(messages, ['test']);
  });

  test('rpc packets reject truncated headers', () {
    expect(
      () => RpcNetworkerPacket.fromBytes(
        const RpcConfig(channelField: true),
        Uint8List.fromList([1]),
      ),
      throwsFormatException,
    );
  });

  test('rpc packets reject values that do not fit the configured header', () {
    expect(
      () => RpcNetworkerPacket(
        function: 256,
        data: Uint8List(0),
      ).toBytes(const RpcConfig(extendedFunctionIdentifiers: false)),
      throwsRangeError,
    );
    expect(
      () => RpcNetworkerPacket(
        function: 1,
        channel: 0x10000,
        data: Uint8List(0),
      ).toBytes(const RpcConfig(channelField: true)),
      throwsRangeError,
    );
  });

  test('closing a server closes and removes every client connection', () async {
    final server = _TestServer();
    final first = _TestConnectionInfo();
    final second = _TestConnectionInfo();
    server.addTestConnection(first);
    server.addTestConnection(second);

    final close = server.close();
    expect(identical(close, server.close()), isTrue);
    await close;

    expect(first.closeCount, 1);
    expect(second.closeCount, 1);
    expect(server.clientConnections, isEmpty);
  });

  test('removing a connection closes it', () async {
    final server = _TestServer();
    final connection = _TestConnectionInfo();
    final channel = server.addTestConnection(connection);

    expect(await server.removeTestConnection(channel), isTrue);

    expect(connection.closeCount, 1);
    expect(server.clientConnections, isEmpty);
    await server.close();
  });
}

final class _TestConnectionInfo implements ConnectionInfo {
  bool _closed = false;
  int closeCount = 0;

  @override
  Uri get address => Uri.parse('test://client');

  @override
  Future<void> close() async {
    closeCount++;
    _closed = true;
  }

  @override
  bool get isClosed => _closed;

  @override
  bool get isOpen => !_closed;

  @override
  Future<void> sendMessage(Uint8List data) async {}
}

final class _TestServer extends NetworkerServer<_TestConnectionInfo> {
  final _open = Stream<void>.empty();
  final _closed = Stream<void>.empty();
  bool _initialized = false;

  Channel addTestConnection(_TestConnectionInfo info) =>
      addClientConnection(info);

  Future<bool> removeTestConnection(Channel channel) =>
      removeConnection(channel);

  @override
  Uri get address => Uri.parse('test://server');

  @override
  Future<void> init() async {
    _initialized = true;
  }

  @override
  bool get isClosed => !_initialized;

  @override
  Stream<void> get onClosed => _closed;

  @override
  Stream<void> get onOpen => _open;
}

class ClientEvents {
  ClientEvents.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};
}
