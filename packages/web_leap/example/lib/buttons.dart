import 'package:jaspr/jaspr.dart';
import 'package:web_leap/web_leap.dart';

class ButtonShowcaseComponent extends StatelessComponent {
  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield TextComponent.h2("Button Showcase");
  }
}
