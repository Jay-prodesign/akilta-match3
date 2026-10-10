# AKILTA Match-3 — Asset Production Bible

Status: ACTIVE IMPLEMENTATION CONTRACT · 2026-10-10  
Scope: Level 1 production completion first; designed to scale to the whole product after D-027.

## 1. Visual Product Lock

The product direction is locked even though final pixels are not.

**Locked visual identity**
- Dark Cute + Witchy Gothic + Cozy Macabre + Dark Feminine.
- Dark plum/charcoal foundation with bone, antique-gold and moon-lilac light.
- Persistent living House; Curio Boutique is the opening chapter/room.
- Gameplay pieces feel like collectible reliquary/sigil objects, never candy, plastic toys or generic gems.
- World-translated grammar: category functions are translated into House-native objects/seals/reliquaries while preserving instant comprehension.
- Cormorant Garamond for ceremonial/display roles; Manrope for functional UI.
- House progression must be physically visible: Level 1 → Moon Cameo → first cabinet awakening.

**Not yet locked**
- final brand/logo;
- exact final color values and final tuning;
- exact final silhouettes/pixels of Founder-unapproved candidate art;
- final whole-product layouts for downstream Shop/Events/Profile;
- final mastery/rating token;
- final launch icon/store creative.

This is intentional: Level 1 is the production slice that locks the reusable visual grammar. D-027 Founder approval is required before Level 2+ art/content scales.

## 2. Canonical Design Viewport

- Portrait baseline: **1080 × 1920 logical px**.
- Development verification viewport: 540 × 960 (0.5 scale).
- Layout must remain responsive; no critical interaction is positioned by screenshot coordinates.
- Keep primary touch targets >= 88 × 88 logical px where practical; utility controls may be smaller visually but retain adequate interactive area.
- Final raster UI/world outputs should normally be authored at 2× intended display size and shipped no larger than necessary.
- No shipped raster dimension above 2048 px unless a measured device/performance case justifies it.

## 3. Folder Contract

All new production assets use these roots:

```
assets/
  pieces/                       # base match families; current canonical location
  specials/                     # line_h, line_v, area, smart, global
  blockers/                     # Wax Seal and later blocker families
  board/                        # board/cell/frame material assets
  curios/                       # persistent collectible Curios
  world/
    ch01_curio_boutique/        # room/environment progression
  ui/
    chrome/                     # 9-slice panels, dividers, restrained ornament
    icons/                      # universal utility icons
    map/                        # chapter-map node/path decorative assets
  vfx/                          # texture primitives used by particle/runtime VFX
  audio/
    music/
    sfx/
  fonts/
  manifests/
  candidate/
    third_party/                # never shipping by implication
  licenses/
```

Do not place final product art under `candidate/third_party`. Candidate third-party material can only graduate through the manifest after provenance + originality review.

## 4. Naming Contract

Filename pattern:

`{scope}_{class}_{semantic_id}_{state}_{variant}_vNN.ext`

Rules:
- lowercase snake_case;
- semantic, not visual-adjective-only names;
- no `final`, `final2`, `new`, `copy`;
- version increments only for meaningful art revisions;
- state is omitted only when the asset has exactly one state.

Examples:
- `gbl_piece_moon_sigil_base_v02.svg`
- `gbl_special_line_h_idle_v01.svg`
- `ch01_blocker_wax_seal_cracked_v01.svg`
- `ch01_curio_moon_cameo_awakened_v01.svg`
- `ch01_world_curio_boutique_stage01_bg_v01.webp`
- `gbl_ui_ritual_panel_9s_base_v01.svg`

Existing first-party piece filenames are grandfathered as current candidate v2 until D-027; renaming them before the visual ruling would create churn without product value.

## 5. Asset Status Contract

Only these statuses exist:

`concept → reference → candidate → approved → shipping → retired`

- **concept**: idea only.
- **reference**: external/internal visual reference; never a runtime dependency.
- **candidate**: may be rendered/playtested; not Founder-approved.
- **approved**: accepted visual language for production.
- **shipping**: approved + optimized/import-tested/provenance-complete.
- **retired**: no longer used.

