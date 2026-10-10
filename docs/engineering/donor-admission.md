# Match-3 Donor Admission

## Candidate

- Upstream: `sempitern0/match3-board`
- Exact audited commit: `11945ef6db1703ba3043b1d93563514930e2ab37`
- Commit date: 2025-07-22
- License: MIT
- Upstream addon version: 2.1.0
- Upstream project feature line: Godot 4.4
- Product target: Godot 4.7.2-stable
- Decision: PENDING RUNTIME AUDIT

## True Gate Outcomes

- **ADMIT** — donor remains a maintainable technical foundation; adaptation is contained.
- **HARVEST** — selected algorithms/utilities are useful, but core architecture remains ours.
- **REJECT** — compatibility/coupling/maintenance cost removes the acceleration benefit.

## Static Architecture Findings

Evidence from exact audited commit:

1. `Match3Board` extends `Node2D`; the board model and scene/runtime object graph are not a pure data-domain core.
2. `Match3PieceGenerator` owns a `RandomNumberGenerator` but calls `rng.randomize()` in `_init()`.
3. Piece selection also calls Array `shuffle()`, which uses global RNG rather than the owned RNG.
4. `Match3Shuffler` calls Array `shuffle()`, again coupling outcome randomness to global RNG.
5. Board resolution contains `await get_tree().process_frame` calls.
6. Core consume/swap/fall paths directly coordinate optional animator hooks.
7. Sequence detector/consumer logic is relatively self-contained and is a promising HARVEST candidate.
8. Demo/product assets are clearly separable under `demo/` and must never be admitted as product assets.

These findings do not alone decide the gate. Runtime compatibility on Godot 4.7.2 is tested separately.

## Mandatory Checks

1. Exact upstream commit pinned. **PASS**
2. MIT license and dependency boundaries verified. **PASS at repository level; file-level notice retained if harvested**
3. Godot 4.7.2 project parse/load. **PENDING**
4. Representative demo/board runtime boot. **PENDING**
5. Shaped/empty-cell support exists. **PASS by API/static evidence**
6. Special spawn/rule extensibility exists. **PASS by API/static evidence**
7. Obstacle/blocker extensibility exists. **PASS by API/static evidence**
8. Gameplay RNG can be controlled or cleanly wrapped for reproducibility. **CONCERN**
9. Logical board outcomes can be observed without presentation owning game truth. **CONCERN**
10. Headless/simulation path remains practical. **PENDING / CONCERN**
11. Demo/product art and UI can be completely excluded. **PASS**
12. No mandatory paid or incompatible dependency. **PASS from current repository audit**

## Product Rule

The donor is allowed to accelerate low-level mechanics only. It does not own product identity, world, levels, economy, live systems, UI, art, audio or commercial behavior.
