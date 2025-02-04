import 'package:flutter/material.dart';

class OffsetListTile extends StatefulWidget {
  final Offset value;
  final ValueChanged<Offset> onChanged;
  final Widget? title, subtitle, leading, trailing;
  final String? xLabel, yLabel;
  final int fractionDigits;
  final EdgeInsetsGeometry? contentPadding;

  const OffsetListTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.fractionDigits = 2,
    this.xLabel,
    this.yLabel,
    this.contentPadding,
  });

  @override
  State<OffsetListTile> createState() => _OffsetListTileState();
}

class _OffsetListTileState extends State<OffsetListTile> {
  final TextEditingController _xController = TextEditingController(),
      _yController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _updateValue(widget.value);
  }

  @override
  void dispose() {
    super.dispose();

    _xController.dispose();
    _yController.dispose();
  }

  @override
  void didUpdateWidget(covariant OffsetListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value) {
      _updateValue(widget.value);
    }
  }

  void _updateValue(Offset value) {
    final x = value.dx.toStringAsFixed(widget.fractionDigits);
    if (_xController.text != x) _xController.text = x;
    final y = value.dy.toStringAsFixed(widget.fractionDigits);
    if (_yController.text != y) _yController.text = y;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: widget.title,
        subtitle: widget.subtitle,
        leading: widget.leading,
        contentPadding: widget.contentPadding,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(width: 4),
            ],
            SizedBox(
              width: 100,
              child: TextField(
                decoration: InputDecoration(
                  labelText: widget.xLabel ?? 'X',
                  filled: true,
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: _xController,
                onChanged: (value) => widget
                    .onChanged(Offset(double.parse(value), widget.value.dy)),
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 100,
              child: TextField(
                decoration: InputDecoration(
                  labelText: widget.yLabel ?? 'Y',
                  filled: true,
                  floatingLabelAlignment: FloatingLabelAlignment.center,
                ),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                controller: _yController,
                onChanged: (value) => widget
                    .onChanged(Offset(widget.value.dx, double.parse(value))),
              ),
            ),
          ],
        ));
  }
}
