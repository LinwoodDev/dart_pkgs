import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/l10n/leap_localizations.dart';

void saveToClipboard(
  BuildContext context,
  String text, {
  Widget? leading,
  SnackBarBehavior? behavior = SnackBarBehavior.floating,
  double? width = 300,
}) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: behavior,
    width: width,
    content: Row(mainAxisSize: MainAxisSize.min, children: [
      if (leading != null) ...[
        leading,
        const SizedBox(width: 8),
      ],
      Text(LeapLocalizations.of(context).copyMessage),
    ]),
  ));
}
