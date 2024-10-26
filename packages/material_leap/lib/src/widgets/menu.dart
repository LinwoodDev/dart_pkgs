import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

extension MenuControllerToggleExtension on MenuController {
  void toggle({Offset? position}) =>
      isOpen ? close() : open(position: position);
}

Widget offsetCalculator(
  BuildContext context,
  Widget Function(Offset? Function() offset) builder, {
  bool calculateLocalOffset = true,
  AlignmentGeometry? alignment = Alignment.topRight,
}) {
  if (!calculateLocalOffset) {
    return builder(() => null);
  }
  return Builder(builder: (currentContext) {
    return builder(() {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final currentRender = currentContext.findRenderObject();
      final offset = renderBox.globalToLocal(Offset.zero,
          ancestor: currentContext.findRenderObject());
      if (alignment != null && currentRender is RenderBox) {
        final size = currentRender.size;
        final alignmentOffset = alignment.resolve(Directionality.of(context));
        return offset + alignmentOffset.alongSize(size);
      } else {
        return offset;
      }
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
  AlignmentGeometry? alignment = Alignment.topRight,
}) =>
    (context, controller, child) => offsetCalculator(
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
          calculateLocalOffset: calculateLocalOffset,
          alignment: alignment,
        );

MenuAnchorChildBuilder defaultFilledMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
  AlignmentGeometry? alignment = Alignment.topRight,
}) =>
    (context, controller, child) => offsetCalculator(
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
          calculateLocalOffset: calculateLocalOffset,
          alignment: alignment,
        );

MenuAnchorChildBuilder defaultFilledTonalMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
  AlignmentGeometry? alignment = Alignment.topRight,
}) =>
    (context, controller, child) => offsetCalculator(
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
          alignment: alignment,
        );

MenuAnchorChildBuilder defaultOutlinedMenuButton({
  Widget? icon,
  MenuAnchorChildBuilder? iconBuilder,
  bool enabled = true,
  bool? isSelected,
  bool selectedOnOpen = true,
  String? tooltip,
  bool calculateLocalOffset = false,
  AlignmentGeometry? alignment = Alignment.topRight,
}) =>
    (context, controller, child) => offsetCalculator(
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
          alignment: alignment,
        );
