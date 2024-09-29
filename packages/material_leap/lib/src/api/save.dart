import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/l10n/leap_localizations.dart';

void saveToClipboard(BuildContext context, String text,
    {Widget? leading, SnackBarBehavior? behavior}) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: behavior ?? SnackBarBehavior.floating,
    content: Row(mainAxisSize: MainAxisSize.min, children: [
      if (leading != null) ...[
        leading,
        const SizedBox(width: 8),
      ],
      Text(LeapLocalizations.of(context).copyMessage),
    ]),
  ));
}
