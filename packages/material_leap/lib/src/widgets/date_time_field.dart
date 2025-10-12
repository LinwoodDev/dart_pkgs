import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:dart_leap/dart_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DateTimeField extends StatefulWidget {
  final DateTime? initialValue;
  final String label;
  final Widget? icon;
  final bool canBeEmpty;
  final ValueChanged<DateTime?> onChanged;
  final bool filled;
  final bool showTime;

  const DateTimeField({
    super.key,
    this.initialValue,
    required this.label,
    required this.onChanged,
    this.canBeEmpty = false,
    this.icon,
    this.filled = true,
    this.showTime = true,
  });

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  DateTime? _value;
  final TextEditingController _controller = TextEditingController();
  String? _locale;
  late final DateFormat _dateFormat, _timeFormat;

  @override
  void initState() {
    super.initState();

    _value = widget.initialValue;

    WidgetsBinding.instance.addPostFrameCallback((_) => setup());
  }

  void setup() {
    _locale = Localizations.localeOf(context).languageCode;
    initializeDateFormatting(_locale);
    _dateFormat = DateFormat.yMd(_locale);
    _timeFormat = DateFormat.Hm(_locale);
    _controller.text = _value == null ? '' : _format(_value!);
  }

  void _change(DateTime? value) {
    setState(() {
      _value = value;
    });
    _controller.text = _value == null ? '' : _format(_value!);
    widget.onChanged(value);
  }

  String _format(DateTime value) => widget.showTime
      ? '${_dateFormat.format(value)} ${_timeFormat.format(value)}'
      : _dateFormat.format(value);

  void _onChanged() {
    try {
      final text = _controller.text.trim();
      if ((text.isEmpty && _value == null) ||
          (_value != null && text == _format(_value!))) {
        return;
      }
      if (text.isEmpty) {
        _change(null);
        return;
      }
      if (!widget.showTime) {
        final date = _dateFormat.parse(text);
        final hour = _value?.hour ?? 0;
        final minute = _value?.minute ?? 0;
        _change(DateTime(date.year, date.month, date.day, hour, minute));
      } else {
        final splitted = text.split(' ');
        if (splitted.length != 2) {
          _change(null);
        } else {
          final date = _dateFormat.parse(splitted[0]);
          final time = _timeFormat.parse(splitted[1]);
          _change(
            DateTime(date.year, date.month, date.day, time.hour, time.minute),
          );
        }
      }
    } catch (_) {
      _change(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final useValue = _value ?? DateTime.now();
    return TextFormField(
      controller: _controller,
      onFieldSubmitted: (_) => _onChanged(),
      onTapOutside: (_) => _onChanged(),
      onEditingComplete: _onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        icon: widget.icon,
        filled: widget.filled,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const PhosphorIcon(PhosphorIconsLight.calendarBlank),
              onPressed: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: useValue,
                  firstDate: DateTime.fromMicrosecondsSinceEpoch(0),
                  lastDate: useValue.addYears(200),
                );
                if (result != null) {
                  _change(
                    widget.showTime
                        ? DateTime(
                            result.year,
                            result.month,
                            result.day,
                            useValue.hour,
                            useValue.minute,
                          )
                        : DateTime(
                            result.year,
                            result.month,
                            result.day,
                            _value?.hour ?? 0,
                            _value?.minute ?? 0,
                          ),
                  );
                }
              },
            ),
            if (widget.showTime)
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsLight.clock),
                onPressed: () async {
                  final result = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(useValue),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(
                          context,
                        ).copyWith(alwaysUse24HourFormat: false),
                        child: child ?? const SizedBox(),
                      );
                    },
                  );
                  if (result != null) {
                    _change(
                      DateTime(
                        useValue.year,
                        useValue.month,
                        useValue.day,
                        result.hour,
                        result.minute,
                      ),
                    );
                  }
                },
              ),
            if (widget.canBeEmpty)
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsLight.x),
                onPressed: () {
                  _change(null);
                },
              ),
          ],
        ),
      ),
    );
  }
}
