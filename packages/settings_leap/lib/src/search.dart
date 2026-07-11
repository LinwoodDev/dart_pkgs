import 'package:flutter/widgets.dart';

import 'model.dart';

final class SettingsLeapTree<S> {
  const SettingsLeapTree(
    this.pages, {
    this.appBarBuilder,
    this.normalizer = defaultSettingsLeapTextNormalizer,
  });

  final Map<String, SettingsLeapPage<S>> pages;
  final SettingsLeapAppBarBuilder<S>? appBarBuilder;
  final SettingsLeapTextNormalizer normalizer;

  List<SettingsLeapFlatNode<S>> flatten(
    BuildContext context,
    S state, {
    bool includeDisabled = false,
  }) {
    final result = <SettingsLeapFlatNode<S>>[];
    for (final entry in pages.entries) {
      _flattenPage(
        context,
        state,
        entry.key,
        entry.value,
        const [],
        result,
        includeDisabled: includeDisabled,
      );
    }
    return result;
  }

  SettingsLeapPage<S>? pageById(String id) {
    final parts = id.split('.');
    if (parts.isEmpty) return null;
    var page = pages[parts.first];
    for (final part in parts.skip(1)) {
      page = page?.children[part];
    }
    return page;
  }

  List<SettingsLeapSearchResult<S>> search(
    BuildContext context,
    S state,
    String query,
  ) {
    final terms = normalizer(
      query,
    ).split(RegExp(r'\s+')).where((term) => term.isNotEmpty).toList();
    if (terms.isEmpty) return const [];

    final results = <SettingsLeapSearchResult<S>>[];
    for (final flatNode in flatten(context, state)) {
      final score = _scoreNode(context, flatNode.node, flatNode.parents, terms);
      if (score > 0) {
        results.add(
          SettingsLeapSearchResult(
            id: flatNode.id,
            node: flatNode.node,
            parents: flatNode.parents,
            score: score,
            pageId: flatNode.pageId,
            focusId: flatNode.focusId,
          ),
        );
      }
    }
    results.sort(
      (a, b) =>
          b.score.compareTo(a.score).nonZero ??
          a.breadcrumb(context).compareTo(b.breadcrumb(context)),
    );
    return results;
  }

  void _flattenPage(
    BuildContext context,
    S state,
    String id,
    SettingsLeapPage<S> page,
    List<SettingsLeapNode<S>> parents,
    List<SettingsLeapFlatNode<S>> result, {
    required bool includeDisabled,
  }) {
    if (!includeDisabled && !page.isEnabled(context, state)) return;
    result.add(
      SettingsLeapFlatNode(id: id, node: page, parents: parents, pageId: id),
    );
    for (final sectionEntry in page.sections.entries) {
      final section = sectionEntry.value;
      final sectionLabel = section.getDisplayName(context);
      if (sectionLabel != null) {
        result.add(
          SettingsLeapFlatNode(
            id: '$id.${sectionEntry.key}',
            node: SettingsLeapSectionSearchNode<S>(
              displayName: section.displayName!,
              description: section.description,
              descriptionBuilder: section.descriptionBuilder,
              help: section.help,
              keywords: section.keywords,
              keywordsBuilder: section.keywordsBuilder,
            ),
            parents: [...parents, page],
            pageId: id,
          ),
        );
      }
      for (final (index, setting) in section.settings.indexed) {
        if (!includeDisabled && !setting.isEnabled(context, state)) continue;
        final settingId =
            '$id.${sectionEntry.key}.${_settingId(setting, index)}';
        result.add(
          SettingsLeapFlatNode(
            id: settingId,
            node: setting,
            parents: [...parents, page],
            pageId: id,
            focusId: settingId,
          ),
        );
        for (final option in setting.buildOptionSearchNodes(context, state)) {
          final optionId = switch (option) {
            SettingsLeapOptionSearchNode<S, Object?>() => option.optionId,
            _ => option.getDisplayName(context),
          };
          result.add(
            SettingsLeapFlatNode(
              id: '$settingId.$optionId',
              node: option,
              parents: [...parents, page, setting],
              pageId: id,
              focusId: settingId,
            ),
          );
        }
      }
    }
    for (final child in page.children.entries) {
      _flattenPage(
        context,
        state,
        '$id.${child.key}',
        child.value,
        [...parents, page],
        result,
        includeDisabled: includeDisabled,
      );
    }
  }

  String _settingId(SettingsLeapSetting<S> setting, int index) =>
      setting.id ?? 'setting$index';

  int _scoreNode(
    BuildContext context,
    SettingsLeapNode<S> node,
    List<SettingsLeapNode<S>> parents,
    List<String> terms,
  ) {
    var score = 0;
    for (final term in terms) {
      final termScore =
          _scoreText(
            node.getDisplayName(context),
            term,
            exact: 120,
            prefix: 90,
            contains: 70,
          ) ??
          _scoreText(
            node.getDescription(context),
            term,
            exact: 55,
            prefix: 40,
            contains: 25,
          ) ??
          _scoreText(node.help, term, exact: 55, prefix: 40, contains: 25) ??
          _scoreText(
            parents.map((parent) => parent.getDisplayName(context)).join(' '),
            term,
            exact: 35,
            prefix: 30,
            contains: 20,
          ) ??
          _scoreKeywords(node.getKeywords(context), term);
      if (termScore == null) return 0;
      score += termScore;
    }
    return score;
  }

  int? _scoreKeywords(Iterable<String> keywords, String term) {
    for (final keyword in keywords) {
      final score = _scoreText(
        keyword,
        term,
        exact: 50,
        prefix: 35,
        contains: 25,
      );
      if (score != null) return score;
    }
    return null;
  }

  int? _scoreText(
    String? text,
    String term, {
    required int exact,
    required int prefix,
    required int contains,
  }) {
    if (text == null || text.isEmpty) return null;
    final normalized = normalizer(text);
    if (normalized == term) return exact;
    if (normalized.startsWith(term)) return prefix;
    if (normalized.contains(term)) return contains;
    return null;
  }
}

typedef SettingsLeapTextNormalizer = String Function(String text);

String defaultSettingsLeapTextNormalizer(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
    .trim();

extension on int {
  int? get nonZero => this == 0 ? null : this;
}
