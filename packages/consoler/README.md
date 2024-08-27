# Consoler

> Console interface for Dart

## Features

- ⌨️ Command line arguments
- 🎨 Custom program configuration
- 💬 Prefix for input
- 🏠 Built in help and unknown program
- ⚙️ Configurable log levels
- 🌈 Colorful output

## Usage

```dart
import 'package:consoler/consoler.dart';

void main() {
  final consoler = Consoler(
    defaultConfig: DefaultProgramConfiguration(
      description: "Quoka server",
    ),
  );
  consoler.registerProgram("echo", EchoProgram(consoler));
  consoler.run();
}

final class EchoProgram extends ConsoleProgram {
  EchoProgram(Consoler consoler) : super(consoler);

  @override
  void run(List<String> args) {
    print(args.join(" "));
  }
}
```