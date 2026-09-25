import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:material_leap/helpers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'number_input.dart';

typedef OnValueChanged = void Function(double value);

class ExactSlider extends StatefulWidget {
  final String? label;
  final int fractionDigits;
  final Widget? header, subtitle, leading, trailing, bottom;
  final double value, min, max;
  final double? defaultValue;
  final double? sliderStep;
  final double? headerWidth;

  /// Maximum width of the editable number field.
  final double inputWidth;
  final OnValueChanged? onChanged, onChangeEnd;
  final Color? color, thumbColor;
  final EdgeInsets? contentPadding;
  final bool divide, clampValue;

  const ExactSlider({
    super.key,
    this.label,
    this.leading,
    this.trailing,
    this.bottom,
    this.subtitle,
    this.fractionDigits = 2,
    this.defaultValue,
    this.sliderStep,
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
    this.inputWidth = 80,
    this.clampValue = false,
  }) : assert(sliderStep == null || sliderStep > 0),
       assert(inputWidth > 0);

  ExactSlider.srgb({
    super.key,
    this.label,
    this.leading,
    this.trailing,
    this.bottom,
    this.subtitle,
    this.fractionDigits = 2,
    this.defaultValue,
    this.sliderStep,
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
    this.inputWidth = 80,
    this.clampValue = false,
  }) : color = color.toColor(),
       thumbColor = thumbColor.toColor(),
       assert(sliderStep == null || sliderStep > 0),
       assert(inputWidth > 0);

  @override
  _ExactSliderState createState() => _ExactSliderState();
}

class _ExactSliderState extends State<ExactSlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value);
  }

  double _clamp(double value) => widget.clampValue
      ? value.clamp(widget.min, widget.max).toDouble()
      : value;

  void _changeValue(double value) {
    final nextValue = _clamp(value);
    if (_value != nextValue) {
      setState(() {
        _value = nextValue;
      });
    }
    widget.onChanged?.call(nextValue);
  }

  double _snapSliderValue(double value) {
    final step = widget.sliderStep;
    if (step == null) return value;
    return ((value / step).round() * step)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  @override
  void didUpdateWidget(covariant ExactSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _value = _clamp(widget.value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ListTileThemeData tileTheme = ListTileTheme.of(context);
    final titleStyle =
        tileTheme.titleTextStyle ??
        TextTheme.of(context).bodyLarge ??
        const TextStyle();
    final subtitleStyle =
        tileTheme.subtitleTextStyle ??
        TextTheme.of(context).bodyMedium ??
        const TextStyle();
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textField = NumberInput(
                value: _value,
                min: widget.min,
                max: widget.max,
                step: widget.sliderStep ?? 1,
                fractionDigits: widget.fractionDigits,
                label: widget.label,
                showButtons: false,
                updateOnInput: true,
                enforceBounds: widget.clampValue,
                onChanged: _changeValue,
                onChangeEnd: widget.onChangeEnd,
              );
              final digits = widget.fractionDigits;
              final slider = Slider(
                value: _value.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                activeColor: widget.color,
                onChangeEnd: widget.onChangeEnd == null
                    ? null
                    : (value) => widget.onChangeEnd!(_snapSliderValue(value)),
                thumbColor: widget.thumbColor,
                divisions: widget.divide
                    ? ((widget.max - widget.min + 1) * pow(10, digits)).toInt()
                    : null,
                onChanged: (value) {
                  _changeValue(_snapSliderValue(value));
                },
              );
              final header = widget.header;
              final subtitle = widget.subtitle;
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
                      DefaultTextStyle(
                        style: titleStyle,
                        child: widget.header ?? const SizedBox(),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        DefaultTextStyle(style: subtitleStyle, child: subtitle),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          ?widget.leading,
                          Flexible(
                            fit: FlexFit.loose,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: widget.inputWidth,
                              ),
                              child: textField,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ?resetButton,
                          ?widget.trailing,
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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ?subtitle,
                      Row(
                        children: [
                          Expanded(child: slider),
                          ?resetButton,
                          ?widget.trailing,
                        ],
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      if (header != null) Expanded(child: header),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: widget.inputWidth,
                        ),
                        child: textField,
                      ),
                    ],
                  ),
                );
              }
              return ListTile(
                leading: widget.leading,
                contentPadding: widget.contentPadding,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (header != null) ...[
                          SizedBox(
                            width: widget.headerWidth ?? 180,
                            child: header,
                          ),
                          const SizedBox(width: 16),
                        ],
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: widget.inputWidth,
                          ),
                          child: textField,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: slider),
                      ],
                    ),
                  ],
                ),
                subtitle: subtitle,
                trailing: switch ((resetButton, widget.trailing)) {
                  (null, final trailing) => trailing,
                  (final reset?, null) => reset,
                  (final reset?, final trailing?) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [reset, trailing],
                  ),
                },
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
