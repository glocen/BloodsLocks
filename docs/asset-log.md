# Asset log

Receipts for everything that ships (owner's IP Safety List): who made each asset, how, and its license. Add a row whenever an asset is created or replaced. Keep `.blend` files, scripts and drafts in git: they show the work is ours.

| Asset | Where it lives | Made by | How | License |
|---|---|---|---|---|
| Gustave's machine pistol (SMG) | `src/shared/Assets/Weapons/SMG.rbxm` | Claude | Blender script `tools/blender/smg.py`, `tools/studio/Models/SMG.luau` | Original |
| Gunfire sprites (muzzle flash and cone, smoke, spark, tracer) | `Client.Vfx.Textures` | Claude | Blender script `tools/blender/vfx_sprites.py` | Original |
| Gustave's sabre: black inlaid blade, gold hilt, garnets (replaces the box-part sabre) | `src/shared/Assets/Weapons/Saber.rbxm` | Claude | Blender script `tools/blender/saber.py` (the inlay drawn by the script), `tools/studio/Models/Saber.luau` | Original |
| Slash trail textures (pale blade smear, bright hairline) | `Client.Vfx.Textures` | Claude | `tools/blender/vfx_sprites.py` (numpy) | Original |
| Combat sound cues (19: gun, impacts, sabre, guard, parry, Crimson Crescent, Light Beam, the bite), provisional until the owner's audition. Replaces the synthesized sheet, rejected by the owner and deleted 2026-10-31 (never uploaded) | ids and slices in `Definitions/Sounds` | Roblox's audio library, used in place (nothing uploaded) | Found, measured and sliced by `tools/studio/Audio`; each cue is its shortlist's top slice loud enough to level | Licensed libraries: ProSoundEffects (12 cues), Roblox (`snap.wav`, BiteFangs). Community uploads (AGENTS.md rule 2: logged, a claim can silence them): 6241709963 SaberSwingHeavy (Aurarus), 109108727131456 GunShot (ChipTheTrainer2), 100961202215282 GunReload (alskdjdjdbdj), 123902330294565 LightBeamLoop (eakflef), 116381638709798 BiteLunge (Axellatic), 130809356016155 BiteRelease (maxsharkey88) |
| VFX textures (beam bands, glint, soft glow) | `Client.Vfx.Textures` (tracked by `tools/vfx/textures.py`) | Claude | `tools/vfx_textures.py` (the blood crescent and its glow were deleted 2026-10-31: no-gore rule) | Original |
| Effect textures: energy crescent and halo, energy wisp, fire flipbook (replacing the Creator Store crescent, wisp and fire art, deleted 2026-10-31) | `Client.Vfx.Textures` | Claude | `tools/blender/vfx_sprites.py` (numpy; the fire is a Cycles emissive volume), tracked by `tools/vfx/textures.py` | Original |
| Menu images (Hunt card, ritual circle) | ids in `Theme.Images` | Claude | `tools/ui_textures.py` | Original |
| Melted-wax candles | Manor | ChatGPT | Blender, `tools/art/build_melted_candles.py` | Original |
| The bite's animations: `Staggered`, `Bite`, `BiteHold`, `Bitten` | ids in `Shared.Config.Animations` | Claude | Animated in Blender by script (`tools/blender/bite_anim.py` on `tools/blender/r6anim.py`), baked and published by `tools/studio/Animations/Author.SaveBaked` | Original |
| The ward: the guard's crimson glass buckler (lens and rim meshes, the template) | `src/shared/Assets/Vfx/Ward.rbxm` (meshes 80536993531212 and 133062466600477) | Claude | Blender script `tools/blender/ward.py`, assembled by `tools/studio/Models/Ward.luau` | Original |
| Ward textures: rose-window tracery, cracks, glass shards | `Client.Vfx.Textures` | Claude | `tools/blender/vfx_sprites.py` (numpy), tracked by `tools/vfx/textures.py` | Original |
| Guard-break sound (provisional, until the owner's sounds) | cue `GuardBreak` in `Definitions/Sounds` (9114855870, "Ice Block Drop To Concrete Shatter 1") | Roblox's audio library: ProSoundEffects | Sliced and levelled by `tools/studio/Audio` | Licensed library |

<!-- To backfill: every .rbxm in src/shared/Assets, the Gustave animations, the Manor and Victorian art kits, uploaded texture maps. -->
