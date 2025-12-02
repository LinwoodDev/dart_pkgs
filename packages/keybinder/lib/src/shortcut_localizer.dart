import 'package:flutter/widgets.dart';
import '../l10n/keybinder_localizations.dart';

/// Helper class to localize shortcut activators.
class ShortcutLocalizer {
  /// Localizes the given [activator] using the [context].
  static String localize(BuildContext context, ShortcutActivator activator) {
    final l10n = KeybinderLocalizations.of(context);

    if (activator is SingleActivator) {
      final ctrl = activator.control ? "${l10n.controlKey}+" : "";
      final shift = activator.shift ? "${l10n.shiftKey}+" : "";
      final alt = activator.alt ? "${l10n.altKey}+" : "";
      final meta = activator.meta ? "${l10n.metaKey}+" : "";
      return "$ctrl$shift$alt$meta${activator.trigger.keyLabel}";
    }

    return activator.toString();
  }
}
