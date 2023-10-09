import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class InputStepper extends StatefulWidget {
  final Widget title;
  final Widget? subtitle;
  final int fractionDigits;
  final double defaultValue, min, max;
  final double step;
  final double? value;
  final OnValueChanged? onChanged;
  final String? label;

  const InputStepper({
    super.key,
    required this.title,
    this.subtitle,
    this.defaultValue = 0,
    this.fractionDigits = 2,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.value,
    this.onChanged,
    this.label,
  });

  @override
  State<InputStepper> createState() => _InputStepperState();
}

class _InputStepperState extends State<InputStepper> {
  final TextEditingController _controller = TextEditingController();
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? widget.defaultValue;
    _controller.text = _value.toStringAsFixed(widget.fractionDigits);
  }

  void _changeValue(double value) {
    value = value.clamp(widget.min, widget.max);
    if (_value != value) {
      final text = value.toStringAsFixed(widget.fractionDigits);
      if (double.tryParse(_controller.text.trim()) != value) {
        _controller.text = text;
      }
      setState(() {
        _value = value;
      });
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final listTile = ListTile(
        title: widget.title,
        subtitle: widget.subtitle,
      );
      final resetButton = IconButton(
        onPressed: () {
          _changeValue(widget.defaultValue);
          widget.onChanged?.call(widget.defaultValue);
        },
        icon: const PhosphorIcon(PhosphorIconsLight.clockCounterClockwise),
      );
      final textField = TextFormField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          filled: true,
          labelText: widget.label,
        ),
      );
      final min = IconButton(
        onPressed: _value <= widget.min
            ? null
            : () => _changeValue(_value - widget.step),
        icon: const PhosphorIcon(PhosphorIconsLight.minusCircle),
      );
      final max = IconButton(
        onPressed: _value >= widget.max
            ? null
            : () => _changeValue(_value + widget.step),
        icon: const PhosphorIcon(PhosphorIconsLight.plusCircle),
      );
      if (constraints.maxWidth < 300) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            listTile,
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                min,
                Expanded(child: textField),
                max,
                const SizedBox(width: 8),
                resetButton,
              ],
            ),
          ],
        );
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: listTile),
          const SizedBox(width: 8),
          min,
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 75),
            child: textField,
          ),
          const SizedBox(width: 4),
          max,
          const SizedBox(width: 8),
          resetButton,
        ],
      );
    });
  }
}
