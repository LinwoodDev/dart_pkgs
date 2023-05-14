import 'package:flutter/material.dart';
import 'package:material_leap/src/helpers/color.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../l10n/leap_localizations.dart';
import '../widgets/exact_slider.dart';
import '../widgets/header.dart';

class ColorPickerResponse {
  final int color;
  final bool pin;
  final bool delete;

  const ColorPickerResponse(this.color,
      [this.pin = false, this.delete = false]);
}

class ColorPicker extends StatefulWidget {
  final Color defaultColor;
  final Color? value;
  final bool pinOption, deleteOption;

  const ColorPicker(
      {super.key,
      this.value,
      this.defaultColor = Colors.white,
      this.pinOption = false,
      this.deleteOption = false});

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
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

  @override
  Widget build(BuildContext context) {
    if (_getColorValueFromHexString(_hexController.text) != color.value) {
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
                              : Row(children: [
                                  Expanded(flex: 2, child: _buildPreview()),
                                  Expanded(
                                      flex: 3,
                                      child: SingleChildScrollView(
                                          child: _buildProperties()))
                                ])),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.deleteOption) ...[
                            MaterialButton(
                                onPressed: () => Navigator.of(context).pop(
                                    ColorPickerResponse(
                                        color.value, false, true)),
                                child:
                                    Text(LeapLocalizations.of(context).delete)),
                          ] else ...[
                            Container(),
                          ],
                          Row(children: [
                            TextButton(
                                child: Text(MaterialLocalizations.of(context)
                                    .cancelButtonLabel),
                                onPressed: () => Navigator.of(context).pop()),
                            const SizedBox(width: 8),
                            if (widget.pinOption) ...[
                              OutlinedButton(
                                  child: Text(MaterialLocalizations.of(context)
                                      .okButtonLabel),
                                  onPressed: () => Navigator.of(context).pop(
                                      ColorPickerResponse(color.value, false))),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                  child:
                                      Text(LeapLocalizations.of(context).pin),
                                  onPressed: () => Navigator.of(context).pop(
                                      ColorPickerResponse(color.value, true))),
                            ] else
                              ElevatedButton(
                                  child: Text(MaterialLocalizations.of(context)
                                      .okButtonLabel),
                                  onPressed: () => Navigator.of(context).pop(
                                      ColorPickerResponse(color.value, false))),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
                constraints:
                    const BoxConstraints(maxHeight: 200, maxWidth: 200),
                color: color),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: TextField(
              controller: _hexController,
              decoration: const InputDecoration(filled: true),
              onSubmitted: (value) {
                final valueNumber = _getColorValueFromHexString(value);
                if (valueNumber == null) return;
                setState(() {
                  color = Color(valueNumber).withAlpha(255);
                });
              },
            ),
          ),
        ],
      );

  int? _getColorValueFromHexString(String value) {
    value = value.trim();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3) {
      value = 'f$value';
    } else if (value.length == 6) {
      value = 'ff$value';
    }
    if (value.length == 4) {
      value = value[0] +
          value[0] +
          value[1] +
          value[1] +
          value[2] +
          value[2] +
          value[3] +
          value[3];
    }
    value = value.trim();
    return int.tryParse(value, radix: 16);
  }

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
      ]);
}
