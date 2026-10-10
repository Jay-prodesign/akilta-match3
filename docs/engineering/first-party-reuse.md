# AKILTA First-Party Technical Reuse

Founder-authorized internal reuse for Match-3.

## Pinned sources

### Beach Cocktails Merge
- Repository: `Sekiph82/Beach-Cocktails-Merge`
- Evaluated head: `dd21439ac0b1fe982dba38705751b3bcdb3fc1e6`
- Reused/adapted ideas: campaign shell sequencing, separate user settings, map/prestart/result navigation contracts, progression test philosophy.
- Not imported: Beach Cocktails art, levels, economy tuning, product identity, merge gameplay, unrelated governance.

### Scrubbots
- Repository: `Sekiph82/Scrubbots`
- Evaluated head: `c2b1c3c7ae0a301cd43d95dd003f0ddf1373eed0`
- Reused/adapted ideas: single navigation authority, legal route edges, settings overlay state and deterministic back behavior.
- Planned later if still fitting: hardened save validation/backup pattern, provider-neutral rewarded-ad provider and exactly-once reward grant.
- Not imported: Scrubbots gameplay, content, art, economy tuning, unrelated governance.

## Current Match-3-owned routes

`BOOT → HOUSE → MAP → PRESTART → GAMEPLAY → HOUSE`

Level 2+ product routes are sealed until D-027 completed-Level-1 Founder approval.


## Implemented hardening

- Match-3 SaveStore now uses the Scrubbots-style validated temp → last-known-good backup → replace lifecycle, adapted to the Match-3 progression schema.
- Corrupt primaries no longer poison a valid backup.
- Future-schema saves are preserved and activate write protection.
- Beach Cocktails presentation settings now reach Match-3 gameplay; Reduced Motion bypasses resolution animation while preserving deterministic state, and High Contrast strengthens board boundaries.
- Rewarded ads remain deliberately deferred because they are not required for completed Level 1 / D-027.
