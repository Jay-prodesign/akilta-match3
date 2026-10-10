# Core Piece SVG Provenance

Status: AKILTA first-party original art-direction candidate v2.

Files:
- moon_sigil.svg
- thorn_rose.svg
- luna_moth.svg
- curio_key.svg
- night_ivy.svg

These SVGs were authored specifically for this Match-3 product. They do not copy donor demo art, paid asset packs, or recognizable third-party product identity. The five families preserve the established gameplay contract: unique silhouette + internal motif + value/material cues in addition to color.

Runtime loading uses Godot Image.load_svg_from_string so CI and first boot do not depend on editor import cache. The older procedural drawing path remains a fail-open fallback until D-027 Founder approval.
