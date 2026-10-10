# Level 1 Ritual-Thread Teaching Cue

Level 1 teaching now consumes the authored `teaching_moves` data directly.

For `ch01_level_001`, the board renders a subtle ritual thread from the Moon global-special cell at (1,4) to the authored destination at (2,4). The cue uses nested seals and progressively larger gold thread-dots rather than a generic tutorial hand or arrow.

Behavior:
- visible only while the authored first move still needs teaching;
- disappears immediately after the first accepted swap;
- returns on retry because the level is reloaded from authored data;
- pulses gently in normal motion mode;
- becomes a stable static cue under Reduced Motion;
- increases contrast under High Contrast.

This is original Match-3 presentation code and introduces no paid or external visual dependency.
