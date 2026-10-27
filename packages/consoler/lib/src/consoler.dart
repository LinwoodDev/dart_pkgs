import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

import 'command.dart';
import 'color.dart';
import 'level.dart';
import 'messages.dart';
import 'module.dart';
import 'output.dart';
import 'parser.dart';
import 'program.dart';
import 'terminal.dart';

final class DefaultProgramConfiguration {
  final String description;
  const DefaultProgramConfiguration({required this.description});
}

final class _InstalledModule {
  final ConsoleModule module;
  final String id;
  final List<String> dependencies;
  final List<ConsoleCommand> commands;
  _InstalledModule(this.module, this.id, this.dependencies, this.commands);
}

final class _Execution {
  final Consoler console;
  bool active = true;
  bool failed = false;
  _Execution(this.console);
}

/// Command registry and executor. Terminal input is optional and injectable.
final class Consoler {
  final bool ignoreCase;
  final String description;
  final String prefix;
  final ConsoleOutput output;
  final Stream<String>? input;
  final bool lineEditing;
  final int historyLimit;
  final Map<String, ConsoleCommand> _commands = {};
  final Map<String, ConsoleProgram> _legacyPrograms = {};
  final Map<String, _InstalledModule> _modules = {};
  final Map<String, int> _activeModuleCalls = {};
  ConsoleMessages messages;
  final List<String> _history = [];
  ConsoleProgram? _unknownProgram;
  StreamSubscription<String>? _subscription;
  ConsoleLineEditor? _editor;
  Completer<void>? _session;
  Future<void> _executions = Future.value();
  Future<void> _moduleOperations = Future.value();
  Future<void>? _disposeFuture;
  bool _disposed = false;
  bool _inModuleHook = false;
  LogLevel minLogLevel;
  static final Object _executionKey = Object();
  static final Object _moduleHookKey = Object();

  Consoler({
    String description = '',
    DefaultProgramConfiguration? defaultProgramConfig,
    this.prefix = '> ',
    this.ignoreCase = false,
    this.minLogLevel = LogLevel.info,
    ConsoleOutput? output,
    this.input,
    this.lineEditing = true,
    this.historyLimit = 100,
    bool builtIns = true,
    this.messages = const ConsoleMessages(),
  }) : description = defaultProgramConfig?.description ?? description,
       output = output ?? TerminalConsoleOutput() {
    if (historyLimit < 0) {
      throw ArgumentError.value(historyLimit, 'historyLimit');
    }
    if (builtIns) {
      addCommand(
        ConsoleCommand(
          name: 'help',
          aliases: ['?'],
          usageBuilder: () => messages.helpUsage,
          descriptionBuilder: () => messages.helpDescription,
          run: (context) => showHelp(context.args),
        ),
      );
    }
  }

  ConsoleColors get colors =>
      ConsoleColors(enabled: output.interactive && output.supportsAnsi);

  bool get isRunning => _session != null;
  List<String> get history => List.unmodifiable(_history);
  Iterable<ConsoleCommand> get commands => List.unmodifiable(_commands.values);
  Iterable<ConsoleModule> get modules =>
      List.unmodifiable(_modules.values.map((entry) => entry.module));

  /// Legacy registry view, including commands installed by modules.
  Iterable<MapEntry<String?, ConsoleProgram>> get programs => [
    for (final command in _commands.values)
      MapEntry(
        command.name,
        _legacyPrograms[command.name] ?? _CommandProgram(this, command),
      ),
    if (_unknownProgram != null) MapEntry(null, _unknownProgram!),
  ];

  String _key(String value) => ignoreCase ? value.toLowerCase() : value;

  void _checkMutable() {
    if (_disposed) throw StateError('Console has been disposed');
    if (_inModuleHook) {
      throw StateError('Module hooks cannot mutate the registry');
    }
  }

  void _validate(
    Iterable<ConsoleCommand> candidates, [
    Iterable<ConsoleCommand> existing = const [],
  ]) {
    final names = <String>{};
    for (final command in existing) {
      names.addAll([command.name, ...command.aliases].map(_key));
    }
    for (final command in candidates) {
      for (final name in [command.name, ...command.aliases]) {
        if (name.isEmpty ||
            RegExp(r'\s').hasMatch(name) ||
            name.startsWith('-')) {
          throw ArgumentError('Invalid command name: $name');
        }
        if (!names.add(_key(name))) {
          throw StateError('Command collision: $name');
        }
      }
      _validate(command.subcommands);
    }
  }

