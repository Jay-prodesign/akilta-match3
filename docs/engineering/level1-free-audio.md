# Level 1 Free Audio Integration

The Level 1 sonic layer uses only provenance-cleared CC0 candidates:

- Curio House ambient: OpenGameArt "Cathedral in the forest (ambient loop)" by congusbongus, CC0.
- Ritual chime: OpenGameArt "Bell dings/chimes" by PWL, CC0/public domain.

The same chime source is transformed at runtime through pitch/gain profiles for match, special, win, fail and retry feedback. This avoids importing a generic commercial sound pack while keeping the implementation completely free.

User settings continue to own Master/Music/SFX bus volume and mute state. Match3AudioDirector owns semantic playback only. Haptics remain a separate fail-open feedback channel.
