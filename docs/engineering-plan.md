# BloodsLocks engineering plan

Locked 2026-10-28. This file is the source of truth. Locked decisions change only with the owner's OK. Values marked *(tune)* are starting points to adjust by feel.

## 1. The game

BloodsLocks is a PvPvE action game. Players gather in a castle hub, pick a class, and enter 8-player matches on large, vertical maps (first world: Victorian gothic; later worlds from other eras). A match runs four phases scored by Virtue. The lowest-Virtue players are culled at the end of phases 2 and 3, and the last three fight a 2-life battle royale. Every match pays out Bloodgems, which buy class skins in the castle.

Inspiration: FromSoftware's The Duskbloods (movement, combat, match structure, hub). Names, characters, lore and art are original.

## 2. Locked decisions

| # | Decision | Notes |
|---|---|---|
| 1 | Movement and combat run in shared simulation code under Roblox Server Authority | `Workspace.AuthorityMode = Server` (the owner sets it in Properties; MCP scripts can't). If the movement step fails its checks, fallback is client authority + server validation using the same step code. |
| 2 | Separate places, one codebase | Castle = this place (ROLOCK). One Match place per world map. Studio-first; the code layout mirrors a Rojo project, so a later switch is a one-time export. Choose Rojo or Roblox Packages for cross-place code sharing when the first Match place is created. |
| 3 | The waiting room lives inside the reserved match server | MemoryStore registry with atomic slot reservations; the server delists itself when it locks. |
| 4 | One entity pipeline | Players, NPCs, bosses and Shinigami share Entity → Action → Hit → Damage. An allegiance model decides who can hit whom. |
| 5 | Data-driven content | Classes, weapons, actions, abilities, passives, Shinigami, skins, NPCs and modes are definition modules validated at boot. |
| 6 | One combat state machine + tags | Replaces scattered true/false attributes. |
| 7 | R6 rigs | All existing content is R6; 6 joints keep animation production fast and snappy. |
| 8 | PC only for now | All gameplay input goes through the Input Action System, so gamepad and touch stay cheap to add. |
| 9 | The owner's ProfileStore system stays the data layer | `ServerScriptService.Data` (DataInit, PlayerHandlerData, ProfileTemplate, ProductManager). No second ProfileStore. New fields go in ProfileTemplate (`Reconcile` fills old saves); new mutations go in PlayerHandlerData in its style. |
| 10 | PvPvE | Fodder, elites, roaming bosses, minions, Shinigami companions. |
| 11 | Free aim + lock-on auto-aim | Crosshair aim by default; while locked on, ranged attacks aim at the target. |
| 12 | Class choice only in the castle | |
| 13 | Parties and private lobbies ship in v1 | |
| 14 | Budget is 0 € until the game earns revenue (owner, 2026-10-29) | Everything is custom and free. Always ask before using anything that could cost money, credits or quota. The owner is the director; the vision is the priority. |
| 15 | Companions are named **Shinigami** (owner, 2026-10-29) | They work exactly like Duskbloods' Kin (pact circles, roles, levelling, recall). The rename is game-facing; code ids use `Shinigami` too. |
| 16 | Team roles (owner, 2026-10-29) | Claude: engineering (systems, infrastructure, UI code, quality). ChatGPT: likely 3D world building in Blender (via the Blender MCP). Both coordinate through the GitHub repo docs. |
| 17 | First match map: Victorian era | It's its own place in the experience. The hub launches matches there and returns players afterwards. |

## 3. Match rules

### Lobby (inside the match server)

- Max 8 players, min 2. *(tune)*
- A 30s countdown starts at 2+ players, cancels if the count drops below 2, and shortens to 10s when the lobby is full.
- Joins close at T-5s, when the server removes its registry entry (it disappears from the castle list). Late arrivals go back to the castle.

### Phases

| Phase | Length *(tune)* | Rules |
|---|---|---|
| 1 | 6 min | Nobody is eliminated. Farm Virtue, level up, find Shinigami. |
| 2 | 5 min | At the end, the lowest-Virtue players are culled. |
| 3 | 5 min | At the end, the lowest-Virtue players are culled again. |
| 4 | Until one remains (4 min cap, then sudden death) | The top 3 (or fewer) fight in a closed arena with 2 lives each. Last survivor wins. The top-Virtue finalist gets a bonus HP buff. |

- Cull counts: `finalists = min(3, players)` and `cut = players - finalists`. The end of phase 2 culls `floor(cut / 2)` and the end of phase 3 culls the rest. With 8 players: 2, then 3.
- Ties go to whoever reached the score first.
- Respawns in phases 1–3 are unlimited after a 5s delay *(tune)*: pick a map region, land at a random spot in it. Time spent dead is Virtue not earned; that's the only death penalty.
- Culled players spectate or return to the castle; they still get rewards.

### Match flow, start to finish: design v1 (2026-10-29, awaiting owner sign-off)

Heavily based on Duskbloods' Dusk Battle (research in docs/duskbloods-reference.md, "How a match starts and runs"). Duskbloods shows no lobby or intro, so those two states are our own. The owner will cut what they don't like later.

One server state machine, `MatchService` (Match role only), with every duration in `Config.Match` *(tune)*:

| State | Length | What players see and do |
|---|---|---|
| **Waiting** | until 2+ players | The **Antechamber**: a small candlelit waiting room in the match place, with a relief of the map. Players can move but not fight. A list shows who has arrived. |
| **Countdown** | 30 s (10 s when full) | A bell tolls each 10 s. Joins close at T-5 and the server delists itself (locked decision 3). |
| **Intro** | 8 s | Screen fades to black; title card "The Dusk Hunt" + the world's name; a camera flyover of 3 landmarks; the 8 hunters shown with class and name. |
| **Intermission** (before phases 1, 2, 3) | 20 s (phase 1), 15 s after | The **map screen**: regions with this phase's **regional features** (icons: skill boon, Shinigami boon, forge, Flame Virtue). Click a region to pick it. Each region holds `ceil(players / regions) + 1`; overflow is moved to a random other region; no pick = random region. |
| **Spawn** | — | A random spawn point inside the region, at least 60 studs from other players when possible. Rise from a pool of blood-mist; 3 s spawn protection that ends early if you attack. |
| **Phase 1** | 6 min | Clock dial top-right. Explore, kill, level, find Shinigami. No ritual site. |
| **Phase 2 / 3** | 5 min each | The clock's shining dot (at 40 %) raises a **Ritual Site** that everyone is called to; leaving it after entering drains HP. At the red dot the phase ends. |
| **Phase end** | 8 s | Commendations awarded (top 2 kills, top 2 items), then the **culling screen**: the cut players' portraits burn away. Culled players choose spectate or return to the Vigil. Flasks refill. |
| **Final** | until one remains (4 min cap, then sudden death) | The top 3 are moved to the final arena. 2 lives each, max HP + a bonus from earned Virtue. |
| **Results** | 12 s | Placement, Virtue, kills, Bloodgems earned, then everyone teleports back to the Vigil. |

**Map data, so world builders never touch code:** each map is a definition (`Definitions/Maps/Victorian`) listing its regions. In the world, regions are parts tagged `BL_Region` with a `Region` attribute, and spawn points are parts tagged `BL_Spawn` inside them. The final arena, the Antechamber and the ritual sites are tagged the same way. ChatGPT's Blender world only has to carry these tags.

**Harsh critique of v1:**
1. An intro the player can't skip gets old by match 10. Keep it at 8 s and skippable by vote later.
2. A plain map screen is dull. It must be the gothic relief map in Theme style, with regional features readable at a glance; mock it up before building it.
3. Region overflow by pure chance can split friends in a party. Parties pick together and move together.
4. Duskbloods' main complaint is sameness. Regional features and ritual site locations must be random per match from a list in the map definition.
5. Waiting alone in a lobby is dead time. The Antechamber has the training dummy and lets players test their kit (no damage to each other).

**Build order (Step 10 then 11):** Waiting/Countdown + matchmaking → Intro → Intermission + regions + spawn → phase clock + phase end → culling → final → results. Each piece is verified in play before the next. The Victorian world is a test layout of tagged region parts until the real map arrives from Blender.

### Virtue (score)

| Source | Virtue *(tune)* |
|---|---|
| Fodder kill | 5 |
| Elite kill | 20 |
| Roaming boss kill | 120, split by damage share |
| Player kill | 30 |
| Relic pickup | 25 |
| Throne corpse (one-time, first come first served) | 60 |
| Capture points, map events | Later |

### In-match leveling

- **Superseded 2026-10-29 (built):** levels 1–20 come from XP earned by kills, separate from the score (`Config.Progression`, `ProgressionService`). The score's player-facing name is `Config.Score.DisplayName` ("Renown"). The old "levels 1–15 from Virtue" rule is retired.
- Each level gives +4% max HP, +3 max stamina and +2% damage. *(tune)*
- Unlocks: second skill at level 5, class ultimate at level 12.

### Passives

- **Innate passive:** one per class, always on.
- **Aspect:** pick 1 of the class's 2–3 aspects in the castle before queueing.
- **Blood boons:** bosses offer a choice of 1 of 3 random boons for the rest of the match (damage, element enchant, skill cooldown, extra flask…).

### Flasks

- Start with 2, max 4. Fodder kills fill a gauge, and a full gauge adds 1 flask. Flasks refill to max at each phase transition.
- Drinking heals 35% max HP over 0.6s. It's an action, so hits can interrupt it. *(tune)*

### Shinigami (companions)

- Summon circles (light pillars) sit around the map. Make a pact at one to get that Shinigami; one active at a time.
- Roles: melee, ranged, support. Each Shinigami has its own skills.
- Shinigami level up alongside you. Recall/resummon has a cooldown; a dead Shinigami returns after a cooldown; switching to a new Shinigami resets it to level 1.
- Shinigami are entities in the same combat pipeline: AI-driven, using the owner's allegiance.

### Minions

Biting a staggered fodder enemy converts it into a temporary minion (its allegiance flips to you). Minions vanish at phase transitions.

### Rewards: Bloodgems

- Paid at match end to every participant (culled players included), before the teleport back.
- Formula *(tune)*: 15 participation + placement (1st 60, 2nd 40, 3rd 30, others 15) + `floor(virtueEarned / 50)` + 2 per player kill, capped at 150.
- Saved as `Bloodgems` in the profile and spent on class skins in the castle shop.

### Owner decisions, 2026-10-29 (confirmed with docs/production-plan.md section 6)

All of these are data (`Definitions/Rules`, `Config`), so a later change is cheap.

| # | Decision |
|---|---|
| D1 | Culls stay ours: none after phase 1, culls after phases 2 and 3 (8 → 8 → 6 → 3). The Duskbloods footage culls after phases 1 and 2; we chose not to follow it. |
| D2 | Final: every finalist gets an HP bonus scaled by their Renown (cap +30%). At the 4:00 cap, sudden death: one life each and a slow blood drain until one remains. If the last two die at once, the higher Renown wins, then whoever reached it first. |
| D3 | Heal uses refill to 2 on death if below. Using the stake at full HP is refused without spending a use. |
| D4 | Player kills give Renown only inside ritual sites (replaces "Player kill 30" anywhere). The 2-Bloodgem kill bonus counts everywhere. |
| D5 | A new Shinigami pact starts 3 levels below its master (minimum 1) and gains a level each time the master does. |
| D6 | Attacks and sprint stay stamina-free. The guard counter and the howl deflecting projectiles will be added (later kit work). |
| D7 | The score keeps the name "Renown". |
| D8 | The Cathedral Quarter is split into four regions for the proof of concept: Lamplighters' Reach (south), Cloister (west), Bell Works (east), Chapter Close (north). |
| D9 | A player who leaves early keeps the participation reward (15) only; culled players get the full formula. |
| D10 | The first loop is built on the Cathedral Quarter alone; more districts join through its sockets after M5. |
| D11 | A match starts with as few as 2 real players (amended by the owner on 2026-10-30 to **1** for the proof of concept); AI hunters fill every seat left up to 8, so each match has a full field (owner, 2026-10-29). Their movement and judgement are scripted later. |
| A-1 | Approved: `ProfileTemplate.MatchAwards` and `PlayerHandlerData.SettleMatch` (additions only; DataInit untouched). |
| A-2 | Approved: MemoryStore, reserved servers, PathfindingService and image uploads (free; Roblox quotas only). |

## 3b. Game roadmap: from framework to the full Duskbloods loop (2026-10-29)

> **2026-10-29:** the working order from here is [production-plan.md](production-plan.md) (milestones M1–M7), built on ChatGPT's [whole-game brief](duskbloods-gameplay-breakdown.md). Steps 1 and 2 below are done.

Owner, 2026-10-29: "we're far from v1; work on the actual game; big inspiration from Duskbloods, creative freedom." Research: duskbloods-reference.md ("PvE and the minute-to-minute match"). ChatGPT is asked for a timestamped video breakdown to refine this.

**Every system a match needs, and where we are:**

| Area | Duskbloods | BloodsLocks today |
|---|---|---|
| Movement + combat kit | multi-jump, air dash, guard/parry/howl, bite, skills, gun | ✅ built (self-test covers it) |
| Companions | Kin: melee / ranged / support, level with you | 🟡 Shinigami core (melee only) |
| **PvE enemies** | mobs, cavalry, hefty brutes, crystal lizards, blood sac swarms | ❌ only training dummies |
| **Bosses** | phase-2 bosses, roaming **Trespassers** (co-op prompt) | ❌ |
| Minions | bite a staggered weak foe → spellbound | ❌ (bite exists) |
| In-match growth | XP/levels (HP, attack, stamina, 2nd ability), Blood Roses (passives), forges (affinities), bloodsacs (skill upgrades) | ❌ (level attribute only) |
| Healing | Goldblood stake (2–4 uses, gauge from kills) | ❌ |
| Items | pickups, chests, 6 quick items | ❌ |
| Score | Virtue: Sword, Pledge, Repulsion, Flame, Commendation, Other | ❌ |
| Match flow | lobby, region pick, 4 phases + clock, culling, final arena, results | 📝 designed (section 3), not built |
| Map | regions, regional features, instant travel, compass, area names, ritual sites, events (starfall) | ❌ (Victorian is an empty baseplate) |
| Social | alliances, sigils, duos | ❌ (later) |

**Build order.** Each step is a playable slice, verified with the self-test plus new checks:
1. **NPC system v1** (below): enemies that patrol, aggro, attack through the same combat pipeline, die, give XP, and respawn. First roster: a fodder mob and a hefty brute. The dummy and Shinigami AIs move onto the same shared base.
2. **In-match XP + levels + Virtue (Repulsion)**, with the HUD medallion showing the number. This is what makes killing NPCs matter.
3. **Match flow skeleton** in the Victorian place on a graybox of tagged regions: waiting → intro → region pick → phases + clock → culling → final → results.
4. **Heal stake + pickups + Flame lanterns** (the phase-1 exploration loop).
5. **Bosses + Trespassers + Blood Roses** (the phase-2 loop).
6. **Ritual sites** (Sword/Pledge, boundary drain) + commendations (the phase-3 loop).
7. **Forges, bloodsacs, minions, random events.**
8. **Alliances, sigils**, then the owner backlog (menu redesign, VFX upgrades).

In parallel (ChatGPT): the Victorian map in Blender carrying our tags, Gustave's look, enemy models.

### NPC system v1: design (2026-10-29)

- **Definitions** (`Definitions/Enemies/<Id>`), validated by Registry:
  - Tier: Fodder / Heavy / Elite / Boss.
  - Body: BaseHealth, StaggerMax, WalkSpeed, ChaseSpeed.
  - Senses: AggroRange, LeashRange.
  - Combat: Attacks (action ids, chosen by range and weight), Telegraph.
  - Rewards: Xp, Virtue.
  - Spawning: Respawn (seconds), Model (template in `Shared.Assets.Enemies`).
  - CanBeSpellbound (for minions later).
- **World contract (no code for world builders):** a part tagged `BL_EnemySpawn` with an `Enemy` attribute (id) and an optional `Count` / `Radius`. ChatGPT's maps only need these.
- **Server:**
  - `NpcService` spawns, despawns and respawns enemies.
  - Each enemy is an entity (`EntityService.MakeEntity`, generalised from MakeDummy).
  - Brains tick at 10 Hz, and only when a player is within 200 studs (performance: a match may hold 60+ enemies).
- **Shared actor base `NpcActor`** (removes today's duplication between DummyBrain and ShinigamiBrain): CanAct, Telegraph, StartAction, FinishAction, Face, Approach. The dummy, Shinigami and enemy brains all use it.
- **Enemy brain:**
  - States: Idle/Patrol → Alert (turn to the target, brief pause: fair) → Chase → Attack (telegraph → action) → Recover → Leash (walk home and heal when the target is gone or out of range).
  - Targets players and Shinigami, nearest, sticky for a few seconds. Never attacks its own spellbound side.
- **Death and credit:** CombatSim records damage per attacker on NPCs. On death, `NpcService.Died` fires with the killer and damage shares; XP/Virtue (step 2) listen to it. The body fades, then respawns after `Respawn`.
- **Self-test:** new cases cover a fodder mob that aggroes, attacks (a hit lands or is dodged), dies at 0 HP, credits the killer, and respawns.

**Harsh critique:**
1. Enemies with saber animations on default rigs will look placeholder. Accepted for the system slice: the look waits on ChatGPT's models and the owner publishing animations. The system must not hard-code any look.
2. Duskbloods' enemies "hit very hard" and testers found enemy variety thin. Tune damage high from day one, and keep the roster data-driven so variety is cheap to add.
3. Several enemies swinging at once can be unreadable. Cap simultaneous attackers per player at 2 (others circle), like Souls group AI.
4. Server cost: 60 brains at 10 Hz plus hit detection. Sleep far-away brains, and measure server frame time in the self-test once enemies exist.
5. Respawning enemies in place makes farming trivial. Respawn only after the area is empty of players for a while (`Respawn` counts from then).

## 4. Movement

### Kit (from the Duskbloods research)

| Feature | Behaviour | Start values *(tune)* |
|---|---|---|
| Walk / sprint | Sprint is a toggle, infinite, and never costs stamina | 18 / 30 studs/s |
| Ground jump | Tap jump | ~8.6 studs (launch 50 at gravity 145) |
| High jump | Hold jump on the ground (≥0.15s) to crouch-charge, release to launch | Full charge 0.6s; 2–3× normal height |
| Air jumps | Up to 3 more jumps in the air (4 total), reset on landing | ~7 studs each; 12 stamina each |
| Air dash | Dodge input in the air: short burst with gravity paused | 1 per airtime; 0.18s; ~13 studs; 20 stamina |
| Ground dodge | Quick step with invincibility frames | 0.40s; ~14 studs; i-frames 0.04–0.28s; 20 stamina |
| Fall damage | None; only kill zones below the map | — |
| Feel helpers | Coyote time / jump buffer / input buffer | 0.10s / 0.12s / 0.15s |
| Turning | Face the move direction; face the target when locked on | 720°/s |

### Stamina (from the Duskbloods research)

- **Costs stamina:** ground dodge, air dash, air jumps, some skills.
- **Free:** sprinting, ground jump, high jump, every attack (melee and ranged).
- **Evasion cancel:** a dodge pressed within 0.15s after one of your attacks connects or ends is free *(tune)*. Mastering it lets you chain attack → dodge → attack without spending stamina.
- **Regen:** 50/s, starting 0.45s after the last spend, or 0.9s after hitting 0 *(tune)*.
- **Max:** 100, +3 per level.
- **Guard:** blocking drains stamina (unverified in Duskbloods; default 0.5 × blocked damage *(tune)*).

### Implementation

- A shared `MovementSim` module runs in `RunService:BindToSimulation` on client and server. It reads Input Action System actions, keeps state in character attributes so rollback works, and uses `time()`.
- Humanoid jumping is disabled. Every jump is a scripted velocity change, so tap vs hold and air jumps stay under our control.
- The server reads camera direction from `Player:GetCameraState()`.
- Animations play inside the simulation and are looked up each frame with `Animator:GetTrackByAnimationId`. An animation layer manager keeps each Animator at ≤8 tracks.

### PC bindings (rebindable)

| Action | Key |
|---|---|
| Move | WASD |
| Sprint (toggle) | Left Shift |
| Jump / high jump (hold) / air jump | Space |
| Dodge / air dash | Q |
| Attack | LMB |
| Strong attack (hold = charged) | R |
| Ranged | RMB |
| Guard (hold) / Howl = Guard + R | F |
| Skill 1 / Skill 2 | 1 / 2 |
| Flask | C |
| Interact | E |
| Lock-on / switch target | Tab or middle mouse / flick the mouse |

The camera is a mouse-locked third-person camera with a center crosshair, so RMB is free for the gun.

## 5. Combat

- **Actions:** everything an entity does is an action definition: attacks, guard, howl, dodge, skills, flask, hit reactions, bite. Each holds duration, phases, cancel windows, lunge curve, turn tracking, hitbox windows, costs and audio/VFX cues. One runner executes them for players and NPCs on both sides.
- **States:** Free, Acting, Guarding, Hitstun, Staggered, Knockdown, Paired, Dead, plus tags (IFrames, HyperArmor, PerfectGuard, …). One `CanStart(action, state)` table governs every action.
- **Hit detection:** authored hitbox shapes relative to the root, swept each simulation step, tested against dedicated hurtbox parts in a "Hurtbox" collision group. Each target is hit at most once per window unless the window is multi-hit. A debug visualizer is available.
- **Damage pipeline (server decides):**
  1. Allegiance check.
  2. I-frames.
  3. Defence: guard takes chip damage, a perfect guard parries, and a howl in its window staggers the attacker.
  4. Modifiers: counter-hit, element, passives, level.
  5. Apply HP and stagger.
  6. Reaction: flinch, stagger, knockdown or launch.
  7. Events and feedback.
- **Stagger + bite:** hits fill a stagger meter (guns fill it fast). A full meter means Staggered, which opens a paired bite action: heavy damage + heal, or minion conversion on fodder.
- **Deliveries:** Melee, Hitscan, Projectile, Beam, Area, Summon. Every ranged weapon picks an ammo model: magazine, cooldown or resource.
- **Lag compensation:** the server keeps 1s of hurtbox history so hitscan shots validate against what the shooter saw (capped at 200ms).
- **Feel:** ~60ms hitstop, camera shake, sparks and blood VFX, layered sounds.

### Grappling (decided 2026-10-28)

Grappling / 3D-maneuver movement is a class skill for a future class (Duskbloods' Zork uses a cable as his own ability), not base movement. Base verticality comes from multi-jumps, the charged high jump and the air dash.

### Class 1: saber + burst SMG all-rounder (working name "Duelist")

The melee saber has a 4-hit light chain, a strong attack and a charged attack, an aerial attack and a plunge. The burst SMG does chip damage and builds stagger fast. Skill 1 is a blood blade projectile, Skill 2 (level 5) a light beam, and the ultimate unlocks at level 12.

## 6. Universe and matchmaking

- **Castle:** public servers; this place.
- **Match:** reserved servers only, one place per world.
- **Create:** the castle calls `TeleportService:ReserveServer(matchPlaceId)`, writes a MemoryStore HashMap record (access code, map, mode, max players, visibility, private code), then teleports the creator (and party) with `TeleportOptions.ReservedServerAccessCode`.
- **Listing:** the match server finds its record through `game.PrivateServerId`. While Waiting or Countdown it refreshes the record every 5s with a 30s TTL, so dead servers disappear on their own.
- **Join:** `UpdateAsync` atomically reserves slots (a whole party at once). Then `TeleportAsync`, retrying with backoff if it fails and freeing the slots on failure.
- **Countdown:** the end time is replicated as `workspace:GetServerTimeNow() + 30`.
- **Arrival:** the server checks for a reservation; anyone without one goes back to the castle. The class and loadout come from the profile, never from TeleportData.
- **Private lobbies:** a 6-character code maps to the match record. Private matches never show in the public list.
- **Parties:** the leader invites players in the same castle server, queues for everyone, and all members teleport in one call.
- **Shutdown:** `BindToClose` on a match server teleports everyone back to the castle.

## 7. Code architecture

There are three layers:
- **Simulation:** shared, inside `BindToSimulation`. Movement, actions, hits, damage, stamina and stagger.
- **Presentation:** client only. Camera, VFX, sound, UI and hitstop, all tolerant of mispredictions.
- **Meta:** server only. Matchmaking, match lifecycle, data, scoring and AI decisions.

Layout as built (refactored 2026-10-29):

```
ReplicatedStorage
├─ Shared
│  ├─ Config/         Game, Movement, Stamina, Camera, Combat, Animations (every tunable number)
│  ├─ Definitions/    Registry (lookup + load-time validation), Common (howl, bite), Classes/, Weapons/
│  ├─ Simulation/     runs inside BindToSimulation on server and client:
│  │                    Runner (the one step pipeline), Rigs (which characters), Input (presses/releases,
│  │                    Face/Aim feed), Spawn (first-step setup), Equipment (welded weapons),
│  │                    Locomotion (movement kit), ActionSim (attacks/guard/howl/bite/gun), Facing,
│  │                    Stamina, CombatSim (damage pipeline), AnimationSim, EntityState (attribute schema)
│  ├─ Assets/         Weapons/ (Saber), TrainingDummy
│  ├─ Net             declarative remotes + rate limits
│  └─ Util/           Loader, Log, Signal, Vector, Parts, Raycast
└─ Modules/           the owner's modules: SharedModules (MuchachoHitbox, StunHandlerV2, CameraShaker, RockModule, screen3D), Combat Agent placeholder, WeaponRarities, Tween list
ServerScriptService
├─ Server/
│  ├─ Boot            the only server entry script
│  └─ Services/
│     ├─ Core/        PlayerService, DataService, DebugService, InputService, SimulationService,
│     │               EntityService (entity tag, deaths), CombatService (+ Melee, Gunfire)
│     └─ Castle/      TrainingService (+ DummyBrain)
├─ Data/              the owner's ProfileStore system (DataInit, PlayerHandlerData, ProfileTemplate, ProductManager)
└─ Libraries/         ProfileStore, RockModuleServer
StarterPlayer.StarterPlayerScripts
└─ Client/
   ├─ Boot            the only client entry script
   ├─ Controllers/Core/  SimulationController, LockOnController, CameraController, HudController, CombatFxController
   └─ UI/             Theme, Components/ (Bar, Crosshair, FloatingText, Flash, Tracer)
```

Simulation step order (Runner): server applies queued hits / client feeds Face+Aim, then per character: Spawn → Input → Locomotion.Sense → ActionSim → Locomotion.Step → Facing → Stamina → stagger drain → AnimationSim.

### Code standards

- One job per module. When a module grows a second job, split it. Helpers that only one service uses are child ModuleScripts of that service (the Loader ignores modules nested in modules), e.g. `CombatService.Melee`.
- No duplicated helpers: direction math goes in `Util.Vector`, model lookups in `Util.Parts`, raycast/overlap params in `Util.Raycast`. Attribute reads use `EntityState.Number` / `EntityState.Set` / `EntityState.CurrentAction`.
- No magic strings: attribute names come from `EntityState.Attr`, the entity tag from `EntityState.Tag`, input names from `Input`. Tunable numbers live in `Config`, content in `Definitions`.
- Defaults are data: spawn state is the `EntityState.Defaults` tables applied with `EntityState.Apply`, not lists of SetAttribute calls.
- UI is built from `UI/Components` styled by `Theme`; controllers don't hand-build widgets.
- Names never depend on child order (e.g. dummies take their number from their spot's name).
- Every module starts with `--!strict` and a header comment saying what it does and where it runs.

- `Data`, `Libraries` and `ReplicatedStorage.Modules` are the owner's keep list. Adding to them is fine; replacing or removing anything there needs the owner's OK.
- Hit detection uses the owner's MuchachoHitbox (the `--!strict` copy in `Modules.SharedModules`) behind a small wrapper, provided it runs cleanly under Server Authority. If it doesn't, ask the owner before swapping it. Camera effects use CameraShaker.

- **Boot:** the Loader requires every module in Services (or Controllers), validates its shape, calls `Init()` on all in order (no cross-calls), then `Start()` on all.
- **Dependency rules:** Definitions require nothing. Simulation requires only Config and Definitions. Server and Client code require Shared, never each other.
- **Place role:** a Workspace attribute `PlaceRole` ("Castle" / "Match") decides which role-specific services boot.

### Framework archive on GitHub: Rojo (locked by the owner, 2026-10-29)

The owner wants the perfected framework kept on GitHub as an archive: each world place gets it from there, and when a world needs an upgrade it takes the newest version again. This replaces "copy the code over" in locked decision 2 and Step 10.

- **Tools (free, open source):** Rojo 7.7.1 pinned in `rokit.toml`; VS Code with the Rojo and Luau LSP extensions; the Rojo Studio plugin.
- **Where:** the repo clone at `C:\Users\gloce\BloodsLocks`. It's outside Documents because Windows Controlled Folder Access blocks git and Rojo there.
- **Mapping (`default.project.json`):** `src/shared`, `src/server`, `src/client`, `src/owner/{Data,Libraries,Modules,Events}`, `src/storage/BLInput`, plus the StarterPlayer settings (R6, jump settings, camera zoom). Place-specific content (world builds, WorldTools, WorldAssets, RBX_ANIMSAVES, Lighting, `PlaceRole`) stays in each place and is never touched by Rojo.
- **Files are the source of truth.** Code is edited in `src/` and Rojo syncs it to Studio. A Studio-side edit is pulled back with `rojo syncback -i <place>.rbxl -y` (it ignores the noise properties `SerializedOverrides` and `SourceAssetId`).
- **Versions:** `framework-v0` = the hub's code as exported 2026-10-29, before the fix pass (125 files, script counts verified against Studio). `framework-v1` = after the fix pass; worlds take that one.
- **Every place runs the same code.** Manor-only and match-only services are split by the `PlaceRole` workspace attribute.
- **Repo layout:** `docs/` (plan, research, notes, `sessions/`), `src/` (framework), `worlds/<World>/` (world-only tools and notes), `tools/` (our asset scripts), `assets/`.

## 8. Data (compatible with the owner's ProfileStore system)

- **The owner's system:**
  - DataInit opens ProfileStore "Test" in Studio and "Live" in game, keyed `Player_<UserId>`, with `Reconcile`, `AddUserId`, and a kick when the session ends.
  - Profiles live in `PlayerHandlerData.Profiles[player]`.
  - The template is in `ProfileTemplate`.
  - Dev products go through `ProductManager` with a `PurchaseIdCache`.
- **Rules:**
  - Never open another ProfileStore.
  - Wait for and read profiles through PlayerHandlerData.
  - Add new fields to ProfileTemplate.
  - Add mutation functions to PlayerHandlerData in its existing style (profile nil-check, then update, then notify the client via `NotificationClientDataRE`).
- **New fields:**
  - `Bloodgems`, `SelectedClass`, `SelectedAspects`, `OwnedSkins`, `EquippedSkins`
  - `Stats` (Matches, Wins, Finals, PlayerKills, Deaths, VirtueEarned), `ClassStats`, `Settings`
  - `DataVersion`, for migrations
- **Never saved:** in-match values (HP, stamina, level, Virtue). Those come from definitions and match state.
- **Found during the audit (not fixed yet):**
  - `ProductManager`'s `IsPurchaseSaved` searches for `purchaseIdCache` instead of `purchaseID`, so it's always false and receipts never return PurchaseGranted.
  - `productId` is undefined in one warn.
  - `DataInit.Initialize` sets MaxHealth from the profile's `Health` (2000) while the legacy `Initilization` used 200.
  - `ServerStorage.WeaponsFLD` doesn't exist, so `AddWeapon` errors for non-empty inventories.

## 9. Castle hub

- **Areas:**
  - Arrival hall.
  - Class altar: pick class + aspect with a 3D preview.
  - Skin shop: priced in Bloodgems.
  - Training yard: dummies, damage numbers, hitbox debug.
  - The gate: server browser with Quick Join / Join / Create / private code.
  - Party system.
- Runs the Core + Castle services. PvP is off outside the training yard.

## 10. UI

- Every color, font, stroke, corner radius and spacing value comes from one Theme module, so a restyle is a one-file change.
- Palette: deep red/purple base with blue and orange accents, matching the owner's lighting.
- Screens are built from a small component kit (Panel, Button, Bar, List, Modal, Tooltip) so they stay coherent.

## 11. Art direction

- Keep the owner's lighting stack (Atmosphere, Bloom, DepthOfField, SunRays, ColorCorrection).
- Realistic Victorian gothic, with a red/purple mood and blue and orange light sources.
- More worlds later (pre-modern era, …).
- Weapon and gun models come later from Blender. VFX and skills are built in Studio (particles, beams, trails).

## 11a. World-building standard (owner, 2026-10-29)

- Every space must have its own atmosphere and read as premium: realistic Victorian gothic, red/purple mood, blue and orange light sources, the owner's lighting stack as the base.
- Process for every build: sketch (layout, landmarks, lighting, sightlines, player flow), write the sketch here, critique it harshly against the vision, implement only what passes.
- Next world piece once the Duelist's kit is done: the castle hub, a Roundtable-style keep sized to need, with an open yard (training ground).

### Castle hub "The Vigil": design v2 (2026-10-29, awaiting owner sign-off)

**References.**
- **Nightreign's Roundtable Hold:** a central hall with the expedition table, wings holding the facilities (shop, journal, codex, character choice), and an outdoor Sparring Grounds with practice dummies and tents.
- **Duskbloods' hub:** pick a character, practice, queue. No public layout details.
- **Our own forms and names:** Duskbloods is inspiration only. No literal round table.

**Layout (north up; sizes in studs; R6 character = 5 tall, sprint 30/s):**

| Area | What it is | Function |
|---|---|---|
| Spawn porch (south) | A covered gothic porch opening into the hall. Players spawn facing north. | Arrival |
| Great hall (centre) | An octagon about 80 across with a 45 high ribbed vault. An oculus frames the blood moon over the **Blood Table**: an octagonal stone plinth with a carved relief map of the match world, ringed by blood candles, under a hanging iron candle crown. An upper gallery runs round it. | Interact with the table → match menu (quick join, create, private lobby, party). Step 10 |
| Hall of Oaths (west wing) | A long gallery with one statue alcove per class (Duelist first). Lit with cold blue moonlight through lancet windows. A dark mirror at the end. | Class choice + skin preview. Step 9 |
| Atelier (east wing) | A tailor's armoury: mannequins wearing skins, a Bloodgem counter with a keeper NPC. Lit with warm orange lamplight. | Skin shop. Step 13 shell in Step 9 |
| The Yard (north, through great doors) | About 140×120, cobbles with dead-grass seams, keep walls and wrought-iron fence. Deliberately **asymmetric**. | Training |
| Yard: movement course (NW) | Stairs, broken walls and a ruined tower with ledges at 8 / 16 / 24 studs (tap jump 8.5, 4 jumps, charged jump 24.7), plus a gap for the air dash. | Practise the movement kit |
| Yard: dummy line (W) + duel ring (centre) | Passive dummies in a row. The aggressive dummy stands in a sanded ring (practise parry, howl, i-frames). | Combat practice (exists today as TrainingService) |
| Yard: Shinigami circle (NE) | A carved sigil in the cobbles under a gold pillar of light (our take on Duskbloods' pact circles). | Shinigami summon practice. Step 12 |
| Bell tower (beyond the north wall) | The tallest landmark, visible from everywhere. | Orientation |

**Sightline.** One axis runs south to north: spawn → Blood Table → open doors → yard → bell tower against the blood moon. The wings branch off at right angles and are colour-coded: west is cold blue (choose who you are), east is warm gold (dress them).

**Lighting.**
- **Base:** keep the owner's lighting stack (dusk, SunRays, Atmosphere, Bloom, DoF, ColorCorrection).
- **Interior:** keyed by orange hearth and candles, with blue moon shafts through the lancets and red accents from stained glass and the blood candles.
- **Yard:** blue moonlight, orange braziers, and the Shinigami circle's gold pillar.
- **Readability:** every station has its own key light so nothing that matters sits in darkness. At most about 6 shadow-casting lights in view at once.

**Harsh critique of v1 (fixed in v2):**
1. A fully symmetric plan is static. Kept for the hall (ceremony), broken in the yard (ruins, off-axis tower, NE Shinigami circle).
2. An octagon of plain parts reads cheap. Build a **modular kit** first (column, rib arch, lancet window, cornice, buttress, door) with trims and real materials (Slate, Cobblestone, WoodPlanks, Fabric, Basalt). Prove it on **one finished bay** before building the rest.
3. Night interiors die in darkness. Key light per station, and review from the player camera.
4. Too big means empty walks. Spawn → table ≤ 25 studs; table → each station ≤ 35; table → yard ≤ 50.
5. The existing white Georgian mansion clashes with gothic. The owner decides (replace, move or keep as a backdrop). The Victorian lamps and iron fences fit and are reused.
6. The yard must exercise the real movement numbers (ledge heights above), or it is decoration.
7. The Shinigami circle has to read from afar, hence the gold pillar.
8. Performance: target under 8k parts in the hub, with StreamingEnabled checked.

**Step A graybox, built 2026-10-29 (owner approved the design as a prototype):**
- **Where:** `workspace.Vigil`, centred on (0, 0, −1000), away from the old yard. It is generated by `ServerStorage.WorldTools.VigilGraybox` (`Build()` replaces `workspace.Vigil`; `Spots()` gives spawn and dummy positions). It's edit-time only and isn't shipped to clients. 186 parts, 36 lights.
- **Moved in:** the SpawnLocation (inside the south door, facing north) and the dummies: DummySpot1, the aggressive one, to the duel ring; DummySpot2 to the dummy line. Old positions, for a restore: spawn (420.2, 0.5, −363.7), DummySpot1 (414.2, 0.5, −377.7), DummySpot2 (426.2, 0.5, −379.7). The old yard and mansion are untouched; the owner hasn't decided on the mansion yet.
- **Review from the player camera:**
  - The axis works: from spawn, the candlelit table, then the great doors framing the duel dummy and the bell tower.
  - The bell tower reads strongly against the blood sky.
  - The colour coding reads through the doorways (west cold blue, east warm).
  - Lighting first pass was pitch-black, second overlit. Settled on a low candle crown (0.7) plus tilted moon shafts, sconces, and per-statue key lights.
- **Distances measured:**
  - spawn → table 28.
  - table → great doors 40.
  - table → first statue 56 and → shop counter 82: over the ≤35 target. That's about 2 to 3 seconds of sprint, but it may feel long. Decide on the walk: shorten the wings or move the counter forward.
  - table → duel ring 108 and → Shinigami circle 147.
- **Graybox gaps (on purpose):** no stairs to the gallery yet, flat vault, block figures, an empty-feeling yard. All of these are step B and C work.

**Build order (each step reviewed before the next):**
- A) graybox the layout, spawn and lighting; the owner walks it.
- B) the modular kit plus one finished bay; review.
- C) dress the whole keep and yard.
- D) wire the stations: table → match menu (Step 10), class altar and atelier (Step 9).

## 11b. Polish backlog (owner feedback, after the core)

- Air-jump animation: the owner doesn't like the forward flip for chained air jumps. Research how Duskbloods animates its multiple air jumps and redo `BL_AirFlip` to match.
- More movement animations the owner noted as missing (charged jump set), to add later.

## 11c. VFX standard and layout

- **Bar:** as good as Duskbloods. FromSoftware look: blood is dark, wet and heavy (near-black body, a thin hot edge, drips and splatter), not neon. Light is warm gold, not white. Review every effect from the player's own camera (behind the shooter) before calling it done.
- **Code:** `StarterPlayerScripts.Client.Vfx`:
  - `Kit`: texture ids, emitter-from-spec, `Burst`, `Flash`, `Tween`, `Release` (stop emitting, let particles die, then destroy).
  - One module per effect (`BloodBlade`, `LightBeam`).
  - `Projectile`: generic client flight. Each projectile look exposes `Spawn(cframe)`, `Move(visual, cframe)` and `Impact(visual, position, direction)`.
  - Colors come from `Theme.Vfx`. Meshes live in `ReplicatedStorage.Shared.Assets.Vfx`.
  - `CombatFxController` maps the server's `ProjectileFx` visual name to a look through `PROJECTILE_LOOKS`.
- **Lessons learned:**
  - Most glow textures have a black background, so use them only with LightEmission 1 (additive). Otherwise they render as black slabs.
  - **Beam textures:** Roblox runs a Beam texture's **vertical** axis along the beam's length. Draw beam art tall: the band runs down the image, tileable top to bottom. A horizontal band shows up as a row of beads.
  - Crescents must face the camera (perpendicular to travel). A flat crescent in the travel plane is edge-on from behind and vanishes.
  - Additive dark red disappears against the bright red sky. Darkness has to come from alpha-textured particles or opaque/glass meshes.
- **Owner review 2026-10-29:** "alright" but **not yet up to our standard**. The slash is now upright (vertical) at the owner's request. The "a little buggy" was most likely the saber falling apart, now fixed.
- **Drawn textures, 2026-10-29:**
  - **The textures:** our own art, drawn by `tools/vfx_textures.py` (pure Python; `py tools/vfx_textures.py <out_dir> --preview`). The sandboxed shell can't write into Documents, so the script draws into a scratch folder.
  - **Uploading:** serve the folder with `py -m http.server 8765 --bind 127.0.0.1 --directory <out_dir>` and pass the `http://127.0.0.1:8765/<file>.png` URLs to the MCP `upload_image`. The ids go in `Kit.Textures`.
  - **Blood Blade:** now a drawn crescent sprite (hot rim, wet gloss, near-black body, needle tips) plus a rim halo, as unlit SurfaceGuis on both faces of a thin plane (replaces the glass mesh).
  - **Light Beam:** the drawn soft band (core, mid, haze) plus drawn energy strands, replacing the onion bands. The beam is now continuous and soft-edged.
  - **Glints:** the charge "armed" glint and the beam flares use the drawn four-point glint.
  - **Owner review:** "still not my standard but fine, move on, we redo it later". The VFX quality revisit is **parked**: come back after the core loop, before the polish step.
- **Next:** a charged Blood Blade (hold) variant.

## 12. Build steps

One puzzle piece at a time. A step starts only after the previous one passes its checks.

| Step | Piece | Checks | Status |
|---|---|---|---|
| 0 | Housekeeping + framework skeleton: old jump/M1/block/HUD prototype removed (owner keeps a copy); Shared/Server/Client boot; Loader, Log, Signal, Net, Config; Studio debug bridge | A playtest boots with zero errors; boot logs list every service and controller | Done 2026-10-28: server and client boot with 0 errors; bridge answers; rate limiter dropped 18 of 20 spam calls with one warning |
| 1 | Data adapter on the owner's ProfileStore | Profile loads in Studio; new fields reconcile; the DataVersion migration runs once; Bloodgems add/remove round-trips and persists across a rejoin | Done 2026-10-28: existing fields untouched; v0 → v1 once; 0 → 25 → 15; invalid amounts rejected with warnings; 15 survived a rejoin; client got both BloodgemsEVENTs; test gems removed afterwards |
| 2 | Server Authority on (the owner flips AuthorityMode) | Default movement works; no errors; own character reports predicted | Done 2026-10-28: character `Predicted`; walked 36 studs with identical client/server positions; 0 errors |
| 3 | Input contexts + entity state + stamina | Inputs read the same on client and server; stamina spend/regen matches config | Done 2026-10-28: `BLGameplay` context (Space/Q/LeftShift, priority 2000, sink) cloned into each player; 23 `BL_` attributes on the character; spend/regen exact (−12 per air jump, −20 per dodge/dash, 0.45s delay, 50/s) |
| 4 | Movement kit | Each feature verified with scripted input; the owner signs off on feel | Mechanics verified 2026-10-28: tap jump 8.5 studs, 4 jumps then refused, charged high jump 24.7 studs, sprint 30 studs/s and auto-off, dodge/backstep 13.1 studs at 55 peak, air dash 70 studs/s once per airtime, client = server position. **Waiting on the owner's feel test.** Dodge needed `Humanoid:Move` + WalkSpeed during the dodge, otherwise the walk controller brakes it. |
| 5 | Camera: mouse-locked third person, crosshair, lock-on | Target switching works; aim ray correct | Done 2026-10-28 (owner feel test pending): `CameraController` + `Config.Camera`; Tab/middle mouse locks; facing goes through the `Face` input action (Scriptable binding) so the server turns the character too: 0.0° standing, ≤5° while strafing; unlock restores free cam. Line of sight and camera collision ignore non-colliding VFX parts. Flick-switching is written but untested (only one dummy in range). Aim ray comes with the gun in Step 8. |
| 6 | Animation layer manager + R6 animation set | ≤8 tracks; authored KeyframeSequences published by the owner | Done 2026-10-28: owner published all 7; verified in play (charge loops while held, launch on release, flip per air jump, dash, 1 dodge = 1 play, backstep, land); peak 5 tracks. `Config.Animations` = Default set + per-class overrides (`Classes.<id>`, read from the character's `BL_ClassId`). Root-level ReplicatedStorage legacy removed (VFX Handler, Animations, Attachment, VFX). More movement animations (owner noted some missing) come later. Earlier notes: `AnimationSim` plays movement animations from simulation state (rollback-safe, no cached tracks); `Config.Animations` holds ids. 7 KeyframeSequences authored in code in `ServerStorage.RBX_ANIMSAVES.R6` (ChargeCrouch, HighJumpLaunch, AirFlip, AirDash, Dodge, Backstep, Land); Sprint uses the owner's published anim. Pipeline proven with a published id (2 dodges → 2 plays, server runs it too, max 3 tracks). Temporary Studio ids don't play under Server Authority, so publishing is required. |
| 7 | Combat core + training dummy | Frame data honored; hitbox visualizer; no double hits | Core done 2026-10-28; **4 saber swing animations waiting on the owner to publish** (`BL_SaberLight1-4` in RBX_ANIMSAVES.R6 → `Config.Animations.Default.SaberLight1-4`). Built: `Definitions` (Registry with load-time validation, class `Duelist`, weapon `Saber` 4-hit chain with frame data), `ActionSim` (in the simulation: buffering, chaining, lunge, tracking then commit, dodge/jump cancel, hitstun lockout), `CombatService` (MuchachoHitbox per hit window, server-side), `CombatSim` (damage pipeline applied inside the server simulation: allegiance, i-frames, damage, stagger meter, hitstun/stagger, knockback; no PvP in the castle), `TrainingService` (2 dummies, regen/revive), `CombatFxController` (damage numbers, flash, "Evaded", CameraShaker shakes), HP bar, saber model built from parts and welded inside the simulation. Verified: full chain L1→L4 at human click speed (55/60/65/95 damage), one hit per swing, stagger meter fills and triggers STAGGERED at 100, evasion cancel free inside the window (0.32s) and 20 stamina outside (0.48s), early dodge refused (0.10s). Not yet testable: i-frames vs incoming attacks (nothing attacks the player until enemies exist, Step 12). |
| 8 | Class 1 full kit (guard, parry, howl, bite included) | 1v1 duel test | Mechanics done 2026-10-28 (verified vs an attacking training dummy, since there's no second player): guard F (block = 20% chip + 0.4×damage stamina, guard break at 0), perfect guard ≤0.15s = parry (attacker 0.9s hitstun), howl = guard + R (stamina 15; melee hit in window staggers the attacker 1.6s), bite E (only on staggered targets: 180 dmg, heals 12% max HP, ends stagger), burst SMG RMB (4 shots × 14 dmg, +5 stagger each, 24 mag, auto-reload 1.6s, free aim at the crosshair or the lock target, tracers), dodge i-frames verified (hit 0.10s in → Evaded, 0.35s → hit), input buffer (last 0.25s of an action). Attacking dummy (`DummySpot1`, `Aggressive` attribute) flashes orange before swinging. Skills done 2026-10-29: skills are actions with charges that recharge one at a time (`Definitions/Skills/<Class>`, slots 1 and 2, unlocked by in-match level; everything unlocked in the castle). Blood Blade (key 1): server-simulated projectile (110 studs/s, 70 dmg, +14 stagger, 2 charges, 5s recharge). Light Beam (key 2, level 5): 1.2s channel, immobile, 10 ticks × 9 dmg every 0.12s, 1 charge, 12s recharge. Verified: charges/refusal/recharge timing exact, projectile and beam hits, client visuals, HUD skill slots. Server: `CombatService.Projectiles`, `Gunfire` handles beams, shared `Util.Hitscan` and `Util.Muzzle`. VFX overhaul done 2026-10-29 (owner rejected the placeholders): new `Client.Vfx` folder (see 11c). Blood Blade = dark wet crescent with a hot crimson edge, facing the camera, drips/splatter/mist, cast flare, splatter impact. Light Beam = muzzle charge (converging motes), onion-layered gold beam with scrolling energy, motes, impact flare, collapse on release. Verified in real casts: hits land, 0 errors, 0 leaked parts. Strong/charged attacks done 2026-10-29 (R; Guard + R stays Howl):
- **Data-driven:** new action fields `Button` (which press chains it), `Charge` (still holding at `At`, before the hit, switches into a hold stance), `Hold` (release after `Min` or reach `Duration` → `Release`) and `Hit.GuardDrain` (blocked-hit stamina multiplier). Registry validates them.
- **Saber moves:** Strong1 (110 dmg, +28 stagger, heavy, ×1.6 guard drain) chains to Strong2 (120/+30). Holding past 0.3s enters the charge stance (immobile, can turn, dodge cancels it); releasing after 0.35s or holding to 1.1s fires the Charged blow (190 dmg, +55 stagger, ×2.5 guard drain).
- **Verified with scripted input:** tap 110; charged 190; max hold auto-release 190; chain 110 → 120; dodge abandons the charge; Light1 buffers into Strong1.
- **Not yet tested:** guard drain vs a guarding target (dummies don't guard).
- **Animations:** `BL_SaberStrong1/2`, `BL_SaberCharge` (looped wind-up), `BL_SaberCharged` are in RBX_ANIMSAVES.R6, retimed from the light swings; they wait for the owner to publish.

Charge telegraph done 2026-10-29 (`Client.Vfx.BloodCharge`, named by `Hold.Fx`, run by `CombatFxController.updateCharges` for every entity):
- **While charging (ramps with charge time):** blood and embers drawn in from around the body, a crimson glow along the blade, dark red mist at the feet, a red light.
- **Armed (Min reached):** a glint on the blade tip.
- **Release:** a flare off the blade; a dodge-abandoned charge drains away instead.
- **Verified in play:** 0 errors, 0 leaked parts.

Also fixed: the saber template's `WeldConstraint`s didn't hold under Server Authority, so the blade, guard, tip, jewel and pommel sat at the world origin with only the handle in hand. They are now plain `Weld`s with explicit C0.

**Still to do in Step 8:** the ultimate (level 12, needs Step 11 leveling); animations for guard/howl/bite/SMG/saber (owner publishes in one batch); 1v1 duel test needs two players. |
| 9 | Castle: Theme + UI kit, HUD, class altar, skin shop shell, training yard | Class choice saves; UI coherent | — |
| 9a | **UI research + UI kit v2** (owner priority 2026-10-29): research Roblox UI practice and premium game UI, then build the Theme v2 + component kit and restyle the HUD | Research written to docs/ui-research.md; the kit is reviewed in play by the owner | — |
| 10 | Match place + matchmaking + parties + private lobbies: the Blood Table menu launches a match in the Victorian place and returns players to the hub | 2 players go castle → match → castle in a live dev test (TeleportService needs a published dev copy) | **Started 2026-10-29.** The Victorian place exists: **placeId 112559855790294**, same universe (10772800943), in `Config.Game.MatchMaps.Victorian`. The code-sharing decision (locked decision 2) is **copy the code over**: the owner opens the Victorian place, and Claude copies Shared, Server and Client from the hub through MCP (two Studios open). Packages and Rojo stay options for later. Next: the copy, then `PlaceRole = "Match"` on the Victorian workspace, MatchmakingService (MemoryStore registry, ReserveServer, waiting room 2 min / 30 s countdown, delist at T-5), and return to the hub. **Update 2026-10-29:** the Victorian place is open in Studio and empty (baseplate + spawn). The match flow is designed (section 3, "Match flow, start to finish"). The owner wants a fix pass on the framework, then a GitHub archive of it (section 7, "Framework archive"); the method (Rojo or copy-paste) waits on the owner. **Framework in the Victorian place, done 2026-10-29 via Rojo:**
- `PlaceRole = "Match"`, gravity 145.
- Boots `Server/Match` with 8 modules and the client with 7, 0 errors. The profile loads, the input context is cloned, and the scripted jump measures 8.50 studs.
- The hub was renamed Castle → Manor at the same time (`Services/Manor`, `Util.PlaceRole`). The Manor boots 10 + 7 modules with 0 errors.
- Next: the owner's framework issue list (fix pass → tag `framework-v1`), then MatchService per the match flow v1. |
| 10a | **Shinigami** (pulled forward from Step 12, owner 2026-10-29): pact circles, roles (melee/ranged/support), levelling, recall and cooldown, as in Duskbloods. Built and tested first at the hub yard's circle | Pact, follow, fight, recall and death cooldown verified against dummies | **Core done 2026-10-29** (melee "Kurogane"). Verified: pact at the yard circle (G), summon/dismiss (T), follows its master, engages enemies in a fight with its master (or with itself), alternates two slashes (40/50), death means dismissed plus a 30 s cooldown with resummon refused, regen while dismissed (2%/s), it never hurts its own master (allegiance via `own` attribute), no leftover models. **To do:** ranged and support types, levelling with its master (Step 11), a real model (Blender), animations. |
| 11 | Match rules: phases, Virtue, culling, respawn, final arena, leveling, flasks | A full match loop with 2–3 players | **Started.** In-match XP, levels (cap 20) and the Renown ledger done 2026-10-29 (commit 66119ed, self-test 44/44). The rest follows production-plan.md M1–M5. Session 0 (2026-10-29): ChatGPT's 5680db7 pulled, both places match `src/` (136 scripts), self-test 44/44 in Manor and Victorian, owner decisions recorded in section 3. **F1 done 2026-10-29:** match rules as data (`Definitions/Rules` over `RuleDefaults`, validated and frozen by `Registry`; the Hunt tab and `TravelService` read them; Bound is sealed), `Config.Match` (waiting room, Studio fast profile), `Shared.Match.Culling` and `.Rewards` (pure math), the world contract `Shared.World.Tags` with `WorldService` (boot check + `WorldReport`), the four D8 regions in `Maps/Victorian`, and `LogicTestService` (`LogicTests`). Verified in both places: logic tests 30/30, self-test 44/44, 0 boot errors, world report clean (Victorian lists the 5 sites W1 will build). **F2 done 2026-10-29:** `Shared.Match.Ledger` (pure: one-time event keys, revokes, standings by total → first to reach → id), `ScoreService` keyed by participant id (UserId, or negative for AI hunters; books outlive leavers; phase tags; `Changed`), `EntityService.PlayerDied` (once per death; credit by attacker side, so a Shinigami's kill is its master's), `Shared.Match.MatchState` (replicated schema) and `Services/Match/ParticipantService` (records, AI hunters filling seats up to 8 per D11, kills/deaths, kill log). Verified: logic 41/41 in both places, self-test 49/49 in both places (new: player kill credit), 0 boot errors; Victorian fills 1 player + 7 AI hunters. **W1 done 2026-10-29:** the Cathedral Quarter blockout from ChatGPT's spec (generator `worlds/Victorian/WorldTools/CathedralQuarter`, 913 parts, dusk lighting per spec section 9), every gameplay marker in place, route probe 1,970 points / 0 problems, real R6 walks on every flight, world report clean, self-test 49/49; plus `Shared.World.Markers` (only markers inside workspace are live). Notes: `worlds/Victorian/CathedralQuarter/w1-blockout.md`. **World art now belongs to ChatGPT (owner).** **L1 done 2026-10-29:** `Services/Match/MatchService` (+ `Spawning`, `Settlement`, `Smoke`). States: Waiting (Antechamber) → Countdown (lock at T−5) → AI hunters fill the field → Intro → RegionChoice (`ChooseRegion` remote, `Shared.Match.Regions` capacity and overflow) → Phase → PhaseResolve (culls, D1) → FinalSetup (lives, Renown HP bonus, D2) → Final (sudden death, simultaneous last deaths to the higher Renown) → Results (Bloodgems once: `PlayerHandlerData.SettleMatch` + `ProfileTemplate.MatchAwards`, leavers settled in `OnLastSave`) → Return. No damage to entrants between phases and 3 s spawn protection that ends on attack (`CombatSim.SetGuard`); revival after the rule's delay; AI hunter bodies (`EntityService.Watch`/`BodyDied`); the HP bonus reaches max HP through `Spawn`. Studio waits for `MatchStart`. Verified: `MatchSmoke` 33/33 (a whole 8-entrant fast match in 20 s), guard, region choice and spawn protection checked in play, logic 48/48 and self-test 49/49 in both places. Not testable in Studio: real countdown cancel with 2+ players, a real disconnect's settlement (A1's published session). **U1 done 2026-10-30** (match screens, spec `docs/match-screens.md`): the HUD clock (phase numeral, time, ritual mark, red under 10 s), the Antechamber panel (status, seats AI will take, roster), the intro (title, world, rule, the field revealed one by one), the region map (relief from above, outlines, standings with the cut, revival choice while dead), banners (phases, final, entering a region). Every screen that takes input goes through `UI.Core.Focus`; text never renders under 16 px (`Text.Legible`). Server side: `MatchService/Atlas` publishes regions and relief. D11 amended: **1 real player minimum** for the proof of concept (`Config.Match.Lobby.MinPlayers`). Verified: self-test 49/49 and logic 48/48 in both places, `MatchSmoke` 33/33 with the screens up, the Blood Table menu still frees and restores the cursor. Not checked: a real 1366×768 capture (MCP can't resize Studio; the owner can use the Device Emulator). **Next: U2** (phase end and cull, spectate, final setup, lives, results, return). |
| 12 | PvE: fodder, elites, boss, minions, Shinigami | Shinigami AI and conversions work | **NPC system v1 done 2026-10-29** (Wretch, Butcher, spawn markers, credit, refill; commit 8459443). Vertical navigation, bosses and minions: production-plan.md N1, B2–B3, X1. |
| 13 | Rewards + skin purchases | Bloodgems granted once per match; purchases persist | — |
| 14 | Victorian world map | Streaming, regions, spawn areas | — |
| 15 | Class 2 | Added with zero core edits | — |
| 16 | Polish, performance, anti-exploit pass | Server frame-time budget met; exploit checklist passes | — |
