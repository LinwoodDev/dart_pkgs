import 'package:localizer/localizer.dart';
import 'package:test/test.dart';

void main() {
  late Localizer localizer;
  setUp(() {
    localizer = Localizer()
      ..loadMap('en', {'hello': r'Hello %1$s', 'fallback': 'English fallback'})
      ..loadMap('de', {'hello': r'Hallo %1$s'});
  });

  test('contexts select languages independently over a shared catalog', () {
    final english = localizer.context('en');
    final german = localizer.context('de-DE');
    expect(english.get('hello', ['Ada']), 'Hello Ada');
    expect(german.get('hello', ['Ada']), 'Hallo Ada');
    expect(german.get('fallback'), 'English fallback');
    german.locale = 'fr';
    expect(german.get('hello', ['Ada']), 'Hello Ada');
    expect(english.locale, 'en');
    expect(german.getOrDefault('missing', 'Not provided'), 'Not provided');
  });

  test('contexts observe catalog updates without owning the translations', () {
    final context = localizer.context('de');
    localizer.loadMap('de', {'hello': r'Guten Tag %1$s'});
    expect(context.get('hello', ['Ada']), 'Guten Tag Ada');
    context.locale = 'en_US.UTF-8';
    expect(context.get('hello', ['Ada']), 'Hello Ada');
  });

  test('explicit locale normalization lives in Localizer', () {
    expect(Localizer.normalizeLocale('de_DE.UTF-8'), 'de');
    expect(Localizer.normalizeLocale('pt-BR'), 'pt');
    expect(Localizer.normalizeLocale(''), 'en');
  });
}
