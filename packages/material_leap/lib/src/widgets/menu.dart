import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

extension MenuControllerToggleExtension on MenuController {
  void toggle({Offset? position}) =>
      isOpen ? close() : open(position: position);
}

MenuAnchorChildBuilder defaultMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  String? tooltip,
}) =>
    (context, controller, child) => IconButton(
          icon: iconBuilder?.call(context, controller, child) ??
              icon ??
              const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
          tooltip: tooltip,
          isSelected: isSelected,
          onPressed: enabled ? controller.toggle : null,
        );

MenuAnchorChildBuilder defaultFilledMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  String? tooltip,
}) =>
    (context, controller, child) => IconButton.filled(
          icon: iconBuilder?.call(context, controller, child) ??
              icon ??
              const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
          tooltip: tooltip,
          isSelected: isSelected,
          onPressed: enabled ? controller.toggle : null,
        );

MenuAnchorChildBuilder defaultFilledTonalMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  String? tooltip,
}) =>
    (context, controller, child) => IconButton.filledTonal(
          icon: iconBuilder?.call(context, controller, child) ??
              icon ??
              const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
          tooltip: tooltip,
          isSelected: isSelected,
          onPressed: enabled ? controller.toggle : null,
        );

MenuAnchorChildBuilder defaultOutlinedMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  String? tooltip,
}) =>
    (context, controller, child) => IconButton.outlined(
          icon: iconBuilder?.call(context, controller, child) ??
              icon ??
              const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
          tooltip: tooltip,
          isSelected: isSelected,
          onPressed: enabled ? controller.toggle : null,
        );
