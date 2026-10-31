# Asset log

Receipts for everything that ships (owner's IP Safety List): who made each asset, how, and its license. Add a row whenever an asset is created or replaced. Keep `.blend` files, scripts and drafts in git: they show the work is ours.

| Asset | Where it lives | Made by | How | License |
|---|---|---|---|---|
| Gustave's machine pistol (SMG) | `src/shared/Assets/Weapons/SMG.rbxm` | Claude | Blender script `tools/blender/smg.py`, `tools/studio/Models/SMG.luau` | Original |
| Gunfire sprites (muzzle flash and cone, smoke, spark, tracer) | `Client.Vfx.Textures` | Claude | Blender script `tools/blender/vfx_sprites.py` | Original |
| Gustave's sabre: black inlaid blade, gold hilt, garnets (replaces the box-part sabre) | `src/shared/Assets/Weapons/Saber.rbxm` | Claude | Blender script `tools/blender/saber.py` (the inlay drawn by the script), `tools/studio/Models/Saber.luau` | Original |
| Slash trail textures (pale blade smear, bright hairline) | `Client.Vfx.Textures` | Claude | `tools/blender/vfx_sprites.py` (numpy) | Original |
| Combat sound sheet (14 cues: gun, impacts, saber, guard, parry, Blood Blade, Light Beam) | id in `Definitions/SoundSheet`; file `build/audio/bl_combat_sounds.wav` | Claude | Synthesized from scratch by `tools/audio/sound_sheet.py` (filters, modal metal, reverb; no samples) | Original |
| VFX textures (beam bands, glint, soft glow) | `Client.Vfx.Textures` (tracked by `tools/vfx/textures.py`) | Claude | `tools/vfx_textures.py` (the blood crescent and its glow were deleted 2026-10-31: no-gore rule) | Original |
| Effect textures: energy crescent and halo, energy wisp, fire flipbook (replacing the Creator Store crescent, wisp and fire art, deleted 2026-10-31) | `Client.Vfx.Textures` | Claude | `tools/blender/vfx_sprites.py` (numpy; the fire is a Cycles emissive volume), tracked by `tools/vfx/textures.py` | Original |
| Menu images (Hunt card, ritual circle) | ids in `Theme.Images` | Claude | `tools/ui_textures.py` | Original |
| Melted-wax candles | Manor | ChatGPT | Blender, `tools/art/build_melted_candles.py` | Original |
| The bite's animations: `Staggered`, `Bite`, `BiteHold`, `Bitten` | ids in `Shared.Config.Animations` | Claude | Animated in Blender by script (`tools/blender/bite_anim.py` on `tools/blender/r6anim.py`), baked and published by `tools/studio/Animations/Author.SaveBaked` | Original |
| The bite's sound cues (`BiteLunge`, `BiteSeize`, `BiteFangs`, `BitePulse`, `BiteRelease`) | the combat sound sheet (`Definitions/SoundSheet`) | Claude | Synthesized from scratch by `tools/audio/sound_sheet.py` (no samples) | Original |

<!-- To backfill: every .rbxm in src/shared/Assets, the Gustave animations, the Manor and Victorian art kits, uploaded texture maps. -->
