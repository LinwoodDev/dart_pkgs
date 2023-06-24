import 'package:jaspr/components.dart';
import 'package:web_leap/components/theme.dart';
import 'package:web_leap/theme.dart';

class ButtonComponent extends StatelessComponent {
  final VoidCallback? onPressed;
  final String label;

  ButtonComponent({required this.label, required this.onPressed});

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield DomComponent(
      tag: 'button',
      child: Text(label),
      styles: Styles.,
    );
  }
}
