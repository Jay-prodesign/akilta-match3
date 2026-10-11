# AKILTA Match-3 Core Symbol Set

Status: AKILTA first-party production candidates for the Curio Boutique opening. The S05 gameplay board uses one invariant eight-family vocabulary across opening level profiles; level profiles may tune surrounding presentation but must not remap a gameplay family to a different visible symbol.

## Canonical runtime family mapping

| Gameplay family ID | Visible symbol | Raster runtime | Owned fallback |
| --- | --- | --- | --- |
| `moon` | Moonstone crescent sigil | `moon_sigil.webp` | `moon_sigil.svg` |
| `rose` | Thorned wine rose | `thorn_rose.webp` | `thorn_rose.svg` |
| `moth` | Luna moth | `luna_moth.webp` | `luna_moth.svg` |
| `key` | Antique curio key | `curio_key.webp` | `curio_key.svg` |
| `leaf` | Night ivy leaf | `night_ivy.webp` | `night_ivy.svg` |
| `cat` | Black cat with crescent collar | `black_cat.webp` | `black_cat.svg` |
| `candle` | Ivory witchlight candle | `candle.webp` | `candle.svg` |
| `skull` | Aged curio skull | `skull.webp` | `skull.svg` |

The runtime resolver is WebP-first and falls back only to the matching owned SVG silhouette if its raster candidate is missing or unreadable. Family identity is invariant across visual profiles.

## S05 production-family pass

The eight raster candidates are one coordinated gameplay family rather than isolated icons. Their shared direction is dark-romantic gothic reliquary objects with moonlit directional light, antique-gold edge language, deep plum/charcoal accents and strong silhouette separation at board scale. Candy, flat-vector, plastic-toy and generic-gem treatments are excluded.

These files remain **candidate** art until the rendered board and actual Golden Loop play/readability gate passes. Technical import success or CI PASS alone does not promote them to approved/shipping.

All files are maintained as AKILTA first-party product assets. Player-facing metadata must describe the canonical visible symbol, never a historical/internal remapping.
