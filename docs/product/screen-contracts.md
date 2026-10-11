# AKILTA Match-3 — Screen Contracts

Status: ACTIVE · 2026-10-11  
Canonical portrait baseline: 1080 × 1920 logical. Development render: 540 × 960.

Each screen is specified as **Screen → Regions → Blocks → Block contents**.

---

## S00 Splash / Loading

### Regions
1. Full-screen background
2. Brand focal area
3. Loading/entry area
4. Safe footer

### Blocks
- Background: castle/House exterior, moon, black cat, roses/candles; no embedded UI text.
- Brand focal: working product mark, chapter/world motif.
- Loading: progress indicator or Enter CTA depending state.
- Footer: version/support text only if needed.

### States
loading / ready / recoverable-error.

### Navigation
ready → House Hub. No bottom nav.

---

## S01 House Hub

### Regions
1. Global header
2. House hero/world region
3. Progress/next-action region
4. Primary CTA
5. Bottom navigation

### Blocks
- Header resources: lives, coins, gems; profile/settings utility.
- House hero: persistent same camera; stage00/01/02/03 environment; black cat as world character, not UI sticker.
- Progress: current chapter, Curio count, chapter restoration progress.
- CTA: next meaningful action, usually continue/open map.
- Bottom nav: House active; Curios, Map, Events, Shop.

### States
dormant / stage01 / stage02 / stage03 complete / returning-player.

### Systems
save/progression, resources, Curio ownership, global navigation.

---

## S02 Chapters

### Regions
1. Global header
2. Title/context
3. House/chapter world
4. Chapter hotspot/card layer
5. Bottom navigation

### Blocks
- World background: full House / estate illustration with chapter regions.
- Chapter hotspots: Curio Boutique, Witch Atelier, Dark Vanity, Archive, Moon Conservatory, Cemetery Garden.
- Chapter status: open/current/locked/complete.
- Locked treatment: lock icon + concise reason; no fake interactivity.

### States
Curio Boutique open; other wings sealed until product roadmap unlocks them.

---

## S03 Chapter Detail / Curio Boutique Route

### Regions
1. Global header
2. Chapter title/progress
3. Route/world region
4. Level nodes
5. Bottom navigation

### Blocks
- Chapter background: Curio Boutique environment/architectural cabinet route.
- Route: runtime scalable path.
- Nodes: level number, state, reward/Curio association when useful.
- States: current, available, completed, locked, future-sealed.
- Progress copy: 0/3 → 3/3 for opening slice.

### Navigation
level node → Pre-start; back → Chapters.

---

## S04 Level Pre-start

### Regions
1. Context header
2. Primary ritual panel
3. Objective block
4. Reward block
5. Aid/booster row
6. CTA
7. Back affordance

### Blocks
- Level identity: number + level title.
- Hero/content art: chapter-specific arrangement/reward art.
- Objective: target icon(s), quantities, move limit.
- Reward: Curio image/name + House consequence.
- Aids: only truthful available aids.
- CTA: Play.
- Back: Chapter Detail.

### States
first-attempt / replay / aid available / aid disabled.

---

## S05 Match-3 Gameplay

### Regions
1. Compact gameplay header/HUD
2. Objective row
3. Board
4. Booster/action row
5. Optional minimal footer / no competing shell chrome
6. Overlays

### Blocks
- Header: level, moves, resources only if actually needed during play, pause.
- Objective: target icons + remaining counts.
- Board: dark stable cell field, restrained frame, standalone illustrated pieces.
- Base pieces: no circular outer medallions/halos as base art.
- Boosters: functional icon + count/state; no fake currencies.
- Overlays: pause, hint teaching, win, fail.

### States
playing / hint / swap / cascade / blocker / special / paused / win / fail.

### Visual rule
The board must resemble the North Star’s readable dark object-grid language: the *piece itself* carries the identity. Cell chrome must not wrap every object in a decorative ring.

---

## S06 Win / Rewards

### Regions
1. Dimmed gameplay context
2. Result panel
3. Reward hero
4. Reward values
5. Persistent consequence copy
6. Continue CTA

### Blocks
- Result title: Level Complete.
- Reward: Curio art/name and any earned currencies actually granted.
- House consequence: what changed physically.
- CTA: Continue to restoration/House.

### States
first-time reward / replay.

---

## S07 House Restoration

### Regions
1. Same House camera/world
2. Before/after focus
3. Awakening VFX
4. Change summary
5. Continue CTA

### Blocks
- House environment uses the same persistent stage system as S01.
- New Curio appears in an authored slot.
- Lighting/prop state changes are layered, not a separate unrelated background.
- Ceremony may use richer motion; progress is already durable before animation begins.

### States
before / transition / after / already-restored.

---

## S08 Curio Collection

### Regions
1. Global header
2. Collection title/count
3. Filter/tabs only if needed
4. Curio grid/display
5. Detail overlay
6. Bottom nav

### Blocks
- Curio card: art, name, state, origin.
- Locked: silhouette/sealed treatment.
- Awakened: full art + restrained glow.
- Detail: hero art, origin, lore, chapter.

---

## S09 Weekly Missions

### Regions
1. Global header
2. Weekly title/timer
3. Mission list
4. Progress/reward blocks
5. Claim CTA where valid
6. Bottom nav

### States
active / progress / claimable / claimed / empty / offline.

---

## S10 Event Center

### Regions
1. Global header
2. Event hero
3. Event cards
4. Timer/reward metadata
5. CTA
6. Bottom nav

### States
live / coming / locked / complete / empty.

---

## S11 Shop

### Regions
1. Global header
2. Featured offer
3. Offer grid
4. Currency section
5. Purchase status overlay
6. Bottom nav

### States
loading / available / disabled / purchasing / success / failure.

### Trust rule
No enabled purchase CTA until real platform commerce is connected and authorized. Internal review must say disabled rather than simulate payment.

---

## S12 Profile / Settings

### Regions
1. Global header
2. Profile summary
3. Progress summary
4. Settings entry
5. Settings modal
6. Support/privacy destinations when real

### Settings blocks
master, music, SFX, haptics, reduced motion, high contrast, language later.

### States
profile / settings-open / each toggle state.

---

# Shared state vocabulary

All reusable blocks must define where applicable:
normal / hover-focus / pressed / selected / disabled / locked / loading / error / complete / claimable.

A block is not “finished” until its required state set is explicit.
