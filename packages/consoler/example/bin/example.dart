import 'package:consoler/consoler.dart';
import 'package:example/example.dart';

Future<void> main(List<String> arguments) async {
  final consoler = Consoler(
    defaultProgramConfig:
        DefaultProgramConfiguration(description: 'Consoler example'),
  );
  consoler.registerProgram('nothing', NothingProgram());
  consoler.registerProgram('warn', WarningProgram(consoler));
  consoler.run();
  for (var i = 10; i >= 0; i--) {
    consoler.print('Countdown: $i');
    await Future.delayed(Duration(seconds: 1));
  }
}