  void addCommand(ConsoleCommand command, {bool replace = false}) {
    _checkMutable();
    final previous = _commands.values
        .where((c) => _key(c.name) == _key(command.name))
        .firstOrNull;
    if (replace && previous != null && _owner(previous) != null) {
      throw StateError(
        'Uninstall the owning module before replacing its command',
      );
    }
    _validate([
      command,
    ], _commands.values.where((c) => !replace || c != previous));
    if (replace && previous != null) {
      _commands.remove(previous.name);
      _legacyPrograms.remove(previous.name);
    }
    _commands[command.name] = command;
  }

  void command(
    String name, {
    required CommandHandler run,
    String description = '',
    String Function()? descriptionBuilder,
    String usage = '',
    String Function()? usageBuilder,
    List<String> aliases = const [],
    List<String> examples = const [],
    String category = '',
    String Function()? categoryBuilder,
    bool hidden = false,
    ArgParser? parser,
    int minArgs = 0,
    int? maxArgs,
  }) => addCommand(
    ConsoleCommand(
      name: name,
      run: run,
      description: description,
      descriptionBuilder: descriptionBuilder,
      usage: usage,
      usageBuilder: usageBuilder,
      aliases: aliases,
      examples: examples,
      category: category,
      categoryBuilder: categoryBuilder,
      hidden: hidden,
      parser: parser,
      minArgs: minArgs,
      maxArgs: maxArgs,
    ),
  );

  void registerProgram(String? name, ConsoleProgram program) {
    _checkMutable();
    if (name == null) {
      _unknownProgram = program;
      return;
    }
    addCommand(ConsoleCommand.fromProgram(name, program));
    _legacyPrograms[name] = program;
  }

  void registerPrograms(Map<String?, ConsoleProgram> programs) {
    _checkMutable();
    final entries = [
      for (final entry in programs.entries)
        if (entry.key != null)
          ConsoleCommand.fromProgram(entry.key!, entry.value),
    ];
    _validate(entries, _commands.values);
    for (final entry in programs.entries) {
      registerProgram(entry.key, entry.value);
    }
  }

  String? _owner(ConsoleCommand command) => _modules.entries
      .where((entry) => entry.value.commands.contains(command))
      .map((entry) => entry.key)
      .firstOrNull;

  bool unregisterProgram(String? name) {
    _checkMutable();
    if (name == null) {
      final existed = _unknownProgram != null;
      _unknownProgram = null;
      return existed;
    }
    final command = _find(_commands.values, name);
    if (command == null) return false;
    if (_owner(command) != null) {
      throw StateError('Uninstall the owning module');
    }
    _commands.remove(command.name);
    _legacyPrograms.remove(command.name);
    return true;
  }

  void resetPrograms() {
    _checkMutable();
    if (_modules.isNotEmpty) {
      throw StateError('Uninstall modules before resetting commands');
    }
    _commands.clear();
    _legacyPrograms.clear();
    _unknownProgram = null;
  }

  Future<void> _moduleOperation(Future<void> Function() action) {
    if (_disposed) throw StateError('Console has been disposed');
    if (identical(Zone.current[_moduleHookKey], this)) {
      throw StateError('Module hooks cannot mutate the registry');
    }
    final next = _moduleOperations.then((_) => action());
    _moduleOperations = next.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return next;
  }

  /// Validates all names and dependencies before acquiring module resources.
  /// Hooks must not register commands or install/uninstall other modules.
  Future<void> install(ConsoleModule module) => _moduleOperation(() async {
    if (_disposed) throw StateError('Console has been disposed');
    final id = module.id;
    final dependencies = List<String>.unmodifiable(module.dependencies);
    if (id.isEmpty || _modules.containsKey(id)) {
      throw StateError('Duplicate or empty module ID: ${module.id}');
    }
    for (final dependency in dependencies) {
      if (!_modules.containsKey(dependency)) {
        throw StateError('Missing module dependency: $dependency');
      }
    }
    final added = List<ConsoleCommand>.unmodifiable(module.commands);
    _validate(added, _commands.values);
    _inModuleHook = true;
    try {
      await runZoned(
        () => module.onLoad(this),
        zoneValues: {_moduleHookKey: this},
      );
    } catch (error, stack) {
      try {
        await runZoned(
          () => module.onUnload(this),
          zoneValues: {_moduleHookKey: this},
        );
      } catch (_) {
        /* Keep the original failure. */
      }
      Error.throwWithStackTrace(error, stack);
    } finally {
      _inModuleHook = false;
    }
    for (final command in added) {
      _commands[command.name] = command;
    }
    _modules[id] = _InstalledModule(module, id, dependencies, added);
  });

