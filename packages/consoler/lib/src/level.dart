import 'dart:io';
import 'color.dart';

enum LogLevel {
  verbose(35),
  info(36),
  warning(33),
  error(31);

  final int colorCode;
  const LogLevel(this.colorCode);

  String format({bool color = false}) => ConsoleColors(enabled: color).paint(
    '[${name.toUpperCase()}]',
    foreground: switch (this) {
      LogLevel.verbose => ConsoleColor.magenta,
      LogLevel.info => ConsoleColor.cyan,
      LogLevel.warning => ConsoleColor.yellow,
      LogLevel.error => ConsoleColor.red,
    },
  );

  /// Compatibility helper. New code should use Consoler's output methods.
  void toConsole([bool withColor = true, bool withSpace = true]) =>
      stdout.write('${format(color: withColor)}${withSpace ? ' ' : ''}');
}
