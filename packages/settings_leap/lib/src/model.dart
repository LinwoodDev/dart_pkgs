import 'package:flutter/material.dart';

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

sealed class SettingsLeapNode<S> {
  const SettingsLeapNode({
    required this.displayName,
    this.description,
    this.descriptionBuilder,
    this.icon,
    this.keywords = const [],
    this.keywordsBuilder,
    this.enabled,
  });

  final SettingsLeapDisplayName displayName;
  final String? description;
  final SettingsLeapDisplayName? descriptionBuilder;
  final IconData? icon;
  final List<String> keywords;
  final SettingsLeapKeywordsBuilder? keywordsBuilder;
  final SettingsLeapEnabled<S>? enabled;

  bool isEnabled(BuildContext context, S state) =>
      enabled?.call(context, state) ?? true;

  String getDisplayName(BuildContext context) => displayName(context);

  String? getDescription(BuildContext context) =>
      descriptionBuilder?.call(context) ?? description;

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
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
    this.sections = const {},
    this.children = const {},
    this.actionsBuilder,
    this.floatingActionButtonBuilder,
    this.appBarBuilder,
    this.builder,
  });

  final Map<String, SettingsLeapSection<S>> sections;
  final Map<String, SettingsLeapPage<S>> children;
  final SettingsLeapPageActionsBuilder<S>? actionsBuilder;
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

  Iterable<String> getKeywords(BuildContext context) sync* {
    yield* keywords;
    yield* keywordsBuilder?.call(context) ?? const [];
  }
}

sealed class SettingsLeapSetting<S> extends SettingsLeapNode<S> {
  const SettingsLeapSetting({
    this.id,
    required super.displayName,
    super.description,
    super.descriptionBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final String? id;

  Widget buildTile(BuildContext context, S state);
}

final class SettingsLeapBoolSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapBoolSetting({
    required super.displayName,
    required this.read,
    required this.write,
    super.description,
    super.descriptionBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final SettingsLeapStateReader<S, bool> read;
  final SettingsLeapStateWriter<bool> write;

  @override
  Widget buildTile(BuildContext context, S state) {
    final description = getDescription(context);

    return SwitchListTile(
      secondary: icon == null ? null : Icon(icon),
      title: Text(getDisplayName(context)),
      subtitle: description == null ? null : Text(description),
      value: read(state),
      onChanged: (value) => write(context, value),
    );
  }
}

final class SettingsLeapEnumSetting<S, V> extends SettingsLeapSetting<S> {
  const SettingsLeapEnumSetting({
    required super.displayName,
    required this.values,
    required this.read,
    required this.write,
    required this.valueLabel,
    super.description,
    super.descriptionBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final List<V> values;
  final SettingsLeapStateReader<S, V> read;
  final SettingsLeapStateWriter<V> write;
  final String Function(BuildContext context, V value) valueLabel;

  @override
  Widget buildTile(BuildContext context, S state) {
    final currentValue = read(state);

    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(getDisplayName(context)),
      subtitle: Text(valueLabel(context, currentValue)),
      onTap: () => _openSheet(context, state),
    );
  }

  Future<void> _openSheet(BuildContext context, S state) {
    final currentValue = read(state);

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(getDisplayName(context))),
            for (final value in values)
              ListTile(
                title: Text(valueLabel(context, value)),
                selected: value == currentValue,
                onTap: () {
                  write(context, value);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

final class SettingsLeapActionSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapActionSetting({
    required super.displayName,
    required this.onTap,
    super.description,
    super.descriptionBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final void Function(BuildContext context) onTap;

  @override
  Widget buildTile(BuildContext context, S state) {
    final description = getDescription(context);

    return ListTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(getDisplayName(context)),
      subtitle: description == null ? null : Text(description),
      onTap: () => onTap(context),
    );
  }
}

final class SettingsLeapCustomSetting<S> extends SettingsLeapSetting<S> {
  const SettingsLeapCustomSetting({
    required super.displayName,
    required this.builder,
    super.description,
    super.descriptionBuilder,
    super.icon,
    super.keywords,
    super.keywordsBuilder,
    super.enabled,
  });

  final SettingsLeapCustomSettingBuilder<S> builder;

  @override
  Widget buildTile(BuildContext context, S state) {
    return builder(context, state);
  }
}

final class SettingsLeapSectionSearchNode<S> extends SettingsLeapNode<S> {
  const SettingsLeapSectionSearchNode({
    required super.displayName,
    super.description,
    super.descriptionBuilder,
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
  });

  final String id;
  final SettingsLeapNode<S> node;
  final List<SettingsLeapNode<S>> parents;
  final int score;

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
  });

  final String id;
  final SettingsLeapNode<S> node;
  final List<SettingsLeapNode<S>> parents;
}
