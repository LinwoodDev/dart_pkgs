import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

typedef SettingsLeapDisplayName = String Function(BuildContext context);
typedef SettingsLeapKeywordsBuilder =
    Iterable<String> Function(BuildContext context);
typedef SettingsLeapStateReader<S, V> = V Function(S state);
typedef SettingsLeapStateWriter<V> =
    void Function(BuildContext context, V value);
typedef SettingsLeapEnabled<S> = bool Function(BuildContext context, S state);
typedef SettingsLeapPageBuilder<S> =
    Widget Function(BuildContext context, S state, bool inView);
typedef SettingsLeapPageActionsBuilder<S> =
    List<Widget> Function(BuildContext context, S state);
typedef SettingsLeapPageReset<S> = void Function(BuildContext context, S state);
typedef SettingsLeapPageFloatingActionButtonBuilder<S> =
    Widget? Function(BuildContext context, S state);
typedef SettingsLeapAppBarBuilder<S> =
    PreferredSizeWidget Function(
      BuildContext context,
      S state,
      bool inView,
      Widget title,
      List<Widget>? actions,
    );
typedef SettingsLeapCustomSectionBuilder<S> =
    Widget Function(BuildContext context, S state, Widget child);
typedef SettingsLeapSectionHeaderBuilder<S> =
    Widget Function(BuildContext context, S state);
typedef SettingsLeapCustomSettingBuilder<S> =
    Widget Function(BuildContext context, S state);
typedef SettingsLeapOptionLeadingBuilder =
    Widget Function(BuildContext context);
typedef SettingsLeapValueLeadingBuilder<V> =
    Widget Function(BuildContext context, V value);

class _SettingsLeapDescriptionButton extends StatelessWidget {
  const _SettingsLeapDescriptionButton({
    required this.title,
    required this.help,
  });

  final String title;
  final String help;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: help,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.all(4),
    constraints: const BoxConstraints.tightFor(width: 32, height: 32),
    icon: const PhosphorIcon(PhosphorIconsLight.question, size: 20),
    onPressed: () => showLeapBottomSheet<void>(
      context: context,
      titleBuilder: (context) => Text(title),
      childrenBuilder: (context) => [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(help),
        ),
      ],
    ),
  );
}

class _SettingsLeapTitle extends StatelessWidget {
  const _SettingsLeapTitle({required this.title, this.help});

  final String title;
  final String? help;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(fit: FlexFit.loose, child: Text(title)),
      if (help != null)
        _SettingsLeapDescriptionButton(title: title, help: help!),
    ],
  );
}

sealed class SettingsLeapNode<S> {
  const SettingsLeapNode({
    required this.displayName,
    this.description,
    this.descriptionBuilder,
    this.help,
    this.hintBuilder,
    this.icon,
    this.keywords = const [],
    this.keywordsBuilder,
    this.enabled,
  });

  final SettingsLeapDisplayName displayName;
  final String? description;
  final SettingsLeapDisplayName? descriptionBuilder;
  final String? help;
  final SettingsLeapDisplayName? hintBuilder;
  final IconData? icon;
  final List<String> keywords;
  final SettingsLeapKeywordsBuilder? keywordsBuilder;
  final SettingsLeapEnabled<S>? enabled;

  bool isEnabled(BuildContext context, S state) =>
      enabled?.call(context, state) ?? true;

  String getDisplayName(BuildContext context) => displayName(context);

  String? getDescription(BuildContext context) =>
      descriptionBuilder?.call(context) ?? description;

  String? getHelp(BuildContext context) => hintBuilder?.call(context) ?? help;

  Iterable<String> getKeywords(BuildContext context) sync* {
    yield* keywords;
    yield* keywordsBuilder?.call(context) ?? const [];
  }
}

final class SettingsLeapPage<S> extends SettingsLeapNode<S> {
  const SettingsLeapPage({
    required super.displayName,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
    this.sections = const {},
    this.children = const {},
    this.actionsBuilder,
    this.onReset,
    this.floatingActionButtonBuilder,
    this.appBarBuilder,
    this.builder,
  });

  final Map<String, SettingsLeapSection<S>> sections;
  final Map<String, SettingsLeapPage<S>> children;
  final SettingsLeapPageActionsBuilder<S>? actionsBuilder;
  final SettingsLeapPageReset<S>? onReset;
  final SettingsLeapPageFloatingActionButtonBuilder<S>?
  floatingActionButtonBuilder;
  final SettingsLeapAppBarBuilder<S>? appBarBuilder;
  final SettingsLeapPageBuilder<S>? builder;
}

