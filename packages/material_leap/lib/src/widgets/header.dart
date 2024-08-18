import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Widget? leading, trailing;
  final List<Widget>? actions;
  final Widget title;
  final EdgeInsetsGeometry? padding;
  final bool centerTitle;
  final double? spacing;

  const Header({
    super.key,
    this.leading,
    this.trailing,
    this.actions,
    this.padding,
    this.spacing,
    this.centerTitle = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: NavigationToolbar(
        middle: DefaultTextStyle(
          style: Theme.of(context).textTheme.headlineSmall ??
              const TextStyle(fontSize: 20),
          textAlign: centerTitle ? TextAlign.center : null,
          child: title,
        ),
        centerMiddle: centerTitle,
        middleSpacing: spacing ?? 16,
        leading: leading == null
            ? null
            : IconTheme(
                data: Theme.of(context).appBarTheme.iconTheme ??
                    Theme.of(context).iconTheme,
                child: leading!),
        trailing: trailing == null || actions == null
            ? null
            : IconTheme(
                data: Theme.of(context).appBarTheme.iconTheme ??
                    Theme.of(context).iconTheme,
                child: actions == null
                    ? trailing!
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!,
                      ),
              ),
      ),
    );
  }
}
