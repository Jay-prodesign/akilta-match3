# Match-3 Donor Admission

## Gate Decision

**HARVEST**

The exact donor commit is technically compatible with Godot 4.7.2, but the whole addon is not admitted as the product's Match-3 foundation because its runtime architecture conflicts with the project's deterministic pure-domain/simulation contract.

## Candidate

- Upstream: `sempitern0/match3-board`
- Exact audited commit: `11945ef6db1703ba3043b1d93563514930e2ab37`
- Commit date: 2025-07-22
- License: MIT
- Upstream addon version: 2.1.0
- Upstream project feature line: Godot 4.4
- Product target tested: Godot 4.7.2-stable

## Runtime Evidence

GitHub Actions donor audit on 2026-10-10:

- exact archive download: PASS;
- repository MIT license check: PASS;
- Godot 4.7.2 editor/project parse: PASS;
- donor demo scene headless boot on Godot 4.7.2: PASS;
- required module files present: PASS.

Therefore the donor is not rejected for compatibility.

## Architecture Evidence

1. `Match3Board` extends `Node2D`; board truth lives in the scene/runtime object graph instead of a pure data-domain core.
2. `Match3PieceGenerator` calls `rng.randomize()`.
3. Piece rolling also calls Array `shuffle()`, using global RNG outside the owned RNG.
4. `Match3Shuffler` calls Array `shuffle()`, also tying gameplay outcome to global RNG.
5. Board resolution contains `await get_tree().process_frame`.
6. Consume/swap/fall paths coordinate animator/runtime hooks directly.
7. Sequence detector/consumer and configuration concepts are comparatively separable and useful.
8. Demo/product assets are isolated and can be excluded completely.

## Why HARVEST Instead of ADMIT

Full ADMIT would save initial board implementation work but would make deterministic simulation, replay/debug traces and strict presentation separation more expensive for the lifetime of the game. Repairing the addon until it meets our architecture would amount to invasive rewrites inside a donor-owned shape.

HARVEST preserves the useful work without accepting that coupling.

## Authorized Harvest Scope

Allowed after tests define our interfaces:

- match/sequence detection concepts and selected MIT implementation ideas;
- sequence priority / special-spawn rule concepts;
- shaped/empty-cell configuration concepts;
- weighted piece-generation concepts, rewritten behind our seeded RNG boundary;
- useful finder/fall/fill algorithm concepts when they fit our pure-domain structures.

Not admitted:

- `Match3Board` as product state authority;
- donor scene/UI/input shell;
- demo levels;
- demo art/assets;
- donor animator/highlighter presentation;
- donor global RNG behavior;
- donor product naming/copy.

## Provenance Rule

Any source code substantially copied or adapted from the audited commit must identify its upstream file in code comments or the third-party register and retain the required MIT copyright/license notice. Purely independent implementations informed by generic Match-3 concepts should not be falsely attributed as copied code.

## Gate Status

- Compatibility: PASS
- Commercial license: PASS
- Product originality boundary: PASS
- Deterministic architecture as full donor: FAIL
- Maintainable selective reuse: PASS
- **FINAL: HARVEST**
