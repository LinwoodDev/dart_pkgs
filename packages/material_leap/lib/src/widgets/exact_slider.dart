import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/helpers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

typedef OnValueChanged = void Function(double value);

class ExactSlider extends StatefulWidget {
  final String? label;
  final int fractionDigits;
  final Widget? header, leading, bottom;
  final double value, min, max;
  final double? defaultValue;
  final double? headerWidth;
  final OnValueChanged? onChanged, onChangeEnd;
  final Color? color, thumbColor;
  final EdgeInsets? contentPadding;
  final bool divide, clampValue;

  const ExactSlider({
    super.key,
    this.label,
    this.leading,
    this.bottom,
    this.fractionDigits = 2,
    this.defaultValue,
    this.min = 0,
    this.max = 100,
    this.divide = false,
    this.color,
    this.value = 1,
    this.header,
    this.onChangeEnd,
    this.onChanged,
    this.thumbColor,
    this.contentPadding,
    this.headerWidth,
    this.clampValue = false,
  });

  ExactSlider.srgb({
    super.key,
    this.label,
    this.leading,
    this.bottom,
    this.fractionDigits = 2,
    this.defaultValue,
    this.min = 0,
    this.max = 100,
    this.divide = false,
    required SRGBColor color,
    this.value = 1,
    this.header,
    this.onChangeEnd,
    this.onChanged,
    required SRGBColor thumbColor,
    this.contentPadding,
    this.headerWidth,
    this.clampValue = false,
  }) : color = color.toColor(),
       thumbColor = thumbColor.toColor();

  @override
  _ExactSliderState createState() => _ExactSliderState();
}

class _ExactSliderState extends State<ExactSlider> {
  late double _value;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value);
    _controller.text = _value.toStringAsFixed(widget.fractionDigits);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _clamp(double value) => widget.clampValue
      ? value.clamp(widget.min, widget.max).toDouble()
      : value;

  void _changeValue(double value, {bool syncText = true}) {
    final nextValue = _clamp(value);
    if (_value != nextValue) {
      if (syncText) {
        _updateText(nextValue);
      }
      setState(() {
        _value = nextValue;
      });
    } else if (syncText) {
      _updateText(nextValue);
    }
    widget.onChanged?.call(nextValue);
  }

  void _commitTextValue() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      _updateText(_value);
      widget.onChangeEnd?.call(_value);
      return;
    }
    _changeValue(parsed);
    widget.onChangeEnd?.call(_value);
  }

  void _updateText(double value) {
    final text = value.toStringAsFixed(widget.fractionDigits);
    if (_controller.text.trim() != text) {
      _controller.text = text;
    }
  }

  @override
  void didUpdateWidget(covariant ExactSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _value = _clamp(widget.value);
        _updateText(_value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textField = TextFormField(
                decoration: InputDecoration(
                  filled: true,
                  labelText: widget.label,
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                ),
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                ],
                controller: _controller,
                onFieldSubmitted: (_) => _commitTextValue(),
                onEditingComplete: _commitTextValue,
                onTapOutside: (_) => _commitTextValue(),
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed == null) return;
                  _changeValue(parsed, syncText: false);
                },
              );
              final digits = widget.fractionDigits;
              final slider = Slider(
                value: _value.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                activeColor: widget.color,
                onChangeEnd: widget.onChangeEnd,
                thumbColor: widget.thumbColor,
                divisions: widget.divide
                    ? ((widget.max - widget.min + 1) * pow(10, digits)).toInt()
                    : null,
                onChanged: (value) {
                  _changeValue(value);
                },
              );
              final header = widget.header;
              final resetButton = widget.defaultValue == null
                  ? null
                  : IconButton(
                      onPressed: () {
                        _changeValue(widget.defaultValue ?? widget.value);
                        widget.onChangeEnd?.call(
                          widget.defaultValue ?? widget.value,
                        );
                      },
                      icon: const PhosphorIcon(
                        PhosphorIconsLight.clockCounterClockwise,
                      ),
                    );
              final width = constraints.maxWidth;
              if (width < 300) {
                return Padding(
                  padding: widget.contentPadding ?? EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header ?? const SizedBox.shrink(),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ?widget.leading,
                          Expanded(child: textField),
                          const SizedBox(width: 8),
                          ?resetButton,
                        ],
                      ),
                      slider,
                    ],
                  ),
                );
              }
              if (width < 500) {
                return ListTile(
                  leading: widget.leading,
                  contentPadding: widget.contentPadding,
                  subtitle: Row(
                    children: [
                      Expanded(child: slider),
                      ?resetButton,
                    ],
                  ),
                  title: Row(
                    children: [
                      if (header != null) Expanded(child: header),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 75),
                        child: textField,
                      ),
                    ],
                  ),
                );
              }
              return ListTile(
                leading: widget.leading,
                contentPadding: widget.contentPadding,
                title: Row(
                  children: [
                    if (header != null) ...[
                      SizedBox(width: widget.headerWidth ?? 180, child: header),
                      const SizedBox(width: 16),
                    ],
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 75),
                      child: textField,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: slider),
                  ],
                ),
                trailing: resetButton,
              );
            },
          ),
          DefaultTextStyle(
            style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
            child: widget.bottom ?? const SizedBox(),
          ),
        ],
      ),
    );
  }
}
