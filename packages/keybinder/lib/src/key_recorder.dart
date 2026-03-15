import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/material_leap.dart';
import '../l10n/keybinder_localizations.dart';
import 'shortcut_localizer.dart';

/// A widget that records a key combination.
///
/// This widget handles the focus and key events for recording a shortcut.
/// It uses a [builder] to render the UI.
class KeyRecorder extends StatefulWidget {
  final ValueChanged<SingleActivator> onNewKey;
  final Widget Function(
    BuildContext context,
    bool isRecording,
    VoidCallback toggleRecording,
  )
  builder;
  final FocusNode? focusNode;
  final LogicalKeyboardKey? cancelKey;

  const KeyRecorder({
    super.key,
    required this.onNewKey,
    required this.builder,
    this.focusNode,
    this.cancelKey,
  });

  @override
  State<KeyRecorder> createState() => _KeyRecorderState();
}

class _KeyRecorderState extends State<KeyRecorder> {
  late FocusNode _focusNode;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void didUpdateWidget(KeyRecorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
    if (_isRecording) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (!_isRecording) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          if (widget.cancelKey != null &&
              event.logicalKey == widget.cancelKey) {
            setState(() {
              _isRecording = false;
            });
            return KeyEventResult.handled;
          }

          // Ignore standalone modifier presses (e.g. just pressing Ctrl)
          if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
              event.logicalKey == LogicalKeyboardKey.controlRight ||
              event.logicalKey == LogicalKeyboardKey.shiftLeft ||
              event.logicalKey == LogicalKeyboardKey.altLeft ||
              event.logicalKey == LogicalKeyboardKey.metaLeft ||
              event.logicalKey == LogicalKeyboardKey.metaRight) {
            return KeyEventResult.handled;
          }

          // Create the new activator
          final newActivator = SingleActivator(
            event.logicalKey,
            control: HardwareKeyboard.instance.isControlPressed,
            shift: HardwareKeyboard.instance.isShiftPressed,
            alt: HardwareKeyboard.instance.isAltPressed,
            meta: HardwareKeyboard.instance.isMetaPressed,
          );

          widget.onNewKey(newActivator);

          setState(() {
            _isRecording = false;
          });
          return KeyEventResult.handled; // Stop propagation
        }
        return KeyEventResult.handled;
      },
      child: widget.builder(context, _isRecording, _toggleRecording),
    );
  }
}

/// A button that records a key combination when clicked.
class KeyRecorderButton extends StatelessWidget {
  final ShortcutActivator currentActivator;
  final ValueChanged<SingleActivator> onNewKey;
  final Color recordingColor, recordingTextColor;
  final VoidCallback? onReset;
  final LogicalKeyboardKey? cancelKey;

  const KeyRecorderButton({
    super.key,
    required this.currentActivator,
    required this.onNewKey,
    this.recordingColor = Colors.redAccent,
    this.recordingTextColor = Colors.white,
    this.onReset,
    this.cancelKey,
  });

  @override
  Widget build(BuildContext context) {
    return KeyRecorder(
      onNewKey: onNewKey,
      cancelKey: cancelKey,
      builder: (context, isRecording, toggleRecording) {
        final l10n = KeybinderLocalizations.of(context);
        String label = l10n.clickToSet;
        if (isRecording) {
          label = l10n.pressAnyKey;
        } else {
          label = ShortcutLocalizer.localize(context, currentActivator);
        }

        final button = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isRecording ? recordingColor : null,
            foregroundColor: isRecording ? recordingTextColor : null,
          ),
          onPressed: toggleRecording,
          child: Text(label),
        );

        if (onReset != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              button,
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: onReset,
                tooltip: LeapLocalizations.of(context).reset,
              ),
            ],
          );
        }

        return button;
      },
    );
  }
}

/// A list tile that records a key combination when tapped.
class KeyRecorderListTile extends StatelessWidget {
  final ShortcutActivator currentActivator;
  final ValueChanged<SingleActivator> onNewKey;
  final Widget? title;
  final Widget? subtitle;
  final Widget? leading;
  final Color recordingColor, recordingTextColor;
  final VoidCallback? onReset;
  final LogicalKeyboardKey? cancelKey;

  const KeyRecorderListTile({
    super.key,
    required this.currentActivator,
    required this.onNewKey,
    this.title,
    this.subtitle,
    this.leading,
    this.recordingColor = Colors.redAccent,
    this.recordingTextColor = Colors.white,
    this.onReset,
    this.cancelKey,
  });

  @override
  Widget build(BuildContext context) {
    return KeyRecorder(
      onNewKey: onNewKey,
      cancelKey: cancelKey,
      builder: (context, isRecording, toggleRecording) {
        final l10n = KeybinderLocalizations.of(context);
        String label = l10n.clickToSet;
        if (isRecording) {
          label = l10n.pressAnyKey;
        } else {
          label = ShortcutLocalizer.localize(context, currentActivator);
        }

        Widget trailing = Chip(
          label: Text(label),
          backgroundColor: isRecording ? recordingColor : null,
          labelStyle: isRecording ? TextStyle(color: recordingTextColor) : null,
        );

        if (onReset != null) {
          trailing = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              trailing,
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.restore),
                onPressed: onReset,
                tooltip: LeapLocalizations.of(context).reset,
              ),
            ],
          );
        }

        return ListTile(
          title: title,
          subtitle: subtitle,
          leading: leading,
          trailing: trailing,
          onTap: toggleRecording,
          selected: isRecording,
        );
      },
    );
  }
}
