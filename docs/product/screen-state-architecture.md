# AKILTA Match-3 — Complete Screen / State Architecture

Status: **CANONICAL · 2026-10-11**

This document is the human-readable map. Slot-level truth is in `assets/manifests/screen_contracts.json`.

## Screen map

| ID | Screen | Product job | Primary states |
|---|---|---|---|
| S00 | Splash / Loading | Load durable state and enter the world | loading, ready, recoverable error |
| S01 | House Hub | See persistent House + next action | dormant, stage01–03, returning |
| S02 | Chapters | Choose House wing | first wing open, partial, complete, locked |
| S03 | Chapter Detail / Route | Choose level in wing | 0/3–3/3, current, available, completed, locked |
| S04 | Level Pre-start | Understand goal/reward and start | first attempt, replay, aids enabled/disabled |
| S05 | Match-3 Gameplay | Solve puzzle | play, teaching, cascades, specials, pause, win, fail |
| S06 | Win / Rewards | Understand earned result | first-time reveal/ready, replay reveal/ready |
| S07 | House Restoration | See persistent physical consequence | before, awakening, after, bypass |
| S08 | Curio Collection | Inspect owned/missing Curios | empty, partial, complete, locked, awakened |
| S09 | Weekly Missions | Progress/claim weekly goals | active, progress, claimable, claimed, empty/offline |
| S10 | Event Center | Discover eligible live/coming content | live, coming, locked, complete, empty |
| S11 | Shop | Truthful economy/commerce surface | review-disabled, loading, available, unavailable, purchase states |
| S12 | Profile / Settings | Inspect progress and preferences | profile, settings open/changed |

## Overlay map

- **O01 Pause** — S05 only.
- **O02 Settings** — House, Gameplay or Profile origin.
- **O03 Fail / Retry** — terminal failed puzzle state.
- **O04 Curio Detail** — collection detail.
- **O05 Locked Explanation** — chapter/level/curio/event lock reason.
- **O06 Confirmation** — only destructive/high-impact actions.
- **O07 Recovery** — recoverable load/session/commerce error.

## Navigation graph

Cold start: **S00 → S01**.

Golden path: **S01 → S03 → S04 → S05 → S06 → S07 → S01**.

Meta:
- S01 ↔ S08
- S01 → S02 → S03
- S01 ↔ S10
- S01 ↔ S11
- utility header → S12 / O02
- S10 ↔ S09 when weekly missions are live

Back:
- S02 → S01
- S03 → S02 or S01 when entered as current-chapter shortcut
- S04 → S03
- S08/S10/S11 → S01
- settings/detail overlays close to origin
- S05 exits only through explicit pause/exit recovery

## Progression state sequence for opening chapter

Level 1 first-time win:
House stage00 → reward transaction → Moon Cameo owned → restoration stage01 → House stage01.

Level 2:
stage01 → Moth Reliquary → stage02.

Level 3:
stage02 → Thorned Locket → stage03 / opening cabinet set complete.

Replay never duplicates Curio ownership, House stage reward, currencies or processed transactions.

## Architecture mismatch policy

If code currently shows a feature as an ad-hoc overlay, uses a temporary SVG world backdrop, or bypasses a canonical route, that is an implementation debt against this architecture—not a reason to modify the architecture around the prototype.
