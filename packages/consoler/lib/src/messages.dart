/// Presentation hooks for built-in output. These are plain text and callbacks;
/// applications own locale selection, resource loading and translation.
class ConsoleMessages {
  final String helpDescription;
  final String helpUsage;
  final String subcommandUsage;
  final String commandsTitle;
  final String optionsTitle;
  final String examplesTitle;
  final String helpHint;
  final String generalCategory;
  final String unclosedQuote;
  final String Function(String value)? _usage;
  final String Function(Iterable<String> values)? _aliases;
  final String Function(String name)? _unknownCommand;
  final String Function(Iterable<String> names)? _suggestion;
  final String Function(String name, Object error)? _commandFailed;
  final String Function(String error)? _invalidArguments;
  final String Function(String description)? _ready;

  const ConsoleMessages({
    this.helpDescription = 'Show commands or help for one command.',
    this.helpUsage = '[command...]',
    this.subcommandUsage = '<command>',
    this.commandsTitle = 'Commands',
    this.optionsTitle = 'Options',
    this.examplesTitle = 'Examples',
    this.helpHint = 'Type help <command> for details.',
    this.generalCategory = 'General',
    this.unclosedQuote =
        'Unclosed quote. Close it with the matching quote character.',
    String Function(String value)? usage,
    String Function(Iterable<String> values)? aliases,
    String Function(String name)? unknownCommand,
    String Function(Iterable<String> names)? suggestion,
    String Function(String name, Object error)? commandFailed,
    String Function(String error)? invalidArguments,
    String Function(String description)? ready,
  }) : _usage = usage,
       _aliases = aliases,
       _unknownCommand = unknownCommand,
       _suggestion = suggestion,
       _commandFailed = commandFailed,
       _invalidArguments = invalidArguments,
       _ready = ready;

  String usage(String value) => _usage?.call(value) ?? 'Usage: $value';
  String aliases(Iterable<String> values) =>
      _aliases?.call(values) ?? 'Aliases: ${values.join(', ')}';
  String unknownCommand(String name) =>
      _unknownCommand?.call(name) ??
      'Unknown command: $name. Type help to see available commands.';
  String suggestion(Iterable<String> names) =>
      _suggestion?.call(names) ?? 'Did you mean ${names.join(', ')}?';
  String commandFailed(String name, Object error) =>
      _commandFailed?.call(name, error) ?? 'Command $name failed: $error';
  String invalidArguments(String error) =>
      _invalidArguments?.call(error) ?? 'Invalid arguments: $error';
  String ready(String description) =>
      _ready?.call(description) ?? '$description — type help to get started.';
}
