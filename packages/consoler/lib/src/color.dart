/// Standard and bright ANSI terminal colors.
enum ConsoleColor {
  black(30),
  red(31),
  green(32),
  yellow(33),
  blue(34),
  magenta(35),
  cyan(36),
  white(37),
  defaultColor(39),
  brightBlack(90),
  brightRed(91),
  brightGreen(92),
  brightYellow(93),
  brightBlue(94),
  brightMagenta(95),
  brightCyan(96),
  brightWhite(97);

  final int foregroundCode;
  const ConsoleColor(this.foregroundCode);
  int get backgroundCode => foregroundCode + 10;
}

/// Output-bound color helpers. Consoler enables these only on ANSI terminals.
/// Disabled helpers return plain text and add no escape sequences.
final class ConsoleColors {
  final bool enabled;
  const ConsoleColors({required this.enabled});

  String paint(
    Object? message, {
    ConsoleColor? foreground,
    ConsoleColor? background,
    bool bold = false,
    bool dim = false,
    bool italic = false,
    bool underline = false,
  }) {
    final text = message.toString();
    final codes = [
      if (bold) 1,
      if (dim) 2,
      if (italic) 3,
      if (underline) 4,
      if (foreground != null) foreground.foregroundCode,
      if (background != null) background.backgroundCode,
    ];
    if (!enabled || codes.isEmpty) return text;
    final open = '\x1B[${codes.join(';')}m';
    const reset = '\x1B[0m';
    // A nested helper resets its style. Reapply the enclosing style afterwards,
    // and close every line independently to avoid leaking into log prefixes.
    return text
        .split('\n')
        .map((line) => '$open${line.replaceAll(reset, '$reset$open')}$reset')
        .join('\n');
  }

  String red(Object? value) => paint(value, foreground: ConsoleColor.red);
  String green(Object? value) => paint(value, foreground: ConsoleColor.green);
  String yellow(Object? value) => paint(value, foreground: ConsoleColor.yellow);
  String blue(Object? value) => paint(value, foreground: ConsoleColor.blue);
  String magenta(Object? value) =>
      paint(value, foreground: ConsoleColor.magenta);
  String cyan(Object? value) => paint(value, foreground: ConsoleColor.cyan);
  String gray(Object? value) =>
      paint(value, foreground: ConsoleColor.brightBlack);
  String bold(Object? value) => paint(value, bold: true);
  String dim(Object? value) => paint(value, dim: true);
  String underline(Object? value) => paint(value, underline: true);
}
