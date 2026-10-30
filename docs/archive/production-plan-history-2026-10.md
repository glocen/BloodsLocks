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
