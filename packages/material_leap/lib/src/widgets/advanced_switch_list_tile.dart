import 'package:flutter/material.dart';

/// A list tile with separate clickable areas for its content and switch.
class AdvancedSwitchListTile extends StatelessWidget {
  final Widget? leading, trailing;
  final Widget? title;
  final Widget? subtitle;
  final bool? selected;
  final bool value;
  final GestureTapCallback? onTap;
  final GestureLongPressCallback? onLongPress;
  final ValueChanged<bool>? onChanged;
  final double? height;

  const AdvancedSwitchListTile({
    super.key,
    this.leading,
    this.trailing,
    this.title,
    this.subtitle,
    this.selected = false,
    required this.value,
    this.onTap,
    this.onLongPress,
    this.onChanged,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final child = ListTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      onLongPress: onLongPress,
      leading: leading,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?trailing,
          const SizedBox(height: 32, child: VerticalDivider()),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
      selected: selected ?? value,
    );
    if (height != null) {
      return SizedBox(height: height, child: child);
    }
    return child;
  }
}
