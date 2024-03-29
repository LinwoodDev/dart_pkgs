import 'package:flutter/material.dart';

/// Show a Bottom Sheet with a title, actions and children
Future<T?> showLeapBottomSheet<T>({
  required BuildContext context,
  String title = '',
  List<Widget> Function(BuildContext)? actionsBuilder,
  List<Widget> Function(BuildContext)? childrenBuilder,
  bool isDismissible = true,
}) =>
    showModalBottomSheet<T>(
      constraints: const BoxConstraints(maxWidth: 640),
      context: context,
      showDragHandle: true,
      isDismissible: isDismissible,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ...actionsBuilder?.call(ctx) ?? [],
                ],
              ),
            ),
            ...childrenBuilder?.call(ctx) ?? [],
          ],
        ),
      ),
    );
