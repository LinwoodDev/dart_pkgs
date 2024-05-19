import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class ResponsiveDialog extends StatelessWidget {
  final int breakpoint;
  final Widget child;
  final BoxConstraints? constraints;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.breakpoint = LeapBreakpoints.compact,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final currentSize = MediaQuery.sizeOf(context).width;
    if (currentSize < breakpoint) {
      return Dialog.fullscreen(
        child: child,
      );
    } else {
      return Dialog(
        child: constraints == null
            ? child
            : ConstrainedBox(
                constraints: constraints!,
                child: child,
              ),
      );
    }
  }
}
