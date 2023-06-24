part of '../theme.dart';

enum ButtonType { primary, outline, text }

enum ButtonState { enabled, disabled, hover, focus, pressed }

Map<ButtonType, Map<ButtonState, StylesBuilder>> getDefaultButtonStyles() => {
      ButtonType.text: {
        ButtonState.enabled: (theme) => Styles.combine([
              Styles.text(
                color: theme.colors[ThemeColors.primary],
              ),
              Styles.box(
                transition: Transition('all', duration: 100),
              ),
            ]),
        ButtonState.disabled: (theme) => Styles.text(
              color: theme.colors[ThemeColors.caption],
            ),
        ButtonState.hover: (theme) => Styles.text(
              color: theme.colors[ThemeColors.primary],
            ),
        ButtonState.focus: (theme) => Styles.combine([
              Styles.text(
                color: theme.colors[ThemeColors.primary],
              ),
              Styles.box(
                outline: Outline(
                  color: theme.colors[ThemeColors.primary],
                  width: OutlineWidth(2.px),
                ),
              ),
            ]),
        ButtonState.pressed: (theme) => Styles.combine([
              Styles.text(
                color: theme.colors[ThemeColors.primary],
              ),
              Styles.box(
                outline: Outline(
                  color: theme.colors[ThemeColors.primary],
                  width: OutlineWidth(1.px),
                ),
              ),
            ]),
      },
    };
