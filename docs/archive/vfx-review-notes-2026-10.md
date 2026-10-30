# Archived: VFX review notes (engineering-plan §11c, 2026-10-29)

Moved here unchanged on 2026-10-30 at the owner's choice. The bar, the lessons and the code layout stay in [engineering-plan.md](../engineering-plan.md) §11c and `.claude/rules/vfx.md`.

- **Owner review 2026-10-29:** "alright" but **not yet up to our standard**. The slash is now upright (vertical) at the owner's request. The "a little buggy" was most likely the saber falling apart, now fixed.
- **Drawn textures, 2026-10-29:**
  - **The textures:** our own art, drawn by `tools/vfx_textures.py` (pure Python; `py tools/vfx_textures.py <out_dir> --preview`). The sandboxed shell can't write into Documents, so the script draws into a scratch folder.
  - **Blood Blade:** now a drawn crescent sprite (hot rim, wet gloss, near-black body, needle tips) plus a rim halo, as unlit SurfaceGuis on both faces of a thin plane (replaces the glass mesh).
  - **Light Beam:** the drawn soft band (core, mid, haze) plus drawn energy strands, replacing the onion bands. The beam is now continuous and soft-edged.
  - **Glints:** the charge "armed" glint and the beam flares use the drawn four-point glint.
  - **Owner review:** "still not my standard but fine, move on, we redo it later". The VFX quality revisit is **parked**: come back after the core loop, before the polish step.
