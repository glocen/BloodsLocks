# Asset log

Receipts for everything that ships (owner's IP Safety List): who made each asset, how, and its license. Add a row whenever an asset is created or replaced. Keep `.blend` files, scripts and drafts in git: they show the work is ours.

| Asset | Where it lives | Made by | How | License |
|---|---|---|---|---|
| Gustave's machine pistol (SMG) | `src/shared/Assets/Weapons/SMG.rbxm` | Claude | Blender script `tools/blender/smg.py`, `tools/studio/Models/SMG.luau` | Original |
| Gunfire sprites (muzzle, smoke, mist) | `Client.Vfx` | Claude | Blender script `tools/blender/vfx_sprites.py` | Original |
| Combat sound sheet (14 cues: gun, impacts, saber, guard, parry, Blood Blade, Light Beam) | id in `Definitions/SoundSheet`; file `build/audio/bl_combat_sounds.wav` | Claude | Synthesized from scratch by `tools/audio/sound_sheet.py` (filters, modal metal, reverb; no samples) | Original |
| VFX textures (blood crescent, glows, beam bands, glint) | ids in `Client.Vfx.Kit.Textures` | Claude | `tools/vfx_textures.py` | Original |
| Menu images (Hunt card, ritual circle) | ids in `Theme.Images` | Claude | `tools/ui_textures.py` | Original |
| Melted-wax candles | Manor | ChatGPT | Blender, `tools/art/build_melted_candles.py` | Original |

<!-- To backfill: every .rbxm in src/shared/Assets, the Gustave animations, the Manor and Victorian art kits, uploaded texture maps. -->
