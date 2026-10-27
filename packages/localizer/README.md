# Localizer

Simple to use dart package to localize your app.

## Features

* 🚀 Written in pure dart
* ⚡ Load data from files (json and yaml), directories or maps
* ❤️ Simple, powerful, & intuitive API

## Getting started

Add the package to your project using a git dependency.

## Usage

Create a new localizer instance, add your localization to it and get them.

```dart
var localizer = Localizer();
localizer.loadMap("en", {"hello-world": "Hello world!"});
localizer.loadMap("es", {"hello-world": "Hola mundo!"});
localizer.loadMap("fr", {"hello-world": "Bonjour le monde!"});
localizer.loadMap("de", {"hello-world": "Hallo Welt!"});

print("EN: ${localizer.get("en", "hello-world")}");
print("ES: ${localizer.get("es", "hello-world")}");
print("FR: ${localizer.get("fr", "hello-world")}");
print("DE: ${localizer.get("de", "hello-world")}");
```


## Locale-bound contexts

A context selects a language over a shared catalog. Locale normalization,
English fallback and printf formatting stay in Localizer:

```dart
final catalog = Localizer()
  ..loadMap('en', {'hello': r'Hello %1$s'})
  ..loadMap('de', {'hello': r'Hallo %1$s'});
final messages = catalog.context('de-DE');
print(messages.get('hello', ['Ada'])); // Hallo Ada
messages.locale = 'en';
```

Contexts select languages independently and use the locale supplied by the
application, defaulting to English. Regional/encoding suffixes are reduced to the
language code. No process environment is inspected. `getOrDefault` accepts a
fallback for application-owned keys.

## Crowdin resources bundled into executables

Maintain flat string catalogs in `l10n/en.json`, `l10n/de.json`, etc. Numbered
printf placeholders allow translated sentences to reorder arguments:

```json
{"hello": "Hello %1$s"}
```

Generate a Dart resource factory with:

```sh
dart run localizer:generate --source l10n --output lib/src/generated/messages.g.dart --name createAppLocalizer
```

Import that generated file and call `createAppLocalizer().context('en')`.
All locale data is embedded in the generated Dart library. Compiled exports need
no JSON files and perform no translation-file reads at runtime. Add `--check`
to verify that committed generated resources match their source. The generator
validates keys and numbered placeholders and writes temporary formatting files
outside the repository.

Example Crowdin mapping:

```yaml
files:
  - source: /l10n/en.json
    translation: /l10n/%two_letters_code%.json
```

Application UI adapters belong to the consuming application. Localizer has no
dependency on Consoler, Flutter, or any specific UI framework.
