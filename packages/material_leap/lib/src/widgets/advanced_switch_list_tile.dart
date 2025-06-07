import 'package:flutter/material.dart';

/// A List Tile with a Switch with an separated clickable area for the ListTile
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
    final child = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Align(
            child: ListTile(
              title: title,
              subtitle: subtitle,
              onTap: onTap,
              onLongPress: onLongPress,
              leading: leading,
              trailing: trailing,
              selected: selected ?? value,
            ),
          ),
        ),
        const VerticalDivider(),
        Switch(value: value, onChanged: onChanged),
      ],
    );
    if (height != null) {
      return SizedBox(height: height, child: child);
    } else {
      return IntrinsicHeight(child: child);
    }
  }
}
