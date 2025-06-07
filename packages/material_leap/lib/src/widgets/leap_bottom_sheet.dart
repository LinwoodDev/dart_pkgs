import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

/// Show a Bottom Sheet with a title, actions and children
Future<T?> showLeapBottomSheet<T>({
  required BuildContext context,
  bool centerTitle = true,
  Widget Function(BuildContext, Widget child)? builder,
  WidgetBuilder? leadingBuilder,
  WidgetBuilder? titleBuilder,
  List<Widget> Function(BuildContext)? actionsBuilder,
  List<Widget> Function(BuildContext)? childrenBuilder,
  double? toolbarHeight,
  double? spacing,
  double? leadingWidth,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  constraints: const BoxConstraints(maxWidth: 640),
  context: context,
  showDragHandle: true,
  isDismissible: isDismissible,
  isScrollControlled: true,
  builder: (ctx) {
    Widget child = Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ListView(
        shrinkWrap: true,
        children: [
          Header(
            title: titleBuilder?.call(ctx) ?? const SizedBox(),
            leading: leadingBuilder?.call(ctx),
            leadingWidth: leadingWidth,
            actions: actionsBuilder?.call(ctx),
            toolbarHeight: toolbarHeight,
            spacing: spacing,
            centerTitle: centerTitle,
          ),
          ...?childrenBuilder?.call(ctx),
        ],
      ),
    );
    child = builder?.call(ctx, child) ?? child;
    return child;
  },
);
