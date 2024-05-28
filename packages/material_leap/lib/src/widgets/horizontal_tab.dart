import 'package:flutter/material.dart';

class HorizontalTab extends StatelessWidget {
  final Widget? icon;
  final Widget label;

  const HorizontalTab({
    super.key,
    this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8),
          ],
          label,
        ],
      ),
    );
  }
}
