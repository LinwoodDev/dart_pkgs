import 'package:jaspr/jaspr.dart';

part '../styles/button.dart';
part '../styles/text.dart';

class LeapTheme {
  final Map<ThemeColors, Color> colors;
  final Map<TextType, StylesBuilder> textStyles;
  final Map<ButtonType, Map<ButtonState, StylesBuilder>> buttonStyles;

  LeapTheme({
    this.colors = kDefaultColors,
    Map<TextType, StylesBuilder> kDefaultTextStyles = const {},
    Map<ButtonType, Map<ButtonState, StylesBuilder>> kDefaultButtonStyles =
        const {},
  })  : textStyles = {...getDefaultTextStyles(), ...kDefaultTextStyles},
        buttonStyles = {...getDefaultButtonStyles(), ...kDefaultButtonStyles};
}

enum ThemeColors { primary, background, surface, caption, error }

typedef StylesBuilder = Styles Function(LeapTheme theme);

const kDefaultColors = <ThemeColors, Color>{
  ThemeColors.primary: Color.hex("#35EF53"),
  ThemeColors.background: Color.hex("#282c34"),
  ThemeColors.surface: Color.hex("#FFFFFF"),
  ThemeColors.caption: Color.hex("#9E9E9E"),
  ThemeColors.error: Color.hex("#B00020"),
};
