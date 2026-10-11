# AKILTA Match-3 — Golden Playable Loop Contract

Status: **P0 IMPLEMENTATION GATE · NOT YET ACCEPTED**

## Journey

1. **S01 House Hub** loads durable stage/resources and presents one truthful next action.
2. **S03 Chapter Detail / Curio Boutique Route** shows the current unlocked level and sealed future nodes.
3. **S04 Level Pre-start** shows objective, moves, reward Curio, House consequence and truthful aids.
4. **S05 Gameplay** runs a deterministic playable puzzle with pause/retry/recovery.
5. **S06 Win / Rewards** reveals what was earned. Replay state must be visibly different from first-time reward.
6. Reward transaction is persisted **exactly once** before irreversible progression is represented.
7. **S07 House Restoration** uses the same House camera and changes the authored Curio/restoration slot.
8. **S01 House Hub** returns with updated House stage, Curio count, level frontier and resources.

## Required failure/replay branches

Failure: S05 → O03 → retry S05 or explicit safe exit.

Replay: S01 → S03 → S04 → S05 → S06(replay) → S01, with no duplicate reward/restoration.

Cold start: S00 → S01 → golden loop.

## Acceptance

The loop is accepted only when all of these are true:

- every route/state follows `screen_contracts.json`;
- Level 1 can be completed end-to-end without a dead end;
- fail → retry works without corrupting board/progress;
- reward application is durable and exactly once;
- restoration visibly changes the same House world state;
- returning to House exposes the newly unlocked frontier;
- owned Curio appears consistently in House and collection truth;
- no fake payment/claim/action is enabled;
- no P0 screen depends on an unrelated procedural illustration or generic fallback;
- interactive text/counters/buttons remain live components;
- rendered Godot screens are verified only after the functional loop passes.

## Explicit non-goals until acceptance

No bulk art. No event/shop/mission polish. No random icon campaign. No second chapter production. No isolated screen beauty pass.
