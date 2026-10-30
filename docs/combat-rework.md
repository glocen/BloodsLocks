# C1 · Combat rework: design

Claude, 2026-10-30. This is the owner's next slice after Q0. Their words: "rework the combat, like the SMG bullet effect, and it gotta spread like not all the bullets land on the enemy, rework the M1, laser beam and blood slash". It also carries earlier asks: "a knockback like when you M1 someone he gets knocked back", "level-ups that matter", "a directional movement system", and the VFX redo to ChatGPT's colour direction.

The rules it follows:
- ChatGPT's [whole-game brief](duskbloods-gameplay-breakdown.md), "Effects": windup, active shape, confirmed contact, residue. Effects are layered; no single neon solids.
- The [VFX standard](engineering-plan.md) (11c).
- The `Theme.Vfx` palette.
- No gore: blood is dark mist, sparks and light.

## The art pipeline (owner, 2026-10-30)

"Do all the VFX, textures, animations and models in Blender, respecting our quality."
- **Textures:** effect sprites and flipbooks are rendered by `tools/blender/vfx_sprites.py` with Blender running headless (`blender.exe -b --python ...`): Cycles volumes for smoke and mist, numpy for flat emissive shapes. The PNGs are uploaded through the Studio MCP (`upload_image`, free), and their ids go into `Vfx/Kit.Textures`. They replace the Creator Store textures the effects still borrow, effect by effect.
- **Models** are built and baked by script in Blender (`tools/blender/<model>.py` on `blcommon.py`), exported as centred mesh JSON into `build/import`, then published and assembled in Studio by `tools/studio/ModelAssembly` (synced to `ServerStorage.BL_Tools`); each model's assembly and asset ids live in `tools/studio/Models/<Name>`. The finished model is serialized into `src/shared/Assets`. Metals are calibrated for Roblox (see `steel_material`).
- **Animations** are body-space sources in `tools/studio/Animations/<Kit>`, saved and published from Studio by `Animations/Author` (`AssetService:CreateAssetAsync`, no owner step); the id goes into `Config.Animations`.

## C1.1 · The SMG

**Spread.** The burst blooms: shot n of a burst gets a cone of min(Base + (n − 1) × Bloom, Max). Each shot picks a point uniformly over that disc, so the first round is close to the crosshair and later rounds scatter. With Base 0.6°, Bloom 1.5° and Max 4.5° on an R6 target (2 studs wide):

| Range | Rounds of 4 that land |
|---|---|
| 10 studs | all of them |
| 30 studs | about 2–3 |
| 60 studs | about 1–2 |

Lock-on aims at the target but keeps the spread. Stagger still builds per landed round. The numbers live in `Definitions/Weapons/BurstSMG` (`Spread = { Base, Bloom, Max }`).

**The bullet effect** (`Vfx/Gunshot`). The server sends the surface normal and whether a body was hit with each shot. The layers:
- **Muzzle:** a flash sprite from a rendered flipbook (one frame per shot, warm core) with a 0.06 s light, and a wisp of smoke that lingers.
- **Tracer:** a short streak flying from the muzzle to the hit point at 700 studs/s, not a full-length line.
- **Surface hit:** sparks thrown out along the normal (rendered streak sprites, velocity-aligned, falling), a dust puff (rendered flipbook) and a brief light.
- **Body hit:** a dark-red mist puff and a few dark sparks: a hit, not a wound.
- **Miss:** only the tracer, passing the target.

**Proof:**
- Self-test "SMG spread": five bursts at 30 studs land some rounds but not all; one burst at close range lands every round.
- Captures from behind the shooter, frozen mid-burst.

## C1.2 · The M1 (saber light chain)

- **Knockback that shows.** A hit stores a short push on the target (`Knock` velocity and `KnockUntil`, in EntityState). The target's own movement step holds that velocity, with WalkSpeed raised so the walk controller doesn't brake it, the way the dodge does:
  - players in Locomotion;
  - NPCs in their brain's step.

  The distance comes from data (`Hit.Knockback` studs). Light 1–3 push 2.5 and Light 4 pushes 6. Strong pushes 5, Charged 10. A blocked hit pushes half; a parried one doesn't push. The old one-frame velocity (`Config.Combat.Knockback`) goes.
- **Hitstop.** On a confirmed hit, the attacker's and the target's animations pause for 0.06 s. It's client-only presentation and never touches the simulation, capped and never on a miss.
- **Slash.** A trail along the blade during the hit window (a crimson edge fading into smoke), and at contact rendered sparks plus a dark-red mist puff.
- **Proof:**
  - Self-test "M1 knockback": the dummy moves by its Knockback distance (±30%).
  - The 4-hit chain still connects: light hits push less than the lunge closes.
  - Captures.

## C1.3 · Blood Blade and C1.4 · Light Beam

These come after C1.1 and C1.2. First a capture of the current effects and a written critique against the brief, then the redo with the rendered sprites. The brief's shapes still hold:
- **Blood Blade:** a dark wet crescent with a crimson edge, restrained drips and mist, cast and impact.
- **Light Beam:** convergence, a layered scrolling core, a contact flare, a collapse.

## Later in C1 (owner's earlier asks)

