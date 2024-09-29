import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
    BuildContext context, bool isFullWidth);

class ResponsiveDialog extends StatelessWidget {
  final double breakpoint;
  final Widget? child;
  final ResponsiveWidgetBuilder? builder;
  final BoxConstraints? constraints;

  const ResponsiveDialog({
    super.key,
    this.child,
    this.builder,
    this.breakpoint = LeapBreakpoints.compact,
    this.constraints,
  }) : assert(
            (child == null && builder != null) ||
                (child != null && builder == null),
            'Either child or builder must be provided');

  @override
  Widget build(BuildContext context) {
    final currentSize = MediaQuery.sizeOf(context).width;
    if (currentSize < breakpoint) {
      return Dialog.fullscreen(
        child: builder?.call(context, true) ?? child,
      );
    } else {
      final content = builder?.call(context, false) ?? child;
      return Dialog(
        child: constraints == null
            ? content
            : ConstrainedBox(
                constraints: constraints!,
                child: content,
              ),
      );
    }
  }
}

class ResponsiveAlertDialog extends StatelessWidget {
  final double breakpoint;
  final Widget title;
  final Widget? content;
  final ResponsiveWidgetBuilder? contentBuilder;
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
    this.content,
    this.contentBuilder,
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
  }) : assert(
            (content == null && contentBuilder != null) ||
                (content != null && contentBuilder == null),
            'Either content or contentBuilder must be provided');

  @override
  Widget build(BuildContext context) {
    final spacing = (buttonPadding?.horizontal ?? 16) / 2;
    final dialogTheme = DialogTheme.of(context);
    return ResponsiveDialog(
      breakpoint: breakpoint,
      constraints: constraints,
      builder: (context, isFullWidth) => Column(
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
                  child: Builder(
                    builder: (context) =>
                        contentBuilder?.call(context, isFullWidth) ??
                        content ??
                        const SizedBox(),
                  ),
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
