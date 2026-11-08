import 'package:material_ui/material_ui.dart';

import 'number_input.dart';

class OffsetListTile extends StatelessWidget {
  final Offset value;
  final ValueChanged<Offset> onChanged;
  final Widget? title, subtitle, leading, trailing;
  final String? xLabel, yLabel;
  final int fractionDigits;
  final EdgeInsetsGeometry? contentPadding;

  /// Null keeps the standard list tile on wide panels and stacks narrow ones.
  /// True places the title and both fields on one row; false stacks the title.
  final bool? inline;
  final bool trimTrailingZeros;
  final double spacing, titleSpacing, min, max;

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
    this.inline,
    this.trimTrailingZeros = false,
    this.spacing = 4,
    this.titleSpacing = 16,
    this.min = double.negativeInfinity,
    this.max = double.infinity,
  }) : assert(fractionDigits >= 0 && fractionDigits <= 20),
       assert(spacing >= 0 && titleSpacing >= 0),
       assert(min <= max);

  int _digits(double number) {
    if (!trimTrailingZeros) return fractionDigits;
    final text = number
        .toStringAsFixed(fractionDigits)
        .replaceFirst(RegExp(r'0+$'), '');
    final point = text.indexOf('.');
    return point < 0 ? 0 : text.length - point - 1;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      Widget field(bool x) => NumberInput(
        key: ValueKey(x),
        value: x ? value.dx : value.dy,
        fractionDigits: _digits(x ? value.dx : value.dy),
        roundValues: true,
        min: min,
        max: max,
        label: x ? xLabel ?? 'X' : yLabel ?? 'Y',
        showButtons: false,
        updateOnInput: true,
        onChanged: (number) =>
            onChanged(x ? Offset(number, value.dy) : Offset(value.dx, number)),
      );
      if (inline == null && constraints.maxWidth >= 350) {
        return ListTile(
          title: title,
          subtitle: subtitle,
          leading: leading,
          contentPadding: contentPadding,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (trailing != null) ...[trailing!, const SizedBox(width: 4)],
              SizedBox(width: 100, child: field(true)),
              SizedBox(width: spacing),
              SizedBox(width: 100, child: field(false)),
            ],
          ),
        );
      }
      final fields = Row(
        children: [
          Expanded(child: field(true)),
          SizedBox(width: spacing),
          Expanded(child: field(false)),
        ],
      );
      final style =
          ListTileTheme.of(context).titleTextStyle ??
          Theme.of(context).textTheme.bodyLarge;
      return Padding(
        padding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (inline == true)
              Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 8)],
                  if (title != null) ...[
                    DefaultTextStyle.merge(style: style, child: title!),
                    SizedBox(width: titleSpacing),
                  ],
                  Expanded(child: fields),
                  if (trailing != null) ...[
                    const SizedBox(width: 4),
                    trailing!,
                  ],
                ],
              )
            else ...[
              if (title != null || leading != null || trailing != null) ...[
                Row(
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: style,
                        child: title ?? const SizedBox(),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                const SizedBox(height: 8),
              ],
              fields,
            ],
            if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
          ],
        ),
      );
    },
  );
}
