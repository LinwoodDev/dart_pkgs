import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class ResponsiveDialog extends StatelessWidget {
  final double breakpoint;
  final Widget child;
  final BoxConstraints? constraints;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.breakpoint = LeapBreakpoints.compact,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final currentSize = MediaQuery.sizeOf(context).width;
    if (currentSize < breakpoint) {
      return Dialog.fullscreen(
        child: child,
      );
    } else {
      return Dialog(
        child: constraints == null
            ? child
            : ConstrainedBox(
                constraints: constraints!,
                child: child,
              ),
      );
    }
  }
}

class ResponsiveAlertDialog extends StatelessWidget {
  final double breakpoint;
  final Widget title, content;
  final Widget? leading;
  final BoxConstraints? constraints;
  final List<Widget>? actions, headerActions;
  final MainAxisAlignment? actionsAlignment;
  final OverflowBarAlignment? actionsOverflowAlignment;
  final double? actionsOverflowButtonSpacing;
  final EdgeInsets? actionsPadding, contentPadding;
  final VerticalDirection? actionsOverflowDirection;
  final EdgeInsetsGeometry? buttonPadding;

  const ResponsiveAlertDialog({
    super.key,
    required this.content,
    this.breakpoint = LeapBreakpoints.compact,
    this.constraints,
    this.actions,
    this.actionsAlignment,
    this.actionsOverflowAlignment,
    this.actionsOverflowButtonSpacing,
    this.actionsOverflowDirection,
    this.buttonPadding,
    this.actionsPadding,
    this.headerActions,
    this.leading,
    required this.title,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = (buttonPadding?.horizontal ?? 16) / 2;
    final dialogTheme = DialogTheme.of(context);
    return ResponsiveDialog(
      breakpoint: breakpoint,
      constraints: constraints,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Header(
                  title: title,
                  actions: headerActions ?? [],
                  leading: leading,
                ),
                Flexible(
                    child: Padding(
                  padding: contentPadding ?? const EdgeInsets.all(16.0),
                  child: content,
                )),
              ],
            ),
          ),
          if (actions != null)
            Padding(
              padding: actionsPadding ??
                  dialogTheme.actionsPadding ??
                  const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
              child: OverflowBar(
                alignment: actionsAlignment ?? MainAxisAlignment.end,
                spacing: spacing,
                overflowAlignment:
                    actionsOverflowAlignment ?? OverflowBarAlignment.end,
                overflowDirection:
                    actionsOverflowDirection ?? VerticalDirection.down,
                overflowSpacing: actionsOverflowButtonSpacing ?? 0,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}
