import 'package:flutter/material.dart';

class BoxTile extends StatelessWidget {
  final Widget title, icon;
  final double size, selectionWidth, selectionRadius;
  final bool selected;
  final GestureTapCallback? onTap;

  const BoxTile({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.size = 100,
    this.selected = false,
    this.selectionWidth = 4,
    this.selectionRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAliasWithSaveLayer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(selectionRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(selectionRadius),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
                width: selectionWidth,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(selectionRadius),
          ),
          child: SizedBox.square(
            dimension: size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: IconTheme(
                    data: Theme.of(context).iconTheme.copyWith(size: 32),
                    child: icon,
                  ),
                ),
                const SizedBox(height: 16),
                title,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
