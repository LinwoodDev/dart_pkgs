import 'package:consoler/consoler.dart';

Future<void> main(List<String> arguments) async {
  final console = Consoler(
    description: 'Consoler example',
    ignoreCase: true,
  );
  console.command(
    'echo',
    description: 'Print a message.',
    usage: '<text...>',
    aliases: ['repeat'],
    examples: ['echo --upper "Hello world"'],
    minArgs: 1,
    parser: ArgParser()
      ..addFlag(
        'upper',
        abbr: 'u',
        negatable: false,
        help: 'Print in uppercase.',
      ),
    run: (context) {
      final message = context.args.join(' ');
      context.write(
        context.options!['upper'] as bool ? message.toUpperCase() : message,
      );
    },
  );
  console.command(
    'exit',
    description: 'Close this console.',
    run: (_) => console.stop(),
  );
  try {
    await console.start();
  } finally {
    await console.dispose();
  }
}
