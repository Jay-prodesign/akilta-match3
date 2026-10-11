# AKILTA Match-3 — Global UI Shell & Design System Contract

Status: LOCKED DIRECTION / IMPLEMENTATION SOURCE · 2026-10-11

## 1. Shell geometry

Canonical portrait: 1080 × 1920.

- Safe horizontal margin: 32–48 logical px depending device safe area.
- Global top resource/header zone: 96–112 logical px.
- Global bottom nav zone: 128–144 logical px.
- Main content must never sit under header/nav without intentional overlap.
- Gameplay may use a compact gameplay HUD instead of full meta header, but uses the same material/tokens.

## 2. Header

Meta screens:
- left/center resource chips: lives, coins, gems;
- right utility: profile/avatar; settings inside Profile or direct utility where appropriate;
- values are live state, never decorative placeholder numbers.

Header is code/UI. Background shell is a reusable scalable material, not baked into environment art.

## 3. Bottom navigation

Exactly five primary destinations:
House / Curios / Map / Events / Shop.

Each item:
- authored functional SVG icon;
- label;
- normal + selected + pressed + disabled states;
- selected state uses stronger antique-gold line/value, not a different layout.

Profile is not a sixth bottom tab.

## 4. Panel family

### Primary ceremonial panel
Use: Pre-start, Win/Rewards, important modal.
Material: near-black/plum glass + antique-gold edge.
Corners: restrained gothic ornament only at focal panel boundaries.
Scalable 9-slice/component.

### Secondary card
Use: Curio cards, mission/event/shop cards.
Material: dark raised surface, lower contrast edge.
No unique decorative frame per screen.

### Utility modal
Use: Settings, Pause, confirmations.
Higher opacity for readability; same radius/material vocabulary.

## 5. Buttons

- Primary: plum/wine fill + antique-gold edge; light bone text.
- Secondary: dark fill + restrained gold/plum edge.
- Destructive: only when real destructive action exists.
- Disabled: reduced luminance/contrast, still readable.
- All button text is live UI text.

## 6. Typography hierarchy

Display/ceremonial:
- screen title;
- chapter/Curio name;
- result reveal.

Functional:
- objective;
- counters;
- button labels;
- settings;
- timers;
- body/supporting copy.

Small functional text must not use ornate display styling.

## 7. Material palette

Semantic roles:
- ink/background: near-black blue/charcoal;
- velvet/plum: primary thematic surface;
- antique gold: focus, selected, premium edge, reward;
- bone/ivory: high-value text;
- moon lilac: magical light/secondary accent;
- rose/wine: danger/thorn/romantic accent;
- cyan/green only for chapter/content identity, never random UI decoration.

Exact values remain tokenized implementation variables after final rendered approval.

## 8. Functional components

Reusable components to own globally:
- TopResourceBar
- ResourceChip
- BottomNavigation
- NavItem
- PrimaryPanel
- SecondaryCard
- PrimaryButton
- SecondaryButton
- ProgressBar
- LockedTreatment
- ModalShell
- SectionHeader
- RewardValue
- TimerRow

No screen may independently rebuild these with unrelated style constants.

## 9. Motion language

- screen transition: restrained fade/slide;
- selected nav: short luminance/edge emphasis;
- button press: scale/value feedback;
- reward: gold/moon light reveal;
- House awaken: richest allowed transition;
- reduced motion: semantic state replacement, minimal travel/pulse.

## 10. Accessibility

- piece recognition: silhouette + motif + value, not color only;
- functional text contrast over dark art must remain readable;
- high-contrast mode may strengthen cell/frame/focus lines without changing piece identity;
- selected/focus state must not rely only on color;
- target sizes must remain touch-safe.
