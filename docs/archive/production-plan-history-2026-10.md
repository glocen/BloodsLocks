# Archived: production-plan snapshots (2026-10-29)

Moved here unchanged on 2026-10-30: the one-time reading list, §1 "Where the code stands" (a snapshot from before F1) and §3 Session 0 (done). Still-open items were carried into the roadmap (SH1, X8, Q7).

**Read for this plan:** the whole-game brief, the UI standard, both evidence files and the archived draft, the Cathedral Quarter spec with its four sketches and layout data, the Manor depth notes and renders, the engineering plan, team notes, the Duskbloods reference and manual summary, UI research, north star, framework audit, the Manor art docs, ChatGPT's art skill, GitHub issues #1 and #2, and every file in `src/`.

## 1. Where the code stands (checked in `src/`)

| Area | Built | Still missing for the game |
|---|---|---|
| Player kit | Gustave: saber chain, strong/charged, guard/parry/howl, bite, burst SMG, Blood Blade, Light Beam, movement, lock-on | Ultimate; four unpublished animations (Howl, Bite, SMGBurst, BloodBlade); two-player checks |
| NPCs | `NpcService`, `EnemyBrain`, `NpcActor`; Wretch and Butcher; `BL_EnemySpawn` markers, kill credit, refill | Vertical navigation (today: flat distance and direct `MoveTo`); bosses; minions; real models |
| Shinigami | Kurogane: pact, summon, AI, death cooldown, regen, level mirror, Gōka | Pact-level rule; ranged/support roles; model and VFX to the bar |
| Growth | `ProgressionService` + `Leveling` (cap 20, XP separate from score) | Level-up feedback; healing; upgrades |
| Score | `ScoreService` ledger ("Renown"), enemy kills only | Ranking by match participant; keeping leavers; event ids; revocable entries |
| Menu / travel | Blood Table v2, class saving, public-server travel, hold Backspace to return | Reserved servers, match registry, parties, private codes |
| Match | Nothing yet: there is no `Services/Match` folder | The whole lifecycle |
| World | Victorian test enemy layout; `Victorian.Zones = {}` | The Cathedral Quarter, regions, spawns, sites |
| HUD | Vitals, Shinigami card, arsenal, posture, crosshair | Clock, map screens, phase/cull/final/results screens, heal stake, items, boss bar, compass, target info |
| Tests | `BL_SelfTest`: 19 cases, 44 checks | Rule-math tests, bot entrants, a fast match |

**Found in the code beyond the brief:**
1. A player at 0 HP gets Roblox's own respawn (`EntityService` zeroes `Humanoid.Health`). There's no revival control and no player-kill credit yet.
2. `ScoreService.Ranking` ranks every connected Player and deletes a leaver's book.
3. Rule ids are magic strings, written twice (`TravelService` and `UI/Menu/Hunt`).
4. A new pact "resets to level 1", and the next step mirrors the master's level, so the reset does nothing.
5. The UI scale floor (0.5) can draw 18 px text at 9 px. The Shinigami card is one 250 px line that overflows.
6. Theme's palette comment still calls Ember "stamina" (posture uses it).
7. The build table in engineering-plan section 12 is stale: NPC v1 and XP/Renown are done.
8. ProfileStore fires `Profile.OnLastSave` just before a session's final save. Match rewards can settle there when a player disconnects, without touching `DataInit`.

## 3. Session 0: pre-flight

