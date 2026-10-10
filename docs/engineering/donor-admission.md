# Match-3 Donor Admission

## Candidate

- Upstream: `sempitern0/match3-board`
- License: MIT
- Current upstream compatibility claim: main branch targets Godot 4.4.x
- Product target: Godot 4.7.2-stable
- Decision: PENDING

## True Gate Outcomes

- **ADMIT** — donor remains a maintainable technical foundation; adaptation is contained.
- **HARVEST** — selected algorithms/utilities are useful, but core architecture remains ours.
- **REJECT** — compatibility/coupling/maintenance cost removes the acceleration benefit.

## Mandatory Checks

1. Exact upstream commit pinned.
2. MIT license and dependency boundaries verified.
3. Godot 4.7.2 project parse/load.
4. Representative adjacent swap.
5. Shaped/empty-cell board.
6. Special spawn/rule extensibility.
7. Obstacle/blocker extensibility.
8. Gameplay RNG can be controlled or cleanly wrapped for reproducibility.
9. Logical board outcomes can be observed without presentation owning game truth.
10. Headless/simulation path remains practical.
11. Demo/product art and UI can be completely excluded.
12. No mandatory paid or incompatible dependency.

## Product Rule

The donor is allowed to accelerate low-level mechanics only. It does not own product identity, world, levels, economy, live systems, UI, art, audio or commercial behavior.
