import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final List<Widget> actions;
  const Header({
    super.key,
    this.leading,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        if (leading != null) ...[
          IconTheme(
              data: Theme.of(context).appBarTheme.iconTheme ??
                  Theme.of(context).iconTheme,
              child: leading!),
          const SizedBox(width: 16),
        ],
        Expanded(
          child: DefaultTextStyle(
              style: Theme.of(context).textTheme.headlineSmall ??
                  const TextStyle(fontSize: 20),
              child: title),
        ),
        if (actions.isNotEmpty) ...[
          const SizedBox(width: 16),
          ...actions,
        ],
      ]),
    );
  }
}
