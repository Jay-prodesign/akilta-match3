# AKILTA Match-3 Core Symbol Set

Status: AKILTA first-party original art-direction candidates for the Curio Boutique opening; Level 1 now uses the complete eight-symbol North Star set.

## Runtime family mapping

| Gameplay family ID | Visible symbol | Runtime SVG |
| --- | --- | --- |
| `moon` | Moonstone crescent | `moon_sigil.svg` |
| `rose` | Thorned wine rose | `thorn_rose.svg` |
| `moth` | Moon Crow | `crow.svg` |
| `key` | Witchlight potion flask | `potion.svg` |
| `leaf` | Gilded pentagram sigil | `pentagram.svg` |

The five gameplay IDs are retained for deterministic level data compatibility. Cat, candle, and skull SVGs are used through level-specific visual profiles while the five logical gameplay family IDs remain stable. This preserves deterministic puzzle rules while varying the actual North Star symbols by chapter. Player-facing art metadata must describe the rendered symbol, not the historical/internal family name.

## Level-specific visual profiles

- `curio_boutique_opening`: moonstone crescent, thorn rose, crow, potion flask, pentagram.
- `sealed_display`: moonstone crescent, thorn rose, black cat, candle, skull.
- `thornlight_arrangement`: moonstone crescent, black cat, crow, potion flask, candle.

## Supporting world symbols

- `black_cat.svg` — black cat motif for House/world scenes and future level families.
- `candle.svg` — candle motif for House/world scenes and future level families.
- `skull.svg` — skull motif for House/world scenes and future level families.
- `curio_key.svg` — antique key relic for collection/world UI.
- `luna_moth.svg` — moth relic motif.
- `night_ivy.svg` — botanical world ornament.

All files in this directory are maintained as original AKILTA art-direction candidates. Runtime piece rendering loads SVGs directly through Godot's SVG image loader; the owned procedural renderer remains a fail-open fallback. Do not describe a symbol as approved final art until it has passed visual review against the North Star Product Board.
