# BloodsLocks production plan

Claude, 2026-10-29. **Status: approved by the owner (all decisions and approvals confirmed as recommended; recorded in engineering-plan §3). Session 0, F1, F2, W1 (blockout), L1, U1 and Q0 done (Q0 waits on the owner's review). In progress, by the owner's order (2026-10-30): C1, the combat rework (C1.1, C1.2 and C1.5 done; `docs/combat-rework.md`, "Progress"; the combat sounds are provisional library slices the owner will replace); the network-test reference study is done for one full playthrough (`docs/reference/network-test/`, its audio measured in `audio.md`), and C1's effects and animations are redone to it next; then U2.**

> Roles, ownership and the team mode: AGENTS.md. D11 and every other owner decision: [engineering-plan.md](engineering-plan.md) §3.

This is the working order for Claude's sessions. [engineering-plan.md](engineering-plan.md) stays the source of truth for locked rules and specs. ChatGPT's [whole-game brief](duskbloods-gameplay-breakdown.md) is the behaviour spec each slice implements, and the [UI quality standard](ui-quality-standard.md) is the bar every screen passes.

## The owner's direction (2026-10-29)

- Claude is the coding north star: back end, HUD and VFX, no excuses.
- Make the game first, in the order ChatGPT's brief sets. The rest comes later.
- The world is built to the premium bar by whoever holds world art (AGENTS.md, "Who works on what"); the owner and ChatGPT's specs direct the art. **The map is vertical.**
- Quality first. Speed comes from order and tooling, never from skipping a check.

**Added 2026-10-30 (evening):**
- **The reference study comes first, and it gets the most effort.** The owner sent a 1080p60 recording (5.3 GB) of the whole Duskbloods network test, with several matches. Claude surveyed one full playthrough of it (0:00–52:23, one frame a second; the owner stopped it there) and wrote organized notes in `docs/reference/network-test/`, with frames kept local. The notes cover:
  - scenery by phase, region and time of day (dusk, twilight, night);
  - gameplay, combat, movement, VFX, SFX and UI.

  These notes are the foundation of full production.
- **UI rework to Duskbloods' look,** as accurate as possible inside the IP guardrail (AGENTS.md): close, never a 1:1 copy. Our own identity comes later.
- **Art direction** (owner): "we aren't making the graphism like Duskbloods". The game should look like Type Soul (a stylized Roblox anime action game), but more detailed, never simplistic, with far more depth.
  - Duskbloods is the reference for gameplay, mood, scenery and UI structure.
  - The owner judged the C1 VFX and animations so far "bad": every effect and animation gets far more craft (layering, impact, anticipation, weight).
  - The reference study now samples every second (owner: "1 second!"); its home is `docs/reference/network-test/`.
- **Combat framework rework:** needed (the owner's Albert video), but not yet. First C1's skills, VFX, SFX and blade reach the bar. Then Claude reports, and the owner and Claude plan it together.

## 1. Status at a glance (2026-10-30)

| Milestone | Done | Now | Open |
|---|---|---|---|
| M1 Foundations | F1, F2 | | |
| M2 First complete match | W1 (blockout), L1, U1, Q0 (awaits the owner's review) | C1 | U2, S1, UI-R, U3, A1 |
| M3 Phase one | | | N1, AI hunters v1, SH1, E1, E2, E3, W2 |
| M4 Bosses | | | B1, B2, B3 |
| M5 Competitive loop | | | R1, R2, W3 |
| M6–M7 | | | X1–X8, Q1–Q7 |

Earlier snapshots (the 2026-10-29 code audit, Session 0, the reading list) are archived in [archive/production-plan-history-2026-10.md](archive/production-plan-history-2026-10.md).

## 2. How each slice is made

The process lives in AGENTS.md ("How the owner wants work done") and the session skills: `/bl-start` and `/bl-finish` (Claude), `bl-world-session` (ChatGPT).

## 3. Session 0: pre-flight

Done 2026-10-29; archived with the snapshots above.

## 4. Contracts to lock before content

These come first so later content plugs in without rework.

1. **Rules are data.**
   - `Definitions/Rules/<Id>` for Standard, Solo and Bound: phase lengths, region-choice times, cull schedule, final (lives, time cap, sudden death, HP bonus), revival delay, spawn separation and protection, reward formula, whether alliances are allowed.
   - `Registry` validates them. `TravelService` and the Hunt tab read the list instead of their own copies.
   - `Config.Match` gets a Studio-only fast profile (about a minute per phase).
   - The cull schedule is one field, so moving culls earlier is a one-line change.
2. **Participants, not Players.**
   - `Services/Match/ParticipantService` keeps one record per entrant, keyed by id: a UserId, or a negative id for a Studio bot.
   - A record holds eligibility, region, alive/dead, revival time, culled, lives, placement, kills, joined and left.
   - Respawning replaces the body, never the record. Leavers stay until settlement.
   - Replicated as attribute bags under `ReplicatedStorage.MatchState`, so screens never depend on world markers that may not be streamed in.
3. **One lifecycle.**
   - `Services/Match/MatchService`: Waiting → Countdown → Intro → RegionChoice → Phase n → PhaseResolve → … → FinalSetup → Final → Results → Return.
   - Server deadlines in `time()`. Every transition and award runs once. A UI fade never extends eligibility.
   - One job per child module: `Culling` (pure math), `Spawning` (region capacity, separation, ground and danger checks, protection), `Settlement` (one immutable result, Bloodgems once).
   - Match places turn off Roblox's auto-respawn. Revival: pick a region, wait 5 s, spawn with 3 s of protection that ends when you attack.
4. **Score ledger v2, the same `ScoreService` extended.**
   - Keyed by participant. Entries carry the phase and an event key, so a replayed event can't pay twice.
   - Entries can be revoked (a pledge overwritten).
   - Ranking covers eligible participants: first to reach a total wins, then a stable fallback.
   - Category totals feed commendations and the results screen.
5. **One death event for everyone.** Players get the same `Died` event as NPCs, with the killer and damage shares. Damage by a Shinigami or a minion credits its master. XP, Renown, the heal gauge, kill counts and match metrics all listen to it, so nothing awards twice.
6. **Allegiance in layers.** `CombatSim.Side` stays. A server-side resolver adds three separate layers that `CanDamage` consults: alliances (gameplay), encounter truces (boss fights) and the match's PvP switch (off while waiting). A party only decides admission.
7. **World contract.**
   - One shared list of tags and attributes: `BL_Region` (Region), `BL_Spawn` (Region), `BL_EnemySpawn` (Enemy or Zone, Count, Radius, Respawn), `BL_PactCircle` (Shinigami), `BL_Antechamber`, `BL_FinalArena` + `BL_FinalSpawn`, `BL_RitualSite`, `BL_Interactable` (Kind, Id), `BL_BossArena`, and the Manor's `BL_CombatZone`.
   - `WorldService` checks the place at boot (unknown ids, missing required sites, markers with no ground) and prints a report.
   - World builders only stamp tags; they never write code.
8. **Interactables.**
   - One hold-to-claim framework for chests, pickups, lanterns, corpses, pledges, forges and boons: seen from afar → prompt (G) → hold → server check → first commit wins → the used state shows for everyone.
   - The server checks range, phase, eligibility and availability, and that you weren't hit during the hold.
   - Content is data (`Definitions/Interactables`, `Definitions/Items`).
9. **Modifiers.** One pipeline for damage, stamina, cooldown, healing and stagger modifiers. Boons, forge affinities and later Relics plug into it. Match modifiers reset with the match.
10. **Presentation.**
    - The server publishes state; the client presents it.
    - A focus owner gives exactly one screen the input (cursor, camera, gameplay context) and restores it on close, death or phase change. The Blood Table menu moves onto it.
    - New kit pieces: Banner, Toast (merges same-source bursts), Countdown, ParticipantCard, ClockDial, ReliefMap, LifeMarks, HoldPrompt.
    - Text sizes adapt so rendered text never falls below 16 px (captions 14) on small screens.
    - Our own drawn art for the clock dial, portrait frames and life marks. The relief map is drawn from the same layout data that builds the world, so they always match.
11. **Test harness.**
    - Rule-math tests (`BL_Debug:Invoke("LogicTests")`): culls for 2/3/4/8 entrants with leavers, ties, rewards, region capacity, ledger replay.
    - A whole fast match with bot entrants, solo in Studio.
    - The self-test pad gains a two-floor stair block for vertical NPC tests.

## 5. Roadmap

Eighteen slices take the game to a full playable proof of concept (M1–M5). Each milestone gets a git tag so it can be restored.

### M1 · Foundations

- **F1 · Rules, world contract, checks.** Contracts 1, 7 and 11.
  - Proof: logic tests pass; a clean world report in both places; self-test 44/44; no change in play.
- **F2 · Participants, ledger v2, deaths.** Contracts 2, 4 and 5, plus Studio bots.
  - Proof: logic tests for replay, revocation and ranking with leavers; a player kill credited on the test pad, including a Shinigami's kill crediting its master.

### M2 · The first complete match (Victorian place)

- **W1 · Cathedral Quarter blockout.**
  - A generator in `worlds/Victorian/`, installed in the place's `WorldTools`, idempotent `Build()`, built from the spec's coordinates.
  - Floors −18 (crypt), 0 (street), +8 (nave), +24 (gallery), +36/+48 (roof courts). Ground, interior, upper and crypt loops.
  - Tags: regions (D8), at least four spawns per region, enemy groups A–E (F reserved), sites R1 and R2, objects O1–O4. The Antechamber and the final garden as separate graybox locations.
  - Proof: the spec's section 10, steps 1–6: views A and B, every loop at zero stamina, stair clearances for R6 and the 1.35-scale Butcher, camera 6/11/16, jump tests, two exits per spawn, no roof that sees every spawn. A clean world report and a part budget.
  - Owner: walk it, then save/publish the place.
- **L1 · Match lifecycle (server).** Contract 3 in full.
  - Fast profile, revival and spawn protection, no PvP while waiting, culls from the rule data, spectate or return when culled, final lives, results, Bloodgems once (match award ids in the profile, settled on `OnLastSave` for disconnects), return through `TravelService`.
  - Proof: a full fast match with 7 bots in a solo test; death at a cutoff; every client reads the same state; logic tests; self-test.
- **U1 · Match screens I.**
  - The focus owner, legible text sizes, the clock dial (top right, gold ritual dot, red end dot), the waiting/countdown roster, the intro card, region choice and revival on one relief-map system with distinct modes (deadline, confirm, explained fallback), the region name banner.
  - Proof: every gate in the UI standard, section 6.
- **Q0 · U1 finished properly** (owner, 2026-10-30, after reviewing U1; done 2026-10-30, waiting on the owner's review). Spec and critique: [match-screens.md](match-screens.md), "Q0 · v2".
  - Jumps raised: tap 12.8, air 10.8, full high jump 40 studs.
  - The text kit and the UI lint.
  - The Passage loading and teleport screen.
  - The Antechamber as a full menu screen.
  - The intermission v2: choose, rise, browse.
  - Spawn facing, the arrival reveal and the protection outline.
  - Plates in the World layer, the alert glint.
  - Falling: the "You fell" band and the body dissolving.
  - Objectives.
  - The themed prompt, Blood Table staging.
  - **Q0.11 Kurogane's pact site** (owner: "we need the Shinigami Kurogane spawn location"), with his spoken lines on pact and summon (owner: "white text like Duskbloods").
  - No AI hunter bodies in the phases (owner).
  - Proof: self-test 70/70 (Victorian) and 69/69 (Manor), logic 48/48, `MatchSmoke` 34/34, world report clean; a capture walk with a written critique, every item fixed or assigned.
- **C1 · Combat rework** (owner, 2026-10-30: next, before U2).
  - The SMG: a real bullet effect, and spread, so not every bullet of a burst lands.
  - The M1 chain: feel, hitstop, knockback (owner earlier: "when you M1 someone they get knocked back").
  - Light Beam and Blood Blade: redone to the VFX standard and ChatGPT's colour direction.
  - Also from the owner: level-ups that matter (damage and HP growth checked against a time-to-kill table), directional movement (8-way strafing while locked, directional dodges).
  - Research the reference footage first, write the spec, then build.
  - Proof: self-test cases for spread and knockback, plus a capture review of every effect.
- **U2 · Match screens II.**
  - Phase resolution (awards → standings and cutoff → the cull), spectate, the final setup banner, the medallion turning into two life marks, the results reveal, return and retry. Fix the Shinigami card (name and level on one line, status on a second).
  - Proof: the same gates, plus one interruption per screen (death or phase change).
- **S1 · Sound foundation** (owner: right after U2).
  - A cue registry with priorities and ducking.
  - Sounds from Roblox's audio library (AGENTS.md rule 2): UI, the countdown, the phase bell, hits, parry, Renown.
    - Briefed, searched and ranked by `tools/studio/Audio`, aimed at the reference's measured feel (`docs/reference/network-test/audio.md`).
    - The owner picks them in the audition panel; `Sfx` levels them.
    - No uploads needed.
- **UI-R · HUD and plates remade** (owner: they "lack depth"). The top-left vitals, the plates and the Shinigami card, rebuilt from the Duskbloods palette and screenshots: layered fills, engraved frames, our own textures.
- **U3 · In-match menu.** Standings, the rule card, "Leave the hunt" with D9's consequence spelled out.
- **A1 · Admission.**
  - Manor: quick join, create, private code, party.
  - MemoryStore registry with atomic party reservations and expiry; reserved servers; delist at T−5; late arrivals sent home; a failed teleport frees its slots and can retry; shutdown returns everyone. Hunt tab v3 (party list, code entry).
  - Proof: registry logic tested in Studio against a fake store, then one published session: two accounts go Manor → reserved match → short full match → results → Manor, plus overbooking, a wrong code and a failed-teleport retry.
  - Owner: two accounts, about 30 minutes.

### M3 · Phase one: explore, fight, grow

- **N1 · NPC vertical navigation.**
  - Pathfinding when the target is on another floor or out of sight; attack choice uses 3D reach with a vertical tolerance; home arrival and leash in 3D; an unreachable target gets menaced, then dropped; a path budget per tick.
  - Groups A–E go live; F after the spec's four cases pass: a player over the crypt, up the stairs, behind a wall, leaving the leash on another floor.
  - Proof: new self-test cases on the two-floor block, walk tests in the quarter, server frame time with 60 enemies.
- **AI hunters v1** (owner: right after N1).
  - They explore their region, fight enemies and earn Renown through the same ledger.
  - They defend themselves, and go to ritual sites in phases II and III.
  - Skill tiers come from data.
  - From then on they get bodies in the phases again (`Config.Match.AiBodies.Phases`).
- **E1 · Heal stake (C).**
  - A new input action. `Common.Heal`: 35% over 0.6 s, interruptible, spent once. 2 uses to start, 4 max, a kill gauge, refilled each phase, plus D3.
  - HUD badge with its gauge. Our own VFX: a local recovery effect and the HP rise in Verdant, never something that reads as immunity.
  - Proof: the brief's heal checks as self-test cases.
- **E2 · Interactables and items.**
  - Contract 8, chests and pickups, a 6-slot quick-item belt (replace or decline), one usable item, Flame lanterns and corpses (unlit → claiming → lit; the big ones pay their first claimant only), the crypt pickup (O3) and the shrine (O4). Item HUD with a tooltip, pickup notices.
  - Proof: two claimants, leaving range, a hit during the hold, a cutoff, a replayed request; world state and ledger agree.
- **E3 · Feedback and commendations.**
  - Renown toasts (amount and source, merged), level-up pulse and toast, unlock notices, target info over the locked enemy (name, HP, glint), compass v1 (relevant opportunities, height cues), top-2 kill and collector commendations at phase end.
  - Added after Q0:
    - the XP gain readout by the level bar;
    - objectives v2 (ritual sites, items);
    - pickup notices and item tooltips;
    - first-time help cards, kept in the Archive (a `SeenHelp` field in `ProfileTemplate`);
    - commendation progress;
    - the Manor's "Back from the hunt" card;
    - hiding Roblox's player list in match places (ask the owner first);
    - the floor readout in map browse, once the world gives floor heights.
  - Proof: UI gates; ties resolve the same way every time.
- **W2 · Art proof of concept.**
  - A lighting and value study for the quarter (grayscale at camera 6/11/16).
  - Then one street-and-cathedral corner to the premium bar: clay → materials → dusk light → causal detail → player view. First, find out why ChatGPT's PBR material test rendered blank.
  - Hero pieces are modelled in Blender by script, and the owner imports them.
  - A harsh written critique before the owner's review.

- **SH1 · Shinigami v2** (open items carried over from the archived 2026-10-29 snapshot; the owner places it): D5's pact level (a new pact starts 3 levels below its master; today a pact simply levels with its master), and the ranged and support roles.

### M4 · Bosses

- **B1 · Modifiers and Blood boons.** Contract 9; choose 1 of 3, up to 5 active, replace or decline; the effects row on the HUD.
- **B2 · Encounter framework.**
  - Trigger → invite nearby players (Join/Decline, 8 s) → remember where they stood → transport → truce → fight → win, lose or cancel → Repulsion split by damage share (rounding documented) → a personal boon claim → return → clean-up.
  - A boss bar that never shares the posture bar's place. The nave's enemy packs pause while R2 is in use.
- **B3 · The first original boss in the nave (R2).**
  - Our own design: silhouette, 3–5 attacks whose ground telegraphs match their hitboxes, one phase change.
  - A built body, not a scaled dummy. Animations authored by script for the owner to publish; VFX to the bar.

### M5 · The competitive loop

- **R1 · Ritual sites.**
  - Candidate sites listed in the map definition, one picked per match. Announced at 40% of the phase (clock dot, map, compass).
  - Bounds that cover stacked floors. Pledge pillars: hold to swear, owner name and accent, provisional score revoked when overwritten.
  - HP drain after leaving, with a warning ribbon until you're back. The player-kill rule (D4). Transactions freeze before standings.
- **R2 · The final, finished.** Sudden death and simultaneous deaths (D2), the HP bonus, the final garden's art (pale flowers, crimson moon), the victory ceremony, the cull presentation. Revival, cull survival, qualification and elimination each read as their own state.
- **W3 · Art across the quarter.** Replicate the approved kit, crypt and roof atmospheres, the ritual court and the nave; streaming, part and light budgets.

**M5 = the full playable proof of concept.**

### M6 · Depth (once the loop plays well)

X1 minions (spellbound fodder; cap and duration as data) · X2 forges and status effects (fire, lightning, poison buildup rules) · X3 bloodsacs and skill upgrades, random events of our own · X4 alliances, Bound duos, ally travel · X5 Atelier: skins and the Bloodgem shop · X6 Relics, after the owner's design · X7 Gustave's ultimate (Lv 12), guard counter and howl deflect (D6) · X8 class 2, added with zero core edits (carried over from the old build table).

### M7 · Quality passes (any can be pulled forward on request)

- **Q1 · VFX revisit:** Gōka with a real lingering fire zone (server ticks and expiry), Blood Blade, Light Beam, the summon, a saber trail with capped hitstop. A leak check: 50 casts leave no growing count of parts, lights or sounds.
- **Q2 · Audio:** the cue registry, plus library sounds the owner picks in the audition panel (combat cues first, 2026-10-31).
- **Q3 · Lag compensation** (audit H3).
- **Q4 · Performance and anti-exploit:** 8 players and 60 enemies, streaming, a review of every remote.
- **Q5 · Real models and animations:** enemies, the boss, Kurogane, Gustave's look; animation publishing in batches.
- **Q6 · Manor:** integrate ChatGPT's art; menu polish (map image, hover/confirm sounds); honest System and Archive tabs.

- **Q7 · Untested leftovers** (carried over from the old build table): lock-on flick-switching (needs two targets in range), and guard drain against a guarding target (dummies don't guard).

New effects and screens are built to the bar inside their own slice, as they're made. Only the revisit of the existing skills waits for Q1.

## 6. Decisions for the owner

All answered as recommended; every owner decision and approval is recorded in [engineering-plan.md](engineering-plan.md) §3. The original question table is archived in [archive/production-plan-history-2026-10.md](archive/production-plan-history-2026-10.md).

## 7. What I need from you, and when

Current asks: "Waiting on the owner" in [team-notes.md](team-notes.md). The 2026-10-29 timetable is archived in [archive/production-plan-history-2026-10.md](archive/production-plan-history-2026-10.md).

## 8. Risks and how they're handled

| Risk | Plan |
|---|---|
| Server Authority limits (1024 bytes of attributes per character, writes inside the simulation, 8 animation tracks) | A self-test check on the character's attribute budget; new per-player state that isn't simulated lives on the Player or in `MatchState` |
| Studio can't teleport | Lifecycle work is tested in Studio with bots; one batched published session per milestone |
| Pathfinding on stairs and stacked floors | Stairs with clean collision; pathfinding links where needed; tested on the pad before the quarter |
| PBR maps rendered blank in ChatGPT's test | Diagnosed first in W2, before any surface work depends on them |
| Mesh imports need your hands | Imports batched; parts and CSG carry the blockout and much of the proof of concept |
| Animations need publishing | Authored by script, published in one batch |
| Rojo 7.7.1 crashes on pulls | `tools/rojo-serve.ps1`; check Studio has the latest code before every test |
| One folder shared with ChatGPT | Stage only my own paths; never `git add -A` |
| Performance (8 players, 60 enemies, effects, lights) | A budget per slice, measured, not assumed |
| Scope creep | Depth content waits until the M5 loop is fun |

**Parallel work:** Studio and Rojo allow one session at a time to write code and drive Studio. Offline tooling (texture and map drawing scripts, Blender mesh scripts) can run in a separate session if you want it faster.

## 9. Lessons carried forward

They live where they're used now: AGENTS.md (evidence labels, honesty, quality, git), CLAUDE.md and `.claude/rules/` (Studio and Roblox facts), and the skills (testing, assets, environment art).
