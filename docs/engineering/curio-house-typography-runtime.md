# Curio House Typography — Runtime Loading

Cormorant Garamond and Manrope are vendored OFL source TTF files. Clean CI/device boots do not rely on Godot editor import-cache files.

- Match3Typography loads each source TTF with FontFile.load_dynamic_font().
- Manrope becomes the ScreenHost default Theme font at runtime.
- Cormorant is applied to narrative Title/Headline labels through the project typography controller.
- OFL notices and pinned binary hashes remain in assets/licenses and assets/fonts.

This keeps typography free/open, deterministic and clean-checkout safe.
