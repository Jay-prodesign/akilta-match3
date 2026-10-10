# P0 / First Production Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Establish the production Godot baseline, make an evidence-based donor admission decision, and deliver the first coherent player journey: launch → dark Match-3 level → win/fail → House awakening → save → relaunch with progress preserved.

**Architecture:** Godot 4.7.2-stable with GDScript. Gameplay authority is separated from presentation and vendor SDKs. The Match-3 donor is evaluated against the product contracts before admission; if it cannot support deterministic simulation, original specials/blockers, and clean presentation separation without invasive surgery, only reusable parts are harvested or it is rejected.

**Tech Stack:** Godot 4.7.2-stable, GDScript, headless Godot test runner, declarative JSON/resource content, no mandatory paid dependencies.

**Spec:** Google Drive canonical product/production authority: R6 Final Product Definition, R7 Experience/Creative Architecture, R8 Commercial/Data Architecture, R9 Technology/Donor Selection, R10 Production Architecture, D-019 Four-Layer Decision Model.

## Global Constraints

- Canonical product core is Match-3.
- Dark Cute / Witchy-Goth / Cozy-Macabre creative North Star is binding.
- Repository may remain public by Founder decision; never commit secrets, private credentials, unlicensed assets/code, or private research documents.
- Godot target is 4.7.2-stable unless a verified compatibility blocker requires a recorded ruling.
- GDScript is the default game/application language.
- No mandatory paid engine, plugin, asset pack, SDK, backend plan, or service dependency.
- Donor identity must not define the product. Donor art, UI shell, campaign levels, economy, copy and world are excluded.
- Gameplay state authority must be testable separately from presentation.
- RNG affecting gameplay must be seedable/reproducible.
- Save/reward transactions must be resilient to interruption and duplication.
- No payer-sensitive hidden difficulty.
- Work units are coherent player outcomes, not micro-features or micro-commits.
- Broad device/build/evidence regression is milestone-based; critical gameplay/save/runtime invariants get focused checks continuously.

## North Star Acceptance Gates

These gates are milestone acceptance criteria, not repeated Founder approval pauses. A failed gate triggers correction and continued implementation unless the correction would change a Locked Product Decision or cross a True Gate.

1. **Core Fun** — Match-3 remains satisfying without meta/world.
2. **Dark-Cute Identity** — the product is unmistakably its own dark-alt game, not a gothic palette swap.
3. **First 60 Seconds** — identity, first move, payoff and House connection arrive quickly without overload.
4. **World–Gameplay Coherence** — puzzle progress and House/Curio progression feel causally connected; no generic stars-to-renovation loop.
5. **Player Trust** — difficulty, fail assistance, rewards and monetization remain understandable and non-manipulative.
6. **Readability & Accessibility** — dark styling never hides gameplay state; piece distinction does not depend on hue alone.
7. **Originality** — donor/template identity is invisible; world, UI, content and store identity are product-specific.
8. **Permanence / Continuity** — progression, Curios, rewards and entitlements survive interruption/relaunch without loss or duplication.
9. **Whole-Product Quality** — gameplay, House, collection, settings, commercial/live and recovery surfaces feel like one complete product.
10. **Commercial Completeness** — scalable content tooling, analytics, economy/reward integrity, live operations, support and release operations exist before release.
11. **Content Depth** — mechanics, level archetypes, Curios and chapters sustain novelty beyond the opening levels.
12. **Desire** — target players should want both the next level and the next world/Curio outcome.

**Final North Star Gate:** Would a dark-alt player plausibly feel this is a polished Match-3 made for their taste rather than a mainstream casual game wearing a gothic skin?

## Review Focus

1. **Godot version drift:** project must fail clearly if opened/run on an unsupported engine baseline rather than silently changing behavior.
2. **Donor coupling:** donor must not make simulation/headless testing or original presentation impractical.
3. **Board determinism:** identical seed + level + move sequence must yield identical logical outcomes.
4. **Interrupted progression:** a crash/relaunch between level completion and House animation must preserve earned progression without duplicate reward.
5. **Dark-board readability:** representative pieces/blocker/specials must remain distinguishable by silhouette/motif/value, not hue alone.

