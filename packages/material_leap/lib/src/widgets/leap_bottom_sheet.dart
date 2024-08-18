import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

/// Show a Bottom Sheet with a title, actions and children
Future<T?> showLeapBottomSheet<T>({
  required BuildContext context,
  String title = '',
  bool centerTitle = false,
  Widget Function(BuildContext, Widget child)? builder,
  Widget? leading,
  Widget? trailing,
  List<Widget>? actions,
  List<Widget>? children,
  double? toolbarHeight,
  double? spacing,
  bool isDismissible = true,
}) =>
    showModalBottomSheet<T>(
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
                title: Text(
                  title,
                  textAlign: TextAlign.center,
                ),
                leading: leading,
                trailing: trailing,
                actions: actions,
                toolbarHeight: toolbarHeight,
                spacing: spacing,
              ),
              ...?children,
            ],
          ),
        );
        child = builder?.call(ctx, child) ?? child;
        return child;
      },
    );
