import 'package:csslib/visitor.dart' as css;
import 'package:xml/xml.dart';

class CssSpecificity implements Comparable<CssSpecificity> {
  final int inline;
  final int ids;
  final int classes;
  final int types;

  const CssSpecificity({
    this.inline = 0,
    this.ids = 0,
    this.classes = 0,
    this.types = 0,
  });

  @override
  int compareTo(CssSpecificity other) {
    for (final (a, b) in [
      (inline, other.inline),
      (ids, other.ids),
      (classes, other.classes),
      (types, other.types),
    ]) {
      final difference = a.compareTo(b);
      if (difference != 0) return difference;
    }
    return 0;
  }
}

class SvgCssSelector {
  final List<_Compound> _compounds;
  final CssSpecificity specificity;

  SvgCssSelector._(this._compounds, this.specificity);

  static SvgCssSelector? compile(css.Selector selector) {
    // Escaped identifiers and namespace-qualified selectors need a larger CSS
    // implementation. Reject them instead of matching the wrong SVG nodes.
    if (selector.span?.text.contains('\\') ?? false) return null;
    final compounds = <_Compound>[];
    var ids = 0, classes = 0, types = 0;
    for (final sequence in selector.simpleSelectorSequences) {
      final simple = sequence.simpleSelector;
      if (simple is css.IdSelector) {
        ids++;
      } else if (simple is css.ClassSelector ||
          simple is css.AttributeSelector) {
        classes++;
      } else if (simple is css.ElementSelector) {
        if (!simple.isWildcard) types++;
      } else if (simple.runtimeType == css.PseudoClassSelector &&
          simple.name == 'root') {
        classes++;
      } else {
        return null;
      }
      final combinator = sequence.isCombinatorNone
          ? _Combinator.same
          : sequence.isCombinatorDescendant
          ? _Combinator.descendant
          : sequence.isCombinatorGreater
          ? _Combinator.child
          : sequence.isCombinatorPlus
          ? _Combinator.adjacent
          : sequence.isCombinatorTilde
          ? _Combinator.sibling
          : null;
      if (combinator == null) return null;
      if (compounds.isEmpty) {
        if (combinator != _Combinator.same) return null;
        compounds.add(_Compound(combinator));
      } else if (combinator != _Combinator.same) {
        compounds.add(_Compound(combinator));
      }
      compounds.last.selectors.add(simple);
    }
    if (compounds.isEmpty) return null;
    return SvgCssSelector._(
      compounds,
      CssSpecificity(ids: ids, classes: classes, types: types),
    );
  }

  bool matches(XmlElement element) => _matches(element, _compounds.length - 1);

  bool _matches(XmlElement element, int index) {
    final compound = _compounds[index];
    if (!compound.selectors.every(
      (selector) => _matchesSimple(element, selector),
    )) {
      return false;
    }
    if (index == 0) return true;
    switch (compound.combinator) {
      case _Combinator.child:
        final parent = element.parent;
        return parent is XmlElement && _matches(parent, index - 1);
      case _Combinator.descendant:
        for (
          var parent = element.parent;
          parent != null;
          parent = parent.parent
        ) {
          if (parent is XmlElement && _matches(parent, index - 1)) return true;
        }
        return false;
      case _Combinator.adjacent:
        final sibling = _previousElement(element);
        return sibling != null && _matches(sibling, index - 1);
      case _Combinator.sibling:
        for (
          var sibling = _previousElement(element);
          sibling != null;
          sibling = _previousElement(sibling)
        ) {
          if (_matches(sibling, index - 1)) return true;
        }
        return false;
      case _Combinator.same:
        return false;
    }
  }
}

enum _Combinator { same, descendant, child, adjacent, sibling }

class _Compound {
  final _Combinator combinator;
  final selectors = <css.SimpleSelector>[];
  _Compound(this.combinator);
}

XmlElement? _previousElement(XmlElement element) {
  for (
    var sibling = element.previousSibling;
    sibling != null;
    sibling = sibling.previousSibling
  ) {
    if (sibling is XmlElement) return sibling;
  }
  return null;
}

bool _matchesSimple(XmlElement element, css.SimpleSelector selector) {
  if (selector is css.ElementSelector) {
    return selector.isWildcard || element.name.local == selector.name;
  }
  if (selector is css.IdSelector) {
    return element.getAttribute('id') == selector.name;
  }
  if (selector is css.ClassSelector) {
    return (element.getAttribute('class') ?? '')
        .split(_whitespace)
        .contains(selector.name);
  }
  if (selector is css.AttributeSelector) {
    final actual = element.getAttribute(selector.name);
    if (actual == null) return false;
    final raw = selector.value;
    final expected = raw is css.Identifier ? raw.name : raw?.toString() ?? '';
    return switch (selector.matchOperator()) {
      '' => true,
      '=' => actual == expected,
      '~=' =>
        expected.isNotEmpty && actual.split(_whitespace).contains(expected),
      '|=' => actual == expected || actual.startsWith('$expected-'),
      '^=' => expected.isNotEmpty && actual.startsWith(expected),
      r'$=' => expected.isNotEmpty && actual.endsWith(expected),
      '*=' => expected.isNotEmpty && actual.contains(expected),
      _ => false,
    };
  }
  return selector.name == 'root' && element.parent is XmlDocument;
}

final _whitespace = RegExp(r'\s+');
