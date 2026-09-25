import 'package:material_ui/material_ui.dart';
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
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? widget.defaultValue;
  }

  @override
  void didUpdateWidget(covariant InputStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != null) {
      _value = widget.value!;
    }
  }

  void _changeValue(double value) {
    value = value.clamp(widget.min, widget.max);
    if (_value != value) {
      setState(() {
        _value = value;
      });
    }
    widget.onChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final listTile = ListTile(
          title: widget.title,
          subtitle: widget.subtitle,
        );
        final resetButton = IconButton(
          onPressed: () => _changeValue(widget.defaultValue),
          icon: const PhosphorIcon(PhosphorIconsLight.clockCounterClockwise),
        );
        final numberInput = NumberInput(
          value: _value,
          min: widget.min,
          max: widget.max,
          step: widget.step,
          fractionDigits: widget.fractionDigits,
          label: widget.label,
          onChanged: _changeValue,
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
                  Expanded(child: numberInput),
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
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: numberInput,
            ),
            const SizedBox(width: 8),
            resetButton,
          ],
        );
      },
    );
  }
}
