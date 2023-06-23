import 'package:networker/networker.dart';
import 'package:test/test.dart';

void main() {
  final messenger = NetworkerMessenger();
  final plugin = NetworkerMessenger();
  messenger.addPlugin(plugin);
  test('plugin calls global sendMessage', () {
    messenger.write.listen(expectAsync1((data) {
      expect(data, 'test');
    }));
    plugin.sendMessage('test');
  });
  test('onMessage calls plugin reader', () {
    plugin.read.listen(expectAsync1((data) {
      expect(data, 'test');
    }));
    messenger.onMessage('test');
  });
}
