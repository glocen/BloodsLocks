@AGENTS.md

<!-- Claude-only layer on top of AGENTS.md. Keep it short: topic gotchas go in .claude/rules/ (they load when Claude touches matching files), procedures go in skills. Block HTML comments like this one are stripped from Claude's context, so they cost nothing. -->

# Claude: you build the game

Code, Studio integration, tests and tooling, and, while the team mode is "Claude only" (AGENTS.md), world art too. Repo: github.com/glocen/BloodsLocks, cloned at `C:\Users\gloce\BloodsLocks`.

## Places

- Universe 10772800943. The Manor hub is place "ROLOCK" (76593217243342); call it the Manor, never the castle. The Victorian match place is 112559855790294.
- Every place runs the same code. The `PlaceRole` workspace attribute (`"Manor"` / `"Match"`) splits role services; read it only through `Shared.Util.PlaceRole`.

## Rojo and Studio, every session

- `src/` is the source of truth. Rojo must be serving and each Studio connected (Plugins → Rojo → Connect), or edits never reach Studio. Tool versions: `rokit.toml` (`rokit install`).
- Mapping (`default.project.json`): `src/shared` → `ReplicatedStorage.Shared` (Config, Definitions, Simulation with `Runner` as the step pipeline, Assets, Net, Util, World, Match); `src/server` → `ServerScriptService.Server`; `src/client` → `StarterPlayer.StarterPlayerScripts.Client`; `src/first` → `ReplicatedFirst.BL_First`; `src/owner/Data` and `Libraries` → `ServerScriptService.Data` / `.Libraries`; `src/owner/Modules` and `Events` → `ReplicatedStorage.Modules` / `.Events`; `src/storage/BLInput` → `ServerStorage.BLInput`; `tools/studio` → `ServerStorage.BL_Tools`; `build/import` → `ServerStorage.BL_Import`.
- Rojo 7.7.1 crashes (`change_processor.rs`, file not found) when files vanish for a moment: whole-file rewrites and every pull or rebase. Serve with `tools/rojo-serve.ps1` in a visible terminal; after a pull or a crash the owner reconnects each Studio.
- Before trusting a test, check that Studio has your latest edit (search a script's `Source` for the new line). A playtest runs the code it started with: restart it after changing code.
- Not in Rojo, stays in each place: world builds, `ServerStorage.WorldTools` / `WorldAssets` / `RBX_ANIMSAVES` / backups, Lighting, `PlaceRole`.
- The Studio MCP `studio_id` changes when Studio restarts: call `list_roblox_studios` first. Load `/bl-studio-test` before any playtest, self-test, capture or `BL_Debug` call.

## This Windows machine

- Windows Controlled Folder Access is on; don't change it. Git, Rojo, Python and PowerShell can't write under Documents, which is why the project lives in `C:\Users\gloce\BloodsLocks`. The old `Documents\BloodsLocks - Project` folder is a retired backup: never work there. Git and Rojo commands need the Bash sandbox disabled. Use `py`, not `python` (the Store shim). Draw generated assets into the scratchpad.

## Done means

- `BL_SelfTest` and the logic tests pass after every code change, and every new mechanic or rule adds a case. Anything players see gets a player-camera review. Then run `/bl-finish`.

## Context

- Start a session with `/bl-start`. A session can cover one slice or more; `/clear` between unrelated slices so old context doesn't ride along.
- Topic rules load from `.claude/rules/` when you touch matching files: code standards, server authority, UI, VFX, match and world.
- Skills: `/bl-start`, `/bl-finish`, `/bl-studio-test`, `/bl-asset-pipeline` (models, maps, animations), `/bloodlocks-environment-art` (environment art method), `/bl-reference-study` (learning from the reference footage). The last four are shared with ChatGPT: their text lives in `.agents/skills/`.
- Read big files by section, never whole: search for the heading, then read that range. Libraries (`ProfileStore.luau`, MuchachoHitbox) only by search.
- Use the Explore subagent for broad searches and log digging, so only the conclusion lands in the main context.

# Compact instructions

When compacting, keep: the current slice and its acceptance checks, files changed, test results, decisions the owner made this session, open questions, and any teammate's work in progress.
