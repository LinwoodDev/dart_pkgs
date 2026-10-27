import 'dart:async';

import 'package:args/args.dart';

import 'consoler.dart';
import 'color.dart';
import 'level.dart';
import 'program.dart';

typedef CommandHandler = FutureOr<void> Function(CommandContext context);

/// Metadata shared by execution, help and completion.
final class ConsoleCommand {
  final String name;
  final List<String> aliases;
  final String _description;
  final String Function()? descriptionBuilder;
  final String _usage;
  final String Function()? usageBuilder;
  final List<String> examples;
  final String _category;
  final String Function()? categoryBuilder;
  final bool hidden;
  final int minArgs;
  final int? maxArgs;
  final ArgParser? parser;
  final List<ConsoleCommand> subcommands;
  final CommandHandler? run;

  ConsoleCommand({
    required this.name,
    String description = '',
    this.descriptionBuilder,
    String usage = '',
    this.usageBuilder,
    List<String> aliases = const [],
    List<String> examples = const [],
    String category = '',
    this.categoryBuilder,
    this.hidden = false,
    this.minArgs = 0,
    this.maxArgs,
    this.parser,
    List<ConsoleCommand> subcommands = const [],
    this.run,
  }) : _description = description,
       _usage = usage,
       _category = category,
       aliases = List.unmodifiable(aliases),
       examples = List.unmodifiable(examples),
       subcommands = List.unmodifiable(subcommands) {
    if (minArgs < 0 || (maxArgs != null && maxArgs! < minArgs)) {
      throw ArgumentError('Invalid argument limits for $name');
    }
  }

  factory ConsoleCommand.fromProgram(String name, ConsoleProgram program) =>
      ConsoleCommand(
        name: name,
        description: program.getDescription() ?? '',
        usage: program.getUsage() ?? '',
        hidden: program.isHidden,
        run: (context) => program.run(context.label, context.args),
      );

  String get description => descriptionBuilder?.call() ?? _description;
  String get usage => usageBuilder?.call() ?? _usage;
  String get category => categoryBuilder?.call() ?? _category;
}

enum CommandStatus { success, empty, usage, unknown, error }

final class CommandResult {
  final CommandStatus status;
  final String? command;
  final Object? error;
  final StackTrace? stackTrace;
  const CommandResult(this.status, {this.command, this.error, this.stackTrace});
  bool get isSuccess => status == CommandStatus.success;
}

final class CommandUsageException implements Exception {
  final String? message;
  const CommandUsageException([this.message]);
}

final class CommandFailure implements Exception {
  final String message;
  const CommandFailure(this.message);
  @override
  String toString() => message;
}

final class CommandContext {
  final Consoler console;
  final ConsoleCommand command;
  final String label;
  final String path;
  final List<String> args;
  final List<String> rawArgs;
  final ArgResults? options;
  CommandContext({
    required this.console,
    required this.command,
    required this.label,
    required this.path,
    required List<String> args,
    required List<String> rawArgs,
    this.options,
  }) : args = List.unmodifiable(args),
       rawArgs = List.unmodifiable(rawArgs);

  ConsoleColors get colors => console.colors;

  void write(Object? message) => console.print(message);
  void info(Object? message) => console.print(message, level: LogLevel.info);
  void success(Object? message) => console.print(message, level: LogLevel.info);
  void warning(Object? message) =>
      console.print(message, level: LogLevel.warning);
  Never fail(String message) => throw CommandFailure(message);
  Never usage([String? message]) => throw CommandUsageException(message);
}
