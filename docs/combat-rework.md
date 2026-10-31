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
- **Blood Blade** (shown to players as "Crimson Crescent", owner 2026-10-30): a huge stylized crimson energy crescent thrown from the raised free hand, thinning to a streak; never liquid, no droplets (AGENTS.md rule 4). Ask the owner about its look before building it.
- **Light Beam:** cold white (owner, 2026-10-30): raise the gun overhead, a star flare at the crystal, aim, a white burst, a thin straight white ray with swirl rings at its root; planted while firing.
- **Every C1 effect is redone to the network-test study** (owner, 2026-10-30): the sabre hit, the SMG, the Blood Blade, the Light Beam, the bite, guard, howl and the movement trails. **No blood effects, ever** (AGENTS.md rule 4; owner, 2026-10-31): a hit is the body's red flash with a white outline. The order and the gaps are in `docs/reference/network-test/takeaways.md` §1.

## C1.5 · The bite (owner, 2026-10-31)

The owner's words: "for the bite it js the animation and let make a wind effect with darky smoke instead of blood", then "it gotta be a bit long both character cant move and it cause iframe for both and the one who bite recover hp ... make it perfect". The reference is the network-test bite, measured at 10 fps ([vfx.md](reference/network-test/vfx.md) §3: grab ≈0.5 s, bite ≈0.4, drain ≈1.5, release, burst ≈0.6). Ours keeps that rhythm with our own beats, and no blood.

**The flow.** A stagger drops its body to one knee, head bowed (the reference's manual, 9:34; owner: "down on his knee, then grabbed, and the bite starts"). The bite lunges as before, and against anything not staggered it whiffs (0.75 s). A hit on a staggered target seizes it: the bite becomes a paired hold (`Common.BiteHold`), run on the server by `Simulation/Bite`, and the victim is hauled up off its knee.

| Beat | From the seize | The biter | The victim | Effect |
|---|---|---|---|---|
| Seize | 0–0.4 s | grips the shoulders and pulls | is yanked in (a short pull through `Knock`), arches back, arms flung wide | dark smoke and wind drawn in |
| Fangs | 0.55 | head to the neck | head thrown aside | the victim's red flash, a dark puff, a camera kick |
| Drain | 0.85–2.05 | holds; the shoulders heave on each pulse | hangs, trembling | 5 pulses 0.3 s apart. Half the bite's damage drains from the victim (never below 1 HP), and the heal flows to the biter in equal parts. Slow dark ribbons circle both; cold-white motes rise round the biter on each pulse |
| Release | 2.35 | shoves the victim off with the gun arm, twisting away | is thrown back 6 studs, turned 25° to the biter's left (so the player's camera sees it fly), and knocked down to a knee for 1 s | the rest of the damage lands (it can kill); the gust: wide ribbons and ground rings |
| Recovery | 2.35–2.75 | back to stance; can dodge from 2.55 | down until 3.35 | |

