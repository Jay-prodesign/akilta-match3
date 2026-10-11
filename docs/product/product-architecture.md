# AKILTA Match-3 — Product Architecture

Status: **CANONICAL PRODUCT SOURCE · ACTIVE · 2026-10-11**

## Authority

The North Star Product Board is now the source for the **whole product architecture**, not merely an art-direction reference.

It defines the relationship between the living House, match-3 play, rewards, restoration, Curio collection, chapters, missions/events, shop and profile/settings. Visual production is downstream of this architecture.

The mandatory derivation order is:

**PRODUCT LOOP → SCREEN/STATE ARCHITECTURE → SCREEN → REGION → BLOCK → SLOT → STATE → COMPONENT/ASSET → IMPLEMENTATION → RENDERED VERIFICATION**

No asset may become the reason a screen exists.

## Core product loop

**ENTER / RESUME → HOUSE STATUS → CHOOSE NEXT RITUAL → PRE-START → MATCH-3 → RESULT → PERSIST REWARD → RESTORE HOUSE → COLLECT / REFLECT → UNLOCK NEXT → HOUSE**

The House is the emotional and progression anchor. Match-3 is the repeatable action system. Curios are persistent collectible proof of progress. Restoration makes success physically visible. Chapters organize long-form progression. Missions/events are retention systems. Shop is an economy surface and remains truthful/disabled until commerce exists.

## Product domains

1. **Living House** — persistent environment state, restoration stages, Curio placement, next action.
2. **Puzzle Session** — deterministic board, moves, objectives, blockers, specials, fail/retry.
3. **Progression** — level unlocks, chapter progress, House stages, exactly-once rewards.
4. **Curios** — ownership, collection, detail, locked/awakened state.
5. **Meta Navigation** — House, Curios, Map/Chapters, Events, Shop; Profile/Settings in utility header.
6. **Retention** — weekly missions and events, only with truthful live state.
7. **Economy** — soft/premium resources and later commerce; no simulated payment.
8. **Preferences** — audio, haptics, reduced motion, high contrast.

## Information architecture

Primary meta destinations are exactly:
**House / Curios / Map / Events / Shop**.

Profile/Settings is utility-level, not a sixth bottom tab.

Map has two levels:
- **S02 Chapters** chooses a House wing.
- **S03 Chapter Detail / Route** chooses a level inside the active wing.

For the opening Golden Loop the House primary next-action enters the current Curio Boutique route at S03. S02 remains the canonical wing switcher reached from Map navigation. House never bypasses S03 to open S04 directly.

## State ownership

Durable truth belongs to progression/save systems, not screen art:
- completed levels;
- highest unlocked level;
- owned Curios;
- House restoration stage;
- processed reward transactions;
- currencies/resources;
- user preferences.

A screen renders this truth. It does not create alternate progress by visual state alone.

## Golden Playable Loop

Canonical P0 loop:

**S01 House → S03 Curio Boutique Route → S04 Pre-start → S05 Gameplay → S06 Win/Rewards → S07 House Restoration → S01 House**

Cold boot adds **S00 Splash** before S01.

Replay skips restoration when nothing new is earned:
**S01 → S03 → S04 → S05 → S06(replay) → S01**.

Failure stays inside the puzzle session:
**S05 → O03 Fail/Retry → S05**, with safe exit available.

Post-restoration verification is part of Golden acceptance:
**S01 House → S08 Curio Collection → S01 House**. The exact Curio earned in S06 and placed in S07 must appear in S08 and survive relaunch.

## Production gate

Until the Golden Playable Loop is accepted:
- no random downstream screen polish;
- no bulk background production;
- no event/shop/mission art production;
- no isolated icon/decorative asset campaigns;
- no new art whose Screen→Block→Slot→State owner is absent.

Existing candidate art may remain in the repository as implementation scaffolding. It must not drive architecture or be treated as final approval.

Canonical machine-readable contract — the single Screen/State/Block/Slot source of truth:
`assets/manifests/screen_contracts.json`.

`content/product/screen_state_architecture.json` is retained only as a deprecated compatibility pointer and must never become a second architecture authority.
