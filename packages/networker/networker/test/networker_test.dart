import 'package:networker/networker.dart';
import 'package:test/test.dart';

const secondPluginPrefix = 'secondPlugin';

(
  SimpleNetworkerPipe,
  SimpleNetworkerPipe,
  NetworkerPipeTransformer<String, String>
) _buildTestMessenger() {
  final messenger = SimpleNetworkerPipe();
  final plugin = SimpleNetworkerPipe();
  final secondTranslator = NetworkerPipeTransformer<String, String>((data) {
    return secondPluginPrefix + data;
  }, (data) {
    if (data.startsWith(secondPluginPrefix)) {
      return data.substring(secondPluginPrefix.length);
    }
    return data;
  });
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
    messenger.write.listen(expectAsync1((data) {
      expect(data.data, 'test');
    }));
    plugin.sendMessage('test');
  });
  test('onMessage calls plugin reader', () {
    final (messenger, plugin, _) = _buildTestMessenger();
    plugin.read.listen(expectAsync1((data) {
      expect(data.data, 'test');
    }));
    messenger.onMessage('test');
  });
  test('plugin calls nested reader', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    secondPlugin.read.listen(expectAsync1((data) {
      expect(data.data, '${secondPluginPrefix}test');
    }));
    messenger.onMessage('test');
  });
  test('plugin calls nested sendMessage', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    messenger.write.listen(expectAsync1((data) {
      expect(data.data, 'test');
    }));
    secondPlugin.sendMessage('${secondPluginPrefix}test');
  });
}

class ClientEvents {
  ClientEvents.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};
}