final class SettingsLeapSection<S> {
  const SettingsLeapSection({
    this.displayName,
    this.description,
    this.descriptionBuilder,
    this.help,
    this.hintBuilder,
    this.settings = const [],
    this.keywords = const [],
    this.keywordsBuilder,
    this.headerBuilder,
    this.builder,
    this.wrapBuilder = true,
    this.fillRemaining = false,
  });

  final SettingsLeapDisplayName? displayName;
  final String? description;
  final SettingsLeapDisplayName? descriptionBuilder;
  final String? help;
  final SettingsLeapDisplayName? hintBuilder;
  final List<SettingsLeapSetting<S>> settings;
  final List<String> keywords;
  final SettingsLeapKeywordsBuilder? keywordsBuilder;
  final SettingsLeapSectionHeaderBuilder<S>? headerBuilder;
  final SettingsLeapCustomSectionBuilder<S>? builder;
  final bool wrapBuilder;
  final bool fillRemaining;

  String? getDisplayName(BuildContext context) => displayName?.call(context);

  String? getDescription(BuildContext context) =>
      descriptionBuilder?.call(context) ?? description;

  String? getHelp(BuildContext context) => hintBuilder?.call(context) ?? help;

  Iterable<String> getKeywords(BuildContext context) sync* {
    yield* keywords;
    yield* keywordsBuilder?.call(context) ?? const [];
  }
}

sealed class SettingsLeapSetting<S> extends SettingsLeapNode<S> {
  const SettingsLeapSetting({
    this.id,
    this.disableOptionSearch = false,
    required super.displayName,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final String? id;
  final bool disableOptionSearch;

  Iterable<SettingsLeapNode<S>> buildOptionSearchNodes(
    BuildContext context,
    S state,
  ) sync* {}

  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  });
}

final class SettingsLeapBoolSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapBoolSetting({
    super.id,
    required super.displayName,
    required this.read,
    required this.write,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final SettingsLeapStateReader<S, bool> read;
  final SettingsLeapStateWriter<bool> write;

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    final description = getDescription(context);

    final value = read(state);
    final help = getHelp(context);
    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: _SettingsLeapTitle(title: getDisplayName(context), help: help),
      subtitle: description == null ? null : Text(description),
      trailing: Switch(
        value: value,
        onChanged: (value) => write(context, value),
      ),
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected,
      onTap: () => write(context, !value),
    );
  }
}

final class SettingsLeapOption<V> {
  const SettingsLeapOption({
    required this.id,
    required this.value,
    required this.displayName,
    this.description,
    this.descriptionBuilder,
    this.help,
    this.hintBuilder,
    this.keywords = const [],
    this.keywordsBuilder,
    this.leadingBuilder,
  });

  final String id;
  final V value;
  final SettingsLeapDisplayName displayName;
  final String? description;
  final SettingsLeapDisplayName? descriptionBuilder;
  final String? help;
  final SettingsLeapDisplayName? hintBuilder;
  final List<String> keywords;
  final SettingsLeapKeywordsBuilder? keywordsBuilder;
  final SettingsLeapOptionLeadingBuilder? leadingBuilder;

  String getDisplayName(BuildContext context) => displayName(context);

  String? getDescription(BuildContext context) =>
      descriptionBuilder?.call(context) ?? description;

  String? getHelp(BuildContext context) => hintBuilder?.call(context) ?? help;

  Iterable<String> getKeywords(BuildContext context) sync* {
    yield* keywords;
    yield* keywordsBuilder?.call(context) ?? const [];
  }
}

