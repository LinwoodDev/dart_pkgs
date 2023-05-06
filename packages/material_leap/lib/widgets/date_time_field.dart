import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_leap/helpers/date_time.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DateTimeField extends StatefulWidget {
  final DateTime? initialValue;
  final String label;
  final Widget? icon;
  final bool canBeEmpty;
  final ValueChanged<DateTime?> onChanged;

  const DateTimeField({
    super.key,
    this.initialValue,
    required this.label,
    required this.onChanged,
    this.canBeEmpty = false,
    this.icon,
  });

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  late DateTime? _value;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _change(DateTime? value) {
    setState(() {
      _value = value;
    });
    widget.onChanged(value);
  }

  String _format(DateTime value) {
    String locale = Localizations.localeOf(context).languageCode;
    return '${DateFormat.yMd(locale).format(value)} ${DateFormat.Hm().format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final useValue = _value ?? DateTime.now();
    _controller.text = _value == null ? '' : _format(useValue);
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        icon: widget.icon ?? const PhosphorIcon(PhosphorIconsLight.calendar),
        suffix: Row(
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
                    _change(DateTime(result.year, result.month, result.day,
                        useValue.hour, useValue.minute));
                  }
                }),
            IconButton(
                icon: const PhosphorIcon(PhosphorIconsLight.clock),
                onPressed: () async {
                  final result = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(useValue),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(alwaysUse24HourFormat: false),
                        child: child ?? const SizedBox(),
                      );
                    },
                  );
                  if (result != null) {
                    _change(DateTime(useValue.year, useValue.month,
                        useValue.day, result.hour, result.minute));
                  }
                }),
            if (widget.canBeEmpty)
              IconButton(
                  icon: const PhosphorIcon(PhosphorIconsLight.x),
                  onPressed: () {
                    _change(null);
                  }),
          ],
        ),
      ),
    );
  }
}
