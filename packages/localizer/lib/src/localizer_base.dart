import 'dart:convert';
import 'dart:io';

import 'package:localizer/src/localizer_locale.dart';
import 'package:yaml/yaml.dart' as yaml;

/// Localizer allows you to manage your application's localizations.
/// Add new localizations using the load methods.
/// Get locales using the [getLocales] method.
/// Get translations directly with the [get] method.
class Localizer {
  final String defaultLocale;
  final List<LocalizerLocale> _locales = [];

  /// Create a new Localizer instance.
  /// [defaultLocale] is the default locale to use when a specific locale has not been found.
  Localizer([this.defaultLocale = 'en']);

  /// Get all supported locales that you can get using the [getLocale] method.
  Iterable<String> get supportedLocales =>
      _locales.map((locale) => locale.name).toList();

  /// Get the default locale specified by [defaultLocale].
  ///
  /// Throws a [StateError] if [defaultLocale] is not supported.
  LocalizerLocale getDefaultLocale() => getLocale(defaultLocale);

  /// Get the locale object for the given locale.
  ///
  /// Throws a [StateError] if the locale is not supported.
  LocalizerLocale getLocale(String name) {
    return _locales.firstWhere((locale) => locale.name == name);
  }

  /// Get the locale object for the given locale.
  /// If the locale is not supported, it returns null.
  LocalizerLocale? getLocaleOrNull(String name) {
    return List<LocalizerLocale?>.from(_locales)
        .firstWhere((locale) => locale?.name == name, orElse: () => null);
  }

  /// Load locales from a specific directory.
  /// All files in the directory will be loaded.
  /// Read more at [loadFile].
  Future<void> loadDirectory(String path) async {
    final dir = Directory(path);
    final files = await dir.list().toList();
    for (final file in files) {
      if (file is File) {
        await loadFile(file.path);
      }
    }
  }

  /// Load locale from a specific file.
  /// The file must be a valid YAML or JSON file.
  /// The name of the file will be used as the locale name if [locale] is null. For example, if the file is named `en.yaml`, the locale name will be `en`.
  /// If a locale with the same name already exists, it will be overwritten.
  Future<void> loadFile(String path, {String? locale}) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File $path does not exist');
    }
    final content = await file.readAsString();
    final name = file.path.split('/').last.split('.').first;
    loadYaml(name, content);
  }

  /// Load locale [locale] from a specific string.
  /// The string must be a valid YAML string.
  /// If a locale with the same name already exists, it will be overwritten.
  void loadYaml(String locale, String data) {
    final yamlData = yaml.loadYaml(data);
    final localeData = <String, String>{};
    void load(String prefix, dynamic value) {
      if (value is String) {
        localeData[prefix] = value;
      } else if (value is yaml.YamlMap) {
        value.forEach((key, value) {
          load('$prefix.$key', value);
        });
      } else if (value is yaml.YamlList) {
        value.asMap().forEach((index, value) {
          load('$prefix.$index', value);
        });
      }
    }

    load('', yamlData);

    return _loadLocale(LocalizerLocale(locale, localeData));
  }

  /// Load locale [locale] from a specific string.
  /// The string must be a valid JSON string.
  /// If a locale with the same name already exists, it will be overwritten.
  void loadJson(String locale, String data) {
    loadMap(locale, Map<String, dynamic>.from(jsonDecode(data)));
  }

  /// Load locale [locale] from a specific map.
  /// If a locale with the same name already exists, it will be overwritten.
  /// The map must be a valid JSON map.
  void loadMap(String locale, Map<String, dynamic> map) {
    final localeData = <String, String>{};
    void load(String prefix, dynamic value) {
      if (value is String) {
        localeData[prefix] = value;
      } else if (value is Map) {
        value.forEach((key, value) {
          var current = key;
          if (prefix != '') current = '$prefix.$current';
          load(current, value);
        });
      } else if (value is Iterable) {
        value.toList().asMap().forEach((index, value) {
          var current = index.toString();
          if (prefix != '') current = '$prefix.$current';
          load('$prefix.$index', value);
        });
      }
    }

    load('', map);

    _loadLocale(LocalizerLocale(locale, localeData));
  }

  void _loadLocale(LocalizerLocale locale) {
    removeLocale(locale.name);
    _locales.add(locale);
    locale;
  }

  /// Test if a locale is supported.
  bool hasLocale(String name) {
    return _locales.any((locale) => locale.name == name);
  }

  /// Remove a locale.
  void removeLocale(String name) {
    _locales.removeWhere((locale) => locale.name == name);
  }

  // Remove all locales.
  void clear() {
    _locales.clear();
  }

  /// Get the translation for the given key.
  /// If the key is not found, it returns the key.
  /// Read more at [LocalizerLocale.get].
  String get(String locale, String key, [List args = const []]) =>
      getOrDefault(locale, key, key, args);

  /// Get the translation for the given key.
  /// If the key is not found, it returns the message in the [defaultLocale] locale. If the key is not found in the [defaultLocale] locale, it returns the key.
  /// Read more at [LocalizerLocale.getOrDefault].
  String getOrDefault(String locale, String key, String defaultValue,
      [List args = const []]) {
    final localeData = getLocaleOrNull(locale) ?? getDefaultLocale();
    return localeData.contains(key)
        ? localeData.get(key, args)
        : getDefaultLocale().getOrDefault(key, defaultValue, args);
  }
}
