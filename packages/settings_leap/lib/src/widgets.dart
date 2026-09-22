import 'dart:ui';

import 'package:material_ui/material_ui.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'model.dart';
import 'search.dart';

typedef SettingsLeapPageOpener<S> =
    void Function(
      BuildContext context,
      String id,
      SettingsLeapPage<S> page,
      String? focusedId,
    );

/// Opens a settings view in a dialog with its own page stack.
Future<T?> showSettingsLeapDialog<T>({
  required BuildContext context,
  required Widget child,
  BoxConstraints constraints = const BoxConstraints(
    maxHeight: 800,
    maxWidth: 1000,
  ),
}) => showGeneralDialog<T>(
  context: context,
  pageBuilder: (context, animation, secondaryAnimation) => ScaffoldMessenger(
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),
        ),
        Dialog(
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: constraints,
            child: SettingsLeapDialogNavigator(child: child),
          ),
        ),
      ],
    ),
  ),
  barrierDismissible: true,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  transitionDuration: const Duration(milliseconds: 200),
  transitionBuilder: (context, animation, secondaryAnimation, child) =>
      SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutQuart)).animate(animation),
        child: child,
      ),
);

/// Keeps settings subpages within the bounds of a dialog.
///
/// Place this around [SettingsLeapView] when it is shown in a dialog. Pages
/// opened by the view use this navigator, while [maybePush] also lets custom
/// settings tiles open their own pages in the same dialog.
class SettingsLeapDialogNavigator extends StatefulWidget {
  const SettingsLeapDialogNavigator({super.key, required this.child});

  final Widget child;

  static bool maybePush(BuildContext context, Widget page) {
    if (context
            .dependOnInheritedWidgetOfExactType<_SettingsLeapDialogScope>() ==
        null) {
      return false;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => page));
    return true;
  }

  @override
  State<SettingsLeapDialogNavigator> createState() =>
      _SettingsLeapDialogNavigatorState();
}

class _SettingsLeapDialogNavigatorState
    extends State<SettingsLeapDialogNavigator> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (didPop) return;
      final navigator = _navigatorKey.currentState;
      if (navigator?.canPop() ?? false) {
        navigator!.pop();
      } else {
        Navigator.of(context).pop();
      }
    },
    child: _SettingsLeapDialogScope(
      child: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) =>
            MaterialPageRoute<void>(builder: (context) => widget.child),
      ),
    ),
  );
}

class _SettingsLeapDialogScope extends InheritedWidget {
  const _SettingsLeapDialogScope({required super.child});

  @override
  bool updateShouldNotify(_SettingsLeapDialogScope oldWidget) => false;
}

class SettingsLeapView<S> extends StatefulWidget {
  const SettingsLeapView({
    super.key,
    required this.tree,
    required this.state,
    this.title = defaultSettingsLeapTitle,
    this.searchHint = defaultSettingsLeapSearchHint,
    this.selectedId,
    this.onSelected,
    this.onOpenPage,
    this.isDialog = false,
    this.closeButton,
    this.compactWidth = 600,
    this.emptySearch,
    this.emptySearchText = 'No results',
    this.searchFieldMargin = const EdgeInsets.all(16),
    this.cardMargin = const EdgeInsets.all(8),
    this.cardPadding = const EdgeInsets.all(16),
    this.sectionTitlePadding = const EdgeInsets.only(
      left: 16,
      top: 8,
      right: 16,
      bottom: 8,
    ),
  });

  final SettingsLeapTree<S> tree;
  final S state;
  final SettingsLeapDisplayName title;
  final SettingsLeapDisplayName searchHint;
  final String? selectedId;
  final ValueChanged<String>? onSelected;
  final SettingsLeapPageOpener<S>? onOpenPage;
  final bool isDialog;
  final Widget? closeButton;
  final double compactWidth;
  final Widget? emptySearch;
  final String emptySearchText;
  final EdgeInsetsGeometry searchFieldMargin;
  final EdgeInsetsGeometry cardMargin;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry sectionTitlePadding;

  @override
  State<SettingsLeapView<S>> createState() => _SettingsLeapViewState<S>();
}

class _SettingsLeapViewState<S> extends State<SettingsLeapView<S>> {
  final _searchController = TextEditingController();
  late final ValueNotifier<S> _stateNotifier;
  String? _selectedId;
  String? _focusedId;

