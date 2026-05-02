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
}

class ClientEvents {
  ClientEvents.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};
}
