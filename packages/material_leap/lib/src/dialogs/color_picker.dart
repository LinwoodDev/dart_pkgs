// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_leap/helpers.dart';
import 'package:material_leap/src/widgets/color_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/leap_localizations.dart';
import '../widgets/exact_slider.dart';
import '../widgets/header.dart';

class ColorPickerResponse<T> {
  final int color;
  final T? action;

  const ColorPickerResponse(this.color, [this.action]);
}

typedef ActionsBuilder<T> = List<Widget> Function(void Function(T?) close);
const kColorBlack = Color(0xFF000000);
const kColorRed = Color(0xFFFF0000);
const kColorGreen = Color(0xFF00FF00);
const kColorBlue = Color(0xFF0000FF);
const kColorWhite = Color(0xFFFFFFFF);

class ColorPicker<T> extends StatefulWidget {
  final Color defaultColor;
  final List<Color> suggested;
  final Color? value;
  final ActionsBuilder<T>? primaryActions, secondaryActions;

  const ColorPicker({
    super.key,
    this.value,
    this.defaultColor = Colors.white,
    this.primaryActions,
    this.secondaryActions,
    this.suggested = const [],
  });

  @override
  _ColorPickerState<T> createState() => _ColorPickerState<T>();
}

class _ColorPickerState<T> extends State<ColorPicker<T>> {
  late Color color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    color = widget.value ?? widget.defaultColor;
    _hexController =
        TextEditingController(text: color.value.toHexColor(alpha: false));
    super.initState();
  }

  void _changeColor({int? red, int? green, int? blue}) => setState(() {
        color = Color.fromARGB(
            255, red ?? color.red, green ?? color.green, blue ?? color.blue);
      });

  void _close([T? action]) =>
      Navigator.of(context).pop(ColorPickerResponse(color.value, action));

  @override
  Widget build(BuildContext context) {
    if (_hexController.text.toColorValue() != color.value) {
      _hexController.text = color.value.toHexColor(alpha: false);
    }
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < LeapBreakpoints.medium;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 1000, maxWidth: 1000),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Header(
              title: Text(LeapLocalizations.of(context).color),
              leading: const PhosphorIcon(PhosphorIconsLight.palette),
            ),
            Flexible(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: isMobile
                            ? SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildPreview(),
                                    _buildProperties(),
                                  ],
                                ),
                              )
                            : Row(children: [
                                Flexible(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: _buildPreview(),
                                  ),
                                ),
                                Flexible(
                                  flex: 3,
                                  child: SingleChildScrollView(
                                    child: _buildProperties(),
                                  ),
                                )
                              ])),
                    const Divider(),
                    OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OverflowBar(
                            children:
                                widget.secondaryActions?.call(_close) ?? []),
                        OverflowBar(children: [
                          TextButton(
                              child: Text(MaterialLocalizations.of(context)
                                  .cancelButtonLabel),
                              onPressed: () => Navigator.of(context).pop()),
                          const SizedBox(width: 8),
                          ...widget.primaryActions?.call(_close) ?? [],
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _close,
                            child: Text(MaterialLocalizations.of(context)
                                .okButtonLabel),
                          ),
                        ]),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300, maxWidth: 300),
            child: Align(
              child: ColorWheelPicker(
                  value: color,
                  onChanged: (value) {
                    setState(() {
                      color = value;
                      _hexController.text =
                          value.value.toHexColor(alpha: false);
                    });
                  }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                ColorButton(color: color, size: 48),
                Expanded(
                  child: TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(filled: true),
                    onSubmitted: (value) {
                      final valueNumber = value.toColorValue();
                      if (valueNumber == null) return;
                      setState(() {
                        color = Color(valueNumber).withAlpha(255);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildProperties() =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        ExactSlider(
          header: Text(LeapLocalizations.of(context).red),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          value: color.red.toDouble(),
          color: kColorRed,
          thumbColor: kColorBlack.withRed(color.red),
          onChanged: (value) => _changeColor(red: value.toInt()),
        ),
        ExactSlider(
          header: Text(LeapLocalizations.of(context).green),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          value: color.green.toDouble(),
          color: kColorGreen,
          thumbColor: kColorBlack.withGreen(color.green),
          onChanged: (value) => _changeColor(green: value.toInt()),
        ),
        ExactSlider(
          header: Text(LeapLocalizations.of(context).blue),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          value: color.blue.toDouble(),
          color: kColorBlue,
          thumbColor: kColorBlack.withBlue(color.blue),
          onChanged: (value) => _changeColor(blue: value.toInt()),
        ),
        if (widget.suggested.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            children: widget.suggested
                .map((e) => SizedBox(
                      height: 64,
                      width: 64,
                      child: ColorButton(
                        color: e,
                        onTap: () => setState(() => color = e),
                      ),
                    ))
                .toList(),
          ),
        ],
      ]);
}

class ColorWheelPicker extends StatelessWidget {
  final Color value;
  final void Function(Color) onChanged;
  final GlobalKey _wheelKey = GlobalKey(), _sliderKey = GlobalKey();

  ColorWheelPicker({super.key, required this.value, required this.onChanged});

  void _onWheelPointer(Offset position) {
    final ctx = _wheelKey.currentContext;
    if (ctx == null) return;
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(position);
    final radius = min(box.size.width / 2, box.size.height / 2);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final angle = atan2(dy, dx);
    final double saturation = min(1.0, sqrt(dx * dx + dy * dy) / radius);
    final double hue = (angle * 180 / pi + 360) % 360;
    onChanged(
        HSVColor.fromAHSV(1, hue, saturation, HSVColor.fromColor(value).value)
            .toColor());
  }

  void _onSliderPointer(PointerEvent event) {
    final ctx = _sliderKey.currentContext;
    if (ctx == null) return;
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(event.position);
    final color = HSVColor.fromColor(value);
    final hsvValue = min(1.0, max(0.0, local.dx / box.size.width));
    onChanged(color.withValue(hsvValue).toColor());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: GestureDetector(
              onPanUpdate: (details) => _onWheelPointer(details.globalPosition),
              onPanDown: (details) => _onWheelPointer(details.globalPosition),
              onPanStart: (details) => _onWheelPointer(details.globalPosition),
              onPanEnd: (details) => _onWheelPointer(details.globalPosition),
              child: CustomPaint(
                key: _wheelKey,
                painter: _ColorWheelPainter(value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: Listener(
            onPointerDown: _onSliderPointer,
            onPointerMove: _onSliderPointer,
            child: CustomPaint(
              key: _sliderKey,
              painter: _ColorWheelSliderPainter(value),
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final Color value;

  _ColorWheelPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = min(size.width / 2, size.height / 2);
    final center = Offset(size.width / 2, size.height / 2);
    final circle = Rect.fromCircle(center: center, radius: radius);

    // Paint the color wheel using SweepGradient
    final hsv = HSVColor.fromColor(value);
    final paint = Paint()
      ..shader = SweepGradient(
        colors: List.generate(
            360,
            (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, hsv.value)
                .toColor()), // Generate smooth hues
        startAngle: 0,
        endAngle: 2 * pi,
      ).createShader(circle);

    canvas.drawCircle(center, radius, paint);

    // Overlay the white-to-transparent radial gradient
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            HSVColor.fromColor(Colors.white)
                .withValue(hsv.value)
                .toColor(), // White at the center for desaturation
            Colors.transparent, // Fully saturated at the edges
          ],
          stops: [0.0, 1], // White at the center, clear at the edges
          tileMode: TileMode.clamp, // Ensures smooth blending
        ).createShader(circle),
    );

    // Draw the current selection indicator
    final point = Offset(
      center.dx + radius * hsv.saturation * cos(hsv.hue * pi / 180),
      center.dy + radius * hsv.saturation * sin(hsv.hue * pi / 180),
    );
    canvas.drawCircle(point, 8, Paint()..color = Colors.white);
    canvas.drawCircle(point, 6, Paint()..color = hsv.toColor());
  }

  @override
  bool shouldRepaint(_ColorWheelPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _ColorWheelSliderPainter extends CustomPainter {
  final Color value;

  _ColorWheelSliderPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final hsv = HSVColor.fromColor(value);
    final rect =
        Rect.fromPoints(const Offset(0, 0), Offset(size.width, size.height));
    final paint = Paint()
      ..shader = const LinearGradient(
              colors: [Colors.black, Colors.white],
              stops: [0, 1],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight)
          .createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)), paint);
    final point = Offset(size.width * hsv.value, size.height / 2);
    canvas.drawCircle(
        point,
        8,
        Paint()
          ..color = kColorWhite
          ..style = PaintingStyle.fill);
    canvas.drawCircle(point, 6, Paint()..color = kColorBlack);
  }

  @override
  bool shouldRepaint(_ColorWheelSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
