import 'package:flutter/material.dart';
import 'package:material_leap/src/widgets/color_button.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/leap_localizations.dart';
import '../widgets/exact_slider.dart';
import '../widgets/header.dart';
import '../helpers/color.dart';

class ColorPickerResponse<T> {
  final int color;
  final T? action;

  const ColorPickerResponse(this.color, [this.action]);
}

typedef ActionsBuilder<T> = List<Widget> Function(void Function(T?) close);

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
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 1000),
        child: Column(
          children: [
            Header(
              title: Text(LeapLocalizations.of(context).color),
              leading: const PhosphorIcon(PhosphorIconsLight.palette),
            ),
            Flexible(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: LayoutBuilder(builder: (context, constraints) {
                  var isMobile = constraints.maxWidth < 600;
                  return Column(
                    children: [
                      Expanded(
                          child: isMobile
                              ? SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildPreview(),
                                      _buildProperties(),
                                    ],
                                  ),
                                )
                              : Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                      Expanded(
                                          flex: 2,
                                          child: SingleChildScrollView(
                                            child: _buildPreview(),
                                          )),
                                      Expanded(
                                          flex: 3,
                                          child: SingleChildScrollView(
                                            child: _buildProperties(),
                                          ))
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
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() => Column(
        children: [
          Align(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: 200,
                height: 200,
                color: color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
      );

  Widget _buildProperties() => Column(children: [
        ExactSlider(
          header: Text(LeapLocalizations.of(context).red),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          value: color.red.toDouble(),
          color: Colors.red,
          onChanged: (value) => _changeColor(red: value.toInt()),
        ),
        ExactSlider(
          header: Text(LeapLocalizations.of(context).green),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          value: color.green.toDouble(),
          color: Colors.green,
          onChanged: (value) => _changeColor(green: value.toInt()),
        ),
        ExactSlider(
          header: Text(LeapLocalizations.of(context).blue),
          fractionDigits: 0,
          defaultValue: 255,
          min: 0,
          max: 255,
          color: Colors.blue,
          value: color.blue.toDouble(),
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
