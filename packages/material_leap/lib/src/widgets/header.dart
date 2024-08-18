import 'package:flutter/material.dart';

class Header extends StatelessWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final Widget title;
  final bool centerTitle;
  final double? spacing, toolbarHeight, leadingWidth;

  const Header({
    super.key,
    this.leading,
    this.actions,
    this.spacing,
    this.toolbarHeight,
    this.leadingWidth,
    this.centerTitle = true,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final double toolbarHeight = this.toolbarHeight ??
        Theme.of(context).appBarTheme.toolbarHeight ??
        kToolbarHeight;
    final iconTheme =
        Theme.of(context).appBarTheme.iconTheme ?? Theme.of(context).iconTheme;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: toolbarHeight),
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
                data: iconTheme,
                child: ConstrainedBox(
                    constraints: BoxConstraints.tightFor(
                        width: leadingWidth ?? kToolbarHeight),
                    child: Center(child: leading!))),
        trailing: actions == null
            ? null
            : IconTheme(
                data: iconTheme,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: actions!,
                ),
              ),
      ),
    );
  }
}
