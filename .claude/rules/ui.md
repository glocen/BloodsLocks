---
paths:
  - "src/client/UI/**"
  - "src/client/Controllers/**"
  - "src/first/**"
  - "tools/ui_textures.py"
---

# UI rules

- Every colour, font, size, stroke, spacing and motion value comes from `UI/Theme` (it re-exports `ReplicatedFirst.BL_First.ThemeBase`: palette, fonts, images, fit formulas), so a restyle stays a one-file change. Screens are built from the UI kit (`UI/Core`, `UI/Kit`); controllers don't hand-build widgets. `BL_First` also holds the Passage, our loading and teleport screen (with named holds).
- Every screen passes `docs/ui-quality-standard.md`; read its gates (section 6) when building one.
- Any screen that takes the input pushes onto `UI.Core.Focus` and releases it on close. Never set `MouseBehavior` or toggle `BLGameplay` or the HUD directly. Match screens (`src/client/UI/Match`) are driven by `Controllers/Match/MatchController`.
- HUD scope (owner): the HUD shows only systems that exist; new reference-style elements arrive with their systems.
- `Text.new` labels start empty, never Roblox's "Label". The self-test's UI lint fails on placeholder text, text overrunning its box by more than 2 px, text under its legible size, and labels off screen.
- Plates and call-outs are drawn in the World layer (projected every frame), not as BillboardGuis, which `screen_capture` doesn't draw.
- `Enum.Font.Garamond`'s family is `rbxasset://fonts/families/Guru.json`; build weights with `Font.new(Font.fromEnum(...).Family, weight)`.
- Tab is also the player-list key, so `InputBegan` reports it as processed: skip keys only while a TextBox is focused.
- Player-visible text follows the IP rules in `AGENTS.md`: no source-game names.
