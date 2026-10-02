import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css;
import 'package:xml/xml.dart';

import 'selector.dart';

/// The SVG and any CSS features that prevented normalization.
///
/// If [warnings] is nonempty, [svg] is the original input. Normalization is
/// atomic: unsupported CSS is never partially applied or silently discarded.
class SvgNormalizationResult {
  final String svg;
  final List<String> warnings;

  SvgNormalizationResult(this.svg, Iterable<String> warnings)
    : warnings = List.unmodifiable(warnings);

  bool get isFullyNormalized => warnings.isEmpty;
}

/// Resolves static stylesheets and inline styles into SVG attributes.
///
/// Unsupported or malformed CSS leaves the original SVG intact and calls
/// [onWarning] for each diagnostic. Malformed XML throws an [XmlException].
/// See [normalizeSvgWithWarnings] to inspect diagnostics without a callback.
String normalizeSvg(String source, {void Function(String)? onWarning}) {
  final result = normalizeSvgWithWarnings(source);
  for (final warning in result.warnings) {
    onWarning?.call(warning);
  }
  return result.svg;
}

/// Normalizes SVG CSS while returning diagnostics about unsupported features.
///
/// The supported subset includes type, universal, ID, class and attribute
/// selectors, compound selectors, selector lists, the four CSS combinators,
/// and `:root`. The cascade uses importance, specificity and source order.
/// Inheritance remains on the SVG tree; inherited styles are not copied onto
/// descendants. External stylesheets, at-rules, other pseudo selectors, CSS
/// variables, shorthands and CSS-wide keywords are outside this subset.
SvgNormalizationResult normalizeSvgWithWarnings(String source) {
  if (!source.contains('style')) {
    return SvgNormalizationResult(source, const []);
  }
  final document = XmlDocument.parse(source);
  final root = document.rootElement;
  if (!_isSvgElement(root) || root.name.local != 'svg') {
    throw FormatException('Expected an SVG root element');
  }
  final elements = [
    root,
    ...root.descendantElements,
  ].where(_isSvgElement).toList();
  final styles = elements.where((e) => e.name.local == 'style').toList();
  final warnings = <String>{};
  final rules = <_Rule>[];
  var order = 0;

  for (final instruction in document.descendants.whereType<XmlProcessing>()) {
    if (instruction.target == 'xml-stylesheet') {
      warnings.add('External xml-stylesheet instructions are unsupported.');
    }
  }
  for (final style in styles) {
    final type = style.getAttribute('type');
    final media = style.getAttribute('media');
    if ((type != null && type.trim().toLowerCase() != 'text/css') ||
        (media != null && media.trim().isNotEmpty && media.trim() != 'all') ||
        style.getAttribute('title') != null) {
      warnings.add('Conditional or non-CSS style elements are unsupported.');
      continue;
    }
    final sheet = _parse(style.innerText, warnings);
    for (final node in sheet.topLevels) {
      if (node is css.CommentDefinition || node is css.CssComment) continue;
      if (node is! css.RuleSet || node.selectorGroup == null) {
        warnings.add('CSS at-rules and nested rules are unsupported.');
        continue;
      }
      final selectors = <SvgCssSelector>[];
      for (final selector in node.selectorGroup!.selectors) {
        final compiled = SvgCssSelector.compile(selector);
        if (compiled == null) {
          warnings.add('Unsupported CSS selector: ${selector.span?.text}.');
        } else {
          selectors.add(compiled);
        }
      }
      final declarations = _declarations(node, warnings);
      rules.add(_Rule(selectors, declarations, order++));
    }
  }

  // Read and match against the original tree before writing any attributes.
  // Otherwise a selector such as [fill] could match attributes we just added.
  final resolved = <XmlElement, Map<String, _Value>>{};
  for (final element in elements) {
    if (element.name.local == 'style') continue;
    final values = <String, _Value>{};
    for (final rule in rules) {
      CssSpecificity? specificity;
      for (final selector in rule.selectors) {
        if (selector.matches(element) &&
            (specificity == null ||
                selector.specificity.compareTo(specificity) > 0)) {
          specificity = selector.specificity;
        }
      }
      if (specificity != null) {
        _apply(values, rule.declarations, specificity, rule.order);
      }
    }
    final inline = element.getAttribute('style');
    if (inline != null) {
      final sheet = _parse('svg {$inline}', warnings);
      if (sheet.topLevels.length == 1 &&
          sheet.topLevels.single is css.RuleSet) {
        _apply(
          values,
          _declarations(sheet.topLevels.single as css.RuleSet, warnings),
          const CssSpecificity(inline: 1),
          order,
        );
      } else {
        warnings.add('Malformed inline CSS style.');
      }
    }
    resolved[element] = values;
  }
  if (warnings.isNotEmpty) {
    return SvgNormalizationResult(source, warnings);
  }

  var changed = styles.isNotEmpty;
  for (final entry in resolved.entries) {
    final element = entry.key;
    if (element.getAttribute('style') != null) {
      element.removeAttribute('style');
      changed = true;
    }
    for (final declaration in entry.value.entries) {
      element.setAttribute(declaration.key, declaration.value.value);
      changed = true;
    }
  }
  for (final style in styles) {
    style.parent?.children.remove(style);
  }
  return SvgNormalizationResult(
    changed ? document.toXmlString() : source,
    const [],
  );
}