**Rules:**
- **Both locked:** the biter's hold is an action with no walking, jumping or dodging until 2.55. The victim is in hitstun until the release, then knocked down.
- **Both invulnerable:** i-frames on both from the seize, the victim's to the release and the biter's to 2.55 (when it can act again). Hits on a held body do nothing, and no "Evaded" pops over it.
- **The heal:** the bite's `Heal` (0.12 of the biter's max HP) comes in five equal pulses; the total shows once, at the release.
- **One victim:** a biter holds one body, and a held body can't be seized by another biter.
- **Ends early, cleanly:** the hold ends at once if either body dies or leaves, the two get more than 6 studs apart (a teleport, a phase change), the victim becomes protected (the match guard), or the biter's hold is cancelled. Both are freed and no further damage lands.
- **Facing:** both face each other for the whole hold.
- **Sizes:** tuned on equal-height bodies (players, Wretches, dummies). The Butcher (1.35×) gets checked from the player's camera; if the pose fails on it, its definition refuses the bite.
- **Never an embrace** (Roblox's Community Standards ban romantic or flirtatious gestures): the gun hand seizes the victim's side, the sabre arm stays low and back, the victim claws at the gripping arm, each pulse is a convulsion, the release is a throw, and the chests stay about 0.9 studs apart.
- **The bodies don't shove each other:** their solid parts ignore each other while held (their animated heads and torsos would push them apart), and the pull is re-aimed every step so it lands on the hold's distance.

**What players see** (`Vfx/BiteWind`): it reads the hold's clock every frame, like the beams and charges, so a late joiner or an early end shows correctly.
- The pull at the seize; at the fangs a dark puff, a cold flash lighting both faces and the victim's red flash; through the drain a slow orbit of smoke rising round the upper bodies, and on each pulse cold-white motes streaming into the biter with a soft glow; at the release the sweep and the ground gust.
- The biter's camera (`Config.Camera.Bite`) eases 40° round to its right (the side of the bite), in to 9 studs and to FOV 62, then back out as the victim is thrown. sleitnick's CameraShaker gives a kick at the seize and the fangs, a low rumble through the drain that heaves on each pulse, and a hard shake at the release.
- No blood, no wounds and no wet sounds (AGENTS.md rule 4).

**Animations**, animated in Blender (owner: "do the animation in Blender, it should be better"): `tools/blender/bite_anim.py` on the R6 toolkit `tools/blender/r6anim.py` (an exact R6 rig from the live Motor6Ds, Blender's curves, reach/gaze/lean solvers for the contacts, a floor solver for planted feet, review renders from the player's camera), baked to `build/import/Anim_<Name>.txt` and saved and published by `Author.SaveBaked`:
- `Staggered` (any body, 2.6 s): rocked back, down on one knee, heaving. `AnimationSim` plays it from `StaggeredAt` while the stagger lasts; the body rises over 0.3 s as it ends.
- `Bite` (0.73 s): the coil, the lunge with the gun hand reaching, the snap.
- `BiteHold` (2.73 s) and `Bitten` (3.33 s, any R6 body, from the victim's `BittenAt`).

**Sounds** (synthesized cues in the sheet, heard once it's uploaded): `BiteLunge`, `BiteSeize` (air rushing in, a grip's thud), `BiteFangs` (a dull blow, a hiss of smoke), `BitePulse` (one deep throb, like a slow heartbeat) and `BiteRelease` (a gust over a deep boom, the hold's Hit). No wet or swallowing sounds; the older body-hit and crescent cues lost their wet layers in the same pass.

**Proof:**
- Self-test "Bite hold", on the pad dummy:
  - the hold starts, and Jump and Dodge do nothing during it;
  - both bodies stay put;
  - a hit on you during the hold does nothing;
  - your HP rises by the heal, and the dummy loses exactly the bite's damage;
  - the gust plays after the release, and you can move again after the recovery.
- Self-test "Bite hold on an enemy": a staggered Wretch is held still and can't attack.
- Self-test "Bite whiff": a dummy that isn't staggered isn't seized.
- Logic test "Bite pulses": for awkward totals the pulses add up exactly to the heal and the drain share, and never take the victim below 1 HP.
- Captures from the player's camera at each beat, frozen and live.

**Critique before building:**
1. **Too long to be locked in a PvPvE fight?** 2.75 s is long, but both bodies are invulnerable and the biter acts again at 2.55. The cost is time: the posture break is spent and other foes close in. That's the owner's ask, and close to the reference (≈3 s).
2. **Unfair on a PvP victim?** The victim already lost the posture duel. The hold also protects them from third parties piling on, and the knockdown (1 s) gives the biter one follow-up, no more.
3. **Snaps or slides?** No teleports. The victim is pulled in through the knockback path (velocity, so it stops at walls), and the biter stays where its lunge put it. The biter's client predicts the whiff for one round trip before the hold arrives; both clips start from the same pose, so the switch blends.
4. **Visuals out of sync:** they read the hold's clock (the action's start), never timers, so they end when the hold does.
5. **Gore:** smoke, wind and cold light only, and the hit feedback is the victim's red flash with a white outline. A neck bite with no blood is common in Roblox vampire games; nothing wet is drawn or heard.
6. **Track budget:** one one-shot per body (`BiteHold` or `Bitten`), within `AnimationSim`'s two.

## C1.6 · The ward: guard, block, parry, guard break (owner, 2026-10-31: "the shield model when blocking")

**Reference (OBSERVED; bursts 9:39.4–9:41.3 at 10 fps and 14:42.5–14:43.7 at 15 fps, crops on the hero):**
- **Raised guard:** a buckler-sized disc, about a third of the body's height, at the off-hand shoulder. It's dark crimson glass, darker at the centre, with a brighter rim. It pops in within 0.1 s (9:40.4 → 9:40.5) and holds still.
- **A blocked hit (14:42.9–14:43.1):** thin orange-gold arcs whirl round the upper body at several radii for about 0.2 s, with red-gold sparks at the hit.
- **The manual's card (9:21):** a red translucent shield with crimson energy at its edge.

**Ours (DESIGN): the ward,** a crimson glass buckler with a gothic rose-window tracery.
- **Form:** a shallow glass lens 1.9 studs across, from `tools/blender/ward.py`, with a separate hot rim (a thin torus). It sits 0.6 studs ahead of the chest on the off-hand side at shoulder height, turned 10° outward, and follows the body. Every guarding entity gets one.
- **Layers:**
  - dark crimson glass, with the tracery drawn on it in gold-red lines;
  - the hot rim, plus a soft ring of glow round it;
  - a faint shimmer skin;
  - a few embers drifting off the rim;
  - a crimson light on the arm and face.
- **Raise and lower:** it grows 0.4 → 1.06 → 1 in 0.12 s with a flash of the rim. Lowered, it shrinks and fades in 0.08 s.
- **Strength:** cracks fade in as stamina falls below half; under a fifth the ward flickers.
- **Block:** the ward flashes hot and a ripple runs out from its centre. Four to six thin gold arcs whirl round it at several radii for 0.2 s, and gold sparks spray off its face. Then the shake and the block sound (both exist).
- **Parry:** a white-gold starburst and a bright ring snapping out from the ward, with more and brighter arcs, more sparks, a stronger shake and the parry sound. Gold is the colour of rites, so it marks the perfect timing.
- **Guard break:** the ward cracks through and shatters. Crimson glass shards fly out and fall, a puff goes from crimson to black (the owner's black gradient), and the rim snaps. A sound is added (a provisional library slice until the owner's sounds arrive).
- **Code:**
  - `Vfx/Ward` (client): one pooled ward per entity. It's raised and lowered from `GuardStart`, cracked from stamina, with bursts on `LastBlockAt`, `LastParryAt` and `GuardBrokenAt`, all through `CombatFxController`.
  - Textures through the pipeline: `WardTracery`, `WardCracks`, `GlassShard`. The arcs, sparks, ring and glint reuse `CrescentArc`, `Spark`, `WindRing` and `Glint`.
  - Meshes: published by `ModelAssembly` into `Assets/Vfx/Ward.rbxm`.

**Critique before building:**
1. **Seen from behind.** The player's camera sees the ward's back. The glass must read from both sides (the tracery is mapped through to the back) and stick out past the silhouette on the off-hand side, as in the reference. Judged from the player's camera; size and offset are tuned there.
2. **Dark on dark.** Dark glass vanishes in night streets, and additive glow vanishes against the red sky. So darkness comes from the glass (alpha), and readability from the hot rim, the embers and the light. Checked over a dark and a bright backdrop.
3. **Floating.** If the off-hand arm isn't near it, the ward looks detached. It's checked against our guard pose. If they clash, the offset moves to the forearm, or the guard animation raises the off-hand.
4. **Clutter.** Arcs and sparks live 0.2 s or less, so blocks in a flurry don't pile up; the parry is bigger but rare.
5. **Cost.** Each guarding entity gets two parts, three emitters and one light, pooled rather than rebuilt per raise. The bursts are short-lived emitters.
6. **No gore.** Glass, light, smoke and sparks only; the shards are glass. Checked before any upload (AGENTS.md rule 4).
7. **Fan test.** A translucent energy buckler is a genre staple. Our rose-window tracery, the hot rim and the gold arcs make it ours, and there is no sphere.

## Later in C1 (owner's earlier asks)

- **Level-ups that matter:** a time-to-kill table per level, then damage and HP growth tuned to it.
- **Directional movement:** 8-way strafing while locked, and directional dodges. It needs new animations for the owner to publish.

## Critique before building

1. **Spread could make the SMG useless.** The first round stays accurate, and close range lands everything; it's the long-range chip that scatters. That's the owner's ask.
2. **Tracers on every round could clutter a crowded fight.** They're short streaks living about 0.1 s, the impact sparks are small, and smoke stays thin.
3. **Knockback could break the chain** by pushing the target out of reach of the next swing. Light hits push 2.5 studs while each swing's lunge closes about 2.4; the 4th hit pushes 6 and ends the chain with space, which is when a gap is wanted.
4. **Knockback and walls:** the push is velocity held by the simulation, so it stops at walls like movement does, with no clipping.
5. **Hitstop desync:** it's presentation only and capped. The simulation's timing is untouched.
6. **No gore:** a body hit shows only as the body flashing red with a white outline (AGENTS.md rule 4).

## Progress (2026-10-30)

**C1.1 done.** Self-test 73/73 and logic 48/48 in the Manor; the sounds wait for the owner's upload.
- **Spread:** in `Gunfire` and `BurstSMG.Spread` (Base 0.8°, Bloom 2.2°, Max 6.5°). Up close every round lands; at 30 studs 13–15 of 20 land.
- **The gun:** Gustave's machine pistol, modelled and baked in Blender (`tools/blender/smg.py`): blued steel, aged brass, walnut grips, garnet medallions that glow (an emissive mask), and an amber crystal (a glass shell over a neon core, with a small light). Held in the left hand by `Equipment.AttachLoadout`. The owner asked for the light without sparkles.
- **The burst:** a duelist's stance. The body blades with the gun shoulder forward, the arm snaps to shoulder height, and each round kicks a little higher with the bloom. Published as `Config.Animations.SMGBurst`.
- **The effect** (`Vfx/Gunshot`, from `ShotFx`): a star flash and flame cone at the gun's real muzzle, a light, and gun smoke. A pale tracer flies at 700 studs/s, and the impact waits for it to land. Surfaces get sparks, dust in the surface's colour and a light. A struck body flashes red with a white outline (no blood effect: AGENTS.md rule 4). `Kit.TimeScale` slows effects for frozen review captures.
- **Lighting** (owner's OK): the Manor's grade now has violet shadows, warm lamp bloom and a light violet haze. The old values are in `ServerStorage.WorldBackups.Lighting_PreDuskbloodsGrade_20261030`.
- **Sound** (2026-10-31): the 19 combat cues are slices of sounds from Roblox's audio library (AGENTS.md rule 2).
  - `tools/studio/Audio` finds them, measures them and slices them, aimed at the reference's measured feel (`docs/reference/network-test/audio.md`).
  - `Sfx` levels every slice to the same loudness.
  - The owner picks each one in the audition panel. Until then, each cue holds its shortlist's top slice.
  - `Definitions/Sounds` says which cue plays when (Registry checks it at load); swings peak as their hit window opens.
  - The synthesized sheet of 2026-10-30 was rejected by the owner and deleted.

**C1.2 done.** Self-test 72/72 and logic tests pass in the Manor.
- **Knockback** (data `Hit.Knockback`, held by the movement step) and **hitstop** (client `AdjustSpeed(0)`, 0.06 s; longer for heavy blows), and the struck body's red flash with a white outline (`UI/Components/Flash`; no blood effects, AGENTS.md rule 4).
- **The sabre**, rebuilt in Blender (`tools/blender/saber.py`) to the owner's direction (2026-10-30): "the blade should be black with some gold and jewel, use Albert as reference".
  - **The blade:** black lacquered steel, damascened in gold (a gothic panel at the root, gold rules on the fuller's shoulders up to a finial, a gold vine in the fuller), with a polished edge.
  - **The garnet:** at the blade's root, in a domed gold quatrefoil with four pearls.
  - **The hilt:** a three-bar gold basket hilt; an oxblood shagreen grip bound with gold wire in a spiral groove; a garnet pommel.
  - **Built for play:** the hilt is scaled to fill an R6 fist (a 0.9-stud grip, like the old sabre's).
  - **Two meshes, two texture sets.** The blade's UVs are laid out by the script, at 723 texels a stud. The inlay is a mask drawn by the script and baked through the blade's material.
  - **Points:** `Grip`, `BladeBase`, `BladeTip` and `Jewel` are named in `Equipment.Points`.
- **The slash** (`Vfx/SlashTrail`, from each melee action's start; rebuilt 2026-10-31 after the network-test study): a short pale motion smear between `BladeBase` and `BladeTip` that takes the scene's light, and a bright line on the point's path, for the swing's fast frames only. A swing cancelled first draws nothing; heavy blows smear a little longer. The textures are drawn by `tools/blender/vfx_sprites.py` (`blade_smear`, `slash_edge`).
- **Reviewed:** captures in the Manor's test pad, from the player's camera and from the side, frozen mid-swing.

**C1.5 done (2026-10-31): the bite and the stagger kneel.** Self-test 100–101 of 100–101 in the Manor and in the Victorian place (the count varies with the screen the UI lint finds), logic 63/63, world report clean.
- **Built:** the hold (`Simulation/Bite`), the kneel, the four Blender clips, `Vfx/BiteWind` on the hold's clock, the bite camera, five sound cues.
- **Reviewed:** Blender sheets from the player's camera and the side, and live captures frozen at the kneel, the fangs, the drain and the release.
- **Open:** the owner's look in play. The Butcher (1.35×) isn't checked yet. The sounds wait for the sheet's upload.

**C1.6 built (2026-10-31): the ward.** Self-test 129/129 in the Manor and 130/130 in the Victorian place, logic 63/63 in both.
- **Built:**
  - the glass buckler: `tools/blender/ward.py`, published into `Assets/Vfx/Ward`;
  - `Vfx/Ward`: raise and lower, cracks with the guard's stamina, the block, the parry and the break;
  - its textures: `WardTracery`, `WardCracks`, `GlassShard`;
  - a guard-break sound: a provisional library slice;
  - the self-test case "Ward".
- **Fixed on the way:** a hit's push turned the body away from its attacker. The push steers the humanoid, and auto-rotate turned it along the push. So a guard stopped one hit and then stood sideways to the next.
  - Pushes now hold the facing the body had when the hit landed (`Knock.Facing`), for players and NPCs.
  - The "Guard" case checks that a second hit is blocked too.
- **Reviewed:** frozen captures from the player's camera on the test pad: raised (front and back), block, parry, break.
  - The ward moved out beside the head; from behind it was hidden.
  - The block's arcs are orange-gold; white-gold is kept for the parry.
  - Every light is kept small, so the floor never pools with red.
- **Open:** a look over the Victorian red sky and a dark interior, and the owner's look in play.

**Next:**
1. C1.3 and C1.4: the Blood Blade and the Light Beam. The beam leaves from the gun's crystal (`CrystalTip`), raised overhead the way Albert raises his (the owner's video).
2. When C1 is at the bar: report to the owner and plan the combat framework rework together (owner, 2026-10-30).