---

### Task 1: Production Bootstrap + Headless Verification Baseline

**Player outcome:** The game has a clean production project that launches into a controlled bootstrap scene and can be verified headlessly before feature work.

**Files:**
- Create: `project.godot`
- Create: `.gitignore`
- Create: `.gitattributes`
- Create: `src/app/app_bootstrap.gd`
- Create: `src/app/app_bootstrap.tscn`
- Create: `tests/test_runner.gd`
- Create: `tests/unit/test_bootstrap.gd`
- Create: `docs/engineering/third-party-notices.md`
- Create: `docs/engineering/donor-admission.md`

**Interfaces:**
- Produces: `AppBootstrap` scene/script and a zero-external-dependency headless test command.
- Consumes: none.

- [ ] **Step 1: Write the failing bootstrap test**

Test asserts:
- project version contract declares 4.7.2;
- `AppBootstrap` can instantiate headlessly;
- bootstrap exposes environment `development` by default;
- no vendor service is required to start.

- [ ] **Step 2: Run test and verify RED**

Run:
`godot --headless --path . -s res://tests/test_runner.gd -- res://tests/unit/test_bootstrap.gd`

Expected: FAIL because bootstrap/project files do not yet exist.

- [ ] **Step 3: Implement minimal production bootstrap**

Create Godot project, bootstrap scene, environment constant/config boundary, and test runner. Do not add gameplay or services yet.

- [ ] **Step 4: Verify GREEN and project parse**

Run:
`godot --headless --path . -s res://tests/test_runner.gd -- res://tests/unit/test_bootstrap.gd`
and:
`godot --headless --path . --editor --quit`

Expected: both exit 0.

- [ ] **Step 5: Commit coherent bootstrap**

Commit message:
`build: establish Godot production baseline`

---

### Task 2: Donor Admission — ADMIT / HARVEST / REJECT

**Player outcome:** We know whether the donor accelerates the real game without constraining product architecture.

**Files:**
- Create/Modify: `docs/engineering/donor-admission.md`
- Create temporary audit workspace under `.audit/match3-board/` (gitignored; never shipping)
- Test: `tests/integration/test_donor_contract.gd` only if donor reaches ADMIT/HARVEST integration stage
- Modify: `docs/engineering/third-party-notices.md` if code is admitted

**Interfaces:**
- Consumes: Godot 4.7.2 baseline from Task 1.
- Produces: one recorded ruling: `ADMIT`, `HARVEST`, or `REJECT`; if admitted, exact upstream repo + commit + license boundary.

- [ ] **Step 1: Pin upstream evidence**

Record:
- upstream `sempitern0/match3-board`;
- exact tested commit SHA;
- MIT license;
- README-declared compatibility currently targeting Godot 4.4.x main;
- any dependencies/assets discovered.

- [ ] **Step 2: Run isolated 4.7.2 compatibility smoke test**

Verify:
- plugin/project parses;
- representative board instantiates;
- adjacent swap works;
- shaped/empty cells work;
- sequence rules can create specials;
- obstacles can be extended;
- animation hooks are separable;
- no hidden paid/incompatible dependency.

Expected: factual compatibility result, not assumed success.

- [ ] **Step 3: Test architecture fit**

Prototype only the minimum required to answer:
- can gameplay-affecting RNG be injected/seeded?
- can board logic run headlessly enough for simulation?
- can logical outcomes be observed without relying on animations?
- can our four special families and blocker rules be implemented without modifying most of the addon?
- can donor visuals/demo assets be completely excluded?

- [ ] **Step 4: Rule**

`ADMIT` if donor can remain a maintainable technical foundation with contained adaptation.
`HARVEST` if selected algorithms/utilities are useful but the node architecture conflicts with deterministic product contracts.
`REJECT` if compatibility, coupling or maintenance cost removes the acceleration benefit.

The ruling is a TRUE GATE. Do not silently soften criteria to preserve the donor.