/// An optional bounded LRU cache keyed by the entire original SVG source.
///
/// Large SVGs are normalized without being retained in the cache. A content
/// change always produces a new entry, so no document-specific invalidation is
/// needed. Instances are independent and can be cleared with [clear].
class SvgNormalizer {
  final int maxCacheEntries;
  final int maxCachedSourceLength;
  final _cache = <String, SvgNormalizationResult>{};

  SvgNormalizer({
    this.maxCacheEntries = 32,
    this.maxCachedSourceLength = 256 * 1024,
  }) {
    RangeError.checkNotNegative(maxCacheEntries, 'maxCacheEntries');
    RangeError.checkNotNegative(maxCachedSourceLength, 'maxCachedSourceLength');
  }

  String normalize(String source, {void Function(String)? onWarning}) {
    final result = normalizeWithWarnings(source);
    for (final warning in result.warnings) {
      onWarning?.call(warning);
    }
    return result.svg;
  }

  SvgNormalizationResult normalizeWithWarnings(String source) {
    final cached = _cache.remove(source);
    final result = cached ?? normalizeSvgWithWarnings(source);
    if (maxCacheEntries > 0 && source.length <= maxCachedSourceLength) {
      _cache[source] = result;
      if (_cache.length > maxCacheEntries) _cache.remove(_cache.keys.first);
    }
    return result;
  }

  void clear() => _cache.clear();
}

bool _isSvgElement(XmlElement element) =>
    element.name.namespaceUri == 'http://www.w3.org/2000/svg' ||
    element.name.namespaceUri == null ||
    element.name.namespaceUri == '';

css.StyleSheet _parse(String source, Set<String> warnings) {
  final messages = <css.Message>[];
  // csslib recognizes only lowercase `important`. CSS makes this token
  // case-insensitive; canonicalize it outside strings and function arguments.
  final sheet = css.parse(
    _canonicalizeImportant(_withoutComments(source)),
    errors: messages,
  );
  for (final message in messages) {
    warnings.add('CSS parse error: ${message.describe}');
  }
  return sheet;
}

List<_Declaration> _declarations(css.RuleSet rule, Set<String> warnings) {
  final result = <_Declaration>[];
  for (final node in rule.declarationGroup.declarations) {
    if (node.runtimeType != css.Declaration) {
      warnings.add(
        'CSS shorthands, variables and nested rules are unsupported.',
      );
      continue;
    }
    final declaration = node as css.Declaration;
    final property = declaration.property.toLowerCase();
    if (!_presentationAttributes.contains(property)) {
      warnings.add('Unsupported SVG CSS property: $property.');
      continue;
    }
    // csslib expression spans can cover only the opening token of a color or
    // string. The full declaration span preserves URLs, quoted text and units.
    final text = declaration.span.text;
    final colon = text.indexOf(':');
    if (colon < 0 || declaration.expression == null) {
      warnings.add('Malformed CSS declaration: $text.');
      continue;
    }
    var value = _withoutComments(text.substring(colon + 1)).trim();
    if (declaration.important) {
      value = value.replaceFirst(_important, '').trim();
    }
    if (value.isEmpty ||
        _cssWideKeywords.contains(value.toLowerCase()) ||
        _cssFunctions.hasMatch(value)) {
      warnings.add('Unsupported SVG CSS value for $property: $value.');
      continue;
    }
    result.add(_Declaration(property, value, declaration.important));
  }
  return result;
}

