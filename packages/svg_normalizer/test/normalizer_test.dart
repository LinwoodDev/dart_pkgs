import 'dart:io';

import 'package:svg_normalizer/svg_normalizer.dart';
import 'package:test/test.dart';
import 'package:xml/xml.dart';

String svg(String body) =>
    '<svg xmlns="http://www.w3.org/2000/svg">$body</svg>';

XmlElement element(String source, String id) => XmlDocument.parse(
  source,
).descendantElements.firstWhere((e) => e.getAttribute('id') == id);

void main() {
  test('Illustrator fixture resolves none and hides the circle', () {
    final source = File('test/fixtures/illustrator.svg').readAsStringSync();
    final result = normalizeSvgWithWarnings(source);
    expect(result.warnings, isEmpty);
    final document = XmlDocument.parse(result.svg);
    final rect = document.findAllElements('rect').single;
    final circle = document.findAllElements('circle').single;
    expect(rect.getAttribute('fill'), 'none');
    expect(rect.getAttribute('stroke'), '#000000');
    expect(rect.getAttribute('stroke-miterlimit'), '10');
    expect(circle.getAttribute('display'), 'none');
    expect(circle.getAttribute('fill'), 'none');
    expect(document.findAllElements('style'), isEmpty);
    expect(document.rootElement.getAttribute('viewBox'), '0 0 100 20');
  });

  test('styles without stylesheets are normalized too', () {
    final output = normalizeSvg(
      svg('<rect id="a" style="fill:none;stroke:#123456"/>'),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
    expect(element(output, 'a').getAttribute('stroke'), '#123456');
    expect(element(output, 'a').getAttribute('style'), isNull);
  });

  test('unstyled SVG is returned byte for byte', () {
    const source =
        '<?xml version="1.0"?>\n<svg xmlns="http://www.w3.org/2000/svg"><rect fill="none"/></svg>';
    expect(normalizeSvg(source), source);
  });

  test('a style word in text does not change unstyled SVG', () {
    final source = svg('<text>stylesheet</text>');
    expect(normalizeSvg(source), source);
  });

  test('normalization is idempotent', () {
    final output = normalizeSvg(
      svg('<style>.a{fill:none}</style><rect class="a"/>'),
    );
    expect(normalizeSvg(output), output);
  });

  test('a class applies to every matching element', () {
    final output = normalizeSvg(
      svg(
        '<style>.a{fill:none}</style><rect id="a" class="a"/><circle id="b" class="a"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
    expect(element(output, 'b').getAttribute('fill'), 'none');
  });

  test('type, ID and compound selectors use specificity', () {
    final output = normalizeSvg(
      svg('''
      <style>#a{fill:blue}.a.b{fill:green}rect{fill:red}</style>
      <rect id="a" class="a b"/><rect id="b" class="a b"/>
    '''),
    );
    expect(element(output, 'a').getAttribute('fill'), 'blue');
    expect(element(output, 'b').getAttribute('fill'), 'green');
  });

  test('inline CSS overrides stylesheet and presentation attributes', () {
    final output = normalizeSvg(
      svg(
        '<style>#a{fill:blue}</style><rect id="a" fill="red" style="fill:none"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('stylesheet overrides existing presentation attributes', () {
    final output = normalizeSvg(
      svg(
        '<style>rect{fill:none}</style><rect id="a" fill="red" stroke="blue"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
    expect(element(output, 'a').getAttribute('stroke'), 'blue');
  });

  test('important stylesheet overrides normal inline CSS', () {
    final output = normalizeSvg(
      svg(
        '<style>rect{fill:none !important}</style><rect id="a" style="fill:red"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('important inline CSS overrides important stylesheet CSS', () {
    final output = normalizeSvg(
      svg(
        '<style>#a{fill:red !important}</style><rect id="a" style="fill:none !important"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('duplicate declarations obey importance and order', () {
    final output = normalizeSvg(
      svg(
        '<rect id="a" style="fill:blue;fill:none !important;fill:red;stroke:red;stroke:blue"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
    expect(element(output, 'a').getAttribute('stroke'), 'blue');
  });

  test('equal specificity follows order across style elements', () {
    final output = normalizeSvg(
      svg(
        '<style>.a{fill:red}</style><style>.a{fill:blue}.a{fill:none}</style><rect id="a" class="a"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('selector lists use the most specific matching selector', () {
    final output = normalizeSvg(
      svg(
        '<style>#a, rect{fill:none}.a{fill:red}</style><rect id="a" class="a"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('specificity compares components instead of weighted sums', () {
    final output = normalizeSvg(
      svg(
        '<style>#a{fill:none}${List.filled(12, '.a').join()}{fill:red}</style><rect id="a" class="a"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  for (final selector in ['g .a', 'g > .a', '#first + .a', '#first ~ .a']) {
    test('matches combinator $selector', () {
      final output = normalizeSvg(
        svg(
          '<style>$selector{fill:none}</style><g><circle id="first"/>\n<!-- space --><rect id="a" class="a"/></g>',
        ),
      );
      expect(element(output, 'a').getAttribute('fill'), 'none');
    });
  }

  test('child and adjacent selectors do not match distant nodes', () {
    final output = normalizeSvg(
      svg(
        '<style>svg > rect{fill:red}#first + rect{stroke:blue}</style><g><circle id="first"/><path/><rect id="a"/></g>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), isNull);
    expect(element(output, 'a').getAttribute('stroke'), isNull);
  });

  test('descendant matching backtracks through matching ancestors', () {
    final output = normalizeSvg(
      svg('<style>svg > g rect{fill:none}</style><g><g><rect id="a"/></g></g>'),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  final attributes = {
    '[data-value]': 'abc-def xyz',
    '[data-value="abc-def xyz"]': 'abc-def xyz',
    '[data-value~="xyz"]': 'abc-def xyz',
    '[data-value|="abc"]': 'abc-def',
    '[data-value^="abc"]': 'abc-def xyz',
    '[data-value\$="xyz"]': 'abc-def xyz',
    '[data-value*="def"]': 'abc-def xyz',
  };
  for (final entry in attributes.entries) {
    test('matches attribute selector ${entry.key}', () {
      final output = normalizeSvg(
        svg(
          '<style>rect${entry.key}{fill:none}</style><rect id="a" data-value="${entry.value}"/>',
        ),
      );
      expect(element(output, 'a').getAttribute('fill'), 'none');
    });
  }

  test('root and universal selectors work', () {
    final output = normalizeSvg(
      svg('<style>*{stroke:blue}:root{fill:none}</style><rect id="a"/>'),
    );
    expect(XmlDocument.parse(output).rootElement.getAttribute('fill'), 'none');
    expect(element(output, 'a').getAttribute('stroke'), 'blue');
  });

  test('matches attributes against original tree', () {
    final output = normalizeSvg(
      svg(
        '<style>.a{fill:none}[fill]{stroke:red}</style><rect id="a" class="a"/><rect id="b" fill="blue"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('stroke'), isNull);
    expect(element(output, 'b').getAttribute('stroke'), 'red');
  });

  test('keeps inheritance at groups and does not flatten opacity', () {
    final output = normalizeSvg(
      svg(
        '<style>.group{fill:none;opacity:0.5}</style><g id="g" class="group"><rect id="a"/><rect id="b" fill="red"/></g>',
      ),
    );
    expect(element(output, 'g').getAttribute('fill'), 'none');
    expect(element(output, 'g').getAttribute('opacity'), '0.5');
    expect(element(output, 'a').getAttribute('fill'), isNull);
    expect(element(output, 'a').getAttribute('opacity'), isNull);
    expect(element(output, 'b').getAttribute('fill'), 'red');
  });

  test('preserves URL fragments, quoted strings, units and currentColor', () {
    final output = normalizeSvg(
      svg('''
      <style><![CDATA[rect{fill:url("#paint");font-family:"Some;Font";stroke:currentColor;stroke-width:2px}]]></style>
      <defs><linearGradient id="paint"/></defs><rect id="a"/>
    '''),
    );
    final rect = element(output, 'a');
    expect(rect.getAttribute('fill'), 'url("#paint")');
    expect(rect.getAttribute('font-family'), '"Some;Font"');
    expect(rect.getAttribute('stroke'), 'currentColor');
    expect(rect.getAttribute('stroke-width'), '2px');
    expect(element(output, 'paint').name.local, 'linearGradient');
  });

  test('CSS comments and mixed case important are parsed', () {
    final output = normalizeSvg(
      svg(
        '<style>.a { fill: /* note */none ! /* note */ IMPORTANT; }</style><rect id="a" class="a" style="fill:red"/>',
      ),
    );
    expect(element(output, 'a').getAttribute('fill'), 'none');
  });

  test('comments inside strings are preserved', () {
    final output = normalizeSvg(
      svg('<style>text{font-family:"/*family*/"}</style><text id="a"/>'),
    );
    expect(element(output, 'a').getAttribute('font-family'), '"/*family*/"');
  });

  test('XML namespaces and non-ASCII text are preserved', () {
    const source =
        '<s:svg xmlns:s="http://www.w3.org/2000/svg" viewBox="0 0 10 20"><s:style>.a{fill:none}</s:style><s:text id="a" class="a">Grüße 日本語</s:text></s:svg>';
    final output = normalizeSvg(source);
    expect(element(output, 'a').getAttribute('fill'), 'none');
    expect(element(output, 'a').innerText, 'Grüße 日本語');
    expect(element(output, 'a').name.prefix, 's');
  });

  for (final body in [
    '<style>.a:hover{fill:none}.a{stroke:red}</style><rect class="a"/>',
    '<style>@media screen{.a{fill:none}}</style><rect class="a"/>',
    '<style>@import url("outside.css");.a{fill:none}</style><rect class="a"/>',
    '<style>.a{--paint:red;fill:var(--paint)}</style><rect class="a"/>',
    '<style>.a{fill:inherit}</style><rect class="a"/>',
    '<style>.a{font:12px serif}</style><rect class="a"/>',
    '<style media="print">.a{fill:none}</style><rect class="a"/>',
    '<style type="text/other">.a{fill:none}</style><rect class="a"/>',
    '<style>svg|rect{fill:none}</style><rect/>',
    r'<style>.escaped\:class{fill:none}</style><rect/>',
    '<rect style="fill:env(foo)"/>',
    '<style>rect{fill}</style><rect/>',
  ]) {
    test('unsupported CSS is atomic: $body', () {
      final source = svg(body);
      final result = normalizeSvgWithWarnings(source);
      expect(result.isFullyNormalized, isFalse);
      expect(result.warnings, isNotEmpty);
      expect(result.svg, source);
    });
  }

  test('external stylesheet is not fetched or discarded', () {
    final source =
        '<?xml-stylesheet href="outside.css"?>${svg('<rect style="fill:red"/>')}';
    final result = normalizeSvgWithWarnings(source);
    expect(result.svg, source);
    expect(result.warnings.single, contains('xml-stylesheet'));
  });

  test('warning callbacks expose unsupported CSS', () {
    final warnings = <String>[];
    final source = svg('<style>rect:hover{fill:none}</style><rect/>');
    expect(normalizeSvg(source, onWarning: warnings.add), source);
    expect(warnings, isNotEmpty);
  });

  test('malformed XML throws', () {
    expect(() => normalizeSvg('<svg><style>'), throwsA(isA<XmlException>()));
  });

  test('cache reuses results, refreshes LRU and evicts by capacity', () {
    final cache = SvgNormalizer(maxCacheEntries: 2);
    final a = svg('<rect style="fill:none"/>');
    final b = svg('<rect style="fill:red"/>');
    final c = svg('<rect style="fill:blue"/>');
    final firstA = cache.normalizeWithWarnings(a);
    final firstB = cache.normalizeWithWarnings(b);
    expect(cache.normalizeWithWarnings(a), same(firstA));
    cache.normalize(c);
    expect(cache.normalizeWithWarnings(a), same(firstA));
    expect(cache.normalizeWithWarnings(b), isNot(same(firstB)));
    cache.clear();
    expect(cache.normalizeWithWarnings(a), isNot(same(firstA)));
  });

  test('disabled cache and oversized input are not retained', () {
    final source = svg('<rect style="fill:none"/>');
    for (final cache in [
      SvgNormalizer(maxCacheEntries: 0),
      SvgNormalizer(maxCachedSourceLength: 1),
    ]) {
      final first = cache.normalizeWithWarnings(source);
      expect(cache.normalizeWithWarnings(source), isNot(same(first)));
    }
  });

  test('cache rejects negative limits', () {
    expect(() => SvgNormalizer(maxCacheEntries: -1), throwsRangeError);
    expect(() => SvgNormalizer(maxCachedSourceLength: -1), throwsRangeError);
  });
}
