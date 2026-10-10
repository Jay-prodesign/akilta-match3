# P1.5 Donor Presentation Harvest

Status: ACTIVE · bounded visual acceleration

## Audited source

- Source: sempitern0/match3-board
- Exact commit: 11945ef6db1703ba3043b1d93563514930e2ab37
- License: MIT
- Godot 4.7.2 compatibility: previously proven PASS
- Product/runtime authority: NOT ADMITTED

## File/capability classification

### HARVEST / ADAPT
- `src/ui/match3_animator.gd`: animator-hook separation and named presentation phases.
- `demo/demo_animator.gd`: swap/reject/clear/fall/spawn/shuffle tween patterns as implementation references only.
- `src/ui/match3_highlighter.gd`: separate input/highlight presentation seam.

The AKILTA renderer does not import the donor Node2D board runtime. These ideas are adapted onto the existing deterministic resolution trace so presentation remains downstream of gameplay truth.

### REJECT DIRECT USE
- donor board runtime/global RNG authority;
- donor demo scene and demo levels;
- donor product/UI identity;
- demo gem PNGs until independent asset provenance is explicitly established.

## Current adaptation

`Match3BoardView` now consumes enriched deterministic trace events and renders a serial resolution language:
swap/reject → clear/special → gravity → spawn → settle.

The timing profile records the exact donor commit/license but is AKILTA-owned and may be tuned independently. No donor demo PNG is required by the implementation.

## D-027 boundary

This harvest is acceleration toward the completed Level 1 candidate. It does not approve Level 1 art direction and cannot authorize canonical Level 2+ content.
