---
paths:
  - "src/server/Services/Match/**"
  - "src/server/Services/Core/WorldService.luau"
  - "src/server/Services/Core/TravelService.luau"
  - "src/server/Services/Core/NpcService/**"
  - "src/server/Services/Core/ScoreService.luau"
  - "src/shared/Match/**"
  - "src/shared/World/**"
  - "src/shared/Definitions/Rules/**"
  - "src/shared/Definitions/Maps/**"
  - "src/shared/Definitions/RuleDefaults.luau"
  - "src/shared/Config/Match.luau"
  - "src/client/Controllers/Match/**"
  - "src/client/UI/Match/**"
  - "src/client/Controllers/Core/PactSiteController.luau"
  - "worlds/**"
---

# Match and world contract

- Only markers inside `workspace` are live; masters and backups in storage are ignored.
- Match rules are `Definitions/Rules/<Id>` over `Definitions/RuleDefaults`, read with `Registry.Rule(id)` / `Registry.Rules()`. The waiting room and the Studio fast profile are in `Config.Match`.
- Participants are keyed by id: a player's UserId, or a negative id for an AI hunter (D11: 1 real player minimum for the proof of concept; AI hunters fill the field to 8). Scores go through `ScoreService` by id; clients read entrants from `ReplicatedStorage.MatchState.Participants` (`Shared.Match.MatchState`).
- AI hunters have no bodies during the phases (`Config.Match.AiBodies`); the final gives them bodies.
- Match screens read `ReplicatedStorage.MatchState`, never world markers, which may not be streamed in.
- Enemy spawns are world content: parts tagged `BL_EnemySpawn` with `Enemy`, optional `Count`, `Radius`, `Respawn`. The Victorian place has a test layout in `workspace.BL_EnemySpawns`.
- `BL_PactCircle` markers are dressed by the client (`PactSiteController`): the moonlight shaft, the sigil, the light and the waiting Shinigami. A Shinigami's look is `Simulation/ShinigamiBody` plus the definition's `Look`; what it says is the definition's `Lines`, shown with `UI/Hud/Subtitle`. Pact markers stay invisible (a visible marker counts as its own art and gets no sigil).
- In the Manor, combat exists only inside `BL_CombatZone` volumes (`Shared.Util.Zones`); the hall is a safe zone. Match places are combat zones everywhere.
- World art follows the team mode (AGENTS.md). While it's "Claude only", the worlds are yours: build them with `/bloodlocks-environment-art` and `/bl-asset-pipeline`, and back up what you replace. When ChatGPT is on, its worlds (art, geometry, markers, Lighting) aren't yours to edit: send requests through the team notes, and before a playtest check with the owner that ChatGPT isn't mid-install.