Technical success, CI PASS, provenance approval, or inclusion in a concept board **does not** promote candidate art to approved. Level 1 core visual assets require Founder acceptance through D-027.

## 6. Level 1 Asset Matrix / Dimensions

### Base match pieces — 5 required
Moon Sigil, Thorn Rose, Luna Moth, Curio Key, Night Ivy.

- source: SVG preferred;
- canonical source artboard: **256 × 256**;
- live silhouette target: approx **180–210 px** inside artboard;
- transparency: yes;
- runtime display: typically **~90–135 px** on the 7×7 portrait board;
- legibility QA: must still identify at **64 px thumbnail** and in grayscale/high-contrast comparison;
- identity: color + silhouette + internal motif + value/material;
- materials:
  - Moon Sigil → smoked moonstone;
  - Thorn Rose → carved wine enamel;
  - Luna Moth → spectral glass;
  - Curio Key → antique metal;
  - Night Ivy → lacquered leaf.

### Specials
Required functional classes:
- line_h;
- line_v;
- area;
- smart;
- global.

Production rule:
- **256 × 256 SVG overlay or self-contained special token**;
- orientation must be readable while static;
- line H/V must not depend on animation to communicate axis;
- global receives strongest premium treatment;
- no rocket/bomb/disco-ball literal art;
- combo-ready resonance is runtime motion/VFX, not a separate duplicate asset unless profiling proves necessary.

### Wax Seal blocker
Level 1/first blocker language:
- artboard **256 × 256**;
- states: `intact`, `cracked`, `shattered/cleared transition`;
- hp states must be distinguishable in peripheral vision and grayscale;
- keep the covered underlying piece readable enough to explain interaction;
- clear-state residue is VFX/runtime, not a fourth static blocker tile unless needed.

### Board
Board remains geometry-first for readability.
- board frame/chrome: vector or **512 × 512 9-slice**, 64 px protected corner inset;
- cell material: runtime vector/StyleBox preferred; if textured, **256 × 256 tile**;
- no ornate texture beneath active pieces;
- active-grid geometry must read before chapter decoration;
- chapter art lives around the board, not through it.

### Moon Cameo Curio
The Level 1 reward must be the same semantic object in result, House and Collection.
- master: SVG or **512 × 512** transparent;
- states: sealed/dormant, awakening, awakened;
- small display: >= 96 px;
- hero/reward/collection display: 220–420 px;
- material grammar inherits Moon Sigil smoked moonstone + antique reliquary metal.

### Curio Boutique environment
Same camera/layout across awakening stages to make persistence obvious.
- canonical portrait environment viewport: **1080 × 1200** max displayed region inside the 1080×1920 app;
- raster source master if used: **2160 × 2400**;
- ship background at max **1080 × 1200** unless device profiling justifies higher;
- alpha foreground layers: PNG/WebP as appropriate;
- stages required for Level 1: stage00 dormant, stage01 first-cabinet-awakened;
- later stages 02–05 are planned but cannot become canonical before D-027.
- layer plan: background wall/window, cabinet architecture, foreground props, Curio/reliquary, light/VFX overlays.

### Chapter map
- route/path is runtime vector/procedural so it scales/scrolls cleanly;
- node icon source if externalized: **256 × 256 SVG**;
- three states minimum: available/current, sealed/locked, complete/awakened;
- Level 1 route shows 10 visible future displays but only Level 1 is selectable before D-027;
- no candy-map dots or generic gold stars.

### Prestart / Result / Collection / Settings / Pause
- primary panels: vector/9-slice, **512 × 512 master**, 64 px protected corners;
- utility icons: **128 × 128 SVG** artboard; test at 32–48 px visual size;
- ceremonial reward/reliquary assets: 512 × 512;
- result win/fail share the same structure; state differs through world semantics, not unrelated layouts.

## 7. Motion / Animation Production Contract

Most gameplay animation is **runtime transform + VFX**, not frame-by-frame sprite sheets. Do not generate animation frames unless the effect genuinely requires hand-authored deformation.

