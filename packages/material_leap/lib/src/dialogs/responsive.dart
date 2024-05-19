import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class ResponsiveDialog extends StatelessWidget {
  final int breakpoint;
  final Widget child;

  const ResponsiveDialog({
    super.key,
    required this.child,
    this.breakpoint = LeapBreakpoints.compact,
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
        child: child,
      );
    }
  }
}

Future<void> showResponsiveDialog({
  required BuildContext context,
  required Widget child,
  int breakpoint = LeapBreakpoints.compact,
}) {
  return showDialog(
    context: context,
    builder: (context) {
      return ResponsiveDialog(
        breakpoint: breakpoint,
        child: child,
      );
    },
  );
}
