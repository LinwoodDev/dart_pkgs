import 'package:flutter/material.dart';
import 'package:material_leap/helpers.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

typedef OnValueChanged = void Function(double value);

class ExactSlider extends StatefulWidget {
  final String? label;
  final int fractionDigits;
  final Widget? header, leading, bottom;
  final double defaultValue, min, max;
  final double? value;
  final OnValueChanged? onChanged, onChangeEnd;
  final Color? color, thumbColor;
  final EdgeInsets? contentPadding;

  const ExactSlider({
    super.key,
    this.label,
    this.leading,
    this.bottom,
    this.fractionDigits = 2,
    this.defaultValue = 1,
    this.min = 0,
    this.max = 100,
    this.color,
    this.value,
    this.header,
    this.onChangeEnd,
    this.onChanged,
    this.thumbColor,
    this.contentPadding,
  });

  ExactSlider.srgb({
    super.key,
    this.label,
    this.leading,
    this.bottom,
    this.fractionDigits = 2,
    this.defaultValue = 1,
    this.min = 0,
    this.max = 100,
    required SRGBColor color,
    this.value,
    this.header,
    this.onChangeEnd,
    this.onChanged,
    required SRGBColor thumbColor,
    this.contentPadding,
  })  : color = color.toColor(),
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
    _value = widget.value ?? widget.defaultValue;
    _controller.text = _value.toStringAsFixed(widget.fractionDigits);
  }

  void _changeValue(double value) {
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
  void didUpdateWidget(covariant ExactSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      setState(() {
        _value = widget.value ?? widget.defaultValue;
        _controller.text = _value.toStringAsFixed(widget.fractionDigits);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final textField = TextFormField(
                  decoration: InputDecoration(
                      filled: true,
                      labelText: widget.label,
                      floatingLabelAlignment: FloatingLabelAlignment.center),
                  textAlign: TextAlign.center,
                  controller: _controller,
                  onEditingComplete: () => widget.onChangeEnd?.call(_value),
                  onChanged: (value) =>
                      _changeValue(double.tryParse(value) ?? _value));
              final slider = Slider(
                value: _value.clamp(widget.min, widget.max),
                min: widget.min,
                max: widget.max,
                activeColor: widget.color,
                onChangeEnd: widget.onChangeEnd,
                thumbColor: widget.thumbColor,
                onChanged: (value) {
                  _changeValue(value);
                },
              );
              final header = widget.header;
              final resetButton = IconButton(
                  onPressed: () {
                    _changeValue(widget.defaultValue);
                    widget.onChangeEnd?.call(widget.defaultValue);
                  },
                  icon: const PhosphorIcon(
                      PhosphorIconsLight.clockCounterClockwise));
              final width = constraints.maxWidth;
              if (width < 300) {
                return ListTile(
                  leading: widget.leading,
                  title: header,
                  contentPadding: widget.contentPadding,
                  subtitle: Column(
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (widget.leading != null) widget.leading!,
                            Flexible(child: textField),
                            const SizedBox(width: 8),
                            resetButton,
                          ]),
                      slider,
                    ],
                  ),
                );
              }
              if (width < 500) {
                return ListTile(
                  leading: widget.leading,
                  contentPadding: widget.contentPadding,
                  subtitle: Row(children: [
                    Expanded(child: slider),
                    resetButton,
                  ]),
                  title: Row(children: [
                    if (header != null) Expanded(child: header),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 75),
                      child: textField,
                    ),
                  ]),
                );
              }
              return ListTile(
                leading: widget.leading,
                contentPadding: widget.contentPadding,
                title: Row(
                  children: [
                    if (header != null) ...[
                      SizedBox(width: 200, child: header),
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
            }),
            DefaultTextStyle(
              style: Theme.of(context).textTheme.bodySmall ?? const TextStyle(),
              child: widget.bottom ?? const SizedBox(),
            ),
          ],
        ));
  }
}