- **Level-ups that matter:** a time-to-kill table per level, then damage and HP growth tuned to it.
- **Directional movement:** 8-way strafing while locked, and directional dodges. It needs new animations for the owner to publish.

## Critique before building

1. **Spread could make the SMG useless.** The first round stays accurate, and close range lands everything; it's the long-range chip that scatters. That's the owner's ask.
2. **Tracers on every round could clutter a crowded fight.** They're short streaks living about 0.1 s, the impact sparks are small, and smoke stays thin.
3. **Knockback could break the chain** by pushing the target out of reach of the next swing. Light hits push 2.5 studs while each swing's lunge closes about 2.4; the 4th hit pushes 6 and ends the chain with space, which is when a gap is wanted.
4. **Knockback and walls:** the push is velocity held by the simulation, so it stops at walls like movement does, with no clipping.
5. **Hitstop desync:** it's presentation only and capped. The simulation's timing is untouched.
6. **No gore:** body hits are mist and sparks, never sprays or pools.

## Progress (2026-10-30)

**C1.1 done.** Self-test 73/73 and logic 48/48 in the Manor; the sounds wait for the owner's upload.
- **Spread:** in `Gunfire` and `BurstSMG.Spread` (Base 0.8°, Bloom 2.2°, Max 6.5°). Up close every round lands; at 30 studs 13–15 of 20 land.
- **The gun:** Gustave's machine pistol, modelled and baked in Blender (`tools/blender/smg.py`): blued steel, aged brass, walnut grips, garnet medallions that glow (an emissive mask), and an amber crystal (a glass shell over a neon core, with a small light). Held in the left hand by `Equipment.AttachLoadout`. The owner asked for the light without sparkles.
- **The burst:** a duelist's stance. The body blades with the gun shoulder forward, the arm snaps to shoulder height, and each round kicks a little higher with the bloom. Published as `Config.Animations.SMGBurst`.
- **The effect** (`Vfx/Gunshot`, from `ShotFx`): a star flash and flame cone at the gun's real muzzle, a light, and gun smoke. A pale tracer flies at 700 studs/s, and the impact waits for it to land. Surfaces get sparks, dust in the surface's colour and a light. Bodies get a crimson mist plume and streaks thrown back toward the shooter (stylized, no wound). `Kit.TimeScale` slows effects for frozen review captures.
- **Lighting** (owner's OK): the Manor's grade now has violet shadows, warm lamp bloom and a light violet haze. The old values are in `ServerStorage.WorldBackups.Lighting_PreDuskbloodsGrade_20261030`.
- **Sound** (2026-10-30): 14 combat cues synthesized from scratch by `tools/audio/sound_sheet.py` (no samples): the shot, reload, surface and body hits, two swings, the saber hit, block, parry, the Blood Blade's cast and impact, and the Light Beam's charge, loop and end. They're packed into one sheet so a batch costs one upload. `Definitions/Sounds` says which cue plays when (Registry checks it at load); `Client.Audio.Sfx` plays them in 3D, and swings peak as their hit window opens. Silent until the owner uploads the sheet. The gunshot's body hit is now dark wet mist (the VFX rule).

**C1.2 done.** Self-test 72/72 and logic tests pass in the Manor.
- **Knockback** (data `Hit.Knockback`, held by the movement step) and **hitstop** (client `AdjustSpeed(0)`, 0.06 s; longer for heavy blows), plus the shared `Vfx/BloodHit` at the blade's contact.
- **The sabre**, rebuilt in Blender (`tools/blender/saber.py`) to the owner's direction (2026-10-30): "the blade should be black with some gold and jewel, use Albert as reference".
  - **The blade:** black lacquered steel, damascened in gold (a gothic panel at the root, gold rules on the fuller's shoulders up to a finial, a gold vine in the fuller), with a polished edge.
  - **The garnet:** at the blade's root, in a domed gold quatrefoil with four pearls.
  - **The hilt:** a three-bar gold basket hilt; an oxblood shagreen grip bound with gold wire in a spiral groove; a garnet pommel.
  - **Built for play:** the hilt is scaled to fill an R6 fist (a 0.9-stud grip, like the old sabre's).
  - **Two meshes, two texture sets.** The blade's UVs are laid out by the script, at 723 texels a stud. The inlay is a mask drawn by the script and baked through the blade's material.
  - **Points:** `Grip`, `BladeBase`, `BladeTip` and `Jewel` are named in `Equipment.Points`.
- **The slash** (`Vfx/SlashTrail`, from each melee action's start): a dark blood smear Trail between `BladeBase` and `BladeTip`, a hot crimson hairline on the point's path, blood flung off the point and a breath of dark mist. It draws from just before the hit window to just after, and a swing cancelled first draws nothing. Heavy blows leave more. The textures are drawn by `tools/blender/vfx_sprites.py` (`slash_smear`, `slash_edge`).
- **Reviewed:** captures in the Manor's test pad, from the player's camera and from the side, frozen mid-swing.

**Next:**
1. C1.3 and C1.4: the Blood Blade and the Light Beam. The beam leaves from the gun's crystal (`CrystalTip`), raised overhead the way Albert raises his (the owner's video).
2. When C1 is at the bar: report to the owner and plan the combat framework rework together (owner, 2026-10-30).