| # | Step | Who |
|---|---|---|
| 1 | Pull ChatGPT's commit `5680db7`. Its paths don't collide with the uncommitted world/art files on disk (checked). A pull crashes Rojo 7.7.1, so serve with `tools/rojo-serve.ps1`, then reconnect both Studios | Claude pulls, owner reconnects |
| 2 | Check that each place's script count matches `src/`, then run `BL_SelfTest` in the Manor and in the Victorian place (baseline 44/44) | Claude |
| 3 | Confirm the Victorian place's `Workspace.AuthorityMode` is Server | Owner (Properties panel) |
| 4 | Reconcile the docs: build table, Lv 20 with separate XP, "Renown" as the display name, and links to the brief and this plan from CLAUDE.md and the engineering plan | Claude |
| 5 | Optional: two project skills, `bl-start` (pull, Rojo, find the Studios, self-test) and `bl-finish` (tests, notes, build table, commit), so every session opens and closes the same way | Claude |
| 6 | Answer the decisions in section 6 that block M2 | Owner |

---

Added 2026-10-30 at the owner's choice, unchanged: §6 (the answered decision table) and §7 (the 2026-10-29 timetable).

## 6. Decisions for the owner

Each comes with a recommendation. Whichever way it goes, it's data, so changing it later is cheap.

| # | Question | Recommendation | Needed before |
|---|---|---|---|
| D1 | Cull schedule. Ours: none after phase I, culls after II and III (8 → 8 → 6 → 3). The footage: after I and II (8 → 6 → 3, and phase III with three) | Keep ours: everyone plays 16 minutes before the first cut, which suits Roblox's casual players | L1 |
| D2 | Final rules | HP bonus for every finalist, scaled by their Renown (cap +30%). At 4:00 sudden death: one life each and a slow blood drain until one remains. Last two die at once: higher Renown wins, then first to reach it | L1 |
| D3 | Revival top-up and full-HP use | Heal uses refill to 2 on death if below (as in the manual). Using the stake at full HP is refused without spending | E1 |
| D4 | Player-kill Renown. Plan: 30 anywhere. Duskbloods: only inside ritual sites | Ritual sites only, plus the 2-Bloodgem kill bonus everywhere: phase-1 exploring stays safe and PvP goes to the objectives | F2 records it, R1 enforces it |
| D5 | Switching Shinigami | A new pact starts 3 levels below you (minimum 1) and gains a level each time you do | M3 |
| D6 | Kit rules | Keep attacks and sprint stamina-free. Add the guard counter and the howl deflecting projectiles (X7) | X7 |
| D7 | The score's name | Keep "Renown", or pick a name now | U1 |
| D8 | Regions for the proof of concept | Split the Cathedral Quarter into four regions: Lamplighters' Reach (south), Cloister (west), Bell Works (east), Chapter Close (north). ChatGPT's spec has it as one region; this needs your OK | W1 |
| D9 | Leaving early | A leaver keeps the participation reward (15) only; culled players get the full formula | L1 |
| D10 | Map growth | Make the first loop on the Cathedral Quarter alone; add districts through its three sockets after M5 | M5 |

**Approvals needed** (rule 11 and the keep list):
- **A-1:** `ProfileTemplate` gets `MatchAwards` (recent match ids, so a reward can't pay twice) and `PlayerHandlerData` gets `SettleMatch`. Additions only; `DataInit` stays untouched. Needed before L1.
- **A-2:** MemoryStore (the match registry), reserved servers, PathfindingService and image uploads are free Roblox services. They use Roblox's quotas, never money. Needed before N1 and A1.

## 7. What I need from you, and when

| When | What | Time |
|---|---|---|
| Session 0 | Reconnect Rojo after the pull; confirm AuthorityMode; answer D1–D3, D7–D9 and A-1 | ~10 min |
| After W1, W2, W3 | Walk the world; save/publish the Victorian place | ~10 min each |
| After U1, U2 | Review the screens | ~10 min each |
| A1 | One published session with two accounts | ~30 min |
| Around M3–M4 | Publish one batch of animations (Howl, Bite, SMGBurst and BloodBlade from ChatGPT's corrected R2 saves, then heal and boss) | ~15 min |
| W2, W3 | Import hero meshes with Studio's 3D Importer (prepared so it's a short step) | ~10 min |
| End of each milestone | Play it and judge the feel | as you like |
