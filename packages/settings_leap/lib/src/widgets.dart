import 'package:flutter/material.dart';

import 'model.dart';
import 'search.dart';

class SettingsLeapView<S> extends StatefulWidget {
  const SettingsLeapView({
    super.key,
    required this.tree,
    required this.state,
    this.title = defaultSettingsLeapTitle,
    this.searchHint = defaultSettingsLeapSearchHint,
    this.selectedId,
    this.onSelected,
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
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
  }

  @override
  void didUpdateWidget(covariant SettingsLeapView<S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _selectedId = widget.selectedId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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
    final selectedRootIndex = _selectedId == null
        ? 0
        : rootEntries.indexWhere((entry) => entry.key == _selectedId);
    final selectedEntry = rootEntries.elementAtOrNull(
      selectedRootIndex < 0 ? 0 : selectedRootIndex,
    );
    final selectedPage = selectedEntry?.value;
    final closeButton = widget.closeButton ?? _buildCloseButton(context);
    final emptySearch = widget.emptySearch ?? _buildEmptySearch(context);

    if (isMobile) {
      return ListView(
        shrinkWrap: true,
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
            ListView(
              shrinkWrap: true,
              children: [
                for (final entry in rootEntries)
                  SettingsLeapPageTile(
                    page: entry.value,
                    onTap: () => _openMobilePage(entry.key, entry.value),
                  ),
              ],
            )
          else
            SettingsLeapSearchResults<S>(
              results: results,
              shrinkWrap: true,
              empty: emptySearch,
              onTap: (result) {
                final rootId = result.id.split('.').first;
                final page = widget.tree.pages[rootId];
                if (page != null) _openMobilePage(rootId, page);
              },
            ),
          const SizedBox(height: 16),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NavigationDrawer(
          selectedIndex: selectedRootIndex < 0 ? null : selectedRootIndex,
          onDestinationSelected: (index) => _select(rootEntries[index].key),
          children: [
            Padding(
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
            ),
            SettingsLeapSearchField(
              controller: _searchController,
              hintText: widget.searchHint(context),
              margin: widget.searchFieldMargin,
              onChanged: (_) => setState(() {}),
            ),
            if (query.trim().isEmpty)
              for (final entry in rootEntries)
                NavigationDrawerDestination(
                  icon: entry.value.icon == null
                      ? const SizedBox.shrink()
                      : Icon(entry.value.icon),
                  selectedIcon: entry.value.icon == null
                      ? const SizedBox.shrink()
                      : Icon(entry.value.icon),
                  label: Text(entry.value.getDisplayName(context)),
                )
            else
              SettingsLeapSearchResults<S>(
                results: results,
                shrinkWrap: true,
                empty: emptySearch,
                onTap: (result) {
                  _searchController.clear();
                  _select(result.id.split('.').first);
                },
              ),
          ],
        ),
        Expanded(
          child: selectedPage == null
              ? const SizedBox.shrink()
              : SettingsLeapGeneratedPage<S>(
                  page: selectedPage,
                  state: widget.state,
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

  void _select(String id, {bool mobile = false}) {
    widget.onSelected?.call(id);
    if (mobile) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _selectedId = id;
    });
  }

  void _openMobilePage(String id, SettingsLeapPage<S> page) {
    widget.onSelected?.call(id);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SettingsLeapGeneratedPage<S>(
          page: page,
          state: widget.state,
          inView: false,
          cardMargin: widget.cardMargin,
          cardPadding: widget.cardPadding,
          sectionTitlePadding: widget.sectionTitlePadding,
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context) {
    return IconButton.outlined(
      icon: const Icon(Icons.close),
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
    final actions = page.actionsBuilder?.call(context, state);
    final sections = page.sections.values;
    final fillRemaining = sections.where((section) => section.fillRemaining);
    final appBar = page.appBarBuilder?.call(
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
      automaticallyImplyLeading: !inView,
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
                Expanded(child: _buildSection(context, fillRemaining.single)),
              ],
            ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    Iterable<SettingsLeapSection<S>> sections,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final section in sections) _buildSection(context, section),
      ],
    );
  }

  Widget _buildSection(BuildContext context, SettingsLeapSection<S> section) {
    final builder = section.builder;
    if (builder != null) {
      if (!section.wrapBuilder) {
        return builder(context, state, _buildSectionChild(context, section));
      }
      return Card(
        margin: cardMargin,
        child: Padding(
          padding: cardPadding,
          child: builder(context, state, _buildSectionChild(context, section)),
        ),
      );
    }
    return Card(
      margin: cardMargin,
      child: Padding(
        padding: cardPadding,
        child: _buildSectionChild(context, section),
      ),
    );
  }

  Widget _buildSectionChild(
    BuildContext context,
    SettingsLeapSection<S> section,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.getDisplayName(context) != null) ...[
          Padding(
            padding: sectionTitlePadding,
            child: Text(
              section.getDisplayName(context)!,
              style: TextTheme.of(context).headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (section.headerBuilder != null) ...[
          section.headerBuilder!(context, state),
          const SizedBox(height: 16),
        ],
        for (final setting in section.settings)
          if (setting.isEnabled(context, state))
            SettingsLeapSettingTile<S>(setting: setting, state: state),
      ],
    );
  }
}

class SettingsLeapSettingTile<S> extends StatelessWidget {
  const SettingsLeapSettingTile({
    super.key,
    required this.setting,
    required this.state,
  });

  final SettingsLeapSetting<S> setting;
  final S state;

  @override
  Widget build(BuildContext context) {
    return setting.buildTile(context, state);
  }
}

class SettingsLeapPageTile<S> extends StatelessWidget {
  const SettingsLeapPageTile({super.key, required this.page, this.onTap});

  final SettingsLeapPage<S> page;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final description = page.getDescription(context);
    return ListTile(
      leading: page.icon == null ? null : Icon(page.icon),
      title: Text(page.getDisplayName(context)),
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
        leading: const Icon(Icons.search),
        trailing: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              if (value.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.close),
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
