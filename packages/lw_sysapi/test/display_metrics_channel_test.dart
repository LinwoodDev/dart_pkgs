import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lw_sysapi/lw_sysapi.dart';
import 'package:lw_sysapi/src/native/display_metrics_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('linwood.dev/lw_sysapi');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'public API reads physical density and native display metadata',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'getDisplayMetrics');
        return {
          'dpiX': 127.7,
          'dpiY': 128,
          'displayId': 'display-2',
          'name': 'External display',
        };
      });

      final metrics = await SysAPI.getDisplayMetrics();
      expect(metrics, isNotNull);
      expect(metrics!.dpiX, 127.7);
      expect(metrics.dpiY, 128.0);
      expect(metrics.displayId, 'display-2');
      expect(metrics.name, 'External display');
    },
  );

  test('queries the platform again after a monitor change', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return {'dpiX': calls == 1 ? 144 : 220, 'dpiY': calls == 1 ? 144 : 220};
    });
    expect((await getNativeDisplayMetrics())!.dpiX, 144);
    expect((await getNativeDisplayMetrics())!.dpiX, 220);
  });

  test('returns null when the platform has no physical metrics', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await getNativeDisplayMetrics(), isNull);
  });

  test('returns null for unavailable plugins and native errors', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw MissingPluginException();
    });
    expect(await getNativeDisplayMetrics(), isNull);

    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await getNativeDisplayMetrics(), isNull);
  });

  test('rejects missing, nonnumeric, and invalid physical densities', () async {
    for (final value in [null, '144', 0, -1, double.nan, double.infinity]) {
      for (final axis in ['dpiX', 'dpiY']) {
        messenger.setMockMethodCallHandler(channel, (_) async {
          return {'dpiX': 144, 'dpiY': 144, axis: value};
        });
        expect(await getNativeDisplayMetrics(), isNull);
      }
    }
  });
}