String _withoutComments(String source) {
  final output = StringBuffer();
  String? quote;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (char == '\\' && i + 1 < source.length) {
      output.write(char);
      output.write(source[++i]);
      continue;
    }
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '/' && i + 1 < source.length && source[i + 1] == '*') {
      final end = source.indexOf('*/', i + 2);
      if (end < 0) {
        output.write(source.substring(i));
        break; // Keep malformed comments for the CSS parser to diagnose.
      }
      i = end + 1;
      output.write(' ');
      continue;
    }
    output.write(char);
  }
  return output.toString();
}

String _canonicalizeImportant(String source) {
  final output = StringBuffer();
  String? quote;
  var parentheses = 0;
  for (var i = 0; i < source.length; i++) {
    final char = source[i];
    if (char == '\\' && i + 1 < source.length) {
      output.write(char);
      output.write(source[++i]);
      continue;
    }
    if (quote != null) {
      if (char == quote) quote = null;
    } else if (char == '"' || char == "'") {
      quote = char;
    } else if (char == '(') {
      parentheses++;
    } else if (char == ')') {
      parentheses--;
    } else if (char == '!' && parentheses == 0) {
      final match = _importantToken.matchAsPrefix(source, i);
      if (match != null) {
        output.write('!important');
        i = match.end - 1;
        continue;
      }
    }
    output.write(char);
  }
  return output.toString();
}

void _apply(
  Map<String, _Value> values,
  List<_Declaration> declarations,
  CssSpecificity specificity,
  int order,
) {
  for (final declaration in declarations) {
    final value = _Value(
      declaration.value,
      declaration.important,
      specificity,
      order,
    );
    final previous = values[declaration.property];
    if (previous == null || value.compareTo(previous) >= 0) {
      values[declaration.property] = value;
    }
  }
}

class _Rule {
  final List<SvgCssSelector> selectors;
  final List<_Declaration> declarations;
  final int order;
  _Rule(this.selectors, this.declarations, this.order);
}

class _Declaration {
  final String property;
  final String value;
  final bool important;
  _Declaration(this.property, this.value, this.important);
}

class _Value implements Comparable<_Value> {
  final String value;
  final bool important;
  final CssSpecificity specificity;
  final int order;
  _Value(this.value, this.important, this.specificity, this.order);

  @override
  int compareTo(_Value other) {
    if (important != other.important) return important ? 1 : -1;
    final comparison = specificity.compareTo(other.specificity);
    return comparison == 0 ? order.compareTo(other.order) : comparison;
  }
}

final _important = RegExp(r'!\s*important\s*$', caseSensitive: false);
final _importantToken = RegExp(r'!\s*important\b', caseSensitive: false);
final _cssFunctions = RegExp(r'\b(?:var|env)\s*\(', caseSensitive: false);
const _cssWideKeywords = {
  'inherit',
  'initial',
  'unset',
  'revert',
  'revert-layer',
};
const _presentationAttributes = {
  'alignment-baseline',
  'baseline-shift',
  'clip',
  'clip-path',
  'clip-rule',
  'color',
  'color-interpolation',
  'color-interpolation-filters',
  'color-profile',
  'color-rendering',
  'cursor',
  'direction',
  'display',
  'dominant-baseline',
  'enable-background',
  'fill',
  'fill-opacity',
  'fill-rule',
  'filter',
  'flood-color',
  'flood-opacity',
  'font-family',
  'font-size',
  'font-size-adjust',
  'font-stretch',
  'font-style',
  'font-variant',
  'font-weight',
  'glyph-orientation-horizontal',
  'glyph-orientation-vertical',
  'image-rendering',
  'kerning',
  'letter-spacing',
  'lighting-color',
  'marker-start',
  'marker-mid',
  'marker-end',
  'mask',
  'opacity',
  'overflow',
  'pointer-events',
  'shape-rendering',
  'stop-color',
  'stop-opacity',
  'stroke',
  'stroke-dasharray',
  'stroke-dashoffset',
  'stroke-linecap',
  'stroke-linejoin',
  'stroke-miterlimit',
  'stroke-opacity',
  'stroke-width',
  'text-anchor',
  'text-decoration',
  'text-rendering',
  'unicode-bidi',
  'vector-effect',
  'visibility',
  'word-spacing',
  'writing-mode',
};
