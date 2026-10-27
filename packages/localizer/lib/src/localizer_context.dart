import 'localizer_base.dart';

/// A locale-bound view over a catalog. Multiple contexts may share translations
/// while selecting their language independently.
class LocalizerContext {
  final Localizer localizer;
  String _locale;

  LocalizerContext(this.localizer, {String locale = 'en'})
    : _locale = Localizer.normalizeLocale(locale);

  String get locale => _locale;
  set locale(String value) => _locale = Localizer.normalizeLocale(value);

  String get(String key, [List<Object?> arguments = const []]) =>
      localizer.get(locale, key, arguments);

  String getOrDefault(
    String key,
    String fallback, [
    List<Object?> arguments = const [],
  ]) => localizer.getOrDefault(locale, key, fallback, arguments);
}
