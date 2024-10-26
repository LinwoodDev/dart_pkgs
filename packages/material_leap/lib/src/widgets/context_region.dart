import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

typedef ContextRegionChildBuilder = Widget Function(
    BuildContext context, Widget button, MenuController controller);
typedef ContextRegionChildrenBuidler = List<ContextMenuButtonItem>? Function(
    BuildContext context);
typedef ContextRegionButtonBuilder = Widget Function(
    BuildContext context, MenuController controller);

class ContextRegion extends StatefulWidget {
  final ContextRegionChildBuilder builder;
  final List<Widget> menuChildren;
  final Widget? icon;
  final MenuAnchorChildBuilder? buttonBuilder;
  final String? tooltip;

  const ContextRegion({
    super.key,
    this.icon,
    this.buttonBuilder,
    this.tooltip,
    required this.builder,
    required this.menuChildren,
  });

  @override
  State<ContextRegion> createState() => _ContextRegionState();
}

class _ContextRegionState extends State<ContextRegion> {
  Offset? _longPressOffset;
  final GlobalKey _buttonKey = GlobalKey();
  final MenuController _menuController = MenuController();

  static bool get _longPressEnabled {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.macOS:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  void _onSecondaryTapUp(TapUpDetails details) {
    _show(details.globalPosition);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _longPressOffset = details.globalPosition;
  }

  void _onLongPress() {
    assert(_longPressOffset != null);
    _show(_longPressOffset!);
    _longPressOffset = null;
  }

  void _show([Offset? position]) {
    if (position != null) {
      final RenderBox renderBox =
          _buttonKey.currentContext?.findRenderObject() as RenderBox;

      position = renderBox.globalToLocal(position);
    }
    _menuController.open(position: position);
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      menuChildren: widget.menuChildren,
      key: _buttonKey,
      builder: (context, controller, child) => GestureDetector(
        onSecondaryTapUp: _onSecondaryTapUp,
        onLongPress: _longPressEnabled ? _onLongPress : null,
        onLongPressStart: _longPressEnabled ? _onLongPressStart : null,
        child: widget.builder(
            context,
            widget.buttonBuilder?.call(context, controller, null) ??
                defaultMenuButton(calculateLocalOffset: true)(
                    context, controller, null),
            controller),
      ),
    );
  }
}