  @override
  void initState() {
    super.initState();
    _stateNotifier = ValueNotifier(widget.state);
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(covariant SettingsLeapView<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _stateNotifier.value = widget.state;
    });
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _stateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < widget.compactWidth;
    final query = _searchController.text;
    final results = widget.tree.search(context, widget.state, query);
    final rootEntries = widget.tree.pages.entries
        .where((entry) => entry.value.isEnabled(context, widget.state))
        .toList();
    final selectedRootId = _selectedId?.split('.').first;
    final selectedRootIndex = selectedRootId == null
        ? 0
        : rootEntries.indexWhere((entry) => entry.key == selectedRootId);
    final selectedRootEntry = rootEntries.elementAtOrNull(
      selectedRootIndex < 0 ? 0 : selectedRootIndex,
    );
    final selectedPageId = _selectedId ?? selectedRootEntry?.key;
    final selectedPage = selectedPageId == null
        ? null
        : widget.tree.pageById(selectedPageId) ?? selectedRootEntry?.value;
    final resolvedPageId = selectedPage == null
        ? null
        : widget.tree.pageById(selectedPageId!) == null
        ? selectedRootEntry?.key
        : selectedPageId;
    final closeButton = widget.closeButton ?? _buildCloseButton(context);
    final emptySearch = widget.emptySearch ?? _buildEmptySearch(context);

