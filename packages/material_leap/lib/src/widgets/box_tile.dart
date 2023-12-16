import 'package:flutter/material.dart';

class BoxTile extends StatelessWidget {
  final Widget title, icon;
  final Widget? subtitle, leading, trailing;
  final double size, selectionWidth, selectionRadius;
  final bool selected;
  final GestureTapCallback? onTap;

  const BoxTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    required this.icon,
    this.onTap,
    this.size = 128,
    this.selected = false,
    this.selectionWidth = 4,
    this.selectionRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Align(
        child: SizedBox.square(
          dimension: size,
          child: Card(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(selectionRadius),
            ),
            child: Stack(
              children: [
                SizedBox.square(
                  dimension: size,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconTheme(
                            data:
                                Theme.of(context).iconTheme.copyWith(size: 32),
                            child: icon,
                          ),
                          Column(
                            children: [
                              DefaultTextStyle(
                                style: Theme.of(context).textTheme.bodySmall!,
                                child: subtitle ?? const SizedBox(),
                              ),
                              title,
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (leading != null)
                  Align(
                    alignment: Alignment.topLeft,
                    child: leading!,
                  ),
                if (trailing != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: trailing!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
