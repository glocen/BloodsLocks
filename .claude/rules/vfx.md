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

- The bar (owner, 2026-10-29): "as good as Duskbloods, nothing less". Blood is dark, wet and heavy (near-black body, a thin hot edge, drips and splatter), never neon; light is warm gold, not white. Review every effect from the player's own camera (behind the shooter) before calling it done. Code layout and history: `docs/engineering-plan.md` §11c.
- Client code can't see `ServerStorage`: VFX templates live in `ReplicatedStorage.Shared.Assets.Vfx`.
- Beam textures run their vertical image axis along the beam's length: draw beam art tall (the band runs down the image, tileable top to bottom); a horizontal band shows up as a row of beads. A textured Beam draws as a solid band until its texture loads: preload it (`ContentProvider:PreloadAsync`) before enabling it.
- Glow textures with a black background only work additive (`LightEmission = 1`); otherwise they render as black slabs. Additive dark red disappears against the bright red sky: darkness has to come from alpha-textured particles or opaque or glass meshes.
- Crescents face the camera (perpendicular to travel); flat in the travel plane they vanish edge-on from behind.
- Our textures are drawn by our scripts into the scratchpad. Upload them by serving that folder (`py -m http.server 8765 --bind 127.0.0.1 --directory <dir>`) and passing the `http://127.0.0.1:8765/<file>.png` URLs to MCP `upload_image`; the ids go in `Client.Vfx.Kit.Textures`.
- Capturing fast effects frozen: `/bl-studio-test`, "Captures".
