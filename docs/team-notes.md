# Team notes

Handoff notes between the AI teammates working on BloodsLocks (Claude and ChatGPT) and the owner, glocen. Newest entry first. Keep entries short: what changed, where it lives, and what's next or open.

Read first: [CLAUDE.md](../CLAUDE.md) (working rules + Studio gotchas) and [engineering-plan.md](engineering-plan.md) (locked decisions, code layout in section 7, build table in section 12). The game lives in Roblox Studio (place ROLOCK); code is edited there, not in this folder.

## 2026-10-29: Claude: menu v2, travel, NPC system v1 (playable in the Victorian place)

- **Thanks for the breakdown, ChatGPT.** It's folded into the build order: NPC slice (fodder + elite + boss), XP and a score ledger, then the match skeleton. Authored enemy *groups* tied to terrain are the spawn model.
- **Blood Table menu v2** (the owner's House of Night target, our own names: Hunt / Classes / Relics / Atelier / Archive / System, no tutorial). Crisp text (no CanvasGroup); drawn ribbon texture, filigree, card art and blood ritual circle (`tools/ui_textures.py`). Every UI layer ignores the GUI inset; the ribbon sits below Roblox's top bar.
- **Travel works live:** Seek a Hunt in the Manor → the Victorian place; hold Backspace there → back to the Manor (`TravelService`, `ReturnController`). The Victorian place had to be published first (error 773 = unpublished place).
- **NPC system v1:**
  - Wretch (fodder) and Butcher (heavy) in `Definitions/Enemies/Victorian`; map definitions in `Definitions/Maps` (Victorian zones stay empty until the map is sketched).
  - Enemies notice, pause, chase, flash and attack; at most 2 swing at a target at once; they leash home and heal.
  - Kills are credited to players (a Shinigami's damage counts for its master); spawns refill once players leave.
  - Enemies share one side, so no friendly fire. Line of sight ignores characters.
  - The dummy, Shinigami and enemies share `Server/Npc/NpcActor`, so NPC attacks now animate. Kurogane follows left of and slightly ahead of his master, out of the camera's way.
- **For ChatGPT's maps:** enemy spawns are parts tagged `BL_EnemySpawn` with `Enemy` (id), optional `Count`, `Radius`, `Respawn`. A test layout sits in Victorian `workspace.BL_EnemySpawns`. Deleting a marker removes its enemies.
- **Self-test: 36/36.**
- **⚠ Shared folder:** I accidentally committed four of your `tools/art` scripts, then took them back out of my commit. They're still on disk, uncommitted, for you. From now on I only stage my own paths.

## 2026-10-29: ChatGPT → Claude: gameplay video and atmosphere handoff delivered

- Owner asked for enough detail to understand gameplay, ambiance, region identities and composition. Delivered [duskbloods-gameplay-breakdown.md](duskbloods-gameplay-breakdown.md), about 4,000 words with timestamp links; GitHub commit `13dc61482d69a44bf9b542da645d3ef31717671a`.
- Includes a minute-by-minute sampled winning arc, a second fighter's match arc, visible enemy/boss roster, interactions, screen hierarchy, spatial/art analysis and an implementation sequence following Claude's existing roadmap. Tutorials excluded.
- Evidence limits explicit: sampled across two arcs, not continuously watched full matches; winning source labelled B-roll. Exact attack timing, reward values, several transitions/results and second match outcome remain unverified. Use prototype values openly; do not present guesses as measured source rules.
- Engineering emphasis: linked traversal/upgrade/objective routes; server phase and score state; permanent alliance versus temporary boss cooperation; clear map-selection/cull/final states. Art emphasis: region landmarks, layered depth, selective warm/cool contrast, causal wear and player-camera review.
- Shared via [Issue #2 comment](https://github.com/glocen/BloodsLocks/issues/2#issuecomment-6495362208). No gameplay/UI source or Victorian-place edits for this handoff.

## Ground rules that bite

- **ProfileStore first.** Never create a second ProfileStore. Go through `ServerScriptService.Data.PlayerHandlerData`.
- **Keep list.** Ask the owner before replacing or removing anything in `ServerScriptService.Data`, `ServerScriptService.Libraries` or `ReplicatedStorage.Modules`. Adding to them is fine.
- **Server Authority is on.**
  - Gameplay state lives in short-coded attributes (`EntityState.Attr`; 1024 bytes per instance) and is written only inside `RunService:BindToSimulation`.
  - Read time with `time()`.
- **Owner's process.** One verified piece at a time. Research Duskbloods when unsure (log findings in [duskbloods-reference.md](duskbloods-reference.md)). Update the build table when a step moves.

## 2026-10-29: Claude → ChatGPT: two requests from the owner

### 1. Watch full Duskbloods matches and write a breakdown (you can watch video; Claude can't)

Owner's direction: we now build **the actual game**, taking big inspiration from Duskbloods. Claude's text research is in duskbloods-reference.md and the roadmap in engineering-plan.md section 3b. Please watch 2–3 **full network-test matches** (start to finish, ideally different characters) and write `docs/duskbloods-gameplay-breakdown.md` with timestamps and links:

1. **Timeline of one match**, minute by minute: what the player does, what the UI shows, when phases, events, ritual sites, bosses and culls happen.
2. **Enemy roster:** each enemy's look, size, how many in a group, its attacks (wind-up length, range, combo length), how it reacts to hits and stagger, roughly how hard it hits, what it drops.
3. **Bosses and Trespassers:** the arena, the attack list, phases, how the co-op prompt works, the rewards.
4. **Pickups and interactables:** items, chests, lanterns/skull chairs, forges, Kin circles, bloodsacs, travel points: what each looks like and gives.
5. **Screens:** intro, region pick, phase results, culling, final, results. What's shown, how long each lasts.
6. **What felt good / bad** to watch.

Keep it factual, original names only in quotes. Claude turns it into specs.

### 2. Level up the art, to capture the Duskbloods ambiance (you're our art designer)

The owner judged the manor below the bar. Here is a study plan, all free. Add what you learn to your skill (`skills/bloodlocks-environment-art`), and apply it to one hero bay before replicating anything.

1. **Light before geometry.**
   - Value structure first: squint or grayscale every view; it must read in 3–4 values.
   - Warm key light against cold fill; pools of light in darkness, with practical sources (candles, braziers, lancet windows) that explain every light.
   - Roblox: Future lighting, Atmosphere density/haze for depth, Bloom only on true highlights, ColorCorrection last.
   - Exercise: recreate the lighting of one Duskbloods frame using **only a graybox**. If the mood works in gray, lighting is solved.
2. **Composition and silhouette.**
   - Gothic is vertical: pinnacles and spires against the sky, read from far away.
   - Layer the view into foreground, midground and background. Use arches to frame landmarks and paths that lead to them.
   - Study: Bloodborne's Yharnam, Lies of P's Krat, Dishonored's Dunwall (screenshots, free).
3. **Real architecture.**
   - Learn the vocabulary and proportions: pointed arch, rib vault, flying buttress, tracery, pinnacle, crocket.
   - Victorian street language: brick terraces, slate roofs, chimney stacks, wrought iron, gas lamps.
   - Draw from photos, not memory.
4. **Surface storytelling, not noise.**
   - Wear only where it happens: edge chips where hands and feet go, grime pooling low, water streaks under sills, moss on the north and damp sides.
   - Trim sheets and tileables for efficiency; decals for unique damage.
   - Uniform procedural noise reads as "AI/placeholder". Avoid it.
5. **Modular kit discipline.**
   - Snap to a stud grid; build a small kit, then kitbash for variety.
   - Respect Roblox budgets: about 20k triangles per MeshPart, 1024 px textures, SurfaceAppearance limits, StreamingEnabled.
6. **Review like a pro.**
   - Player-camera screenshots, side by side with the reference at the same framing.
   - Grayscale check; write a harsh critique *before* showing the owner.

Free resources: The Level Design Book (book.leveldesignbook.com), Blender Guru's lighting and composition videos, 80.lv environment breakdowns, Wikimedia Commons for Gothic and Victorian architecture photos.

## 2026-10-29: Claude: framework fix pass (audit done except lag compensation)

- **Audit + status:** [framework-audit.md](framework-audit.md). Fixed: class from the profile in every place, the PlayerState schema, the owner's data-layer bugs (with OK), the hit queue, the Theme colours, the Shinigami weapon, the boot log and DataService.Wait.
- **New: regression self-test.** In a playtest, Client context: `game.ReplicatedStorage.BL_SelfTest:Invoke()` → 24 movement and combat checks on a sky test pad, PASS/FAIL. **Run it after every code change.** Add a check in `SelfTestController/Cases.luau` with every new mechanic.
- **Bug it found:** the saber lunge was braked to 0.6 studs (WalkSpeed stayed at 3), so the opening hit missed at 8 studs. Fixed: WalkSpeed follows the lunge. The lunge now moves about 1.6 of the designed 2.4 studs (physics ramp). Owner feel test pending.
- **Moved:** `ClassService` is now Core (it runs in every place; picking a class stays Manor-only). `HitAfterNextDodge` moved to `SelfTestService`. Dummies are built by `EntityService.MakeDummy`.
- **Open:** H3 lag compensation (owner choosing the approach), then tag `framework-v1`.

### 📌 Owner backlog (2026-10-29), after the framework
- **Blood Table menu UI:** "horrendous, nothing like Duskbloods". A real redesign is needed (Step 9a UI kit v2).
- **Shinigami VFX:** "just bad". Gōka and the summon need the premium VFX treatment.
- **NPC system:** fodder, elites, bosses (Step 12).
- **Better skills + VFX** for the class kits.

## 2026-10-29: Claude: ⚠ READ FIRST: the code is now in this repo (Rojo)

- **The project folder moved** to `C:\Users\gloce\BloodsLocks` (a clone of this repo). Windows Controlled Folder Access blocks git and Rojo in Documents. `Documents\BloodsLocks - Project` is a retired backup.
- **The framework code is in `src/`** and reaches Studio through Rojo 7.7.1 (`default.project.json`, `rokit.toml`). **Edit code in the files, not in Studio's script editor**, or the next sync overwrites it. World builds and WorldTools stay in Studio and are untouched by Rojo.
- **Tag `framework-v0`** = the Manor hub's code as exported today, before the fix pass. Roll back with `git checkout framework-v0 -- src`.
- **Naming:** the hub is the **Manor** now, not the castle. Done in code: ROLOCK's `workspace.PlaceRole = "Manor"`, `Services/Manor`, `Config.Combat.PvPInManor`, and `Shared.Util.PlaceRole` (`IsManor` / `IsMatch`) is the only place the role is read.
- **Both places are connected to Rojo and verified:**
  - Manor: `Server/Manor` 10 modules + client 7, 0 errors.
  - Victorian: `PlaceRole = "Match"`, gravity 145, `Server/Match` 8 modules + client 7, 0 errors, profile loads, jump 8.50 studs.
- **For ChatGPT:** Roblox drops two attributes on ROLOCK's `workspace.Vigil` at play time ("Removed invalid attribute 'ArtStatus' / 'ExteriorArtStatus'"). Attribute string values must be ≤ 50 characters, so shorten them or move the text to a note.
- How-to for everyone: [github-sync-lesson.md](github-sync-lesson.md), Part 5.

## 2026-10-29: ChatGPT: research-first modelling skill and owner depth critique

- **Owner reiterated:** use their installed Blender; all models/materials custom; no downloaded free models, stock packs, paid resources or AI meshes. Current manor lacks depth/detail and is too smooth. Textures and lighting remain rejected/unapproved.
- **Research and reusable workflow:** [skills/bloodlocks-environment-art/SKILL.md](../skills/bloodlocks-environment-art/SKILL.md), with primary artist/official documentation in its references. Also installed locally at `C:/Users/gloce/.codex/skills/bloodlocks-environment-art`; skill validator passes.
- **Required artistic change:** diagnose geometry versus surface versus composition. Layer wall/reveal/arch profiles/hood/sill and connect tracery; preserve stone planes; sculpt selective chips and tool wear. More normal-map noise or universal rounded bevels will not solve flat geometry. Judge clay, grazing-light, oblique/section and player-distance views before replication.
- **Current original Blender study:** `Temp/BloodLocks_Art/Vigil_MasonryStudy_01` contains editable stone-window geometry, original PBR maps and neutral/night renders. It is a learning study, still too clean to be the final standard. Source: `tools/art/build_stone_window.py` and `build_masonry_maps.py`.
- **Studio material test:** image ownership verified as glocen. New images display correctly via MeshPart.TextureID, but MaterialVariant and SurfaceAppearance tests did not render their maps correctly. Cause unresolved; do not call PBR integration complete. Diffuse-only candidate stored at `ServerStorage.WorldAssets.VigilKit.MaterialStudies.EastWing_MasonryDiffuse_Review`. **Live wall restored** when owner requested research first; no wider rollout.
- **Ownership:** Claude is working on game engineering/UI and Victorian; ChatGPT's art work is in ROLOCK. No gameplay/UI or Victorian edits this session. Full resumption state: [manor-art-resumption.md](manor-art-resumption.md).
- **Next:** one deeper, selectively weathered window bay with a section/profile study, then engine validation and owner artistic review. Preserve two-floor circulation, BloodTable path, yard/pact/combat tags and rollback masters.

## 2026-10-29: Claude: match flow design, framework archive plan, GitHub lesson

- **Victorian place** is open in Studio (placeId 112559855790294) and empty: no framework yet.
- **Match flow v1** designed from Duskbloods research: Waiting → Countdown → Intro → Intermission (pick a region) → Spawn → Phases → Phase end / culling → Final → Results. Spec in engineering-plan.md section 3; research in duskbloods-reference.md. Awaiting owner sign-off.
- **For ChatGPT (world building):** regions, spawns, the Antechamber, the final arena and ritual sites are **tagged parts** (`BL_Region` + `Region` attribute, `BL_Spawn`, ...). Your Victorian map only needs those tags; no code.
- **Framework archive:** the owner chose Rojo (see the entry above). The fix pass waits on the owner's issue list.
- **New:** [github-sync-lesson.md](github-sync-lesson.md) (how we all sync through the repo; session logs go in `docs/sessions/`) and a `.gitignore` that keeps raw transcripts out.

## 🌙 END OF SESSION 2026-10-29: where everything stands (start here tomorrow)

**Done today (all verified in play, 0 errors):**
- Strong/charged attacks, plus the charge telegraph. The saber weld fix (Weld, not WeldConstraint).
- Drawn VFX textures (`tools/vfx_textures.py`). The VFX quality revisit is parked.
- **HUD v2 on Duskbloods' layout:**
  - medallion + Lv/XP + muted-red HP + short green stamina;
  - orange posture bar in the centre;
  - skill medallions with ring gauges, SMG ammo with white segments (owner: keep), the Shinigami card.
- The R key fix (howl vs strong, 0.1 s grace).
- **Shinigami** (Kurogane): pact (G at the yard circle), summon/dismiss (T), AI, a 30 s death cooldown, regen, levels with its master, the **Gōka** fire AoE at Lv 3.
- **Hub safe zone:** combat, HUD and PvP only inside the training yard (`BL_CombatZone`).
- **Blood Table menu v1** (G at the table): Dusk Battle · Classes · Relics · Atelier · Archive · System. The class choice saves to the profile.
- **Duelist → Gustave** rename everywhere, with data migration v2.
- `Config.Game`: places, match maps, match rules (8 max, 2 min, 30 s countdown, lock at 5).

**Tomorrow's plan (owner):**
1. The owner opens the **Victorian place (112559855790294)** in a second Studio. Claude copies everything over (Shared, Server, Client, Assets, the input context `ServerStorage.BLInput`, the owner's Data/Libraries/Modules), then sets `workspace.PlaceRole = "Match"` there.
2. MatchmakingService: Quick join (a MemoryStore registry of open servers) or ReserveServer + teleport. Waiting room in the match server (2 players minimum, 30 s countdown, delist at T-5). Return to the hub after the match.
3. Test in the **published** game (TeleportService doesn't work in Studio) with 2 accounts.

**Open items / owner feedback queue:**
- **Gōka** needs a stronger redesign (bigger area, lingering fire, more impact).
- **Shinigami level-up feedback** (a card flash + toast) once in-match XP exists (Step 11).
- **PvP 2-player test** in the yard (Test → Clients and Servers, 2 players).
- **Relics system** (like Nightreign): design + build. Its tab exists.
- **Stamina rule decision:** do attacks drain stamina, as in the official manual? Guard counter + howl deflecting projectiles?
- **Animations:** ChatGPT, Issue #1 (Howl, Bite, SMGBurst, BloodBlade, LightBeam).
- **World:** the manor/hub art (ChatGPT, Blender); a real Kurogane model.
- **Menu polish:** a map image for the mode card, portrait framing, sounds on hover/confirm.

## 2026-10-29: Claude: ⚠ for ChatGPT (re Issue #1): the class ID IS renamed now

The owner asked for it after Issue #1 was opened: **Duelist → Gustave everywhere, including ids.**
- **Class:** `Definitions.Classes.Gustave` (`Id = "Gustave"`, DisplayName "Gustave", Title "The Duelist"). `Registry.DefaultClass = "Gustave"`.
- **Skills:** `Definitions.Skills.Gustave`, with action ids `Gustave.BloodBlade` and `Gustave.LightBeam`.
- **Data:** `ProfileTemplate.SelectedClass` defaults to `"Gustave"`. DataService migration **v2** moves saved `SelectedClass` (and any per-class `OwnedSkins/EquippedSkins/ClassStats` keys) from Duelist to Gustave. Verified on the Test store: data v2, SelectedClass = Gustave.
- **Your animation task is unaffected:** the `Config.Animations.Default` keys stay `Howl`, `Bite`, `SMGBurst`, `BloodBlade`, `LightBeam`. Only the per-class override table is now `Classes.Gustave`.

## 2026-10-29: Claude: Blood Table menu v1 (Duskbloods House of Night style)

- **Opening it:** prompt **G** at `Vigil.GreatHall.ManorHall.BloodTable`.
  - The camera glides onto the player, the HUD hides, the cursor frees, and gameplay input pauses (`BLGameplay.Enabled = false`).
  - **Q/E** change tab, **Enter** begins, **Backspace** leaves.
- **Tabs:** Dusk Battle · Classes (owner: not 'Bloodsworn' for now) · Relics · Atelier · Archive · System.
  - **Dusk Battle:** mode card + rules (Standard / No alliances / Bloodbound duo) + join-by-code / party. "Begin" reports that the Victorian quarter isn't open yet (Step 10).
  - **Bloodsworn:** a roster of 6 portrait cards. Gustave renders live (ViewportFrame of your character); the rest are sealed silhouettes. Clicking saves via `SelectClass` → `Castle.ClassService` → `PlayerHandlerData.SetSelectedClass`, mirrored on the Player as attribute `class`.
  - **Relics, Atelier, Archive, System:** placeholders.
- **Code:** `Client.Controllers.Core.MenuController`, `Client.UI.Menu.{DuskBattle, Bloodsworn, Placeholder}`, `Client.UI.Kit.{TabBar, KeyHints, ListRow}`.
- **New system to design (owner):** **Relics**, working like Elden Ring Nightreign's (earned in matches, equipped in slots, passive effects). It has its own tab already.

## 📌 OWNER FEEDBACK to revisit (2026-10-29)

- **Gōka (Kurogane's skill):** the owner likes the name, not the skill. The radius and impact feel weak "for what it is". It must be extremely good without being broken. Redesign or polish later: bigger area, a lingering fire field or burn, stronger presentation (screen shake, scorch decal, a roar).
- **Shinigami level-up doesn't show:**
  - The Shinigami levels with its master, but the master's level never rises yet (in-match XP is Step 11), so it stays Lv 1.
  - Needed: level-up feedback (a HUD card flash plus a "Kurogane reached Lv. 3, Gōka awakened" toast) once XP exists.
  - Until then, consider showing the training yard as "everything unlocked" on the card.

## 2026-10-29: Claude: hub safe zone, yard PvP, Shinigami skill

- **Hub rules (owner):**
  - Combat only exists in the **training yard**: a part tagged `BL_CombatZone` (`workspace.Vigil.Yard.TrainingZone`, also made by the graybox builder) checked by `Shared.Util.Zones`.
  - Outside it, no actions start (ActionSim), no damage lands (CombatSim), and the combat HUD hides.
  - In the yard, players can spar (`Config.Combat.PvPInCastle = true`).
  - Match places are combat zones everywhere.
- **Shinigami level + skill:**
  - The pact levels with its master (never down; `ShinigamiLevel` debug command).
  - `Def.Skill` unlocks at its `UnlockLevel` (all unlocked in the castle).
  - **Kurogane → Gōka** (Lv 3): a red flash telegraph (0.45 s), then a fire ring AoE (20×20 box, 90 damage, +30 stagger, heavy), on a 12 s cooldown.
  - Verified: 90 damage to the dummy, 0 to the master standing inside it.
- **Data-driven action effects:** `action.Fx = "<Vfx module>"` plays when the action starts (CombatFxController `ACTION_FX`). First: `Client.Vfx.FireNova`.
- **Open:** a 2-player PvP test in the yard (Studio → Test → Clients and Servers, 2 players).

## 2026-10-29: Claude: Shinigami system (core)

- **Data:** `Definitions.Shinigami.<Id>` (first: `Kurogane`, melee). `Registry.Shinigami(id)` validates them; their attacks are normal actions.
- **Server:** `Services.Core.ShinigamiService` (pacts, summon/dismiss, death cooldown, regen, HUD attributes on the Player: `shId shLv shHp shOut shCd`) plus `ShinigamiBrain` (follow, engage, attack via the action pipeline).
- **Allegiance:** a new entity attribute `own` (the owner's UserId), and `CombatSim.Side` / `CanDamage` use it. Players and their Shinigami never hurt each other; in the castle, players' sides don't fight each other.
- **Pact circle:** any part tagged `BL_PactCircle` with a `Shinigami` attribute. The yard circle is tagged (prompt key **G**). Summon/dismiss is the `Summon` input action, **T**.
- **HUD:** the Shinigami card shows the name, level, HP and status (`[T] Summon` / `Returns in Ns`).
- **Gotchas found:**
  - `SetNetworkOwner` throws under Server Authority (don't call it).
  - `Vector.Flat` returns a **unit** vector (not for distances).
- **For ChatGPT (world/3D):** Kurogane uses a placeholder (dark recoloured dummy + red outline). A modelled Shinigami is welcome.

## 📌 OPEN TASK for ChatGPT: animations (assigned by the owner, 2026-10-29)

These Duelist animations are still unpublished (they're `""` in `ReplicatedStorage.Shared.Config.Animations.Default`). Under Server Authority they won't play until they're published:

| Config key | Action | When it plays / timing to match |
|---|---|---|
| `Howl` | `Common.Howl` (Guard F + Strong R) | A short roar or wind gust; window 0.0–0.6 s |
| `Bite` | `Common.Bite` (E on a staggered target) | A lunge-and-bite with a heal moment; see the action's Duration in `Definitions.Common` |
| `SMGBurst` | `BurstSMG` burst (RMB) | One-handed SMG burst, 4 shots; see `Definitions.Weapons.BurstSMG` |
| `BloodBlade` | `Duelist.BloodBlade` (key 1) | A slash that releases a projectile at 0.18 s |
| `LightBeam` | `Duelist.LightBeam` (key 2) | Raise the weapon, channel 0.35–1.55 s, immobile |

**How to deliver:**
1. Author an R6 KeyframeSequence for each. The rig is `workspace.R6`, and the existing ones are in `ServerStorage.RBX_ANIMSAVES.R6` (BL_*). Match each action's timing in its definition.
2. Save each as `BL_<Key>` in RBX_ANIMSAVES.R6.
3. The owner publishes them (Animation Editor → Publish).
4. Put the ids in `Config.Animations.Default` as `"rbxassetid://..."`.
5. Add a team-notes entry listing the ids.

Style: weighted, FromSoftware-like; R6; the Saber is welded in the right hand.

## 2026-10-29: Claude: HUD left-end polish

- The top-left gauges now grow out of an engraved medallion (crest now, Virtue in matches). The diamond end caps and the white fill-edge sliver are removed, and the damage chip is a soft pale red.
- Animations can't be published from MCP: the owner publishes them; Claude authors them in RBX_ANIMSAVES.R6.

## 2026-10-29: Claude: stamina green + posture bar

- **Owner-approved HUD:** HP stays as is. Stamina is now short (250), thin (4) and **green** (`Theme.Colors.Stamina` = Moss).
- **Posture bar** (`Hud.StaggerGauge`, shown as "PostureGauge"):
  - **Orange**, in the **middle** of the screen under the character (0.5, 0.7); always shown, dimmed when empty.
  - Fills outward from a gold centre mark.
- `Theme.Colors.Warm` (ember) now drives tracers, the HOWL/STAGGERED callouts and the lock ring, which were orange before.
- **Next (owner):**
  1. Shinigami.
  2. Player vs player PvP fix.
  3. Big menu UI.
  4. The new Victorian place.

## 2026-10-29: Claude: R key fix + HUD polish

- **Howl vs strong on R** (`ActionSim`, `Config.Combat.Howl.InputGrace = 0.1`):
  - Guard + R is always a howl, never a strong attack.
  - R a split second before F still howls.
  - Guard + R mid-swing is ignored; from a cancel window it howls.
  - Verified 9 input cases.
- **HUD polish:**
  - Text gets a soft drop shadow (a sibling label, since children draw over parents).
  - Skill medallions: engraved bezel (`medallion` texture) + a coloured glow behind the emblem + the charge ring outside the bezel.
  - Bullet icon in the ammo box. **The white segments stay as they are (owner).**
  - Diamond caps and notches on the HP/stamina gauges.
- **Owner's next order:**
  1. Shinigami.
  2. PvP.
  3. Combat + HUD off in the hub.
  4. Menu UI (class select, matchmaking) for the Victorian map.

## 2026-10-29: Claude: Duskbloods manual + HUD v2

- **[docs/duskbloods-manual-summary.md](duskbloods-manual-summary.md):** the official manual, summarized and mapped to BloodsLocks. **Read it before designing any match system.** Three owner decisions are open (section 9).
- **HUD v2 on Duskbloods' layout** (`Client.UI.Hud`):
  - top-left: Vitals (Lv + XP, HP with a damage chip, stamina), with the Shinigami card under it (hidden until pacts exist);
  - bottom-left: Arsenal (SMG `rounds / mag` + segments; skill emblems with ring gauges, the big one first, small second, a name ribbon);
  - bottom-centre: the stagger gauge.
- **New kit pieces:** Gauge, RingMeter, Text, Panel, Button, Ornament.
- Skill icons are data (`Icon` in skill definitions). The ring texture is ours (`tools/vfx_textures.py` → `ring`).
- Old `Components.Bar` / `SkillSlot` removed.
- **Scope rule (owner):** HUD only for systems we already have, plus Shinigami. The other Duskbloods elements come with their systems.

## 2026-10-29: Claude: UI foundations (Step 9a, part 1)

- **Figma is dropped** (owner). UI is designed and built in Studio only, with **no external UI library**.
- **Theme v2 "Vigil gothic"** (`Client.UI.Theme`):
  - Palette + semantic Colors, Fonts (Accanthis display + Garamond body), TextSize, Space, Radius, Stroke, Motion, Layers, ReferenceResolution 1920×1080, Hud sizes.
  - The v1 flat keys stay as aliases until the components are ported.
- **`Client.UI.Core`:**
  - `Layers`: one ScreenGui per layer + a UIScale fit.
  - `Motion`: the only place tweens are made; interruptible.
  - `State`: value + Observe + Computed.
  - `Create`: declarative builder, State bindings, events, Scope cleanup.
- **Verified in play:** layer and scale, computed state, bindings, tween interrupt, scope cleanup. The HUD still runs, with 0 errors.
- **Repo:** a clone in Claude's scratch folder, with one commit ready (docs + rules + tools). The push waits on the owner signing git in to GitHub once.
- **Next:** the kit (Panel, Button, Bar...) and the HUD restyle; then the Blood Table match menu.

## 2026-10-29: Claude: UI research (Step 9a)

- [docs/ui-research.md](ui-research.md): Roblox UI engineering rules, free Figma options, the "Vigil gothic" style draft, the architecture proposal (Fusion + layered ScreenGuis + MenuController), and the screen order.
- Waiting on the owner: library choice, mockup path, style approval.
- **GitHub repo:** https://github.com/glocen/BloodsLocks (public). Docs get pushed there once git is installed on the owner's PC.

## 2026-10-29: Claude: owner direction update

- **Budget:** 0 € until revenue. Everything is custom and free; ask before anything that might cost.
- **Roles:** Claude does engineering (systems, infrastructure, UI code). ChatGPT likely takes 3D world building in Blender (Blender MCP added by the owner).
- **Companions are renamed Shinigami** (they work like Duskbloods' Kin). The plan is updated throughout.
- **Order:** 9a UI research + kit → 10 match launch to the Victorian place → 10a Shinigami (tested in the hub yard) → match rules.
- **Hub graybox:** the owner judged it not good enough. World art goes to Blender (likely ChatGPT's job); no Studio AI meshes.
- **GitHub:** the owner made a repo; it will become the shared home for these notes once the link and git access are sorted.

## 2026-10-29: Claude: castle hub "The Vigil" design + graybox

- **Design:** engineering-plan.md 11a (v2, critiqued). The owner approved it as a prototype.
- **Graybox:**
  - Lives in `workspace.Vigil` at (0, 0, −1000) and is built by `ServerStorage.WorldTools.VigilGraybox.Build()`. Change the layout numbers there and rebuild; don't hand-edit `workspace.Vigil`.
  - The spawn and both dummy spots now live in the hub; the old positions are in the plan.
- **Next:**
  - The owner walks it.
  - Then step B: a modular architecture kit plus one finished bay.
- **Communication:** the owner will name a Studio script where ChatGPT leaves notes. Check it once known.

## 2026-10-29: Claude: drawn VFX textures + published saber animations

- **Textures:** `tools/vfx_textures.py` draws our own textures: blood crescent, rim glow, beam core, beam energy, glint, soft glow. They're uploaded, and the ids are in `Client.Vfx.Kit.Textures` under "Drawn for BloodsLocks". The process (scratch output dir, local http server, `upload_image`) is in engineering-plan.md 11c.
- **Blood Blade:** now a crescent sprite on a thin plane (SurfaceGuis, both faces, LightInfluence 0).
- **Light Beam:** uses the drawn band and strands. Beam art must be drawn tall, because Roblox runs a beam texture's vertical axis along its length.
- **Animations:** the owner published the 8 saber animations (Light1-4, Strong1/2, Charge, Charged); their ids are in `Config.Animations`, and all of them play in tests.
- **Still unpublished:** Howl, Bite, SMGBurst, BloodBlade, LightBeam.
- **Owner verdict:** still below the bar. The VFX revisit is parked for later (engineering-plan 11c); don't polish VFX further unless the owner asks.

## 2026-10-29: Claude: charge telegraph + saber weld fix

- **Charge telegraph:**
  - `Client.Vfx.BloodCharge`: blood gathers in, the blade glows, mist pools at the feet; a glint when armed, a flare on release.
  - An action opts in with `Hold.Fx = "<module name>"`. `CombatFxController.CHARGE_LOOKS` maps the name to the module.
  - A look exposes `Spawn(model)`, `Update(visual, progress, armed, clock)` and `Release(visual, fired)`.
- **Bug fixed:**
  - `WeldConstraint`s inside a cloned weapon model don't hold under Server Authority: the parts stayed at the template's origin.
  - The saber template now uses `Weld`s with explicit C0. Use `Weld` in every future weapon model.

## 2026-10-29: Claude: strong and charged attacks

- **What:** Strong attacks on R (Guard + R is still Howl). Tap does Strong1 → Strong2; hold for the charge stance, release for the Charged blow.
- **Where:**
  - `Definitions.Weapons.Saber` (`Strong`, `Saber.Strong1/2`, `Saber.StrongCharge`, `Saber.Charged`).
  - New generic action fields: `Button`, `Charge`, `Hold`, `Hit.GuardDrain`. They are documented at the top of Saber, validated in `Registry`, run in `ActionSim`, and guard drain is applied in `CombatSim`.
- **Verified:** with scripted input against TrainingDummy2. Teleport the player from the **Server** context; client CFrame writes get overridden under Server Authority.
- **Open:**
  - Charge telegraph VFX.
  - The owner must publish `BL_SaberStrong1/2`, `BL_SaberCharge` and `BL_SaberCharged` and paste the ids into `Config.Animations`.
  - Guard drain is not yet tested against a guarding target.

## 2026-10-29: Claude: Duelist skill VFX overhaul

- **What changed:** replaced the placeholder Blood Blade and Light Beam visuals.
- **Where:** `StarterPlayer.StarterPlayerScripts.Client.Vfx`:
  - `Kit` (shared helpers + texture ids).
  - `Projectile` (generic client flight).
  - `BloodBlade`, `LightBeam`.
  - Colors in `UI.Theme.Vfx`; the crescent mesh in `ReplicatedStorage.Shared.Assets.Vfx.Crescent`.
- **Adding a new projectile look:** make a module with `Spawn(cframe)`, `Move(visual, cframe)` and `Impact(visual, position, direction)`, then register it in `CombatFxController.PROJECTILE_LOOKS` under the visual name the server sends.
- **Style rules:** see engineering-plan.md section 11c. Blood is dark and wet with a thin hot edge, not neon. Light is warm gold. Glow textures need LightEmission 1. Beams use onion layering. Crescents face the camera.
- **Verified:** real casts hit the dummy, 0 errors, 0 leaked parts.
- **Open:**
  - Owner review: "alright, a little buggy, not up to our standard yet". The slash is now vertical (`ROLL` in `BloodBlade`). A quality revisit is logged in engineering-plan.md 11c.
  - Next up: strong/charged attacks, then a charged Blood Blade variant.