  Future<void> uninstall(String id) => _moduleOperation(() async {
    final installed = _modules[id];
    if (installed == null) throw StateError('Unknown module: $id');
    if ((_activeModuleCalls[id] ?? 0) > 0) {
      throw StateError('Module $id still has an executing command');
    }
    final dependents = _modules.values.where(
      (m) => m.dependencies.contains(id),
    );
    if (dependents.isNotEmpty) throw StateError('Module $id is still required');
    await _uninstall(installed);
  });

  Future<void> _uninstall(_InstalledModule installed) async {
    _inModuleHook = true;
    try {
      await runZoned(
        () => installed.module.onUnload(this),
        zoneValues: {_moduleHookKey: this},
      );
    } finally {
      _inModuleHook = false;
      _modules.remove(installed.id);
      for (final command in installed.commands) {
        _commands.remove(command.name);
      }
    }
  }

  ConsoleCommand? _find(Iterable<ConsoleCommand> commands, String name) =>
      commands
          .where(
            (c) => [c.name, ...c.aliases].any((n) => _key(n) == _key(name)),
          )
          .firstOrNull;

  Future<CommandResult> execute(String line) {
    if (_disposed) return Future.error(StateError('Console has been disposed'));
    final active = Zone.current[_executionKey];
    if (active is _Execution &&
        active.active &&
        identical(active.console, this)) {
      return _execute(line);
    }
    final next = _executions.then((_) => _execute(line));
    _executions = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<CommandResult> _execute(String line) async {
    if (_disposed) {
      return CommandResult(
        CommandStatus.error,
        error: StateError('Console has been disposed'),
      );
    }
    List<String> words;
    try {
      words = parseCommandLine(line);
    } on FormatException catch (error) {
      print(messages.unclosedQuote, level: LogLevel.error);
      return CommandResult(CommandStatus.usage, error: error);
    }
    if (words.isEmpty) return const CommandResult(CommandStatus.empty);
    var choices = _commands.values;
    ConsoleCommand? command;
    final path = <String>[];
    var index = 0;
    while (index < words.length) {
      final found = _find(choices, words[index]);
      if (found == null) break;
      command = found;
      path.add(found.name);
      index++;
      choices = found.subcommands;
      if (choices.isEmpty) break;
    }
    if (command == null) {
      if (_unknownProgram != null) {
        try {
          await runPrintZone(
            () => _unknownProgram!.run(words.first, words.skip(1).toList()),
          );
        } catch (error, stack) {
          print(
            messages.commandFailed(words.first, error),
            level: LogLevel.error,
          );
          return CommandResult(
            CommandStatus.error,
            error: error,
            stackTrace: stack,
          );
        }
      } else {
        _unknown(words.first, _commands.values);
      }
      return CommandResult(CommandStatus.unknown, command: words.first);
    }
    final selected = command;
    final commandPath = path.join(' ');
    final raw = words.skip(index).toList();
    final state = _Execution(this);
    final owner = _owner(_commands[path.first]!);
    if (owner != null) {
      _activeModuleCalls[owner] = (_activeModuleCalls[owner] ?? 0) + 1;
    }
    try {
      return await runZoned(() async {
        if (raw.length == 1 && raw.first == '--help') {
          showHelp(path);
          return CommandResult(CommandStatus.success, command: commandPath);
        }
        if (selected.run == null) {
          if (raw.isEmpty) {
            showHelp(path);
            return CommandResult(CommandStatus.success, command: commandPath);
          }
          _unknown(raw.first, selected.subcommands);
          return CommandResult(CommandStatus.unknown, command: commandPath);
        }
        ArgResults? options;
        try {
          options = selected.parser?.parse(raw);
        } on FormatException catch (error) {
          throw CommandUsageException(messages.invalidArguments(error.message));
        }
        final args = options?.rest ?? raw;
        if (args.length < selected.minArgs ||
            (selected.maxArgs != null && args.length > selected.maxArgs!)) {
          throw const CommandUsageException();
        }
        final context = CommandContext(
          console: this,
          command: selected,
          label: words.first,
          path: commandPath,
          args: args,
          rawArgs: raw,
          options: options,
        );
        await runPrintZone(() => selected.run!(context));
        return CommandResult(
          state.failed ? CommandStatus.error : CommandStatus.success,
          command: commandPath,
        );
      }, zoneValues: {_executionKey: state});
    } on CommandUsageException catch (error) {
      if (error.message != null) print(error.message, level: LogLevel.error);
      showHelp(path);
      return CommandResult(
        CommandStatus.usage,
        command: commandPath,
        error: error,
      );
    } catch (error, stack) {
      print(
        error is CommandFailure
            ? error.message
            : messages.commandFailed(commandPath, error),
        level: LogLevel.error,
      );
      return CommandResult(
        CommandStatus.error,
        command: commandPath,
        error: error,
        stackTrace: stack,
      );
    } finally {
      state.active = false;
      if (owner != null) {
        final count = _activeModuleCalls[owner]! - 1;
        if (count == 0) {
          _activeModuleCalls.remove(owner);
        } else {
          _activeModuleCalls[owner] = count;
        }
      }
    }
  }

  void _unknown(String name, Iterable<ConsoleCommand> choices) {
    print(messages.unknownCommand(name), level: LogLevel.error);
    final candidates = <(int, String)>[];
    for (final command in choices.where((c) => !c.hidden)) {
      final distance = [command.name, ...command.aliases]
          .map((n) => _distance(name.toLowerCase(), n.toLowerCase()))
          .reduce((a, b) => a < b ? a : b);
      if (distance <= (name.length > 5 ? 2 : 1)) {
        candidates.add((distance, command.name));
      }
    }
    candidates.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    if (candidates.isNotEmpty) {
      print(messages.suggestion(candidates.take(3).map((e) => e.$2)));
    }
  }

  void showHelp([List<String> path = const []]) {
    if (path.isEmpty) {
      final lines = <String>[if (description.isNotEmpty) description, ''];
      final groups = <String, List<ConsoleCommand>>{};
      for (final command in _commands.values.where((c) => !c.hidden)) {
        final category = command.category.isEmpty
            ? messages.generalCategory
            : command.category;
        groups.putIfAbsent(category, () => []).add(command);
      }
      final categories = groups.keys.toList()..sort();
      for (final category in categories) {
        lines.add(category);
        final commands = groups[category]!
          ..sort((a, b) => a.name.compareTo(b.name));
        final width = commands
            .map((c) => c.name.length)
            .fold(0, (a, b) => a > b ? a : b);
        for (final command in commands) {
          final description = command.description;
          lines.add('  ${command.name.padRight(width)}  $description');
        }
        lines.add('');
      }
      lines.add(messages.helpHint);
      print(lines.join('\n'));
      return;
    }
    var choices = _commands.values;
    ConsoleCommand? command;
    final canonical = <String>[];
    for (final part in path) {
      command = _find(choices, part);
      if (command == null) {
        throw CommandFailure(messages.unknownCommand(path.join(' ')));
      }
      canonical.add(command.name);
      choices = command.subcommands;
    }
    final selected = command!;
    final usage = [
      canonical.join(' '),
      if (selected.usage.isNotEmpty) selected.usage,
      if (selected.run == null && selected.subcommands.isNotEmpty)
        messages.subcommandUsage,
    ].join(' ');
    final lines = <String>[messages.usage(usage), selected.description];
    if (selected.aliases.isNotEmpty) {
      lines.add(messages.aliases(selected.aliases));
    }
    if (selected.parser?.usage.isNotEmpty == true) {
      lines.addAll(['', messages.optionsTitle, selected.parser!.usage]);
    }
    if (selected.subcommands.isNotEmpty) {
      lines.addAll(['', messages.commandsTitle]);
      for (final child in selected.subcommands.where((c) => !c.hidden)) {
        lines.add('  ${child.name} ${child.usage}  ${child.description}');
      }
    }
    if (selected.examples.isNotEmpty) {
      lines.addAll([
        '',
        messages.examplesTitle,
        ...selected.examples.map((e) => '  $e'),
      ]);
    }
    print(lines.join('\n'));
  }

  /// Suggestions include aliases, subcommands and flags from package:args.
  List<String> complete(String line) {
    List<String> words;
    try {
      words = parseCommandLine(line);
    } on FormatException {
      return const [];
    }
    final trailing = line.isNotEmpty && line[line.length - 1].trim().isEmpty;
    final partial = trailing || words.isEmpty ? '' : words.removeLast();
    var choices = _commands.values;
    ConsoleCommand? parent;
    final pathWords =
        words.isNotEmpty && _find(choices, words.first)?.name == 'help'
        ? words.skip(1)
        : words;
    for (final word in pathWords) {
      final found = _find(choices, word);
      if (found == null) return const [];
      parent = found;
      choices = found.subcommands;
    }
    final names = <String>[
      for (final c in choices.where((c) => !c.hidden)) c.name,
      for (final c in choices.where((c) => !c.hidden)) ...c.aliases,
      if (parent?.parser != null)
        for (final option in parent!.parser!.options.values) ...[
          '--${option.name}',
          if (option.negatable ?? false) '--no-${option.name}',
        ],
    ];
    return (names
        .where((name) => _key(name).startsWith(_key(partial)))
        .toSet()
        .toList()
      ..sort());
  }

  /// Aligned tables retain full values, including fingerprints and identifiers.
  /// Terminal cells wrap; redirected output keeps each record on one line.
  void table(List<String> headers, Iterable<List<Object?>> rows) {
    if (headers.isEmpty) return;
    final data = [
      headers,
      for (final row in rows)
        row.map((value) => value?.toString() ?? '—').toList(),
    ];
    if (data.any((row) => row.length != headers.length)) {
      throw ArgumentError('Table column mismatch');
    }
    final available =
        ((output.columns - 2 * (headers.length - 1)) ~/ headers.length).clamp(
          1,
          60,
        );
    final widths = List.generate(headers.length, (column) {
      final width = data
          .map(
            (row) =>
                row[column].replaceAll(RegExp(r'[\r\n\t]'), ' ').runes.length,
          )
          .fold(1, (a, b) => a > b ? a : b);
      return output.interactive ? width.clamp(1, available) : width;
    });
    final lines = <String>[];
    for (var rowIndex = 0; rowIndex < data.length; rowIndex++) {
      final columns = <List<String>>[];
      for (var column = 0; column < headers.length; column++) {
        final runes = data[rowIndex][column]
            .replaceAll(RegExp(r'[\r\n\t]'), ' ')
            .runes
            .toList();
        columns.add([
          if (runes.isEmpty) '',
          for (var start = 0; start < runes.length; start += widths[column])
            String.fromCharCodes(runes.skip(start).take(widths[column])),
        ]);
      }
      final height = columns
          .map((column) => column.length)
          .reduce((a, b) => a > b ? a : b);
      for (var line = 0; line < height; line++) {
        final cells = <String>[];
        for (var column = 0; column < headers.length; column++) {
          final value = columns[column].elementAtOrNull(line) ?? '';
          cells.add(value + ' ' * (widths[column] - value.runes.length));
        }
        lines.add(cells.join('  ').trimRight());
      }
      if (rowIndex == 0) {
        lines.add(widths.map((width) => '─' * width).join('  '));
      }
    }
    print(lines.join('\n'));
  }

  R runPrintZone<R>(R Function() action) => runZoned(
    action,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, message) {
        print(message);
      },
    ),
  );

  void print(Object? message, {LogLevel? level}) {
    if (level != null && level.index < minLogLevel.index) return;
    if (level == LogLevel.error) {
      final state = Zone.current[_executionKey];
      if (state is _Execution) state.failed = true;
    }
    final label = level == null
        ? ''
        : '${level.format(color: output.interactive && output.supportsAnsi)} ';
    final rendered = message
        .toString()
        .split('\n')
        .map((line) => '$label$line')
        .join('\n');
    if (_editor != null) {
      _editor!.log(rendered);
    } else {
      output.write('$rendered\n');
    }
  }

  void sendPrefix() {
    if (output.interactive) output.write(prefix);
  }

  /// Runs until EOF or stop(). Repeated calls share the current session.
  Future<void> start() {
    if (_disposed) return Future.error(StateError('Console has been disposed'));
    if (_session != null) return _session!.future;
    final session = _session = Completer<void>();
    var raw = false;
    bool? oldEcho, oldLine;
    void restore() {
      if (raw) {
        stdin.lineMode = oldLine!;
        stdin.echoMode = oldEcho!;
        raw = false;
      }
      _editor = null;
      if (identical(_session, session)) _session = null;
    }

    _restoreTerminal = restore;
    try {
      if (input == null &&
          stdin.hasTerminal &&
          output.interactive &&
          output.supportsAnsi &&
          lineEditing) {
        oldEcho = stdin.echoMode;
        oldLine = stdin.lineMode;
        stdin.echoMode = false;
        stdin.lineMode = false;
        raw = true;
        _editor = ConsoleLineEditor(
          output: output,
          prefix: prefix,
          history: _history,
          historyLimit: historyLimit,
          complete: complete,
          onLine: (line) {
            unawaited(execute(line));
          },
          onClose: () {
            unawaited(stop());
          },
        );
        _editor!.redraw();
      } else if (output.interactive) {
        sendPrefix();
      }
      final stream =
          input ??
          (raw
              ? stdin.transform(utf8.decoder)
              : stdin.transform(utf8.decoder).transform(const LineSplitter()));
      _subscription = stream.listen(
        (value) {
          if (raw) {
            _editor?.add(value);
          } else {
            unawaited(
              execute(value).then((_) {
                if (isRunning) sendPrefix();
              }),
            );
          }
        },
        onDone: () async {
          await _executions;
          restore();
          if (!session.isCompleted) session.complete();
        },
        onError: (Object error, StackTrace stack) {
          restore();
          if (!session.isCompleted) session.completeError(error, stack);
        },
        cancelOnError: true,
      );
    } catch (error, stack) {
      restore();
      session.completeError(error, stack);
    }
    return session.future;
  }

  void Function()? _restoreTerminal;

  /// Compatibility entry point. Prefer awaiting start().
  void run({bool? wasPrefixShown}) {
    unawaited(
      start().catchError((Object error) {
        print(error, level: LogLevel.error);
      }),
    );
  }

  /// Stops input without waiting for the active command (which may call stop).
  Future<void> stop() async {
    final subscription = _subscription;
    _subscription = null;
    final session = _session;
    _restoreTerminal?.call();
    _restoreTerminal = null;
    await subscription?.cancel();
    if (session != null && !session.isCompleted) session.complete();
  }

  Future<void> dispose() {
    if (identical(Zone.current[_moduleHookKey], this)) {
      return Future.error(
        StateError('Module hooks cannot dispose the console'),
      );
    }
    return _disposeFuture ??= _dispose();
  }

  Future<void> _dispose() async {
    _disposed = true;
    await stop();
    await _moduleOperations;
    final active = Zone.current[_executionKey];
    if (active is! _Execution ||
        !active.active ||
        !identical(active.console, this)) {
      await _executions;
    }
    Object? firstError;
    StackTrace? firstStack;
    for (final installed in _modules.values.toList().reversed) {
      try {
        await _uninstall(installed);
      } catch (error, stack) {
        firstError ??= error;
        firstStack ??= stack;
      }
    }
    _commands.clear();
    _legacyPrograms.clear();
    if (firstError != null) Error.throwWithStackTrace(firstError, firstStack!);
  }
}

final class _CommandProgram extends ConsoleProgram {
  final Consoler console;
  final ConsoleCommand command;
  _CommandProgram(this.console, this.command);
  @override
  String? getDescription() => command.description;
  @override
  String? getUsage() => command.usage;
  @override
  bool get isHidden => command.hidden;
  @override
  Future<void> run(String label, List<String> args) async {
    String quote(String value) =>
        '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
    await console.execute([quote(command.name), ...args.map(quote)].join(' '));
  }
}

int _distance(String a, String b) {
  var previous = List.generate(b.length + 1, (i) => i);
  for (var i = 0; i < a.length; i++) {
    final current = [i + 1];
    for (var j = 0; j < b.length; j++) {
      final values = [
        current[j] + 1,
        previous[j + 1] + 1,
        previous[j] + (a[i] == b[j] ? 0 : 1),
      ];
      current.add(values.reduce((a, b) => a < b ? a : b));
    }
    previous = current;
  }
  return previous.last;
}
