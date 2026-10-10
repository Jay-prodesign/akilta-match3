# AKILTA Match-3 — Production Design Engineering Contract

Status: ACTIVE ENGINEERING GUARDRAIL · 2026-10-10

## Authority

Google Drive remains canonical for product truth, roadmap, decisions, North Star and current project state. This file mirrors only the engineering constraints needed to keep implementation aligned. If this file conflicts with current Drive authority, Drive wins.

Current protected boundary: Founder approval of rendered Level 1 gameplay/readability and the core asset language is required before Level 2+ content or broad reusable shipping-asset production becomes canonical. Existing Level 2–3 work is provisional engineering exploration.

## World-Translated Game Grammar

Do not implement a generic casual-game component first and merely recolor it gothic.

For every player-facing element ask:

1. What is the category/function the player must understand?
2. What is this game's House-native dark-cute / witchy-gothic expression of that function?
3. Is it still immediately readable and accessible?
4. What gameplay/UX role and states does it own?
5. Is it original and coherent with the rest of the product?

Stars, chests, gems, badges, locks, level nodes, booster presentation, victory markers and similar category shorthand are not automatic defaults. Utility controls such as back, close, settings and audio should remain familiar when thematic reinvention would reduce usability.

## Base Piece Ecology

- Stable base-family identity uses color + silhouette + motif + value structure.
- A level explicitly owns its active family set; not every available object belongs in every level.
- Avoid same-color conflicting base identities in one level unless an intentionally taught mechanic requires them.
- Preserve learned functional mapping across chapter variants by default.
- Prefer novelty through blockers, objectives, topology, specials, environmental interactions and selected chapter-specific objects before repeatedly changing the learned base-piece vocabulary.
- Gameplay scanning speed outranks ornament.

Current opening candidate families are moon, rose, moth, key and leaf. Their current procedural drawings and candidate colors are not approved shipping art until the Founder Level 1/core-asset gate passes.

## Screen Contract

Before a player-facing screen is complete, define:

- player job / primary action;
- information hierarchy;
- world translation;
- required states: normal, pressed, disabled, loading, error, empty, locked, complete where applicable;
- navigation and recovery;
- accessibility/readability;
- localization/responsive behavior;
- motion/audio/haptic roles;
- performance constraints.

A screen is not complete because its happy-path screenshot looks attractive.

## Asset Contract

Shipping assets must eventually be registered with:

- semantic ID;
- asset class;
- gameplay/UX role;
- global or chapter scope;
- required variants/states;
- target import/display sizes;
- source/provenance;
- production status: concept | reference | candidate | approved | shipping | retired;
- performance/import notes.

Concept/reference/procedural assets never silently become shipping assets.

## Design Tokens

After the Founder approves Level 1/core visual direction, approved palette, typography, spacing, radius, materials, functional state colors and motion timings must be centralized as semantic tokens/resources. Do not proliferate final hard-coded visual constants across scenes/scripts.

Until that approval, candidate values may remain local for gate evidence but must be treated as replaceable.

## Level Authoring Contract

Level content must explicitly define or resolve:

- active base-piece families;
- objective family / blocker set;
- mechanic introductions;
- board topology;
- chapter expression/profile;
- teaching/tutorial requirements;
- validation seed and expected behavior.

Authoring/validation should reject unknown family mappings, invalid content states and layouts that violate readability contracts once the approved visual registry exists.

## Motion Contract

Presentation consumes logical gameplay state/ResolutionTrace; animation must never own gameplay truth.

Motion roles must cover, as applicable:

- swap;
- rejected swap;
- match/clear;
- gravity;
- refill/spawn;
- special creation;
- special trigger;
- special combo;
- blocker damage/clear;
- objective completion;
- win/fail;
- House/Curio awakening.

Motion should explain state change and preserve the next actionable state. Reduced-motion equivalents are required before release-scale production.

## World / Chapter Contract

The House is persistent progression, not a menu wallpaper. Chapter art, blockers, objectives, selected objects, VFX and environment can vary, while shared typography/material/UI grammar remains coherent across gameplay, meta, events and commercial surfaces.

A chapter must not feel like a separate app or require players to relearn the basic match vocabulary without deliberate tutorialization.

## Review / Gate Model

Use risk-based, milestone-level review rather than micro-approval:

- Level 1 + core asset language: Founder true gate before scale.
- During implementation: continuous checks for gameplay state, save/progression, input and runtime invariants.
- Meaningful player-outcome milestones: rendered visual/readability/North Star review.
- P4/P5 production: asset manifest + token + motion contracts become implementation requirements.
- P14/P15: integrated real-device/session validation for identity, readability, accessibility, performance and coherence.

## Current Repository Interpretation

The current procedural pieces, board styling and Curio Boutique drawing are production-direction prototypes. The architecture is intentionally separable enough that approved final assets/tokens/motion can replace presentation without replacing deterministic gameplay authority.
