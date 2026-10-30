# BloodsLocks engineering plan

Locked 2026-10-28. This file is the source of truth. Locked decisions change only with the owner's OK. Values marked *(tune)* are starting points to adjust by feel. `Config` is the truth for numbers: the design tables below show the original design values.

## 1. The game

BloodsLocks is a PvPvE action game. Players gather in the Manor hub, pick a class, and enter 8-player matches on large, vertical maps (first world: Victorian gothic; later worlds from other eras). A match runs four phases scored by Renown (design name: Virtue; D7). The lowest-Virtue players are culled at the end of phases 2 and 3, and the last three fight a 2-life battle royale. Every match pays out Bloodgems, which buy class skins in the Manor.

Inspiration: FromSoftware's The Duskbloods (movement, combat, match structure, hub). Names, characters, lore and art are original.

## 2. Locked decisions

| # | Decision | Notes |
|---|---|---|
| 1 | Movement and combat run in shared simulation code under Roblox Server Authority | `Workspace.AuthorityMode = Server` (the owner sets it in Properties; MCP scripts can't). If the movement step fails its checks, fallback is client authority + server validation using the same step code. |
| 2 | Separate places, one codebase | The Manor = the hub place (ROLOCK). One Match place per world map. Every place takes the same code from this repo through Rojo (§7 "Framework archive"; chosen by the owner on 2026-10-29 over Roblox Packages and copying code by hand). |
| 3 | The waiting room lives inside the reserved match server | MemoryStore registry with atomic slot reservations; the server delists itself when it locks. |
| 4 | One entity pipeline | Players, NPCs, bosses and Shinigami share Entity → Action → Hit → Damage. An allegiance model decides who can hit whom. |
| 5 | Data-driven content | Classes, weapons, actions, abilities, passives, Shinigami, skins, NPCs and modes are definition modules validated at boot. |
| 6 | One combat state machine + tags | Replaces scattered true/false attributes. |
| 7 | R6 rigs | All existing content is R6; 6 joints keep animation production fast and snappy. |
| 8 | PC only for now | All gameplay input goes through the Input Action System, so gamepad and touch stay cheap to add. |
| 9 | The owner's ProfileStore system stays the data layer | `ServerScriptService.Data` (DataInit, PlayerHandlerData, ProfileTemplate, ProductManager). No second ProfileStore. New fields go in ProfileTemplate (`Reconcile` fills old saves); new mutations go in PlayerHandlerData in its style. |
| 10 | PvPvE | Fodder, elites, roaming bosses, minions, Shinigami companions. |
| 11 | Free aim + lock-on auto-aim | Crosshair aim by default; while locked on, ranged attacks aim at the target. |
| 12 | Class choice only in the Manor | |
| 13 | Parties and private lobbies ship in v1 | |
| 14 | Budget is 0 € until the game earns revenue (owner, 2026-10-29) | Everything is custom and free. Always ask before using anything that could cost money, credits or quota. The owner is the director; the vision is the priority. |
| 15 | Companions are named **Shinigami** (owner, 2026-10-29) | They work exactly like Duskbloods' Kin (pact circles, roles, levelling, recall). The rename is game-facing; code ids use `Shinigami` too. |
| 16 | Team roles (owner) | Current roles and the team mode live in AGENTS.md ("Who works on what"). History: 2026-10-29, Claude engineering and ChatGPT 3D world art; 2026-10-30, Claudius named lead designer, and ChatGPT off until the owner switches it on. Everyone coordinates through the GitHub repo docs. |
| 17 | First match map: Victorian era | It's its own place in the experience. The hub launches matches there and returns players afterwards. |

## 3. Match rules

### Lobby (inside the match server)

- Max 8 players; the minimum is D11 (1 real player for the proof of concept, AI hunters fill the rest). *(tune)*
- A 30s countdown starts once the minimum is in, cancels if the count drops below it, and shortens to 10s when the lobby is full.
- Joins close at T-5s, when the server removes its registry entry (it disappears from the Manor's list). Late arrivals go back to the Manor.

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
- Culled players spectate or return to the Manor; they still get rewards.

### Match flow, start to finish: design v1 (2026-10-29; built in L1, U1 and Q0)

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

### Renown, the score (design name: Virtue; D7)

| Source | Virtue *(tune)* |
|---|---|
| Fodder kill | 5 |
| Elite kill | 20 |
| Roaming boss kill | 120, split by damage share |
| Player kill | 30 (superseded by D4: Renown only inside ritual sites) |
| Relic pickup | 25 |
| Throne corpse (one-time, first come first served) | 60 |
| Capture points, map events | Later |

### In-match leveling

- **Superseded 2026-10-29 (built):** levels 1–20 come from XP earned by kills, separate from the score (`Config.Progression`, `ProgressionService`). The score's player-facing name is `Config.Score.DisplayName` ("Renown"). The old "levels 1–15 from Virtue" rule is retired.
- Each level gives +4% max HP, +3 max stamina and +2% damage. *(tune)*
- Unlocks: second skill at level 5, class ultimate at level 12.

### Passives

- **Innate passive:** one per class, always on.
- **Aspect:** pick 1 of the class's 2–3 aspects in the Manor before queueing.
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
- Saved as `Bloodgems` in the profile and spent on class skins in the Manor's shop.

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

## 3b. NPC system v1

The 2026-10-29 game roadmap that stood here is archived in [archive/roadmap-3b-2026-10-29.md](archive/roadmap-3b-2026-10-29.md); the working order is [production-plan.md](production-plan.md).

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
| Ground jump | Tap jump | ~12.8 studs (launch 61 at gravity 145; raised from 8.6 on 2026-10-30, owner: "too small") |
| High jump | Hold jump on the ground (≥0.15s) to crouch-charge, release to launch | Full charge 0.6s: 16.9 to 40.2 studs (3.1× the tap jump; research says 2–3× and "scale buildings": 40 clears a 3–4 storey façade) |
| Air jumps | Up to 3 more jumps in the air (4 total), reset on landing | ~10.8 studs each (was 7); 12 stamina each. Ideal chain from the ground: 72.6 studs |
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

- **Manor:** public servers (ROLOCK).
- **Match:** reserved servers only, one place per world.
- **Create:** the Manor calls `TeleportService:ReserveServer(matchPlaceId)`, writes a MemoryStore HashMap record (access code, map, mode, max players, visibility, private code), then teleports the creator (and party) with `TeleportOptions.ReservedServerAccessCode`.
- **Listing:** the match server finds its record through `game.PrivateServerId`. While Waiting or Countdown it refreshes the record every 5s with a 30s TTL, so dead servers disappear on their own.
- **Join:** `UpdateAsync` atomically reserves slots (a whole party at once). Then `TeleportAsync`, retrying with backoff if it fails and freeing the slots on failure.
- **Countdown:** the end time is replicated as `workspace:GetServerTimeNow() + 30`.
- **Arrival:** the server checks for a reservation; anyone without one goes back to the Manor. The class and loadout come from the profile, never from TeleportData.
- **Private lobbies:** a 6-character code maps to the match record. Private matches never show in the public list.
- **Parties:** the leader invites players in the same Manor server, queues for everyone, and all members teleport in one call.
- **Shutdown:** `BindToClose` on a match server teleports everyone back to the Manor.

## 7. Code architecture

There are three layers:
- **Simulation:** shared, inside `BindToSimulation`. Movement, actions, hits, damage, stamina and stagger.
- **Presentation:** client only. Camera, VFX, sound, UI and hitstop, all tolerant of mispredictions.
- **Meta:** server only. Matchmaking, match lifecycle, data, scoring and AI decisions.

Layout as built (checked against `src/` and `default.project.json`, 2026-10-30):

```
ReplicatedFirst
└─ BL_First/          ThemeBase (palette, fonts, images, fit formulas), Passage (our loading and teleport screen), Loading
ReplicatedStorage
├─ Shared/
│  ├─ Config/         Game, Match, Movement, Stamina, Camera, Combat, Animations, Npc, Progression, Score
│  ├─ Definitions/    Registry (lookup + load-time validation), Common, RuleDefaults, Rules/, Classes/, Weapons/,
│  │                    Skills/, Shinigami/, Enemies/, Maps/, Objectives, Tips
│  ├─ Simulation/     runs inside BindToSimulation on server and client: Runner (the one step pipeline), Rigs, Input,
│  │                    Spawn, Equipment, Locomotion, ActionSim, Facing, Stamina, CombatSim, AnimationSim, EntityState
│  │                    (attribute schema), PlayerState, Leveling, ShinigamiBody
│  ├─ Match/          MatchState, Ledger, Culling, Regions, Rewards
│  ├─ World/          Tags (the world contract), Markers, Sightline
│  ├─ Assets/         Weapons/ (Saber, SMG), Vfx/ (Crescent), TrainingDummy
│  ├─ Net             declarative remotes + rate limits
│  └─ Util/           Loader, Log, Signal, Vector, Parts, Raycast, Hitscan, Muzzle, Numerals, PlaceRole, Zones
├─ Modules/           the owner's modules: SharedModules (MuchachoHitbox, StunHandlerV2, CameraShaker, RockModule,
│                       screen3D), Combat Agent placeholder, WeaponRarities, Tween list
└─ Events/            the owner's remotes
ServerScriptService
├─ Server/
│  ├─ Boot            the only server entry script
│  ├─ Npc/            NpcActor (the actor base the dummy, Shinigami and enemies share)
│  └─ Services/
│     ├─ Core/        PlayerService, DataService, DebugService, InputService, SimulationService, EntityService,
│     │               CombatService (+ Melee, Gunfire, Projectiles), ClassService, NpcService (+ EnemyBrain),
│     │               ShinigamiService (+ ShinigamiBrain), ProgressionService, ScoreService, StageService,
│     │               TravelService, WorldService, LogicTestService, SelfTestService
│     ├─ Manor/       TrainingService (+ DummyBrain)
│     └─ Match/       MatchService (+ Atlas, Settlement, Smoke, Spawning), ParticipantService
├─ Data/              the owner's ProfileStore system (DataInit, PlayerHandlerData, ProfileTemplate, ProductManager,
│                       LeaderboardData)
└─ Libraries/         ProfileStore, RockModuleServer
ServerStorage
├─ BLInput            the input context
├─ BL_Tools           tools/studio: ModelAssembly, Models/, Animations/ (Edit-mode art tools)
└─ BL_Import          build/import: the temporary mesh channel
StarterPlayer.StarterPlayerScripts
└─ Client/
   ├─ Boot            the only client entry script
   ├─ Controllers/    Core/ (Simulation, Camera, LockOn, Hud, CombatFx, Menu, Prompt, Plate, PactSite, Passage,
   │                    Shinigami, SelfTest), Match/ (Match, Arrival, Return)
   ├─ UI/             Theme, Core/ (Layers, Motion, State, Create, Focus, Stage), Kit/, Hud/, Match/, Menu/, World/,
   │                    Components/
   ├─ Vfx/            Kit, Projectile, BloodBlade, LightBeam, BloodCharge, FireNova, Gunshot, Arrival
   └─ Util/           Budget
```

Simulation step order (Runner): server applies queued hits / client feeds Face+Aim, then per character: Spawn → Input → Locomotion.Sense → ActionSim → Locomotion.Step → Facing → Stamina → stagger drain → AnimationSim.

### Code standards

They live in `.claude/rules/code-standards.md` (Claude loads it when editing code; Codex reads it before editing `src/`). The owner's keep list is in AGENTS.md.

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
- **Found during the audit; all four fixed with the owner's OK on 2026-10-29 (commit d55e801). The purchase flow still needs a test in the published game with a real dev product:**
  - `ProductManager`'s `IsPurchaseSaved` searches for `purchaseIdCache` instead of `purchaseID`, so it's always false and receipts never return PurchaseGranted.
  - `productId` is undefined in one warn.
  - `DataInit.Initialize` sets MaxHealth from the profile's `Health` (2000) while the legacy `Initilization` used 200.
  - `ServerStorage.WeaponsFLD` doesn't exist, so `AddWeapon` errors for non-empty inventories.

## 9. Manor hub (called the castle hub until 2026-10-29)

- **Areas:**
  - Arrival hall.
  - Class altar: pick class + aspect with a 3D preview.
  - Skin shop: priced in Bloodgems.
  - Training yard: dummies, damage numbers, hitbox debug.
  - The gate: server browser with Quick Join / Join / Create / private code.
  - Party system.
- Runs the Core + Manor services. PvP is off outside the training yard.

## 10. UI

- The Theme rule and the UI bar: `.claude/rules/ui.md` and [ui-quality-standard.md](ui-quality-standard.md).
- Palette: deep red/purple base with blue and orange accents, matching the owner's lighting.
- Screens are built from a small component kit (Panel, Button, Bar, List, Modal, Tooltip) so they stay coherent.

## 11. Art direction

- Mood, lighting stack and the premium bar: AGENTS.md ("How the owner wants work done").
- More worlds later (pre-modern era, …).
- Weapon and gun models come later from Blender. VFX and skills are built in Studio (particles, beams, trails).

## 11a. World-building standard (owner, 2026-10-29)

- The standard (atmosphere, premium bar, sketch → write → critique → build) lives in AGENTS.md ("How the owner wants work done").
- After the Duelist's kit came the castle hub, now the Manor: a Roundtable-style keep sized to need, with an open yard (training ground).

### Manor hub "The Vigil": design v2 (2026-10-29, owner-approved as a prototype)

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

- **The bar and the lessons learned** (beam textures, additive glows, crescents, uploads): `.claude/rules/vfx.md`.
- **Code:** `StarterPlayerScripts.Client.Vfx`:
  - `Kit`: texture ids, emitter-from-spec, `Burst`, `Flash`, `Tween`, `Release` (stop emitting, let particles die, then destroy).
  - One module per effect (`BloodBlade`, `LightBeam`).
  - `Projectile`: generic client flight. Each projectile look exposes `Spawn(cframe)`, `Move(visual, cframe)` and `Impact(visual, position, direction)`.
  - Colors come from `Theme.Vfx`. Meshes live in `ReplicatedStorage.Shared.Assets.Vfx`.
  - `CombatFxController` maps the server's `ProjectileFx` visual name to a look through `PROJECTILE_LOOKS`.
- **Owner review 2026-10-29:** "alright" but **not yet up to our standard**. The slash is now upright (vertical) at the owner's request. The "a little buggy" was most likely the saber falling apart, now fixed.
- **Drawn textures, 2026-10-29:**
  - **The textures:** our own art, drawn by `tools/vfx_textures.py` (pure Python; `py tools/vfx_textures.py <out_dir> --preview`). The sandboxed shell can't write into Documents, so the script draws into a scratch folder.
  - **Blood Blade:** now a drawn crescent sprite (hot rim, wet gloss, near-black body, needle tips) plus a rim halo, as unlit SurfaceGuis on both faces of a thin plane (replaces the glass mesh).
  - **Light Beam:** the drawn soft band (core, mid, haze) plus drawn energy strands, replacing the onion bands. The beam is now continuous and soft-edged.
  - **Glints:** the charge "armed" glint and the beam flares use the drawn four-point glint.
  - **Owner review:** "still not my standard but fine, move on, we redo it later". The VFX quality revisit is **parked**: come back after the core loop, before the polish step.
- **Next:** a charged Blood Blade (hold) variant.

## 12. Build steps

Steps 0–12 (2026-10-28 and 29) built the framework. Their table, with every check and status, is archived in [archive/build-log-2026-10.md](archive/build-log-2026-10.md). From M1 on, the working order and status live in [production-plan.md](production-plan.md), which also carries the table's open items (class 2, untested leftovers).
