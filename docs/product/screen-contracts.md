# AKILTA Match-3 — Screen → Block → Slot Contracts

Status: **CANONICAL · 2026-10-11**

The complete machine-readable contract is:
`assets/manifests/screen_contracts.json`.

Every screen follows:

**Screen → Region → Block → Slot → State → Component/Asset**

An asset request without that ownership chain is invalid.

## P0 Golden Loop ownership

- **S01 House** → world → house_hero → full_environment / character_world_layer / restoration_slots / ambient_world_fx.
- **S03 Route** → route → chapter_route → environment / route_path / level_nodes / frontier_focus.
- **S04 Pre-start** → primary → primary_ritual_panel → level_art / objective / move_budget / reward_curio / house_consequence.
- **S05 Gameplay** → board → match_board → board_field / base_pieces / specials / blockers / board_fx.
- **S06 Win** → result → result_panel → result_title / reward_curio / reward_values / house_consequence / continue / reward_fx.
- **S07 Restoration** → world → house_hero → full_environment / restored_curio_slot / character_world_layer / awakening_fx.
- **S01 Return** renders the new durable state; it is not a second background invented for the result.

## Global shell ownership

Meta header owns resource values and utility access.
Bottom nav owns House / Curios / Map / Events / Shop.
Gameplay owns its compact HUD and pause only.
Panels/buttons are reusable structural UI; environment art never contains live text or counters.

## Downstream screens

S00–S12 and O01–O07 are fully enumerated in the JSON contract. Their state and slot ownership exists now, but downstream art production remains gated until the Golden Playable Loop is accepted.
