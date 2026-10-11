# AKILTA Match-3 — Complete Screen / State Architecture

Status: **CANONICAL PRODUCT ARCHITECTURE · 2026-10-11**

North Star is the source for the **whole product architecture**, not an asset prompt board. The canonical machine-readable contract is `assets/manifests/screen_contracts.json`.

## Product loop

**Enter House → choose/continue a ritual → understand objective/reward → solve Match-3 → receive truthful reward → see the House physically change → return to House with persistent progress → choose the next useful action.**

The first acceptance path is intentionally smaller than the whole product:

**S01 House Hub → S03 Curio Boutique Route → S04 Level Pre-start → S05 Gameplay → S06 Win/Rewards → S07 House Restoration → S01 House Hub.**

This is the **Golden Playable Loop**. Cold start adds S00 before S01; Golden acceptance also verifies S01 → S08 → S01 after restoration. S02 Chapters remains the wing-switcher surface. Missions, Events, Shop and Profile stay architecture-complete but may not trigger art production or create a competing visual system before the Golden Loop is accepted.

## Architectural hierarchy

Every surface follows:

**Screen → Region → Block → Slot → State → implementation owner**

A slot declares whether it is:
- live UI/component;
- runtime data/state;
- runtime VFX;
- authored background/content/gameplay art.

Only the last category authorizes asset production, and only after its screen/block/slot contract exists.

## Canonical screen map

| ID | Surface | Priority | Product role |
|---|---|---:|---|
| S00 | Splash / Loading | P0 | first impression / boot |
| S01 | House Hub | P0 | persistent emotional + progression anchor |
| S02 | Chapters | P1 | choose House wing |
| S03 | Chapter Detail / Route | P0 | choose level/display |
| S04 | Level Pre-start | P0 | objective/reward/start decision |
| S05 | Match-3 Gameplay | P0 | core puzzle |
| S06 | Win / Rewards | P0 | reward + consequence |
| S07 | House Restoration | P0 | persistent same-camera change |
| S08 | Curio Collection | P0 | collection/progression inspection |
| S09 | Weekly Missions | P2 | recurring goals |
| S10 | Event Center | P2 | live/coming content |
| S11 | Shop | P2 | truthful economy surface |
| S12 | Profile / Settings | P2 | player progress + preferences |

Overlays O01–O07 cover Pause, Settings, Reward Reveal, Fail/Retry, Curio Detail, Locked Explanation and destructive/high-impact Confirmation.

## Production gate

`bulk_art_authorized = false` until the Golden Loop satisfies all acceptance conditions. Existing SVG/world candidates are reference/prototype material only and cannot define the product architecture.

The next task is selected from **the highest-priority incomplete screen contract**, never from an asset wish-list.

## Single source of truth

`assets/manifests/screen_contracts.json` is the only canonical Screen → Region → Block → Slot → State architecture. The former `content/product/screen_state_architecture.json` is a compatibility pointer only. Asset production can be authorized only by the canonical contract and remains restricted to Golden Loop gaps until acceptance.
