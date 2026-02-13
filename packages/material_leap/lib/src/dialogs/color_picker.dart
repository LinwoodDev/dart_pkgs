import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/helpers.dart';
import 'package:material_leap/src/widgets/color_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/leap_localizations.dart';
import '../widgets/exact_slider.dart';
import '../widgets/header.dart';

class ColorPickerResponse<T> {
  final int value;
  final T? action;

  const ColorPickerResponse(this.value, [this.action]);

  SRGBColor toSRGB() => SRGBColor(value);
  Color toColor() => Color(value);
}

typedef ActionsBuilder<T> = List<Widget> Function(void Function(T?) close);

enum ColorPickerTab { rgb, hsv, hsl }

class ColorPicker<T> extends StatefulWidget {
  final SRGBColor defaultColor;
  final List<SRGBColor> suggested;
  final SRGBColor? value;
  final bool allowAlpha;
  final ColorPickerTab initialTab;
  final ValueChanged<ColorPickerTab>? onTabChange;
  final ActionsBuilder<T>? primaryActions, secondaryActions;

  const ColorPicker({
    super.key,
    this.value,
    this.defaultColor = SRGBColor.white,
    this.allowAlpha = false,
    this.initialTab = ColorPickerTab.rgb,
    this.onTabChange,
    this.primaryActions,
    this.secondaryActions,
    this.suggested = const [],
  });

  ColorPicker.native({
    super.key,
    Color value = Colors.white,
    Color defaultColor = Colors.white,
    this.allowAlpha = false,
    this.initialTab = ColorPickerTab.rgb,
    this.onTabChange,
    this.primaryActions,
    this.secondaryActions,
    List<Color> suggested = const [],
  }) : defaultColor = defaultColor.toSRGB(),
       value = value.toSRGB(),
       suggested = suggested.map((e) => e.toSRGB()).toList();

  @override
  _ColorPickerState<T> createState() => _ColorPickerState<T>();
}

class _ColorPickerState<T> extends State<ColorPicker<T>> {
  late SRGBColor color;
  late HSVColor _hsv;
  late HSLColor _hsl;
  late ColorPickerTab _tab;
  late final TextEditingController _hexController;

