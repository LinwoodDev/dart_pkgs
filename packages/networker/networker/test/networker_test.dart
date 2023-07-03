import 'package:networker/networker.dart';
import 'package:test/test.dart';

const secondPluginPrefix = 'secondPlugin';

(NetworkerMessenger, NetworkerMessenger, SimpleNetworkerPlugin<String, String>)
    _buildTestMessenger() {
  final messenger = NetworkerMessenger();
  final plugin = NetworkerMessenger();
  final secondTranslator = SimpleNetworkerPlugin<String, String>((data) {
    return secondPluginPrefix + data;
  }, (data) {
    if (data.startsWith(secondPluginPrefix)) {
      return data.substring(secondPluginPrefix.length);
    }
    return data;
  });
  final simple = SimpleNetworkerPlugin<Map<String, dynamic>, ClientEvents>(
    ClientEvents.fromJson,
    (data) => data.toJson(),
  );
  final json = JsonNetworkerPlugin();
  json.addPlugin(simple);
  plugin.addPlugin(json);
  messenger.addPlugin(plugin);
  plugin.addPlugin(secondTranslator);
  return (messenger, plugin, secondTranslator);
}

void main() {
  test('plugin calls global sendMessage', () {
    final (messenger, plugin, _) = _buildTestMessenger();
    messenger.write.listen(expectAsync1((data) {
      expect(data, 'test');
    }));
    plugin.sendMessage('test');
  });
  test('onMessage calls plugin reader', () {
    final (messenger, plugin, _) = _buildTestMessenger();
    plugin.read.listen(expectAsync1((data) {
      expect(data, 'test');
    }));
    messenger.onMessage('test');
  });
  test('plugin calls nested reader', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    secondPlugin.read.listen(expectAsync1((data) {
      expect(data, '${secondPluginPrefix}test');
    }));
    messenger.onMessage('test');
  });
  test('plugin calls nested sendMessage', () {
    final (messenger, _, secondPlugin) = _buildTestMessenger();
    messenger.write.listen(expectAsync1((data) {
      expect(data, 'test');
    }));
    secondPlugin.sendMessage('${secondPluginPrefix}test');
  });
}

class ClientEvents {
  ClientEvents.fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson() => {};
}
