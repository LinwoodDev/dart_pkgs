part of '../theme.dart';

enum TextType {
  h1("h1"),
  h2("h2"),
  h3("h3"),
  h4("h4"),
  h5("h5"),
  h6("h6"),
  subtitle1("p"),
  subtitle2("p"),
  body1("p"),
  body2("p"),
  primary("p"),
  caption("p"),
  overline("p");

  final String tag;

  const TextType(this.tag);
}

Map<TextType, StylesBuilder> getDefaultTextStyles() => {
      TextType.h1: (theme) => Styles.text(
            fontWeight: FontWeight.w300,
            fontSize: Unit.pixels(32),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.h2: (theme) => Styles.text(
            fontWeight: FontWeight.w300,
            fontSize: Unit.pixels(24),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.h3: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(20),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.h4: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(18),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.h5: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(16),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.h6: (theme) => Styles.text(
            fontWeight: FontWeight.w500,
            fontSize: Unit.pixels(14),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.subtitle1: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(16),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.subtitle2: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(14),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.body1: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(16),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.body2: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(14),
            color: theme.colors[ThemeColors.surface],
          ),
      TextType.primary: (theme) => Styles.text(
            fontWeight: FontWeight.w500,
            fontSize: Unit.pixels(14),
            color: theme.colors[ThemeColors.primary],
          ),
      TextType.caption: (theme) => Styles.text(
            fontWeight: FontWeight.w400,
            fontSize: Unit.pixels(12),
            color: theme.colors[ThemeColors.caption],
          ),
    };
