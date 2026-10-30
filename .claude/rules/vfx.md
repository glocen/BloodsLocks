---
paths:
  - "src/client/Vfx/**"
  - "src/client/Controllers/Core/CombatFxController.luau"
  - "src/shared/Assets/Vfx/**"
  - "tools/vfx_textures.py"
  - "tools/blender/vfx_sprites.py"
  - "assets/vfx/**"
---

# VFX rules

- The bar (owner, 2026-10-29): "as good as Duskbloods, nothing less", rendered in our own style (owner, 2026-10-30): stylized like Type Soul, but more detailed and deeper. Measure every effect against the network-test study (`docs/reference/network-test/vfx.md`). Review every effect from the player's own camera (behind the shooter) before calling it done. Code layout and history: `docs/engineering-plan.md` §11c.
- **NO GORE, EVER: AGENTS.md rule 4, the Roblox Terms of Use, comes before every look** (owner, 2026-10-31, after uploaded blood textures drew a moderation warning on the owner's account).
  - No blood effects at all: no drops, drips, strings, sprays, splatter, stains, smears or pools, and nothing realistic.
  - A hit shows only as the body flashing red with a white outline (`UI/Components/Flash`).
  - Never upload an image that could read as gore.
  - In doubt, ask the owner first.
  - The reference footage's blood is never reproduced.
- **Colour roles:** cold white for the Light Beam and for magic and passage (travel, deaths); gold for objectives and rites; warm orange for fire and gunfire.
- Client code can't see `ServerStorage`: VFX templates live in `ReplicatedStorage.Shared.Assets.Vfx`.
- Beam textures run their vertical image axis along the beam's length: draw beam art tall (the band runs down the image, tileable top to bottom); a horizontal band shows up as a row of beads. A textured Beam draws as a solid band until its texture loads: preload it (`ContentProvider:PreloadAsync`) before enabling it.
- Glow textures with a black background only work additive (`LightEmission = 1`); otherwise they render as black slabs. Additive dark red disappears against the bright red sky: darkness has to come from alpha-textured particles or opaque or glass meshes.
- **Velocity-aligned particles** (`Orientation = VelocityParallel`) lead with the texture's **left** edge (tested 2026-10-31: a streak drawn upright flew sideways). Draw their art moving left: `tools/blender/vfx_sprites.py` draws it moving up, then turns it with `lead_left`.
- Trail textures run the same way (tested 2026-10-30): the vertical image axis along the trail, its top the newest edge; the horizontal axis from Attachment0 (left) to Attachment1 (right).
- Crescents face the camera (perpendicular to travel); flat in the travel plane they vanish edge-on from behind.
- Our textures are drawn by our scripts into the scratchpad. Upload them by serving that folder (`py -m http.server 8765 --bind 127.0.0.1 --directory <dir>`) and passing the `http://127.0.0.1:8765/<file>.png` URLs to MCP `upload_image`; the ids go in `Client.Vfx.Kit.Textures`.
- Capturing fast effects frozen: `/bl-studio-test`, "Captures".
