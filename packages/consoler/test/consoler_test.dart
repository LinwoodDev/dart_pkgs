import 'dart:async';
import 'package:consoler/consoler.dart';
import 'package:consoler/src/terminal.dart';
import 'package:test/test.dart';

final class TestModule extends ConsoleModule {
  @override
  final String id;
  @override
  final List<ConsoleCommand> commands;
  @override
  final List<String> dependencies;
  final FutureOr<void> Function()? load;
  final FutureOr<void> Function()? unload;
  TestModule(
    this.id, {
    this.commands = const [],
    this.dependencies = const [],
    this.load,
    this.unload,
  });
  @override
  FutureOr<void> onLoad(Consoler console) => load?.call();
  @override
  FutureOr<void> onUnload(Consoler console) => unload?.call();
}

final class LegacyProgram extends ConsoleProgram {
  final void Function() action;
  LegacyProgram(this.action);
  @override
  String getDescription() => 'Legacy';
  @override
  void run(String label, List<String> args) => action();
}

final class _CustomMessages extends ConsoleMessages {
  const _CustomMessages();
  @override
  String get helpDescription => 'Custom command overview';
  @override
  String get unclosedQuote => 'Custom missing quote';
}

void main() {
  late BufferConsoleOutput output;
  late Consoler console;
  setUp(() {
    output = BufferConsoleOutput();
    console = Consoler(output: output, ignoreCase: true);
  });
  tearDown(() => console.dispose());

  group('parser', () {
    test('whitespace and empty input', () {
      expect(parseCommandLine(' \t  '), isEmpty);
      expect(parseCommandLine('echo\t hello  world'), [
        'echo',
        'hello',
        'world',
      ]);
    });
    test('quotes, empty arguments and adjacent fragments', () {
      expect(parseCommandLine('echo "hello world" \'a b\' "" x"y z"'), [
        'echo',
        'hello world',
        'a b',
        '',
        'xy z',
      ]);
    });
    test('escaped quotes and paths', () {
      expect(parseCommandLine(r'echo "a\"b" hello\ world C:\temp'), [
        'echo',
        'a"b',
        'hello world',
        r'C:\temp',
      ]);
    });
    test('unclosed quote', () {
      expect(() => parseCommandLine('echo "hello'), throwsFormatException);
    });
  });

  test('empty input never invokes fallback', () async {
    var invoked = false;
    console.registerProgram(null, LegacyProgram(() => invoked = true));
    expect((await console.execute(' ')).status, CommandStatus.empty);
    expect(invoked, isFalse);
  });
  test('case folding affects names and aliases, preserves arguments', () async {
    List<String>? args;
    console.command(
      'echo',
      aliases: ['repeat'],
      run: (ctx) {
        args = ctx.args;
      },
    );
    await console.execute('RePeAt "MiXeD Name"');
    expect(args, ['MiXeD Name']);
  });
  test('case sensitivity is configurable', () async {
    final sensitive = Consoler(output: output);
    addTearDown(sensitive.dispose);
    sensitive.command('echo', run: (_) {});
    expect((await sensitive.execute('ECHO')).status, CommandStatus.unknown);
  });
  test('alias and name collisions are atomic', () {
    console.command('echo', aliases: ['repeat'], run: (_) {});
    expect(() => console.command('REPEAT', run: (_) {}), throwsStateError);
    expect(
      () => console.registerPrograms({
        'fresh': LegacyProgram(() {}),
        'ECHO': LegacyProgram(() {}),
      }),
      throwsStateError,
    );
    expect(console.commands.map((c) => c.name), isNot(contains('fresh')));
  });
  test('nested collisions are rejected', () {
    expect(
      () => console.addCommand(
        ConsoleCommand(
          name: 'root',
          subcommands: [
            ConsoleCommand(name: 'a'),
            ConsoleCommand(name: 'A'),
          ],
        ),
      ),
      throwsStateError,
    );
  });
  test('replacement is explicit', () async {
    var count = 0;
    console.command(
      'echo',
      run: (_) {
        count++;
      },
    );
    console.addCommand(
      ConsoleCommand(
        name: 'echo',
        run: (_) {
          count += 10;
        },
      ),
      replace: true,
    );
    await console.execute('echo');
    expect(count, 10);
  });
  test('package:args options, defaults and positional arguments', () async {
    console.command(
      'echo',
      parser: ArgParser()
        ..addFlag('loud', abbr: 'l', negatable: false)
        ..addOption('times', defaultsTo: '1'),
      run: (ctx) {
        expect(ctx.options!['loud'], isTrue);
        expect(ctx.options!['times'], '2');
        expect(ctx.args, ['Hello']);
        expect(ctx.rawArgs, ['-l', '--times', '2', 'Hello']);
      },
    );
    expect(
      (await console.execute('echo -l --times 2 Hello')).isSuccess,
      isTrue,
    );
  });
  test('invalid options and argument counts return usage', () async {
    var invoked = false;
    console.command(
      'echo',
      parser: ArgParser(),
      minArgs: 1,
      maxArgs: 1,
      run: (_) {
        invoked = true;
      },
    );
    expect((await console.execute('echo --bad')).status, CommandStatus.usage);
    expect((await console.execute('echo')).status, CommandStatus.usage);
    expect(invoked, isFalse);
  });
  test('subcommands fold case without changing identifiers', () async {
    console.addCommand(
      ConsoleCommand(
        name: 'roles',
        subcommands: [
          ConsoleCommand(
            name: 'permission',
            subcommands: [
              ConsoleCommand(
                name: 'add',
                minArgs: 1,
                run: (ctx) {
                  expect(ctx.path, 'roles permission add');
                  expect(ctx.args, ['MyRole']);
                },
              ),
            ],
          ),
        ],
      ),
    );
    expect(
      (await console.execute('ROLES PERMISSION ADD MyRole')).isSuccess,
      isTrue,
    );
  });
  test('async handlers complete before the next command', () async {
    final order = <int>[];
    final gate = Completer<void>();
    console.command(
      'first',
      run: (_) async {
        await gate.future;
        order.add(1);
      },
    );
    console.command(
      'second',
      run: (_) {
        order.add(2);
      },
    );
    final first = console.execute('first');
    final second = console.execute('second');
    await Future<void>.delayed(Duration.zero);
    expect(order, isEmpty);
    gate.complete();
    await Future.wait([first, second]);
    expect(order, [1, 2]);
  });
  test(
    'async failures are returned with stack trace and console stays usable',
    () async {
      console.command(
        'fail',
        run: (_) async {
          throw StateError('broken');
        },
      );
      final result = await console.execute('fail');
      expect(result.status, CommandStatus.error);
      expect(result.stackTrace, isNotNull);
      expect(output.toString(), contains('broken'));
      expect((await console.execute('help')).isSuccess, isTrue);
    },
  );
  test('legacy print capture and reported errors', () async {
    console.registerProgram(
      'legacy',
      LegacyProgram(() {
        print('captured');
      }),
    );
    await console.execute('legacy');
    expect(output.toString(), contains('captured'));
    console.command(
      'error',
      run: (ctx) {
        ctx.console.print('bad', level: LogLevel.error);
      },
    );
    expect((await console.execute('error')).status, CommandStatus.error);
  });
  test('unknown commands suggest but never run commands', () async {
    var invoked = false;
    console.command(
      'players',
      run: (_) {
        invoked = true;
      },
    );
    expect((await console.execute('palyers')).status, CommandStatus.unknown);
    expect(output.toString(), contains('players'));
    expect(invoked, isFalse);
  });
  test('custom messages work without a translation provider', () async {
    final custom = Consoler(output: output, messages: const _CustomMessages());
    addTearDown(custom.dispose);
    await custom.execute('help');
    expect(output.toString(), contains('Custom command overview'));
    output.clear();
    await custom.execute('echo "');
    expect(output.toString(), contains('Custom missing quote'));
  });
  test(
    'help contains flags, examples, aliases, and hides hidden commands',
    () async {
      console.command(
        'echo',
        description: 'Print',
        aliases: ['repeat'],
        usage: '<text>',
        examples: ['echo Hello'],
        parser: ArgParser()
          ..addFlag('loud', negatable: false, help: 'Uppercase'),
        run: (_) {},
      );
      console.command('secret', hidden: true, run: (_) {});
      await console.execute('help');
      expect(output.toString(), isNot(contains('secret')));
      output.clear();
      await console.execute('echo --help');
      expect(output.toString(), contains('--loud'));
      expect(output.toString(), contains('echo Hello'));
      expect(output.toString(), contains('repeat'));
    },
  );
  test('completion uses subcommands, aliases and args options', () {
    console.addCommand(
      ConsoleCommand(
        name: 'roles',
        subcommands: [
          ConsoleCommand(
            name: 'list',
            aliases: ['ls'],
            parser: ArgParser()..addFlag('all', negatable: false),
            run: (_) {},
          ),
        ],
      ),
    );
    expect(console.complete('ROLES l'), ['list', 'ls']);
    expect(console.complete('help roles l'), ['list', 'ls']);
    expect(console.complete('roles list --a'), ['--all']);
  });
  test('nonterminal output has neither prompts nor ANSI sequences', () async {
    await console.execute('help');
    console.print('message', level: LogLevel.info);
    expect(output.toString(), isNot(contains('\x1B')));
    expect(output.toString(), isNot(matches(RegExp(r'^> ', multiLine: true))));
  });

  group('modules', () {
    test('install and remove only owned registrations', () async {
      console.command('own', run: (_) {});
      await console.install(
        TestModule(
          'demo',
          commands: [
            ConsoleCommand(
              name: 'demo',
              aliases: ['d'],
              run: (ctx) {
                ctx.write('Hello Ada');
              },
            ),
          ],
        ),
      );
      await console.execute('D');
      expect(output.toString(), contains('Hello Ada'));
      expect(() => console.unregisterProgram('d'), throwsStateError);
      await console.uninstall('demo');
      expect(console.commands.map((c) => c.name), contains('own'));
      expect((await console.execute('d')).status, CommandStatus.unknown);
    });
    test('collisions are checked before load', () async {
      var loaded = false;
      await expectLater(
        console.install(
          TestModule(
            'bad',
            commands: [ConsoleCommand(name: 'HELP')],
            load: () {
              loaded = true;
            },
          ),
        ),
        throwsStateError,
      );
      expect(loaded, isFalse);
      expect(console.modules, isEmpty);
    });
    test('failed loading cleans resources and publishes nothing', () async {
      var cleaned = false;
      await expectLater(
        console.install(
          TestModule(
            'bad',
            commands: [ConsoleCommand(name: 'new')],
            load: () {
              throw StateError('load');
            },
            unload: () {
              cleaned = true;
            },
          ),
        ),
        throwsStateError,
      );
      expect(cleaned, isTrue);
      expect(console.commands.map((c) => c.name), isNot(contains('new')));
      expect(console.modules, isEmpty);
    });
    test('dependencies prevent premature removal', () async {
      await expectLater(
        console.install(TestModule('child', dependencies: ['base'])),
        throwsStateError,
      );
      await console.install(TestModule('base'));
      await console.install(TestModule('child', dependencies: ['base']));
      await expectLater(console.uninstall('base'), throwsStateError);
      await console.uninstall('child');
      await console.uninstall('base');
    });
    test('concurrent installs check collisions in sequence', () async {
      final gate = Completer<void>();
      final one = console.install(
        TestModule(
          'one',
          commands: [ConsoleCommand(name: 'same')],
          load: () => gate.future,
        ),
      );
      final two = console.install(
        TestModule('two', commands: [ConsoleCommand(name: 'SAME')]),
      );
      final rejected = expectLater(two, throwsStateError);
      gate.complete();
      await one;
      await rejected;
      expect(console.modules.map((m) => m.id), ['one']);
    });
    test(
      'dispose unloads in reverse order and continues after failures',
      () async {
        final order = <String>[];
        await console.install(
          TestModule(
            'one',
            unload: () {
              order.add('one');
            },
          ),
        );
        await console.install(
          TestModule(
            'two',
            unload: () {
              order.add('two');
              throw StateError('cleanup');
            },
          ),
        );
        await expectLater(console.dispose(), throwsStateError);
        expect(order, ['two', 'one']);
        // Replace for tearDown: repeated disposal preserves its original outcome.
        console = Consoler(output: output);
      },
    );
  });

  test('injected input is sequential and start ends at EOF', () async {
    final values = <String>[];
    final piped = Consoler(
      output: output,
      input: Stream.fromIterable(['echo one', 'echo two']),
    );
    addTearDown(piped.dispose);
    piped.command(
      'echo',
      run: (ctx) {
        values.add(ctx.args.single);
      },
    );
    await piped.start();
    expect(values, ['one', 'two']);
    expect(piped.isRunning, isFalse);
  });
  test('a command can stop its own session without deadlocking', () async {
    final input = StreamController<String>();
    final piped = Consoler(output: output, input: input.stream);
    addTearDown(input.close);
    addTearDown(piped.dispose);
    piped.command('stop', run: (_) => piped.stop());
    final session = piped.start();
    input.add('stop');
    await session.timeout(const Duration(seconds: 2));
  });

  group('concurrent lifecycle', () {
    test('external module installation queues behind a running hook', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final first = console.install(
        TestModule(
          'first',
          load: () async {
            entered.complete();
            await release.future;
          },
        ),
      );
      await entered.future;
      final second = console.install(TestModule('second'));
      release.complete();
      await Future.wait([first, second]);
      expect(console.modules.map((module) => module.id), ['first', 'second']);
    });

    test(
      'external disposal waits for initialization and cleans it up',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        var cleaned = false;
        final installation = console.install(
          TestModule(
            'loading',
            load: () async {
              entered.complete();
              await release.future;
            },
            unload: () {
              cleaned = true;
            },
          ),
        );
        await entered.future;
        final disposal = console.dispose();
        release.complete();
        await installation;
        await disposal;
        expect(cleaned, isTrue);
      },
    );

    test(
      'external disposal waits for the active handler before unloading',
      () async {
        final entered = Completer<void>();
        final release = Completer<void>();
        var cleaned = false;
        await console.install(
          TestModule(
            'busy',
            commands: [
              ConsoleCommand(
                name: 'wait',
                run: (_) async {
                  entered.complete();
                  await release.future;
                  expect(cleaned, isFalse);
                },
              ),
            ],
            unload: () {
              cleaned = true;
            },
          ),
        );
        final execution = console.execute('wait');
        await entered.future;
        await expectLater(console.uninstall('busy'), throwsStateError);
        final disposal = console.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(cleaned, isFalse);
        release.complete();
        await execution;
        await disposal;
        expect(cleaned, isTrue);
      },
    );

    test('a hook cannot dispose its own console and deadlock', () async {
      await expectLater(
        console.install(TestModule('invalid', load: () => console.dispose())),
        throwsStateError,
      );
      expect(console.modules, isEmpty);
    });
  });

  group('editor', () {
    late ConsoleLineEditor editor;
    late List<String> lines;
    late List<String> history;
    setUp(() {
      lines = [];
      history = [];
      editor = ConsoleLineEditor(
        output: output,
        prefix: '> ',
        history: history,
        historyLimit: 2,
        complete: console.complete,
        onLine: lines.add,
        onClose: () {},
      );
    });
    test('edits at cursor and handles split escape sequences', () {
      editor.add('helo\x1B[');
      editor.add('D');
      editor.add('l\r\n');
      expect(lines, ['hello']);
    });
    test('history preserves draft and stays bounded', () {
      editor.add('one\rtwo\rthree\r');
      expect(history, ['two', 'three']);
      editor.add('draft\x1B[A');
      expect(editor.line, 'three');
      editor.add('\x1B[B');
      expect(editor.line, 'draft');
    });
    test('logs retain input and completion uses registered commands', () {
      console.command('players', run: (_) {});
      editor.add('pla\t');
      expect(editor.line, 'players ');
      editor.log('incoming log');
      expect(editor.line, 'players ');
      expect(output.toString(), contains('incoming log'));
    });
    test('Unicode editing removes codepoints without splitting UTF-16', () {
      editor.add('ä🙂\x7F\r');
      expect(lines, ['ä']);
    });
  });
}
