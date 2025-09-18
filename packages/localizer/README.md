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
