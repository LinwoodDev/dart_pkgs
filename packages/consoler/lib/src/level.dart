import 'dart:io';

enum LogLevel {
  verbose(35),
  info(36),
  warning(33),
  error(31);

  final int colorCode;

  const LogLevel(this.colorCode);

  void toConsole([bool withColor = true, bool withSpace = true]) {
    if (withColor) {
      stdout.write('\x1B[${colorCode}m');
    }
    stdout.write('[');
    stdout.write(name.toUpperCase());
    stdout.write(']');
    if (withColor) {
      stdout.write('\x1B[0m');
    }
    if (withSpace) {
      stdout.write(' ');
    }
  }
}
