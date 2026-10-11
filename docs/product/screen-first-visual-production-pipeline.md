# AKILTA Match-3 — Screen-First Visual Production Pipeline

Status: ACTIVE PRODUCT EXECUTION CONTRACT · 2026-10-11  
Authority: North Star Product Board + current Match-3 product truth.  
Purpose: stop isolated art production and force visual implementation to follow product dependency order.

## 1. Non-negotiable production rule

A generated image is not a screen. An asset is never produced because it looks useful in isolation.

Every visual task must resolve this chain before work starts:

**SCREEN → REGION → BLOCK → SLOT → STATE → ASSET / COMPONENT → IMPLEMENTATION → RENDERED VERIFICATION**

If an asset has no exact Screen/Block/Slot/State owner, it is not ready for production.

The North Star board is the target experience language, not a literal screenshot template. The app must preserve:
- dark romantic gothic atmosphere;
- living House progression;
- black / antique gold / plum material language;
- moon, candle, thorn rose and black-cat motifs;
- readable portrait mobile UI;
- premium coherent presentation;
- code-driven interactive UI, not rasterized phone screenshots.

## 2. Complete screen inventory

### S00 — Splash / Loading
Player job: enter the world and understand tone immediately.
Entry: app boot / relaunch.
Exit: House Hub.
States: loading, ready-to-enter, recoverable load error.
Systems: save load, audio bootstrap, branding.

### S01 — House Hub
Player job: understand persistent House state, next useful action and current resources.
Entry: splash, gameplay completion, back from shell screens.
Exit: Chapters, Curios, Events, Shop, Profile/Settings.
States: dormant, stage01, stage02, stage03/opening-complete, returning-player.
Systems: progression, curios, resources, global navigation, settings.

### S02 — Chapters
Player job: choose a House wing.
Entry: House/Map navigation.
Exit: Chapter Detail, House.
States: first chapter available, later wings locked, current chapter partially restored, chapter complete.
Systems: chapter unlock state, progression.

### S03 — Chapter Detail / Curio Boutique Route
Player job: choose a level/display inside the current chapter.
Entry: Chapters.
Exit: Level Pre-start, Chapters.
States: 0/3, 1/3, 2/3, 3/3 opening progress; level current/available/completed/locked; future displays sealed.
Systems: level unlocks, completion state, chapter art/profile.

### S04 — Level Pre-start
Player job: understand objective, move budget, reward and optional aids; start intentionally.
Entry: Chapter Detail.
Exit: Gameplay, Chapter Detail.
States: first attempt, replay, booster/aids available, unavailable/disabled.
Systems: level content, objective, reward definition, boosters.

### S05 — Match-3 Gameplay
Player job: solve the active puzzle.
Entry: Pre-start.
Exit: Win/Rewards or Fail/Retry, pause, House via explicit exit.
States: playing, teaching/hint, swap, cascade, special-created, special-triggered, blocker-damaged, objective-complete, paused, won, failed.
Systems: deterministic board, objectives, moves, specials, blockers, resources, VFX/audio/haptics.

### S06 — Win / Rewards
Player job: understand success, reward and persistent consequence.
Entry: Gameplay won.
Exit: Restoration ceremony / House.
States: first-time reward, replay completion, reward reveal, continue.
Systems: exactly-once reward transaction, curio unlock, resources, progression.

### S07 — House Restoration
Player job: see what physically changed in the House because of the level win.
Entry: first-time Win/Rewards.
Exit: House Hub.
States: before, awakening transition, after, already-restored/replay bypass.
Systems: House stage, curio placement, motion/audio/haptics, save continuity.

### S08 — Curio Collection
Player job: inspect collected Curios and understand missing ones.
Entry: global nav / House.
Exit: House, optional Curio detail.
States: empty, partial, complete, curio locked, curio awakened, detail.
Systems: progression, curio metadata, chapter origin.

### S09 — Weekly Missions
Player job: understand weekly goals and claim earned rewards.
Entry: House/Event surfaces.
Exit: House / Events.
States: active, in-progress, claimable, claimed, reset/empty, offline-safe.
Systems: mission state, timers, rewards. No fake claim behavior before backend/live contract exists.

### S10 — Event Center
Player job: discover active/coming events and enter eligible content.
Entry: global nav.
Exit: Event detail/gameplay, House.
States: live, coming soon, locked, completed, empty/no-live-event.
Systems: event schedule, eligibility, rewards.

### S11 — Shop
Player job: understand purchasable/earnable offers without deceptive controls.
Entry: global nav.
Exit: House.
States: catalog loading, available offer, unavailable/disabled, purchase-in-progress, success, failure, restore where applicable.
Systems: economy/IAP only after commercial gate. Internal review must clearly disable real purchasing.

### S12 — Profile / Settings
Player job: inspect player identity/progress and control experience settings.
Entry: header/profile affordance.
Exit: previous screen / House.
States: profile summary, settings modal, audio on/off, haptics, reduced motion, high contrast, support/privacy later.
Systems: player progress, preferences, accessibility.

## 3. Overlay / modal inventory

- O01 Pause: resume, retry, settings, exit.
- O02 Settings: audio/music/SFX/haptics/reduced-motion/high-contrast.
- O03 Win/Reward reveal: sits above gameplay but is a distinct product state.
- O04 Fail/Retry: retry primary; no shaming copy.
- O05 Curio detail: art, name, origin, state, lore.
- O06 Locked explanation: tells player why a chapter/level/feature is unavailable.
- O07 Confirmation only where destructive/high-impact action exists.

No modal may invent its own visual system.

## 4. Navigation contract

Primary bottom navigation is globally consistent where appropriate:
**House / Curios / Map / Events / Shop**.

Profile/Settings belongs to the top/header utility area, not as a sixth primary tab.

Gameplay may visually minimize global chrome, but must preserve safe pause/exit/recovery. It must not duplicate unrelated navigation components over the board.

Back behavior:
- Chapters → House.
- Chapter Detail → Chapters.
- Pre-start → Chapter Detail.
- Collection / Events / Shop → House or previous shell state.
- Settings closes to origin screen.
- Gameplay exit requires an explicit player action and returns safely to House/current progression.

## 5. Dependency order

Production order is now:

1. complete screen inventory;
2. screen contracts;
3. global UI shell + design system;
4. asset layer plan;
5. asset production manifest;
6. reference vertical slice;
7. only then downstream screen expansion.

Reference vertical slice:
**House Hub → Level Pre-start → Gameplay → Win/Rewards → House Restoration → House Hub**.

No downstream screen is allowed to become the source of a new visual system before this slice establishes the reusable grammar.

## 6. Vertical-slice acceptance

The reference slice is not accepted until all are true:
- House feels like the emotional anchor, not a menu with a wallpaper;
- top resources and bottom navigation are structurally consistent;
- Pre-start communicates objective/reward with the same panel/button grammar;
- Gameplay pieces are standalone readable illustrated objects, not circular medallions or candy tokens;
- board chrome supports, rather than competes with, pieces;
- result communicates reward and persistent consequence;
- restoration visibly changes the same House camera/state;
- animations explain state changes;
- no obvious placeholder/prototype cards, Unicode icon substitutes or temporary backgrounds remain in the slice;
- all interactive text/buttons/counters are live UI components;
- screenshots are produced from the actual Godot app and compared back to the North Star.

## 7. Next-work selection rule

Always select:

**highest-priority incomplete screen contract → required blocks → missing assets → implementation → rendered verification**

Never select “an asset to make” in isolation.
