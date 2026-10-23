import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

import 'drop_models.dart';
import 'drop_stub.dart'
    if (dart.library.io) 'drop_native.dart'
    if (dart.library.js_interop) 'drop_web.dart';

/// Receives OS/browser drops without changing the system clipboard.
///
/// The innermost enabled target under the pointer receives the drop. Opaque
/// overlays and modal routes occlude targets using Flutter's normal hit test.
class SystemDropTarget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final FutureOr<void> Function(SystemDropDetails) onDrop;
  final ValueChanged<bool>? onHover;
  final bool showFeedback;
  final void Function(Object, StackTrace)? onError;

  const SystemDropTarget({
    super.key,
    required this.child,
    required this.onDrop,
    this.enabled = true,
    this.onHover,
    this.showFeedback = false,
    this.onError,
  });

  @override
  State<SystemDropTarget> createState() => _SystemDropTargetState();
}

final _targets = <_SystemDropTargetState>{};
final _events = createDropEvents();
StreamSubscription<SystemDropEvent>? _subscription;
_SystemDropTargetState? _hovered;

void _setHovered(_SystemDropTargetState? target) {
  if (_hovered == target) return;
  _hovered?._hover(false);
  _hovered = target;
  target?._hover(true);
}

void _handleEvent(SystemDropEvent event) {
  if (event.phase == SystemDropPhase.exit) {
    _setHovered(null);
    return;
  }
  final hit = HitTestResult();
  final targetContext = _targets.firstOrNull?.context;
  if (targetContext == null) return;
  GestureBinding.instance.hitTestInView(
    hit,
    event.position,
    View.of(targetContext).viewId,
  );
  _SystemDropTargetState? target;
  for (final entry in hit.path) {
    final object = entry.target;
    if (object is RenderMetaData && object.metaData is _SystemDropTargetState) {
      final candidate = object.metaData as _SystemDropTargetState;
      if (candidate.widget.enabled &&
          !candidate._busy &&
          (ModalRoute.of(candidate.context)?.isCurrent ?? true)) {
        target = candidate;
        break;
      }
    }
  }
  if (event.phase == SystemDropPhase.hover) {
    _setHovered(target);
    return;
  }
  _setHovered(null);
  if (target == null) return;
  final box = target.context.findRenderObject() as RenderBox;
  unawaited(
    target._receive(
      SystemDropDetails(
        localPosition: box.globalToLocal(event.position),
        globalPosition: event.position,
        items: event.items,
      ),
    ),
  );
}

class _SystemDropTargetState extends State<SystemDropTarget> {
  bool _hovering = false;
  bool _busy = false;

  void _hover(bool value) {
    if (_hovering == value || !mounted) return;
    setState(() => _hovering = value);
    widget.onHover?.call(value);
  }

  void _error(Object error, StackTrace stack) {
    if (widget.onError != null && mounted) {
      widget.onError!(error, stack);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'lw_sysapi',
          context: ErrorDescription('while receiving dropped content'),
        ),
      );
    }
  }

  Future<void> _receive(SystemDropDetails details) async {
    if (_busy || !widget.enabled) return;
    setState(() => _busy = true);
    try {
      await widget.onDrop(details);
    } catch (error, stack) {
      if (mounted) _error(error, stack);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _register() {
    if (widget.enabled) {
      _targets.add(this);
      _subscription ??= _events.listen(
        _handleEvent,
        onError: (Object error, StackTrace stack) {
          final target = _hovered;
          _setHovered(null);
          if (target != null) {
            target._error(error, stack);
          } else {
            FlutterError.reportError(
              FlutterErrorDetails(
                exception: error,
                stack: stack,
                library: 'lw_sysapi',
              ),
            );
          }
        },
      );
    } else {
      _unregister();
    }
  }

  void _unregister() {
    if (_hovered == this) {
      _hovered = null;
      _hovering = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _hovered != this) widget.onHover?.call(false);
      });
    }
    _targets.remove(this);
    if (_targets.isEmpty) {
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(SystemDropTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _register();
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MetaData(
    metaData: this,
    behavior: HitTestBehavior.translucent,
    child: !widget.showFeedback
        ? widget.child
        : Stack(
            children: [
              widget.child,
              if (_hovering || _busy)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: _busy
                          ? const Center(child: CircularProgressIndicator())
                          : null,
                    ),
                  ),
                ),
            ],
          ),
  );
}
