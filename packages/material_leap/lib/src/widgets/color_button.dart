import 'package:flutter/material.dart';
import 'package:material_leap/helpers.dart';

class ColorButton extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback? onTap, onLongPress, onSecondaryTap;
  final double? size;

  const ColorButton({
    super.key,
    required this.color,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.size,
  });

  ColorButton.srgb({
    super.key,
    required SRGBColor color,
    this.selected = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.size,
  }) : color = color.toColor();

  @override
  Widget build(BuildContext context) {
    Widget child = AnimatedContainer(
      height: size,
      width: size,
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 4,
        ),
      ),
    );
    if (size == null) {
      child = AspectRatio(aspectRatio: 1, child: child);
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
