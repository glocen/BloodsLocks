---
name: bl-studio-test
description: Test and inspect BloodsLocks in Roblox Studio through the Studio MCP - playtests, BL_SelfTest, BL_Debug commands, logic tests, world report, match testing, timed input tests and screen captures. Load before any playtest, capture or debug-bridge call.
---

# Testing in Studio (shared by Claude and ChatGPT)

## Before you trust a result

- `list_roblox_studios` first: the `studio_id` changes when Studio restarts.
- Check Studio has your latest code (search a script's `Source` for your new line). A playtest runs the code it started with: restart it after edits.
- A playtest locks the place's Edit DataModel, so MCP edits fail while it runs: never playtest a place a teammate is editing.
- If the owner is playing during a test, their inputs show up in the logs: ask them to step away for timed tests.
- Read logs and reports for what matters (counts, FAIL lines, errors); don't pull whole logs into the conversation.
- Known output noise to ignore: the ZonitoVisuals plugin's HTTP warning and `rbxassetid://203785492 ... Asset type does not match`.
- Studio sessions use the "Test" ProfileStore; live servers use "Live".

## The tools

- **Regression self-test** (Client context, any place, during a playtest): `game.ReplicatedStorage.BL_SelfTest:Invoke()`, or `:Invoke("Dodge")` for the checks whose name contains it. It builds a test pad at y=3000 with its own dummy, runs every movement and combat check against Config and definition numbers, cleans up and returns a PASS/FAIL report. Cases: `src/client/Controllers/Core/SelfTestController/Cases.luau`.
- **Debug bridge** (Server context, Studio only): `game.ServerStorage.BL_Debug:Invoke("Commands")` lists every command. Services add commands with `DebugService.Register`.
- **Logic tests:** `BL_Debug:Invoke("LogicTests")` checks the rule math (culls, rewards, rules, world contract); cases in `src/server/Services/Core/LogicTestService/Cases.luau`. **World report:** `BL_Debug:Invoke("WorldReport")` checks the place's tagged markers against `Shared.World.Tags`; WorldService also logs a one-line summary at boot. Run both with the self-test after a change.
- **Test pad** (SelfTestService): `TestPad`, `TestHitAfter(who, "Now"|"Dodge"|"Guard", delay, actionId?)`, `TestPadClear`, `HitAfterNextDodge(who, delay)`. Use `BL_Debug:Invoke("TestPad", player)` for combat or VFX tests, since the Manor hall is a safe zone.
- **Enemies:** `Enemies` lists enemies, kills and the last kill; `SpawnEnemy(who, id, distance)`.
- **Participants:** `Participants`, `FillWithAi`, `AiScore`. `TestLethalHit(side)` and `TestLastDeath` check player-kill credit.

## Match (Victorian place)

- In Studio the match stays Idle until `BL_Debug:Invoke("MatchStart")` (fast lengths), so a plain playtest keeps the self-test environment. Live match servers start at once.
- `MatchSkip` ends the current wait, `MatchState` shows the standings, `MatchKill(id)` kills an entrant (returns false for bodiless AI hunters), `MatchSmoke` runs a whole checked match; restart the playtest afterwards, since it ends in Return. Lifecycle code: `src/server/Services/Match/MatchService`.
- TeleportService doesn't work in Studio: teleports are tested in a published dev copy. Teleport error 773 means the target place isn't published.

## MCP limits

- `execute_luau` runs as a plugin with its own module instances, so it can't see live game state through `require`: use the debug bridge from the Server context. Cold-require a module (`:Clone()`) after editing it.
- `Workspace.AuthorityMode` can't be read or set from MCP (needs RobloxScript capability): ask the owner to set it in the Properties panel.
- HttpService is disabled for MCP plugin code too.
- `user_mouse_input` / `user_keyboard_input` add about 0.3 s per action, too slow for combo timing. For exact timing, fire the Scriptable test bindings from the Client context: `LocalPlayer.BLGameplay.<Jump|Dodge|Attack|Guard|Strong|Ranged|Bite|Face|Aim>.Script:Fire(state)`. Input-to-server delay varies between sessions: timed tests (parry) measure it rather than assume it.
- To place a player for a test, set the root CFrame from the Server context.
- Scripts open in Studio editor tabs keep their own document text: after writing `.Source`, sync open tabs with `ScriptEditorService:UpdateSourceAsync` (its callback returns one string), or a stale tab can overwrite the new code.

## Captures

- `screen_capture` is blank in edit mode and works in play mode, a moment late. It doesn't draw BillboardGuis, and its camera parameters don't move the play camera (CameraController drives it every frame).
- Match screens: the fast profile runs phases in seconds, faster than MCP calls. Start with `BL_Debug:Invoke("MatchStart", nil, false)` (the rule's real lengths) and advance with `MatchSkip`.
- Fast effects, frozen: require the client's `Vfx` modules from the Client context, set `Kit.TimeScale` (that copy only), play the effect, then set it to 0 and every emitter's `TimeScale` to 0. Capture frozen or slowed effects instead of racing a fast projectile.
- The test pad is far away, so the Studio `R6` animation rig streams out on the client: clone the character for a posed preview. A client-only rig's Animator doesn't step, so preview poses by setting `Motor6D.Transform`.
