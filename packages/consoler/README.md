# Consoler

Dart commands, modules, package:args options, generated help and terminal editing.
The only runtime package dependency is args.

## Quick start

```dart
import 'package:consoler/consoler.dart';

Future<void> main() async {
  final console = Consoler(description: 'My server', ignoreCase: true);
  console.command(
    'echo',
    description: 'Print a message.',
    usage: '<text...>',
    aliases: ['repeat'],
    examples: ['echo --upper "Hello world"'],
    minArgs: 1,
    parser: ArgParser()
      ..addFlag('upper', abbr: 'u', negatable: false, help: 'Use uppercase.'),
    run: (context) {
      final message = context.args.join(' ');
      context.write(context.options!['upper'] as bool
          ? message.toUpperCase() : message);
    },
  );
  console.command('exit', run: (_) => console.stop());
  try {
    await console.start();
  } finally {
    await console.dispose();
  }
}
```

The args package is re-exported. Optional ArgParser instances handle flags,
options, defaults and validation. CommandContext.options contains ArgResults;
args contains the positionals, and rawArgs preserves tokens before option parsing.
Commands without a parser receive their tokens unchanged. Use -- to pass
option-like values. ignoreCase applies to command names, aliases and subcommands;
values retain their case, and options follow package:args rules.

## Commands and results

Use command() for callbacks or addCommand(ConsoleCommand(...)) for reusable
definitions. Handlers can be synchronous or asynchronous. Metadata includes
aliases, description, category, usage, examples, hidden visibility, argument
counts and nested subcommands. Description, category and usage also accept
callbacks, which are evaluated when help is rendered:

```dart
console.command(
  'echo',
  descriptionBuilder: () => applicationDescription(),
  categoryBuilder: () => applicationCategory(),
  run: (context) => context.write(context.args.join(' ')),
);
```

execute('ECHO "Mixed Case"') works without terminal input and returns CommandResult:
success, empty, usage, unknown or error. Errors preserve their exception and
stack trace. Commands execute sequentially; nested execute() calls in a handler
are awaited directly.

context.usage() shows command help, and context.fail(message) reports an expected
failure. Other exceptions are handled centrally. Legacy print() calls inside
handlers use the configured ConsoleOutput.

help, ?, help <command...> and <command> --help share the command metadata.
Typo suggestions include visible commands and never execute a suggestion.
Names and aliases must be unique under the configured case comparison.
Explicit replacement uses addCommand(..., replace: true).

## Modules

```dart
class GreetingModule extends ConsoleModule {
  @override
  String get id => 'greetings';

  @override
  Iterable<ConsoleCommand> get commands => [
    ConsoleCommand(
      name: 'hello',
      description: 'Greet someone.',
      usage: '<name>',
      minArgs: 1,
      maxArgs: 1,
      run: (context) => context.write('Hello ${context.args.single}!'),
    ),
  ];
}

await console.install(GreetingModule());
await console.execute('HELLO Ada');
await console.uninstall('greetings');
```

Modules own commands, aliases and lifecycle hooks. The complete command tree and
dependencies are validated before onLoad(console). Failed loading calls
onUnload(console) to release partially acquired resources without publishing
registrations. Hooks cannot mutate the registry or dispose their own console.

Uninstalling removes only the owning module's registrations. Dependencies and
executing handlers prevent premature removal. External disposal waits for
initialization and handlers, unloads modules in reverse order, and attempts
every cleanup even when one hook fails.

## Presentation and application localization

ConsoleMessages provides plain English defaults for built-in output. Override
individual values/callbacks or subclass it for an application-owned adapter:

```dart
final console = Consoler(messages: ConsoleMessages(
  helpDescription: 'Befehle anzeigen',
  helpUsage: '[Befehl...]',
  helpHint: 'Mit help <Befehl> erhältst du weitere Informationen.',
  usage: (syntax) => 'Verwendung: $syntax',
  unknownCommand: (name) => 'Unbekannter Befehl: $name',
));
```

All help headings, argument labels, hints, parser errors, unknown-command
messages and command failures are customizable. Replace console.messages at
runtime to switch the presentation; the built-in help reads current values.
Command metadata builders can read any application state.

Consoler has no locale, translation keys, catalogs, resource loader, interpolation
engine, or translation-package dependency. The application connects its chosen
translation library through these presentation callbacks. For Localizer, keep the
adapter in the application; locale contexts, printf formatting, fallback and the
JSON-to-Dart bundling tool belong to the separate localizer package.

## Colors and styles

Color helpers use the current output's terminal capabilities:

```dart
console.print(console.colors.green('Server ready'));
context.write(context.colors.paint('Notice',
  foreground: ConsoleColor.cyan,
  background: ConsoleColor.black,
  bold: true,
));
```

Named helpers include red, green, yellow, blue, magenta, cyan and gray, plus
bold, dim and underline. paint() combines foreground/background colors with
bold, dim, italic and underline. Standard and bright colors are supported.
Nested styles restore the enclosing style, and multiline output resets each
line. Pipes and buffers receive plain text. Standalone callers can explicitly
create ConsoleColors(enabled: ...) without constructing a console.

## Terminal and testing

start() returns at EOF or stop(); repeated active calls share the current session.
stop() cancels input without awaiting the active command so a handler can stop
its own console. dispose() is awaitable and idempotent; disposed instances cannot
restart.

ANSI terminals support cursor arrows, Home/End, Delete, Ctrl+A/E/U, Ctrl+C to clear,
Ctrl+D to close empty input, and Tab completion for names, aliases, subcommands
and flags. Up/Down access bounded in-memory history. Logs preserve current input,
and terminal modes are restored on EOF, stop, disposal and input errors.
lineEditing: false disables the editor. History is never written to disk.

Pipes receive plain lines without prompts or ANSI colors. I/O is injectable:

```dart
final output = BufferConsoleOutput();
final console = Consoler(
  output: output,
  input: Stream.fromIterable(['help']),
);
await console.start();
print(output.toString());
await console.dispose();
```

table(headers, rows) aligns output while preserving complete values.

## Migration from 1.x

Use Consoler instead of the unsafe Consoler<T> generic. ConsoleProgram,
registerProgram(s), DefaultProgramConfiguration, run(), runPrintZone(), programs
and LogLevel.toConsole() remain adapters. Synchronous run methods continue to
work; asynchronous implementations return Future<void> directly.

Collisions now fail rather than silently replacing a command. Use explicit
replacement for standalone commands or uninstall their owning module.
The legacy null fallback is supported; the default dispatcher supplies suggestions.

Prefer awaiting start() and dispose(). Application owners should dispose the
console when handling termination signals.
