import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

MenuAnchorChildBuilder defaultMenuButton({
  Widget? icon,
  bool enabled = true,
  bool? isSelected,
  String? tooltip,
}) =>
    (context, controller, child) => IconButton(
          icon:
              icon ?? const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
          tooltip: tooltip,
          isSelected: isSelected,
          onPressed: enabled
              ? () => controller.isOpen ? controller.close() : controller.open()
              : null,
        );
