# World contract: what the game code reads from a world

For whoever builds a world (see the team mode in `AGENTS.md`). The code truth is `src/shared/World/Tags.luau`, which lists every tag and its attributes; this page says how the game uses them. Claude keeps it current. Gathered from the team notes of 2026-10-29 and 2026-10-30.

## Markers

- Gameplay markers are tagged parts (`BL_Region`, `BL_Spawn`, `BL_EnemySpawn`, `BL_PactCircle`, `BL_RitualSite`, `BL_Antechamber`, `BL_FinalArena`, `BL_FinalSpawn`, `BL_BossArena`, `BL_Interactable`, `BL_CombatZone`, `BL_Stage`). Only markers inside `workspace` are live; masters and backups in storage are ignored.
- **Regions:** `BL_Region` volumes with a `Region` attribute. The Victorian ids are `LamplightersReach`, `Cloister`, `BellWorks` and `ChapterClose`; `BL_Spawn` uses the same ids in its `Region` attribute.
- **Spawns:** at least one `BL_Spawn` per region. The match places players at `BL_Antechamber` while they wait, at `BL_Spawn` by region (kept apart) during the phases, and at `BL_FinalSpawn` for the final, so final spawns must stand on a floor. A hunter arrives facing the spawn's most open direction (16 rays at chest height), so spawn orientation doesn't matter; the world report flags a spawn whose most open view is under 20 studs as "cramped".
- **Enemies:** `BL_EnemySpawn` parts with `Enemy` (the enemy id), and optional `Count`, `Radius`, `Respawn`. Deleting a marker removes its enemies.
- **Pact circles:** `BL_PactCircle` with a `Shinigami` attribute. Keep them invisible: the client dresses each one (moonlight shaft, sigil, light, and the companion waiting, facing the marker's look direction, so turn the marker to aim it). A visible marker counts as its own art and gets no sigil.
- **Manor combat:** combat exists only inside `BL_CombatZone` volumes; the hall is a safe zone.
- Keep each marker inside the region volume it belongs to: the region map marks every region's pact circles, ritual sites and enemy groups.
- Attribute string values must stay at 50 characters or fewer, or Roblox drops them at play time.

## The region map

- The intermission map uses `ServerStorage.WorldAssets.<MapId>MapRelief` (for the Victorian place, `VictorianMapRelief`) when it exists, recoloured by height: keep it a clean, simplified top-down model in step with the city.
- Without it, the map copies the visible, anchored geometry inside the `BL_Region` volumes, so roofs and big canopies show up: keep region volumes tight to the playable streets.
- Each region has a one-line `Blurb` in `src/shared/Definitions/Maps/Victorian.luau`. Rewrite them freely to match the city.

## The Antechamber

- Players wait under a full menu screen with their hunter on a stage. Until the room is dressed, a dark velvet backdrop hides it. When the room's art is done, set `Dressed = true` on the `BL_Antechamber` volume: the backdrop goes away and players can press P to step out into the room.
- Optional `BL_Stage` marker: where a hunter stands for a full-screen menu, facing the camera. One in the Antechamber lines arrivals up beside it; one near the Blood Table in the Manor places the hunter exactly.

## Movement envelope

- Players jump high: a tap jump, a charged high jump, three air jumps and an air dash (the numbers are in `src/shared/Config/Movement.luau`). Anything a player must not reach needs more height above the highest nearby standing surface than a full jump chain, plus an air dash's distance sideways. Routes keep their 14-stud headroom.

## Checks

- Edit mode, Cathedral Quarter: `require(game.ServerStorage.WorldTools.CathedralQuarter.Probe).Run()` walks the routes.
- During a playtest: `game.ServerStorage.BL_Debug:Invoke("WorldReport")` checks every marker (wrong types, unknown ids, markers with no ground under them, and what's still missing).
- A playtest locks the place's Edit DataModel: coordinate playtests through the owner.
- Lighting lessons from tuning the blockout: `worlds/Victorian/CathedralQuarter/w1-blockout.md`.