    if (isMobile) {
      return Column(
        children: [
          if (widget.isDialog)
            _SettingsLeapHeader(
              title: widget.title(context),
              closeButton: closeButton,
            ),
          SettingsLeapSearchField(
            controller: _searchController,
            hintText: widget.searchHint(context),
            margin: widget.searchFieldMargin,
            onChanged: (_) => setState(() {}),
          ),
          if (query.trim().isEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: rootEntries.length,
                itemBuilder: (context, index) {
                  final entry = rootEntries[index];
                  return SettingsLeapPageTile(
                    page: entry.value,
                    onTap: () => _openPage(entry.key, entry.value),
                  );
                },
              ),
            )
          else
            Expanded(
              child: SettingsLeapSearchResults<S>(
                results: results,
                empty: emptySearch,
                onTap: (result) {
                  final page = widget.tree.pageById(result.pageId);
                  if (page != null) {
                    _openPage(result.pageId, page, result.focusId);
                  }
                },
              ),
            ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (query.trim().isEmpty)
          NavigationDrawer(
            selectedIndex: selectedRootIndex < 0 ? null : selectedRootIndex,
            onDestinationSelected: (index) => _select(rootEntries[index].key),
            header: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDrawerHeader(context, closeButton),
                SettingsLeapSearchField(
                  controller: _searchController,
                  hintText: widget.searchHint(context),
                  margin: widget.searchFieldMargin,
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
            children: [
              for (final entry in rootEntries)
                NavigationDrawerDestination(
                  icon: entry.value.icon == null
                      ? const SizedBox.shrink()
                      : Icon(entry.value.icon),
                  selectedIcon: entry.value.icon == null
                      ? const SizedBox.shrink()
                      : Icon(entry.value.icon),
                  label: Text(entry.value.getDisplayName(context)),
                ),
            ],
          )
        else
          Drawer(
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildDrawerHeader(context, closeButton),
                  SettingsLeapSearchField(
                    controller: _searchController,
                    hintText: widget.searchHint(context),
                    margin: widget.searchFieldMargin,
                    onChanged: (_) => setState(() {}),
                  ),
                  Expanded(
                    child: SettingsLeapSearchResults<S>(
                      results: results,
                      empty: emptySearch,
                      onTap: (result) {
                        _searchController.clear();
                        _select(result.pageId, focusedId: result.focusId);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: selectedPage == null
              ? const SizedBox.shrink()
              : SettingsLeapGeneratedPage<S>(
                  page: selectedPage,
                  pageId: resolvedPageId,
                  state: widget.state,
                  focusedId: _focusedId,
                  appBarBuilder: widget.tree.appBarBuilder,
                  inView: true,
                  showAppBar: false,
                  cardMargin: widget.cardMargin,
                  cardPadding: widget.cardPadding,
                  sectionTitlePadding: widget.sectionTitlePadding,
                ),
        ),
      ],
    );
  }

  Widget _buildDrawerHeader(BuildContext context, Widget closeButton) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 16, 16),
      child: Row(
        spacing: 16,
        children: [
          if (widget.isDialog) closeButton,
          Expanded(
            child: Text(
              widget.title(context),
              style: TextTheme.of(context).headlineSmall,
            ),
          ),
        ],
      ),
    );
  }

  void _select(String id, {String? focusedId, bool mobile = false}) {
    widget.onSelected?.call(id);
    if (mobile) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _selectedId = id;
      _focusedId = focusedId;
    });
  }

  void _openPage(String id, SettingsLeapPage<S> page, [String? focusedId]) {
    widget.onSelected?.call(id);
    final onOpenPage = widget.onOpenPage;
    if (onOpenPage != null) {
      onOpenPage(context, id, page, focusedId);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ValueListenableBuilder<S>(
          valueListenable: _stateNotifier,
          builder: (context, state, child) => SettingsLeapGeneratedPage<S>(
            page: page,
            pageId: id,
            state: state,
            focusedId: focusedId,
            appBarBuilder: widget.tree.appBarBuilder,
            inView: widget.isDialog,
            cardMargin: widget.cardMargin,
            cardPadding: widget.cardPadding,
            sectionTitlePadding: widget.sectionTitlePadding,
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return IconButton.outlined(
      icon: const PhosphorIcon(PhosphorIconsLight.x),
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(widget.emptySearchText),
    );
  }
}

class SettingsLeapGeneratedPage<S> extends StatelessWidget {
  const SettingsLeapGeneratedPage({
    super.key,
    required this.page,
    required this.state,
    this.pageId,
    this.focusedId,
    this.appBarBuilder,
    this.inView = false,
    this.showAppBar = true,
    this.cardMargin = const EdgeInsets.all(8),
    this.cardPadding = const EdgeInsets.all(16),
    this.sectionTitlePadding = const EdgeInsets.only(
      left: 16,
      top: 8,
      right: 16,
      bottom: 8,
    ),
  });

  final SettingsLeapPage<S> page;
  final S state;
  final String? pageId;
  final String? focusedId;
  final SettingsLeapAppBarBuilder<S>? appBarBuilder;
  final bool inView;
  final bool showAppBar;
  final EdgeInsetsGeometry cardMargin;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry sectionTitlePadding;

  @override
  Widget build(BuildContext context) {
    final customBuilder = page.builder;
    if (customBuilder != null) {
      return customBuilder(context, state, inView);
    }
    final actions = [
      ...?page.actionsBuilder?.call(context, state),
      if (page.onReset != null)
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsLight.clockCounterClockwise),
          tooltip: LeapLocalizations.of(context).reset,
          onPressed: () => page.onReset!(context, state),
        ),
    ];
    final sections = page.sections.entries;
    final fillRemaining = sections.where((entry) => entry.value.fillRemaining);
    final customAppBarBuilder = page.appBarBuilder ?? appBarBuilder;
    final appBar = customAppBarBuilder?.call(
      context,
      state,
      inView,
      Text(page.getDisplayName(context)),
      actions,
    );
    final defaultAppBar = AppBar(
      title: Text(page.getDisplayName(context)),
      backgroundColor: inView ? Colors.transparent : null,
      actions: actions,
      automaticallyImplyLeading: true,
    );
    return Scaffold(
      backgroundColor: inView ? Colors.transparent : null,
      floatingActionButton: page.floatingActionButtonBuilder?.call(
        context,
        state,
      ),
      appBar: showAppBar ? appBar ?? defaultAppBar : defaultAppBar,
      body: fillRemaining.isEmpty
          ? ListView(children: [_buildSections(context, sections)])
          : Column(
              children: [
                Expanded(
                  child: _buildSection(
                    context,
                    fillRemaining.single.key,
                    fillRemaining.single.value,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    Iterable<MapEntry<String, SettingsLeapSection<S>>> sections,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in sections)
          _buildSection(context, entry.key, entry.value),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String sectionId,
    SettingsLeapSection<S> section,
  ) {
    final builder = section.builder;
    if (builder != null) {
      if (!section.wrapBuilder) {
        return builder(
          context,
          state,
          _buildSectionChild(context, sectionId, section),
        );
      }
      return Card(
        margin: cardMargin,
        child: Padding(
          padding: cardPadding,
          child: builder(
            context,
            state,
            _buildSectionChild(context, sectionId, section),
          ),
        ),
      );
    }
    return Card(
      margin: cardMargin,
      child: Padding(
        padding: cardPadding,
        child: _buildSectionChild(context, sectionId, section),
      ),
    );
  }

  Widget _buildSectionChild(
    BuildContext context,
    String sectionId,
    SettingsLeapSection<S> section,
  ) {
    final displayName = section.getDisplayName(context);
    final header = section.headerBuilder?.call(context, state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (displayName != null) ...[
          Padding(
            padding: sectionTitlePadding,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextTheme.of(context).headlineSmall,
                  ),
                ),
                ?header,
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (displayName == null && header != null) ...[
          header,
          const SizedBox(height: 16),
        ],
        for (final (index, setting) in section.settings.indexed)
          if (setting.isEnabled(context, state))
            SettingsLeapSettingTile<S>(
              setting: setting,
              state: state,
              focused: focusedId == _settingId(sectionId, setting, index),
            ),
      ],
    );
  }

  String _settingId(
    String sectionId,
    SettingsLeapSetting<S> setting,
    int index,
  ) {
    final pagePrefix = pageId;
    final settingId = setting.id ?? 'setting$index';
    if (pagePrefix == null) return '$sectionId.$settingId';
    return '$pagePrefix.$sectionId.$settingId';
  }
}

class SettingsLeapSettingTile<S> extends StatefulWidget {
  const SettingsLeapSettingTile({
    super.key,
    required this.setting,
    required this.state,
    this.focused = false,
  });

  final SettingsLeapSetting<S> setting;
  final S state;
  final bool focused;

  @override
  State<SettingsLeapSettingTile<S>> createState() =>
      _SettingsLeapSettingTileState<S>();
}

class _SettingsLeapSettingTileState<S>
    extends State<SettingsLeapSettingTile<S>> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusIfNeeded();
  }

  @override
  void didUpdateWidget(covariant SettingsLeapSettingTile<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.focused && widget.focused) {
      _focusIfNeeded();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.setting.buildTile(
      context,
      widget.state,
      focusNode: _focusNode,
      autofocus: widget.focused,
      selected: widget.focused,
    );
  }

  void _focusIfNeeded() {
    if (!widget.focused) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.5,
      );
    });
  }
}

