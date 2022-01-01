# Localizer

![Pub Version](https://img.shields.io/pub/v/localizer?style=for-the-badge)

A plugin to localize your dart project.

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
        localizer: latest
  ```

  Replace latest with the latest version

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
