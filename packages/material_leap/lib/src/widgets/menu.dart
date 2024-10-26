import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

extension MenuControllerToggleExtension on MenuController {
  void toggle({Offset? position}) =>
      isOpen ? close() : open(position: position);
}

Widget _offsetCalculator(
  BuildContext context,
  Widget Function(Offset? Function() offset) builder, {
  bool calculateLocalOffset = true,
}) {
  if (!calculateLocalOffset) {
    return builder(() => null);
  }
  return Builder(builder: (currentContext) {
    return builder(() {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      return renderBox.globalToLocal(Offset.zero,
          ancestor: currentContext.findRenderObject());
    });
  });
}

MenuAnchorChildBuilder defaultMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
}) =>
    (context, controller, child) => _offsetCalculator(
        context,
        (offset) => IconButton(
              icon: iconBuilder?.call(context, controller, child) ??
                  icon ??
                  const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
              tooltip: tooltip,
              isSelected:
                  (selectedOnOpen && controller.isOpen) ? true : isSelected,
              onPressed:
                  enabled ? () => controller.toggle(position: offset()) : null,
            ),
        calculateLocalOffset: calculateLocalOffset);

MenuAnchorChildBuilder defaultFilledMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
}) =>
    (context, controller, child) => _offsetCalculator(
        context,
        (offset) => IconButton.filled(
              icon: iconBuilder?.call(context, controller, child) ??
                  icon ??
                  const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
              tooltip: tooltip,
              isSelected:
                  (selectedOnOpen && controller.isOpen) ? true : isSelected,
              onPressed:
                  enabled ? () => controller.toggle(position: offset()) : null,
            ),
        calculateLocalOffset: calculateLocalOffset);

MenuAnchorChildBuilder defaultFilledTonalMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
}) =>
    (context, controller, child) => _offsetCalculator(
          context,
          (offset) => IconButton.filledTonal(
            icon: iconBuilder?.call(context, controller, child) ??
                icon ??
                const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
            tooltip: tooltip,
            isSelected:
                (selectedOnOpen && controller.isOpen) ? true : isSelected,
            onPressed:
                enabled ? () => controller.toggle(position: offset()) : null,
          ),
          calculateLocalOffset: calculateLocalOffset,
        );

MenuAnchorChildBuilder defaultOutlinedMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
}) =>
    (context, controller, child) => _offsetCalculator(
          context,
          (offset) => IconButton.outlined(
            icon: iconBuilder?.call(context, controller, child) ??
                icon ??
                const PhosphorIcon(PhosphorIconsLight.dotsThreeVertical),
            tooltip: tooltip,
            isSelected:
                (selectedOnOpen && controller.isOpen) ? true : isSelected,
            onPressed:
                enabled ? () => controller.toggle(position: offset()) : null,
          ),
          calculateLocalOffset: calculateLocalOffset,
        );
