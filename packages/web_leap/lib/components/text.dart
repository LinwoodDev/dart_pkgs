import 'package:jaspr/components.dart';
import 'package:jaspr/jaspr.dart';

import '../theme.dart';

class TextComponent extends StatelessComponent {
  final TextType? type;
  final String text;

  TextComponent({this.type, required this.text});
  TextComponent.h1(this.text) : type = TextType.h1;
  TextComponent.h2(this.text) : type = TextType.h2;
  TextComponent.h3(this.text) : type = TextType.h3;
  TextComponent.h4(this.text) : type = TextType.h4;
  TextComponent.h5(this.text) : type = TextType.h5;
  TextComponent.h6(this.text) : type = TextType.h6;
  TextComponent.subtitle1(this.text) : type = TextType.subtitle1;
  TextComponent.subtitle2(this.text) : type = TextType.subtitle2;
  TextComponent.body1(this.text) : type = TextType.body1;
  TextComponent.body2(this.text) : type = TextType.body2;
  TextComponent.primary(this.text) : type = TextType.primary;
  TextComponent.caption(this.text) : type = TextType.caption;
  TextComponent.overline(this.text) : type = TextType.overline;
  TextComponent.unstyled(this.text) : type = null;

  @override
  Iterable<Component> build(BuildContext context) sync* {
    yield DomComponent(
      tag: type?.tag ?? 'p',
      child: Text(text),
    );
  }
}