Required Level 1 motion roles:
- swap accepted: 180–240 ms;
- rejected swap: 240–320 ms with readable return;
- match/clear: 220–320 ms;
- gravity/refill: 320–460 ms depending travel distance;
- special creation: 260–380 ms;
- special activation: 320–520 ms;
- blocker hit/crack: 220–320 ms;
- combo emphasis: 400–650 ms;
- objective completion/reward reveal: 550–900 ms;
- House Moon Cameo awakening: 900–1500 ms, allowed to be richer because action has ended.

Current trace-driven profile is the implementation baseline; timings may be tuned through playtest without changing gameplay truth.

Reduced Motion:
- no repeated pulsing;
- no long travel/zoom;
- preserve semantic state change using <=150 ms fades/state replacement where possible;
- gameplay remains immediately actionable.

If a sprite sequence is needed:
- source sheet cell: 256 or 512 square;
- 12–24 fps authored cadence;
- trim transparent bounds consistently;
- pivot fixed across frames;
- manifest must include frame count, fps and loop/one-shot role.

## 8. VFX Contract

- base match: local family color + silver/bone micro-spark;
- cascade: restrained moonlight rise;
- special: family accent + bone-white focal core;
- combo: two accents allowed, bright center retained;
- objective complete: antique gold / moon silver;
- world awaken: moon lilac + warm candle gold;
- fail: muted desaturation, no red-screen punishment;
- win: bone/gold/moon light, no rainbow confetti.

Texture primitives: prefer 256 × 256 grayscale/alpha masks that can be tinted at runtime. Use 512 only for soft gradients requiring it. Avoid large pre-baked full-screen VFX textures.

## 9. Typography

- Cormorant Garamond variable: ceremonial headers, room names, Curio names, major reveals.
- Manrope variable: objective, counters, buttons, settings, body/supporting copy.
- Both are OFL and already vendored with license/provenance.
- Do not use ornate display type for small functional text.
- Minimum functional body target: 18–20 logical px at 1080 baseline unless visual QA proves a larger need.

## 10. Audio / Haptics

Level 1 currently uses free CC0 candidates only:
- ambient music/atmosphere: Music bus;
- ritual chime semantic variants: SFX bus;
- match/special/win/fail/retry each have distinct pitch/gain profile;
- haptic vocabulary remains separate and can be disabled.

Audio candidate status does not imply final sonic approval.

## 11. Approval / Selection Rule

An asset may enter runtime only if:
1. it exists in `assets/manifests/level1_asset_manifest.json`;
2. semantic role and required states are known;
3. target size/format is defined;
4. provenance is first-party or commercially clean/free under D-029;
5. it passes readability/originality/performance review;
6. its status permits runtime use.

Selection order:
**locked product function → North Star/world translation → readability → originality → state completeness → technical fit/performance → provenance → visual preference.**

Do not select an asset because it is attractive in isolation.

## 12. Whole-Product Visual Destination

The finished app should read as one coherent **living gothic curiosity House**, not a dark skin over a generic match-3:
- House/Home is the emotional anchor;
- chapter map is architectural/ritual, not candy dots;
- board is a readable dark ritual display;
- pieces are ownable collectible reliquary tokens;
- rewards are persistent world objects, not generic prize cards;
- Curios physically alter the House;
- UI is restrained, bone/gold/lilac, with ceremonial typography only at focal moments;
- utilities stay recognizable;
- events/shop/profile later inherit the same materials/tokens rather than becoming a separate app.

This destination is directionally locked. Exact downstream pixels remain intentionally unlocked until the finished Level 1 is Founder-approved.

## 13. Current Level 1 Production Priority

1. five core piece candidate refinement;
2. specials + Wax Seal state art;
3. board/cell/frame material;
4. Moon Cameo sealed/awakening/awakened consistency;
5. Curio Boutique stage00/stage01 environment polish;
6. map node/path/chrome polish;
7. prestart/win/fail/collection/pause/settings surface polish;
8. motion/VFX tuning;
9. audio/haptic holistic pass;
10. accessibility/readability + performance pass;
11. D-027 finished-Level-1 evidence package.

No Level 2+ art production before #11 is explicitly approved by Founder.
