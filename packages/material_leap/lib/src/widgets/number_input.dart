import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// A numeric text field with optional step buttons and pointer shortcuts.
///
/// Text entry keeps its precision. The [step] applies only to the buttons,
/// arrow keys, mouse wheel, and Ctrl-drag gestures.
class NumberInput extends StatefulWidget {
  final double value, min, max, step;
  final int fractionDigits;
  final ValueChanged<double>? onChanged, onChangeEnd;
  final String? label, errorText;
  final bool showButtons, updateOnInput, enforceBounds;

  const NumberInput({
    super.key,
    required this.value,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
    this.step = 1,
    this.fractionDigits = 1,
    this.onChanged,
    this.onChangeEnd,
    this.label,
    this.errorText,
    this.showButtons = true,
    this.updateOnInput = false,
    this.enforceBounds = true,
  }) : assert(step > 0),
       assert(min <= max);

  @override
  State<NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<NumberInput> {
  final TextEditingController _controller = TextEditingController();
  Timer? _stepTimer;
  late double _value;
  bool _invalid = false;
  double? _dragX;
  double _dragRemainder = 0;

  @override
  void initState() {
    super.initState();
    _syncValue(widget.value);
  }

  @override
  void didUpdateWidget(covariant NumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value ||
        oldWidget.fractionDigits != widget.fractionDigits) {
      final editingValue = double.tryParse(
        _controller.text.trim().replaceAll(',', '.'),
      );
      if (widget.updateOnInput &&
          oldWidget.fractionDigits == widget.fractionDigits &&
          editingValue == widget.value) {
        _value = widget.value;
        return;
      }
      _syncValue(widget.value);
    }
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool _isValid(double value) =>
      value.isFinite &&
      (!widget.enforceBounds || (value >= widget.min && value <= widget.max));

  String _format(double value) {
    final formatted = value.toStringAsFixed(widget.fractionDigits);
    if ((double.parse(formatted) - value).abs() < 1e-9) return formatted;
    return value.toString();
  }

  void _syncValue(double value) {
    _value = value;
    _invalid = !_isValid(value);
    _controller.text = _format(value);
  }

  void _changeValue(double value, {bool updateText = true}) {
    final next = value.clamp(widget.min, widget.max).toDouble();
    if (next == _value && !_invalid) return;
    setState(() {
      _value = next;
      _invalid = false;
      if (updateText) {
        _controller.text = _format(next);
      }
    });
    widget.onChanged?.call(next);
  }

  void _commitTextValue() {
    final parsed = double.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (parsed == null || !_isValid(parsed)) {
      setState(() => _invalid = true);
      return;
    }
    final next = widget.enforceBounds
        ? parsed.clamp(widget.min, widget.max).toDouble()
        : parsed;
    setState(() {
      _value = next;
      _invalid = false;
      _controller.text = _format(next);
    });
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  double get _effectiveStep {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    var multiplier = 1.0;
    if (keys.contains(LogicalKeyboardKey.shiftLeft) ||
        keys.contains(LogicalKeyboardKey.shiftRight)) {
      multiplier *= 5;
    }
    if (keys.contains(LogicalKeyboardKey.altLeft) ||
        keys.contains(LogicalKeyboardKey.altRight)) {
      multiplier /= 10;
    }
    return widget.step * multiplier;
  }

  bool _step(int direction, {bool finish = true}) {
    final next = (_value + direction * _effectiveStep)
        .clamp(widget.min, widget.max)
        .toDouble();
    if (next == _value) return false;
    _changeValue(next);
    if (finish) widget.onChangeEnd?.call(next);
    return true;
  }

  void _startStepping(int direction) {
    _stepTimer?.cancel();
    if (!_step(direction)) return;
    _stepTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_step(direction)) _stopStepping();
    });
  }

  void _stopStepping() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  Widget _stepButton(int direction, IconData icon, bool enabled) =>
      GestureDetector(
        onLongPressStart: enabled ? (_) => _startStepping(direction) : null,
        onLongPressEnd: enabled ? (_) => _stopStepping() : null,
        child: IconButton(
          onPressed: enabled ? () => _step(direction) : null,
          icon: PhosphorIcon(icon),
        ),
      );

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && event.scrollDelta.dy != 0) {
      GestureBinding.instance.pointerSignalResolver.register(
        event,
        (resolved) =>
            _step((resolved as PointerScrollEvent).scrollDelta.dy < 0 ? 1 : -1),
      );
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (event.buttons & kPrimaryButton != 0 &&
        (keys.contains(LogicalKeyboardKey.controlLeft) ||
            keys.contains(LogicalKeyboardKey.controlRight))) {
      _dragX = event.localPosition.dx;
      _dragRemainder = 0;
    }
  }

  void _onPointerMove(PointerMoveEvent event) {
    final previous = _dragX;
    if (previous == null) return;
    _dragX = event.localPosition.dx;
    _dragRemainder += (event.localPosition.dx - previous) / 8;
    final steps = _dragRemainder.truncate();
    if (steps == 0) return;
    _dragRemainder -= steps;
    final next = (_value + steps * _effectiveStep)
        .clamp(widget.min, widget.max)
        .toDouble();
    _changeValue(next);
  }

  void _endDrag() {
    if (_dragX != null) widget.onChangeEnd?.call(_value);
    _dragX = null;
  }

  @override
  Widget build(BuildContext context) {
    final field = Focus(
      onKeyEvent: _onKeyEvent,
      child: Listener(
        onPointerSignal: _onPointerSignal,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: (_) => _endDrag(),
        onPointerCancel: (_) => _endDrag(),
        child: TextField(
          controller: _controller,
          decoration: InputDecoration(
            filled: true,
            labelText: widget.label,
            errorText: _invalid ? (widget.errorText ?? '') : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          keyboardType: const TextInputType.numberWithOptions(
            signed: true,
            decimal: true,
          ),
          textAlign: TextAlign.center,
          onChanged: (text) {
            if (!widget.updateOnInput) return;
            final parsed = double.tryParse(text.replaceAll(',', '.'));
            if (parsed != null && _isValid(parsed)) {
              _value = parsed;
              widget.onChanged?.call(parsed);
            }
          },
          onSubmitted: (_) => _commitTextValue(),
          onTapOutside: (_) => _commitTextValue(),
        ),
      ),
    );
    if (!widget.showButtons) return field;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton(-1, PhosphorIconsLight.minus, _value > widget.min),
        const SizedBox(width: 2),
        Flexible(child: field),
        const SizedBox(width: 2),
        _stepButton(1, PhosphorIconsLight.plus, _value < widget.max),
      ],
    );
  }
}