class SettingsLeapPageTile<S> extends StatelessWidget {
  const SettingsLeapPageTile({super.key, required this.page, this.onTap});

  final SettingsLeapPage<S> page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = page.getDescription(context);
    final help = page.getHelp(context);
    return ListTile(
      leading: page.icon == null ? null : Icon(page.icon),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Text(page.getDisplayName(context)),
          ),
          if (help != null)
            IconButton(
              tooltip: help,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              icon: const PhosphorIcon(PhosphorIconsLight.question, size: 20),
              onPressed: () => showLeapBottomSheet<void>(
                context: context,
                titleBuilder: (context) => Text(page.getDisplayName(context)),
                childrenBuilder: (context) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(help),
                  ),
                ],
              ),
            ),
        ],
      ),
      subtitle: description == null ? null : Text(description),
      onTap: onTap,
    );
  }
}

class _SettingsLeapHeader extends StatelessWidget {
  const _SettingsLeapHeader({required this.title, this.closeButton});

  final String title;
  final Widget? closeButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        spacing: 16,
        children: [
          ?closeButton,
          Expanded(
            child: Text(title, style: TextTheme.of(context).headlineSmall),
          ),
        ],
      ),
    );
  }
}

class SettingsLeapSearchField extends StatelessWidget {
  const SettingsLeapSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
    this.margin = EdgeInsets.zero,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SearchBar(
        controller: controller,
        autoFocus: autofocus,
        hintText: hintText,
        leading: const PhosphorIcon(PhosphorIconsLight.magnifyingGlass),
        trailing: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const PhosphorIcon(PhosphorIconsLight.x),
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                },
              );
            },
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class SettingsLeapSearchResults<S> extends StatelessWidget {
  const SettingsLeapSearchResults({
    super.key,
    required this.results,
    this.onTap,
    this.empty,
    this.shrinkWrap = false,
    this.padding = EdgeInsets.zero,
  });

  final List<SettingsLeapSearchResult<S>> results;
  final ValueChanged<SettingsLeapSearchResult<S>>? onTap;
  final Widget? empty;
  final bool shrinkWrap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return empty ?? const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      padding: padding,
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          leading: result.node.icon == null ? null : Icon(result.node.icon),
          title: Text(result.node.getDisplayName(context)),
          subtitle: Text(result.breadcrumb(context)),
          onTap: onTap == null ? null : () => onTap!(result),
        );
      },
    );
  }
}

String defaultSettingsLeapTitle(BuildContext context) => 'Settings';

String defaultSettingsLeapSearchHint(BuildContext context) => 'Search';
