import 'package:jaspr/jaspr.dart';

import '../theme.dart';

class ThemeComponent extends InheritedComponent {
  final LeapTheme theme;

  const ThemeComponent({required this.theme, required super.child});

  static LeapTheme of(BuildContext context) {
    return context
        .dependOnInheritedComponentOfExactType<ThemeComponent>()!
        .theme;
  }

  @override
  bool updateShouldNotify(covariant ThemeComponent oldComponent) {
    return oldComponent.theme != theme;
  }
}
