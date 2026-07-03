# Bloom theme tokens

Extracted verbatim from `Bloom Calculator (all-in-one).html` lines 11-41 (`:root` and the
`rose`/`peony`/`soft` presets) and lines 1750-1763 (`THEME_VARS`, the 12 user-editable tokens).

Preset selectors only redeclare a subset of CSS custom properties; any token not redeclared
by `[data-theme="rose"|"peony"|"soft"]` falls through to the `:root` value via normal CSS
custom-property resolution (both selectors target `<html>`, and only listed properties are
overridden). That is why `good`, `ripple`, `sh1`, and `radius` are identical across all four
presets below: none of the three non-default presets ever redeclare them.

## The 16 tokens (CONTRACTS UI registry, camelCase names)

| token (camelCase) | CSS var | cherry (root, default) | rose | peony | soft |
|---|---|---|---|---|---|
| bg | `--bg` | `#FDF2F7` | `#FDF2F1` | `#FDF1F8` | `#FEF7F9` |
| surface | `--surface` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` | `#FFFFFF` |
| surfaceSoft | `--surface-soft` | `#FBE4EE` | `#FADDE0` | `#F9DCEC` | `#FBE7ED` |
| surface2 | `--surface-2` | `#FDF0F5` | `#FCEBEC` | `#FCEAF3` | `#FDF1F4` |
| primary | `--primary` | `#F06FA7` | `#E56A87` | `#E15BA4` | `#EE9DBB` |
| primaryStrong | `--primary-strong` | `#E2417F` | `#CE3E63` | `#C22E85` | `#DB6E93` |
| deep | `--deep` | `#B01B58` | `#A11C41` | `#8E1560` | `#B04266` |
| text | `--text` | `#421527` | `#431B23` | `#3B1030` | `#4A2533` |
| muted | `--muted` | `#8E5F72` | `#92626D` | `#8F5F7E` | `#97707F` |
| line | `--line` | `#F2CEDF` | `#F1CBD1` | `#EFC8E0` | `#F4D8E1` |
| flowerCenter | `--flower-center` | `#FFC966` | `#FFC878` | `#FFC966` | `#FFD488` |
| good | `--good` | `#2E9E5B` | `#2E9E5B` (inherited, not redeclared) | `#2E9E5B` (inherited, not redeclared) | `#2E9E5B` (inherited, not redeclared) |
| shadow | `--shadow` | `rgba(176,27,88,.16)` | `rgba(161,28,65,.16)` | `rgba(142,21,96,.16)` | `rgba(176,66,102,.14)` |
| ripple | `--ripple` | `rgba(255,255,255,.55)` | inherited (same) | inherited (same) | inherited (same) |
| sh1 | `--sh-1` | `0 1px 2px rgba(66,21,39,.10),0 1px 1px rgba(66,21,39,.06)` | inherited (same) | inherited (same) | inherited (same) |
| radius | `--radius` | `22px` | inherited (same) | inherited (same) | inherited (same) |

Notes:
- `radius` is a CGFloat-encoded string per the CONTRACTS `ThemeSpec.tokens: [String: String]`
  shape; the numeric value is `22` (points), suffix `px` dropped by the iOS layer.
- The source also defines `--radius-lg:24px`, `--radius-md:16px`, `--radius-sm:12px`,
  `--radius-pill:999px` which are not part of the frozen 16-token registry and are not
  included here; worker-core/UI workers should hardcode these as needed since the contract
  only freezes the single `radius` token.
- `--shadow` and `--ripple` are rgba() strings, not hex; `--sh-1` is a raw CSS box-shadow
  value with two comma-separated layers. These are carried through as opaque strings in
  `ThemeSpec.tokens`, not decomposed.
- `surface` is `#FFFFFF` in every preset, no exceptions.

## The 12 editable tokens (THEME_VARS, lines 1750-1763)

These are the only tokens the in-app color-picker (custom theme editor) exposes. Order and
human labels are verbatim from the source array.

| order | CSS var | camelCase token | human label |
|---|---|---|---|
| 1 | `--bg` | bg | Page background |
| 2 | `--surface` | surface | Card surface |
| 3 | `--surface-soft` | surfaceSoft | Keys & panels |
| 4 | `--surface-2` | surface2 | Accent panels |
| 5 | `--primary` | primary | Flower petals |
| 6 | `--primary-strong` | primaryStrong | Strong accent |
| 7 | `--deep` | deep | Headlines |
| 8 | `--text` | text | Main text |
| 9 | `--muted` | muted | Soft text |
| 10 | `--line` | line | Borders |
| 11 | `--flower-center` | flowerCenter | Flower center |
| 12 | `--good` | good | Growth color |

The remaining 4 of the 16 registry tokens (`shadow`, `ripple`, `sh1`, `radius`) are **not**
editable via THEME_VARS; they are derived/fixed values not exposed to the custom theme UI in
the source app.

## Font roles

Extracted from the `@font-face`/`--font-*` declarations (line 9 Google Fonts link, lines
19-21 `:root` font variables) and corroborated by usage across the stylesheet.

| role | CSS var | family | fallback stack | usage |
|---|---|---|---|---|
| body | `--font-body` | Quicksand | `-apple-system, 'Segoe UI', Roboto, sans-serif` | default body text, UI chrome |
| numbers / headings | `--font-display` | Playfair Display | `Georgia, serif` | calculator display, headings, weights 500/600, italic 500 |
| splash / poem titles | `--font-script` | Great Vibes | `'Brush Script MT', cursive` | splash screen brand script, poem/egg titles |

Google Fonts request (line 9): `family=Great+Vibes&family=Playfair+Display:ital,wght@0,500;0,600;1,500&family=Quicksand:wght@400;500;600;700`.

Per CONTRACTS scaffold registry, the iOS build embeds these as `UIAppFonts` entries:
`Quicksand`, `PlayfairDisplay`, `PlayfairDisplay-Italic`, `GreatVibes`, fetched at CI time
from pinned google/fonts GitHub raw URLs (never committed to the repo).

## Source line references

- `:root` theme vars: `Bloom Calculator (all-in-one).html:11-24`
- `rose` preset: `Bloom Calculator (all-in-one).html:25-29`
- `peony` preset: `Bloom Calculator (all-in-one).html:30-34`
- `soft` preset: `Bloom Calculator (all-in-one).html:35-41`
- `THEME_VARS` (12 editable tokens): `Bloom Calculator (all-in-one).html:1750-1763`
- Google Fonts stylesheet link: `Bloom Calculator (all-in-one).html:9`