- [ ] **Step 5: Commit only admitted material / admission record**

Commit message:
`arch: decide Match-3 donor admission`

---

### Task 3: Deterministic Match-3 Core + Representative Gameplay Grammar

**Player outcome:** A real board supports responsive legal swaps, cascades, four special families, one blocker, win/fail state and reproducible outcomes.

**Files:**
- Create/Modify: `src/match3/domain/board_state.gd`
- Create/Modify: `src/match3/domain/board_rng.gd`
- Create/Modify: `src/match3/domain/move_resolver.gd`
- Create/Modify: `src/match3/domain/match_detector.gd`
- Create/Modify: `src/match3/domain/resolution_trace.gd`
- Create/Modify: `src/match3/domain/special_rules.gd`
- Create/Modify: `src/match3/domain/objective_state.gd`
- Create/Modify: `src/match3/domain/blockers/wax_seal.gd`
- Create: `content/levels/ch01/level_001.json`
- Test: `tests/unit/match3/*`

Exact files may map to admitted donor extension points; interfaces below remain authoritative.

**Interfaces:**
- Produces:
  - `BoardState.from_level(level_data, seed)`
  - `MoveResolver.try_swap(board, from, to) -> ResolutionTrace`
  - deterministic logical trace events
  - level result `playing | won | failed`
- Consumes: donor only through an adapter/extension boundary if admitted.

- [ ] **Step 1: RED — deterministic seed contract**

Identical level + seed produces identical initial logical board.

- [ ] **Step 2: GREEN — RNG and board state**

Implement minimum board state/RNG boundary.

- [ ] **Step 3: RED — legal/illegal swap and cascade trace**

Assert invalid swaps restore state; valid swap emits match/clear/gravity/spawn events in deterministic order.

- [ ] **Step 4: GREEN — move/match/cascade resolution**

Implement only enough to satisfy product grammar.

- [ ] **Step 5: RED — four special creation families and pair-combo contract**

Cover directional, area, smart-target and global special creation; pin at least the most critical pair interactions now and table-drive the remaining matrix.

- [ ] **Step 6: GREEN — specials + combo resolution**

Special function is domain logic; fantasy naming/animation remains presentation.

- [ ] **Step 7: RED — Wax Seal objective + win/fail**

Assert adjacent/special damage states, objective count updates, move consumption and terminal result.

- [ ] **Step 8: GREEN — blocker/objective/terminal state**

Implement representative first blocker and clear objective.

- [ ] **Step 9: Full headless core suite**

Run all core tests. Expected: 0 failures and deterministic replay checks green.

- [ ] **Step 10: Commit coherent gameplay core**

Commit message:
`feat: build deterministic Match-3 core`

---

### Task 4: Dark-Cute Playable Level — Production-Direction Visual Slice

**Player outcome:** The player can actually play Level 1 with the product’s dark identity, readable pieces, responsive swaps, representative specials/blocker and fast win/fail feedback.

**Files:**
- Create: `src/match3/presentation/board_view.tscn`
- Create: `src/match3/presentation/board_view.gd`
- Create: `src/match3/presentation/piece_view.gd`
- Create: `src/match3/presentation/special_view.gd`
- Create: `src/match3/presentation/blocker_view.gd`
- Create: `src/ui/gameplay/gameplay_screen.tscn`
- Create: `src/ui/gameplay/gameplay_screen.gd`
- Create: `src/ui/gameplay/result_overlay.tscn`
- Create: `src/ui/theme/nocturne_plum_theme.tres`
- Create representative owned/generated runtime assets only after provenance is recorded
- Test: `tests/integration/test_gameplay_screen.gd`

**Interfaces:**
- Consumes: `ResolutionTrace` + domain state from Task 3.
- Produces: gameplay screen that never owns Match-3 rules.

- [ ] **Step 1: RED — presentation reacts to logical state without mutating it**

Test UI can render board state and consume a trace while domain result remains identical.

- [ ] **Step 2: GREEN — board/piece view**

Implement portrait board composition and touch input forwarding.