final class SettingsLeapListSetting<S, V> extends SettingsLeapSetting<S> {
  const SettingsLeapListSetting({
    super.id,
    super.disableOptionSearch,
    required super.displayName,
    required this.options,
    required this.read,
    required this.write,
    this.optionEquals,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final List<SettingsLeapOption<V>> options;
  final SettingsLeapStateReader<S, V> read;
  final SettingsLeapStateWriter<V> write;
  final bool Function(V a, V b)? optionEquals;

  @override
  Iterable<SettingsLeapNode<S>> buildOptionSearchNodes(
    BuildContext context,
    S state,
  ) sync* {
    for (final option in options) {
      yield SettingsLeapOptionSearchNode<S, V>(option: option);
    }
  }

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    final currentValue = read(state);
    final currentOption = _optionForValue(currentValue);
    final description = getDescription(context);
    final help = getHelp(context);

    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: _SettingsLeapTitle(title: getDisplayName(context), help: help),
      trailing: currentOption == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Text(currentOption.getDisplayName(context)),
                if (currentOption.leadingBuilder != null)
                  currentOption.leadingBuilder!(context),
              ],
            ),
      subtitle: description == null ? null : Text(description),
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected,
      onTap: () => _openSheet(context, state),
    );
  }

  Future<void> _openSheet(BuildContext context, S state) {
    final currentValue = read(state);

    return showLeapBottomSheet<void>(
      context: context,
      titleBuilder: (context) => Text(getDisplayName(context)),
      childrenBuilder: (context) => [
        for (final option in options)
          ListTile(
            leading: option.leadingBuilder?.call(context),
            title: _SettingsLeapTitle(
              title: option.getDisplayName(context),
              help: option.getHelp(context),
            ),
            subtitle: switch (option.getDescription(context)) {
              final description? => Text(description),
              null => null,
            },
            selected: _isSelected(option.value, currentValue),
            onTap: () {
              write(context, option.value);
              Navigator.of(context).pop();
            },
          ),
      ],
    );
  }

  SettingsLeapOption<V>? _optionForValue(V value) {
    for (final option in options) {
      if (_isSelected(option.value, value)) return option;
    }
    return null;
  }

  bool _isSelected(V a, V b) => optionEquals?.call(a, b) ?? a == b;
}

