# Flutter Localizer

![Pub Version](https://img.shields.io/pub/v/localizer?style=for-the-badge)

Flutter port of [localizer](https://github.com/LinwoodDev/dart_pkgs/tree/main/packages/localizer).
Simple to use dart package to localize your app.

## Features

* 🚀 Written in pure dart
* ⚡ Load data from files (json and yaml), directories or maps
* ❤️ Simple, powerful, & intuitive API

## Getting started

Add the package to your project.

* Use `flutter pub add <package>` or `dart pub add <package>` to add this package to your project
* Add the package manually to your project
  
  ```yaml
    dependencies:
        flutter_localizer: latest
  ```

  Replace latest with the latest version

## Usage

Create a new localizer instance, add your localization to it and get them.

```dart
// Uses file l10n/en.json as default
var localizer = Localizer.fromAsset();

print("EN: ${localizer.get("en", "hello-world")}");
print("ES: ${localizer.get("es", "hello-world")}");
print("FR: ${localizer.get("fr", "hello-world")}");
print("DE: ${localizer.get("de", "hello-world")}");
```
