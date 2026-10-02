# svg_normalizer

A pure Dart SVG compatibility layer for renderers that support presentation
attributes but do not implement `<style>` stylesheets. Works on native platforms
and the web, without Flutter or platform bindings.

```dart
import 'package:svg_normalizer/svg_normalizer.dart';

final normalized = normalizeSvg(svgSource, onWarning: print);
// Pass normalized to your SVG renderer, such as SvgStringLoader.
```

For example, `<style>.outline{fill:none;stroke:black}</style>` and
`<rect class="outline" .../>` become `<rect class="outline" fill="none"
stroke="black" .../>`. `display:none` is preserved too, so hidden artwork stays
hidden. The stylesheet and resolved inline styles are removed only after all
styles have been successfully processed.

## Supported CSS

- Type, universal (`*`), ID, class and attribute selectors, including the six
  attribute match operators.
- Compound selectors, comma-separated selector lists and multiple classes.
- Descendant, child (`>`), adjacent (`+`) and general sibling (`~`) combinators.
- `:root`, stylesheet order, specificity, inline styles and `!important`.
- SVG 1.1 presentation properties and `vector-effect`. Values such as `none`,
  `currentColor`, units, quoted font names and local `url(...)` references are
  preserved. Renderer support for individual properties remains unchanged.
- Multiple style elements, CSS comments, CDATA and namespace-prefixed SVG XML.

Declarations are written onto the elements they match. Group inheritance and
group opacity remain on the original SVG tree; styles are not copied to every
descendant. IDs, classes, geometry, definitions, dimensions and text are retained.

This is a static SVG subset, not a browser CSS engine. At-rules (including media
queries, font faces and imports), external stylesheets, namespace and escaped
selectors, pseudo selectors other than `:root`, custom properties, `var()` and
`env()`, shorthands and CSS-wide keywords are unsupported. If any unsupported or
malformed CSS is encountered, the **entire original SVG is returned unchanged**
with diagnostics. No stylesheets or external resources are fetched.

```dart
final result = normalizeSvgWithWarnings(svgSource);
if (!result.isFullyNormalized) {
  for (final warning in result.warnings) {
    print(warning);
  }
}
render(result.svg);
```

Malformed XML throws an `XmlException`. SVGs without styles are returned
unchanged. The normalizer is not an SVG validator or sanitizer.

## Caching

For repeated rendering, use an instance with a bounded LRU cache:

```dart
final normalizer = SvgNormalizer(maxCacheEntries: 32);
final normalized = normalizer.normalize(svgSource, onWarning: print);
normalizer.clear();
```

Cache keys contain the original source, so changed assets cannot reuse stale
styles. By default, sources longer than 256 Ki characters are not cached. Set
`maxCacheEntries: 0` to disable caching.

## Development

The package is a member of the `dart_pkgs` pub workspace. From this directory:

```sh
flutter pub get
dart analyze
dart test
```

Flutter resolves the monorepo's Flutter dependencies; this package itself is pure
Dart. Tests cover Illustrator exports, the CSS cascade, selector matching,
inheritance, preservation of SVG content, unsupported CSS and cache behavior.
