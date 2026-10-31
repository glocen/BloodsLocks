---
paths:
  - "src/client/Vfx/**"
  - "src/client/Controllers/Core/CombatFxController.luau"
  - "src/shared/Assets/Vfx/**"
  - "tools/vfx_textures.py"
  - "tools/blender/vfx_sprites.py"
  - "tools/vfx/**"
  - "assets/vfx/**"
---

# VFX rules

- The bar (owner, 2026-10-29): "as good as Duskbloods, nothing less", rendered in our own style (owner, 2026-10-30): stylized like Type Soul, but more detailed and deeper. Type Soul 2 is a quality check only (owner, 2026-10-31): its finish, readability and timing, never its giant effects; the Duskbloods study sets our scale (`docs/reference/type-soul/README.md` and its checklist). Measure every effect against the network-test study (`docs/reference/network-test/vfx.md`). Review every effect from the player's own camera (behind the shooter) before calling it done. Code layout and history: `docs/engineering-plan.md` §11c.
- **NO GORE, EVER: AGENTS.md rule 4, the Roblox Terms of Use, comes before every look** (owner, 2026-10-31, after uploaded blood textures drew a moderation warning on the owner's account).
  - No blood effects at all: no drops, drips, strings, sprays, splatter, stains, smears or pools, and nothing realistic.
  - A hit shows only as the body flashing red with a white outline (`UI/Components/Flash`).
  - Never upload an image that could read as gore.
  - In doubt, ask the owner first.
  - The reference footage's blood is never reproduced.
- **Colour roles:** cold white for the Light Beam and for magic and passage (travel, deaths); gold for objectives and rites; warm orange for fire and gunfire.
- **Blood-themed looks** (owner, 2026-10-31):
  - The Crimson Crescent stays red with some black gradient.
  - Black (ink, shadow) may stand where the reference has blood.
  - Never spill: no drops, drips, splatter or pools.
  - If it could read as gore, even in black, ask the owner first.
- Client code can't see `ServerStorage`: VFX templates live in `ReplicatedStorage.Shared.Assets.Vfx`.
- Beam textures run their vertical image axis along the beam's length: draw beam art tall (the band runs down the image, tileable top to bottom); a horizontal band shows up as a row of beads. A textured Beam draws as a solid band until its texture loads: preload it (`ContentProvider:PreloadAsync`) before enabling it.
- Glow textures with a black background only work additive (`LightEmission = 1`); otherwise they render as black slabs. Additive dark red disappears against the bright red sky: darkness has to come from alpha-textured particles or opaque or glass meshes.
- **Velocity-aligned particles** (`Orientation = VelocityParallel`) lead with the texture's **left** edge (tested 2026-10-31: a streak drawn upright flew sideways). Draw their art moving left: `tools/blender/vfx_sprites.py` draws it moving up, then turns it with `lead_left`.
- Trail textures run the same way (tested 2026-10-30): the vertical image axis along the trail, its top the newest edge; the horizontal axis from Attachment0 (left) to Attachment1 (right).
- Crescents face the camera (perpendicular to travel); flat in the travel plane they vanish edge-on from behind.
- Every effect texture is ours and goes through the tracked pipeline: `tools/vfx/textures.py` (build, review sheet, MCP upload, record, status; `.agents/skills/bl-asset-pipeline`, "Effect textures"). Its ids live in the generated `Client.Vfx.Textures`, which `Kit.Textures` reads; never paste an id by hand or use a Creator Store texture. Draw art white and tint it in the game.
- Capturing fast effects frozen: `/bl-studio-test`, "Captures".