- [ ] **Step 3: Build representative five-family piece language**

Requirements:
- distinguishable silhouette;
- internal motif;
- value structure;
- Nocturne Plum palette;
- no hue-only distinction;
- no donor/demo art.

- [ ] **Step 4: Implement representative special/Wax Seal feedback**

Fast, readable, original product expression. Avoid rockets/bombs/disco-ball literal copying.

- [ ] **Step 5: Implement win/fail overlay**

Retry prominent, failure non-shaming, board context preserved.

- [ ] **Step 6: Render/visual acceptance**

Capture representative phone viewport(s) and check:
- board geometry instantly readable;
- pieces distinguishable without color alone;
- special function legible;
- VFX does not hide next actionable state;
- screen cannot be mistaken for generic bright-candy Match-3 after palette removal.

- [ ] **Step 7: Run headless + rendered smoke checks**

Expected: gameplay integration tests green and no runtime errors in a complete Level 1 attempt.

- [ ] **Step 8: Commit coherent playable level**

Commit message:
`feat: deliver dark Match-3 playable slice`

---

### Task 5: House Awakening + Durable Save — First Complete Player Journey

**Player outcome:** Launch → play → win → see Curio Boutique awaken → continue → close/relaunch → progress remains exactly once.

**Files:**
- Create: `src/progression/player_progress.gd`
- Create: `src/save/save_store.gd`
- Create: `src/save/save_schema.gd`
- Create: `src/world/house_state.gd`
- Create: `src/world/curio_boutique.tscn`
- Create: `src/world/curio_boutique.gd`
- Create: `src/ui/home/house_home.tscn`
- Create: `src/ui/home/house_home.gd`
- Modify: `src/app/app_bootstrap.gd`
- Test: `tests/unit/save/*`
- Test: `tests/integration/test_first_player_journey.gd`

**Interfaces:**
- Consumes: level terminal result from Task 3/4.
- Produces:
  - versioned local save;
  - chapter milestone transaction;
  - House stage;
  - once-only awakening ceremony flag.

- [ ] **Step 1: RED — atomic/versioned save**

Assert write/read round-trip, backup recovery and schema version metadata.

- [ ] **Step 2: GREEN — save store**

Use temp-write/replace pattern and last-known-good fallback.

- [ ] **Step 3: RED — win transaction is exactly once**

Simulate level win twice / relaunch between durable progress commit and ceremony completion. Assert:
- progress increments once;
- reward/state does not duplicate;
- ceremony may resume without changing durable value.

- [ ] **Step 4: GREEN — progression + ceremony separation**

Commit world progress before decorative awakening.

- [ ] **Step 5: Build Curio Boutique first awakening**

Production-direction environment state:
- dormant;
- first cabinet lit/open;
- persistent next-state on relaunch.

No generic renovation action.

- [ ] **Step 6: End-to-end journey test**

Boot → Level 1 → win → House → relaunch.

Expected:
- same player progress;
- first awakening preserved;
- no duplicate grant;
- valid next-level route.

- [ ] **Step 7: Milestone verification**

Run:
- full headless suite;
- Godot parse;
- representative rendered journey;
- repository secret/provenance scan.

- [ ] **Step 8: Commit first complete player journey**

Commit message:
`feat: complete first Match-3 player journey`

---

## P0/P1 Completion Contract

This plan is complete only when:
- exact Godot baseline is pinned and reproducible;
- donor has an explicit ADMIT/HARVEST/REJECT ruling;
- deterministic headless Match-3 core is green;
- representative dark Level 1 is playable and readable;
- win/fail works;
- Curio Boutique awakening is visible and persistent;
- save/relaunch preserves progress exactly once;
- no secrets/unlicensed donor product assets are committed;
- public repo contains only material acceptable for public disclosure.

Deferred to later coherent outcomes:
- cloud/backend provider;
- real IAP/ad SDK;
- weekly missions/event center;
- Curio collection UI depth;
- levels 2–30;
- final brand/icon;
- full chapter production;
- live-ops and release plumbing.