  @override
  void initState() {
    color = widget.value ?? widget.defaultColor;
    _hsv = HSVColor.fromColor(color.toColor());
    _hsl = HSLColor.fromColor(color.toColor());
    _tab = widget.initialTab;
    _hexController = TextEditingController(
      text: color.toHexString(alpha: widget.allowAlpha, leadingHash: false),
    );
    super.initState();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  int _clamp8Bit(int value) => value.clamp(0, 255).toInt();
  double _clampUnit(double value) => value.clamp(0.0, 1.0).toDouble();
  double _clampHue(double value) => value.clamp(0.0, 359.0).toDouble();

  void _setColor(
    SRGBColor value, {
    bool syncHex = true,
    HSVColor? hsvOverride,
    HSLColor? hslOverride,
  }) {
    setState(() {
      color = widget.allowAlpha ? value : value.withValues(a: 255);
      final colorValue = color.toColor();
      _hsv = hsvOverride ?? HSVColor.fromColor(colorValue);
      _hsl = hslOverride ?? HSLColor.fromColor(colorValue);
      if (syncHex) {
        _hexController.text = color.toHexString(
          alpha: widget.allowAlpha,
          leadingHash: false,
        );
      }
    });
  }

  void _changeColor({int? alpha, int? red, int? green, int? blue}) {
    _setColor(
      color.withValues(
        a: alpha == null ? null : _clamp8Bit(alpha),
        r: red == null ? null : _clamp8Bit(red),
        g: green == null ? null : _clamp8Bit(green),
        b: blue == null ? null : _clamp8Bit(blue),
      ),
    );
  }

  void _resetColor() => _setColor(widget.defaultColor);

  Future<void> _copyHex() async {
    await Clipboard.setData(
      ClipboardData(text: color.toHexString(alpha: widget.allowAlpha)),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LeapLocalizations.of(context).copyMessage)),
      );
    }
  }

  Future<void> _pasteHex() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    final parsed = SRGBColor.tryParse(text);
    if (parsed == null) return;
    _setColor(parsed);
  }

  void _submitHex(String value) {
    final valueNumber = SRGBColor.tryParse(value.trim());
    if (valueNumber == null) return;
    _setColor(valueNumber, syncHex: false);
  }

  void _changeTab(ColorPickerTab tab) {
    if (_tab == tab) return;
    setState(() {
      _tab = tab;
    });
    widget.onTabChange?.call(tab);
  }

  void _changeHsv({double? hue, double? saturation, double? value}) {
    final hsv = _hsv;
    final nextHsv = hsv
        .withHue(_clampHue(hue ?? hsv.hue))
        .withSaturation(_clampUnit(saturation ?? hsv.saturation))
        .withValue(_clampUnit(value ?? hsv.value));
    final nextColor = nextHsv.toColor();
    _setColor(
      nextColor.toSRGB(),
      hsvOverride: nextHsv,
      hslOverride: HSLColor.fromColor(nextColor),
    );
  }

  void _changeHsl({double? hue, double? saturation, double? lightness}) {
    final hsl = _hsl;
    final nextHsl = hsl
        .withHue(_clampHue(hue ?? hsl.hue))
        .withSaturation(_clampUnit(saturation ?? hsl.saturation))
        .withLightness(_clampUnit(lightness ?? hsl.lightness));
    final nextColor = nextHsl.toColor();
    _setColor(
      nextColor.toSRGB(),
      hsvOverride: HSVColor.fromColor(nextColor),
      hslOverride: nextHsl,
    );
  }

  void _close([T? action]) =>
      Navigator.of(context).pop(ColorPickerResponse(color.value, action));

  @override
  Widget build(BuildContext context) {
    if (SRGBColor.tryParse(_hexController.text)?.value != color.value) {
      _hexController.text = color.toHexString(
        alpha: widget.allowAlpha,
        leadingHash: false,
      );
    }
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < LeapBreakpoints.medium;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Dialog(
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: isMobile ? size.height - 16 : 1000,
          maxWidth: isMobile ? size.width - 16 : 1000,
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Header(
                  title: Text(LeapLocalizations.of(context).color),
                  leading: const PhosphorIcon(PhosphorIconsLight.palette),
                ),
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12 : 20,
                      vertical: isMobile ? 12 : 15,
                    ),
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
                                      _buildPreview(isMobile: true),
                                      const SizedBox(height: 8),
                                      _buildProperties(),
                                    ],
                                  ),
                                )
                              : Row(
                                  children: [
                                    Flexible(
                                      flex: 2,
                                      child: SingleChildScrollView(
                                        child: _buildPreview(isMobile: false),
                                      ),
                                    ),
                                    Flexible(
                                      flex: 3,
                                      child: SingleChildScrollView(
                                        child: _buildProperties(),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Divider(),
                        OverflowBar(
                          alignment: MainAxisAlignment.spaceBetween,
                          overflowAlignment: OverflowBarAlignment.end,
                          children: [
                            OverflowBar(
                              children:
                                  widget.secondaryActions?.call(_close) ?? [],
                            ),
                            OverflowBar(
                              spacing: 8,
                              overflowSpacing: 8,
                              children: [
                                TextButton(
                                  child: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).cancelButtonLabel,
                                  ),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                ...widget.primaryActions?.call(_close) ?? [],
                                ElevatedButton(
                                  onPressed: _close,
                                  child: Text(
                                    MaterialLocalizations.of(
                                      context,
                                    ).okButtonLabel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreview({required bool isMobile}) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? 260 : 300),
        child: Align(
          child: ColorWheelPicker(
            value: color,
            onChanged: (value) {
              _setColor(value);
            },
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(child: ColorButton.srgb(color: color, size: 48)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hexController,
                    decoration: const InputDecoration(
                      filled: true,
                      labelText: 'HEX',
                      prefixText: '#',
                    ),
                    onSubmitted: _submitHex,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _resetColor,
                        icon: const PhosphorIcon(
                          PhosphorIconsLight.clockCounterClockwise,
                        ),
                        label: Text(LeapLocalizations.of(context).reset),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _copyHex,
                        icon: const PhosphorIcon(PhosphorIconsLight.copy),
                        label: Text(
                          MaterialLocalizations.of(context).copyButtonLabel,
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _pasteHex,
                        icon: const PhosphorIcon(
                          PhosphorIconsLight.clipboardText,
                        ),
                        label: Text(
                          MaterialLocalizations.of(context).pasteButtonLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                children: [
                  ColorButton.srgb(color: color, size: 48),
                  Expanded(
                    child: TextField(
                      controller: _hexController,
                      decoration: const InputDecoration(
                        filled: true,
                        labelText: 'HEX',
                        prefixText: '#',
                      ),
                      onSubmitted: _submitHex,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: LeapLocalizations.of(context).reset,
                    onPressed: _resetColor,
                    icon: const PhosphorIcon(
                      PhosphorIconsLight.clockCounterClockwise,
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).copyButtonLabel,
                    onPressed: _copyHex,
                    icon: const PhosphorIcon(PhosphorIconsLight.copy),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).pasteButtonLabel,
                    onPressed: _pasteHex,
                    icon: const PhosphorIcon(PhosphorIconsLight.clipboardText),
                  ),
                ],
              ),
      ),
    ],
  );

  Widget _buildProperties() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Wrap(
        spacing: 8,
        children: [
          ChoiceChip(
            label: const Text('RGB'),
            selected: _tab == ColorPickerTab.rgb,
            onSelected: (_) => _changeTab(ColorPickerTab.rgb),
          ),
          ChoiceChip(
            label: const Text('HSV'),
            selected: _tab == ColorPickerTab.hsv,
            onSelected: (_) => _changeTab(ColorPickerTab.hsv),
          ),
          ChoiceChip(
            label: const Text('HSL'),
            selected: _tab == ColorPickerTab.hsl,
            onSelected: (_) => _changeTab(ColorPickerTab.hsl),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (widget.allowAlpha)
        ExactSlider.srgb(
          header: const Text('A'),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          clampValue: true,
          value: color.a.toDouble(),
          color: SRGBColor.white,
          thumbColor: SRGBColor.black.withValues(a: color.a),
          onChanged: (value) => _changeColor(alpha: value.toInt()),
        ),
      if (_tab == ColorPickerTab.rgb) ...[
        ExactSlider.srgb(
          header: Text(LeapLocalizations.of(context).red),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          clampValue: true,
          value: color.r.toDouble(),
          color: SRGBColor.red,
          thumbColor: SRGBColor.black.withValues(r: color.r),
          onChanged: (value) => _changeColor(red: value.toInt()),
        ),
        ExactSlider.srgb(
          header: Text(LeapLocalizations.of(context).green),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          clampValue: true,
          value: color.g.toDouble(),
          color: SRGBColor.green,
          thumbColor: SRGBColor.black.withValues(g: color.g),
          onChanged: (value) => _changeColor(green: value.toInt()),
        ),
        ExactSlider.srgb(
          header: Text(LeapLocalizations.of(context).blue),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          clampValue: true,
          value: color.b.toDouble(),
          color: SRGBColor.blue,
          thumbColor: SRGBColor.black.withValues(b: color.b),
          onChanged: (value) => _changeColor(blue: value.toInt()),
        ),
      ],
      if (_tab == ColorPickerTab.hsv) ...[
        ExactSlider(
          header: const Text('H'),
          fractionDigits: 0,
          defaultValue: 0,
          min: 0,
          max: 359,
          clampValue: true,
          value: _clampHue(_hsv.hue),
          onChanged: (value) => _changeHsv(hue: value),
        ),
        ExactSlider(
          header: const Text('S'),
          fractionDigits: 0,
          defaultValue: 0,
          min: 0,
          max: 100,
          clampValue: true,
          value: _hsv.saturation * 100,
          onChanged: (value) => _changeHsv(saturation: value / 100),
        ),
        ExactSlider(
          header: const Text('V'),
          fractionDigits: 0,
          defaultValue: 100,
          min: 0,
          max: 100,
          clampValue: true,
          value: _hsv.value * 100,
          onChanged: (value) => _changeHsv(value: value / 100),
        ),
      ],
      if (_tab == ColorPickerTab.hsl) ...[
        ExactSlider(
          header: const Text('H'),
          fractionDigits: 0,
          defaultValue: 0,
          min: 0,
          max: 359,
          clampValue: true,
          value: _clampHue(_hsl.hue),
          onChanged: (value) => _changeHsl(hue: value),
        ),
        ExactSlider(
          header: const Text('S'),
          fractionDigits: 0,
          defaultValue: 0,
          min: 0,
          max: 100,
          clampValue: true,
          value: _hsl.saturation * 100,
          onChanged: (value) => _changeHsl(saturation: value / 100),
        ),
        ExactSlider(
          header: const Text('L'),
          fractionDigits: 0,
          defaultValue: 100,
          min: 0,
          max: 100,
          clampValue: true,
          value: _hsl.lightness * 100,
          onChanged: (value) => _changeHsl(lightness: value / 100),
        ),
      ],
      if (widget.suggested.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(
          children: widget.suggested
              .map(
                (e) => SizedBox(
                  height: 64,
                  width: 64,
                  child: ColorButton.srgb(
                    color: e,
                    selected: e.value == color.value,
                    onTap: () => _setColor(e),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ],
  );
}

class ColorWheelPicker extends StatelessWidget {
  final SRGBColor value;
  final void Function(SRGBColor) onChanged;
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
      HSVColor.fromAHSV(
        1,
        hue,
        saturation,
        HSVColor.fromColor(value.toColor()).value,
      ).toSRGB(),
    );
  }

  void _onSliderPointer(PointerEvent event) {
    final ctx = _sliderKey.currentContext;
    if (ctx == null) return;
    final RenderBox box = ctx.findRenderObject() as RenderBox;
    final local = box.globalToLocal(event.position);
    final color = HSVColor.fromColor(value.toColor());
    final hsvValue = min(1.0, max(0.0, local.dx / box.size.width));
    onChanged(color.withValue(hsvValue).toSRGB());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const sliderHeight = 48.0;
        const gap = 8.0;
        final maxWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : 300.0;
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : double.infinity;
        final availableWheelHeight = maxHeight.isFinite
            ? max(0.0, maxHeight - sliderHeight - gap)
            : maxWidth;
        final wheelSize = min(maxWidth, availableWheelHeight).toDouble();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox.square(
              dimension: wheelSize,
              child: GestureDetector(
                onPanUpdate: (details) =>
                    _onWheelPointer(details.globalPosition),
                onPanDown: (details) => _onWheelPointer(details.globalPosition),
                onPanStart: (details) =>
                    _onWheelPointer(details.globalPosition),
                child: CustomPaint(
                  key: _wheelKey,
                  painter: _ColorWheelPainter(value.toColor()),
                ),
              ),
            ),
            const SizedBox(height: gap),
            SizedBox(
              height: sliderHeight,
              child: Listener(
                onPointerDown: _onSliderPointer,
                onPointerMove: _onSliderPointer,
                child: CustomPaint(
                  key: _sliderKey,
                  painter: _ColorWheelSliderPainter(value.toColor()),
                ),
              ),
            ),
          ],
        );
      },
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
          (i) => HSVColor.fromAHSV(1, i.toDouble(), 1, hsv.value).toColor(),
        ), // Generate smooth hues
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
    final rect = Rect.fromPoints(
      const Offset(0, 0),
      Offset(size.width, size.height),
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.black, Colors.white],
        stops: [0, 1],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      paint,
    );
    final point = Offset(size.width * hsv.value, size.height / 2);
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..color = SRGBColor.white.toColor()
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(point, 6, Paint()..color = SRGBColor.black.toColor());
  }

  @override
  bool shouldRepaint(_ColorWheelSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