final class SettingsLeapEnumSetting<S, V> extends SettingsLeapSetting<S> {
  const SettingsLeapEnumSetting({
    super.id,
    super.disableOptionSearch,
    required super.displayName,
    required this.values,
    required this.read,
    required this.write,
    required this.valueLabel,
    this.valueDescription,
    this.valueLeadingBuilder,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final List<V> values;
  final SettingsLeapStateReader<S, V> read;
  final SettingsLeapStateWriter<V> write;
  final String Function(BuildContext context, V value) valueLabel;
  final String Function(BuildContext context, V value)? valueDescription;
  final SettingsLeapValueLeadingBuilder<V>? valueLeadingBuilder;

  @override
  Iterable<SettingsLeapNode<S>> buildOptionSearchNodes(
    BuildContext context,
    S state,
  ) sync* {
    for (final value in values) {
      yield SettingsLeapOptionSearchNode<S, V>(option: _buildOption(value));
    }
  }

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    return _asListSetting().buildTile(
      context,
      state,
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected,
    );
  }

  SettingsLeapListSetting<S, V> _asListSetting() {
    return SettingsLeapListSetting<S, V>(
      displayName: displayName,
      description: description,
      descriptionBuilder: descriptionBuilder,
      help: help,
      hintBuilder: hintBuilder,
      icon: icon,
      keywords: keywords,
      keywordsBuilder: keywordsBuilder,
      enabled: enabled,
      disableOptionSearch: disableOptionSearch,
      options: [for (final value in values) _buildOption(value)],
      read: read,
      write: write,
    );
  }

  SettingsLeapOption<V> _buildOption(V value) {
    return SettingsLeapOption<V>(
      id: value is Enum ? value.name : value.toString(),
      value: value,
      displayName: (context) => valueLabel(context, value),
      descriptionBuilder: valueDescription == null
          ? null
          : (context) => valueDescription!(context, value),
      leadingBuilder: valueLeadingBuilder == null
          ? null
          : (context) => valueLeadingBuilder!(context, value),
    );
  }
}

final class SettingsLeapSliderSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapSliderSetting({
    super.id,
    required super.displayName,
    required this.read,
    required this.write,
    this.min = 0,
    this.max = 100,
    this.defaultValue,
    this.fractionDigits = 2,
    this.divisions = false,
    this.onChangeEnd,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final SettingsLeapStateReader<S, double> read;
  final SettingsLeapStateWriter<double> write;
  final SettingsLeapStateWriter<double>? onChangeEnd;
  final double min;
  final double max;
  final double? defaultValue;
  final int fractionDigits;
  final bool divisions;

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    final title = getDisplayName(context);
    final help = getHelp(context);
    return ExactSlider(
      leading: icon == null ? null : Icon(icon),
      header: _SettingsLeapTitle(title: title, help: help),
      subtitle: switch (getDescription(context)) {
        final description? => Text(description),
        null => null,
      },
      value: read(state),
      min: min,
      max: max,
      defaultValue: defaultValue,
      fractionDigits: fractionDigits,
      divide: divisions,
      clampValue: true,
      onChanged: (value) => write(context, value),
      onChangeEnd: onChangeEnd == null
          ? null
          : (value) => onChangeEnd!(context, value),
    );
  }
}

final class SettingsLeapAdvancedSwitchSetting<S, V>
    extends SettingsLeapSetting<S> {
  const SettingsLeapAdvancedSwitchSetting({
    super.id,
    super.disableOptionSearch,
    required super.displayName,
    required this.options,
    required this.readEnabled,
    required this.writeEnabled,
    required this.read,
    required this.write,
    this.optionEquals,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final List<SettingsLeapOption<V>> options;
  final SettingsLeapStateReader<S, bool> readEnabled;
  final SettingsLeapStateWriter<bool> writeEnabled;
  final SettingsLeapStateReader<S, V> read;
  final SettingsLeapStateWriter<V> write;
  final bool Function(V a, V b)? optionEquals;

  SettingsLeapListSetting<S, V> _asListSetting() =>
      SettingsLeapListSetting<S, V>(
        displayName: displayName,
        options: options,
        read: read,
        write: write,
        optionEquals: optionEquals,
        disableOptionSearch: disableOptionSearch,
      );

  @override
  Iterable<SettingsLeapNode<S>> buildOptionSearchNodes(
    BuildContext context,
    S state,
  ) => _asListSetting().buildOptionSearchNodes(context, state);

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    final listSetting = _asListSetting();
    final currentOption = listSetting._optionForValue(read(state));
    final help = getHelp(context);
    return AdvancedSwitchListTile(
      leading: icon == null ? null : Icon(icon),
      title: _SettingsLeapTitle(title: getDisplayName(context), help: help),
      subtitle: switch (getDescription(context)) {
        final description? => Text(description),
        null => null,
      },
      trailing: currentOption == null
          ? null
          : Text(currentOption.getDisplayName(context)),
      selected: selected,
      value: readEnabled(state),
      onTap: () => listSetting._openSheet(context, state),
      onChanged: (value) => writeEnabled(context, value),
    );
  }
}

final class SettingsLeapActionSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapActionSetting({
    super.id,
    required super.displayName,
    required this.onTap,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final void Function(BuildContext context) onTap;

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    final description = getDescription(context);
    final help = getHelp(context);

    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: _SettingsLeapTitle(title: getDisplayName(context), help: help),
      subtitle: description == null ? null : Text(description),
      focusNode: focusNode,
      autofocus: autofocus,
      selected: selected,
      onTap: () => onTap(context),
    );
  }
}

final class SettingsLeapCustomSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapCustomSetting({
    super.id,
    required super.displayName,
    required this.builder,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final SettingsLeapCustomSettingBuilder<S> builder;

  @override
  Widget buildTile(
    BuildContext context,
    S state, {
    FocusNode? focusNode,
    bool autofocus = false,
    bool selected = false,
  }) {
    return builder(context, state);
  }
}

final class SettingsLeapOptionSearchNode<S, V> extends SettingsLeapNode<S> {
  SettingsLeapOptionSearchNode({required SettingsLeapOption<V> option})
    : optionId = option.id,
      super(
        displayName: option.displayName,
        description: option.description,
        descriptionBuilder: option.descriptionBuilder,
        help: option.help,
        hintBuilder: option.hintBuilder,
        keywords: option.keywords,
        keywordsBuilder: option.keywordsBuilder,
      );

  final String optionId;
}

final class SettingsLeapSectionSearchNode<S> extends SettingsLeapNode<S> {
  const SettingsLeapSectionSearchNode({
    required super.displayName,
    super.description,
    super.descriptionBuilder,
    super.help,
    super.hintBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });
}

final class SettingsLeapSearchResult<S> {
  const SettingsLeapSearchResult({
    required this.id,
    required this.node,
    required this.parents,
    required this.score,
    required this.pageId,
    this.focusId,
  });

  final String id;
  final SettingsLeapNode<S> node;
  final List<SettingsLeapNode<S>> parents;
  final int score;
  final String pageId;
  final String? focusId;

  String breadcrumb(BuildContext context) => [
    ...parents.map((parent) => parent.getDisplayName(context)),
    node.getDisplayName(context),
  ].join(' / ');
}

final class SettingsLeapFlatNode<S> {
  const SettingsLeapFlatNode({
    required this.id,
    required this.node,
    required this.parents,
    required this.pageId,
    this.focusId,
  });

  final String id;
  final SettingsLeapNode<S> node;
  final List<SettingsLeapNode<S>> parents;
  final String pageId;
  final String? focusId;
}
