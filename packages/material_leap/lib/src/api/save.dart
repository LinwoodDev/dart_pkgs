import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_leap/l10n/leap_localizations.dart';

void saveToClipboard(BuildContext context, String text) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(LeapLocalizations.of(context).copyMessage),
  ));
}
