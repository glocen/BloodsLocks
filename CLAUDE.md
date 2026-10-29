# BloodsLocks

PvPvE Roblox action game inspired by FromSoftware's The Duskbloods. Duskbloods is inspiration only: names, art and lore are our own. Owner: glocen.

## Where things are

- **The project folder is `C:\Users\gloce\BloodsLocks`**, a git clone of https://github.com/glocen/BloodsLocks. The old `Documents\BloodsLocks - Project` folder is retired (kept only as a backup).
- The game lives in Roblox Studio, reached through the Roblox Studio MCP. Places in universe 10772800943:
  - **Manor** hub (the hub is called the Manor now, not the castle) = place "ROLOCK", placeId 76593217243342.
  - **Victorian** match place = placeId 112559855790294.
- **Code lives in `src/` and reaches Studio through Rojo** (since 2026-10-29). The files are the source of truth: edit code in files, never in Studio's script editor (Studio edits get overwritten on the next sync). How-to: [docs/github-sync-lesson.md](docs/github-sync-lesson.md), Part 5.
  - `src/shared` → `ReplicatedStorage.Shared`: Config, Definitions, Simulation (Runner is the step pipeline), Assets, Net, Util
  - `src/server` → `ServerScriptService.Server`: Boot + Services
  - `src/client` → `StarterPlayer.StarterPlayerScripts.Client`: Boot + Controllers
  - `src/owner/Data`, `src/owner/Libraries` → `ServerScriptService.Data` / `.Libraries`: the owner's data system and libraries (ProfileStore, ProductManager, RockModuleServer)
  - `src/owner/Modules`, `src/owner/Events` → `ReplicatedStorage.Modules` / `.Events`: the owner's modules (MuchachoHitbox, StunHandlerV2, CameraShaker, RockModule, screen3D, Combat Agent placeholder, WeaponRarities, Tween list) and remotes
  - `src/storage/BLInput` → `ServerStorage.BLInput` (the input context)
  - Mapping: `default.project.json`. Tool versions: `rokit.toml` (`rokit install`).
  - Not in Rojo (place-specific, stays in Studio): world builds, `ServerStorage.WorldTools` / `WorldAssets` / `RBX_ANIMSAVES` / backups, Lighting, the `PlaceRole` workspace attribute.
  - The old jump/M1/block/HUD prototype was deleted on 2026-10-28 at the owner's request (they keep their own copy).
- Source of truth for every decision, spec and build step: [docs/engineering-plan.md](docs/engineering-plan.md)
- Duskbloods research notes: [docs/duskbloods-reference.md](docs/duskbloods-reference.md)

## Working rules (from the owner)

1. Step by step, like a puzzle. Finish and verify each piece before starting the next. No half-built pieces, no rush.
2. Locked decisions in the plan change only with the owner's OK.
3. ProfileStore compatibility is the top priority. Never create a second ProfileStore. Read profiles through `PlayerHandlerData.Profiles` / `PlayerHandlerData.WaitForProfile`, add fields to `ProfileTemplate`, and add mutations to `PlayerHandlerData` in its existing style.
4. When unsure how a mechanic should work, research Duskbloods (previews, wikis, gameplay write-ups) before deciding, and record findings in docs/duskbloods-reference.md.
5. UI must look coherent and well made. The style will change often, so every color, font and stroke comes from the Theme module.
6. `ServerScriptService.Data`, `ServerScriptService.Libraries` and `ReplicatedStorage.Modules` are the owner's keep list: adding to them is fine, but ask before replacing or removing anything in them. Everything else may be reorganized.
7. Keep the build-step table in docs/engineering-plan.md current.
9. World building is held to a premium, artistic standard (owner, 2026-10-29): every 3D space needs its own atmosphere (red/purple mood with blue and orange light, realistic Victorian gothic; keep the owner's lighting stack). No slop, no placeholder-looking builds. Process: sketch the design first (layout, landmarks, lighting, sightlines), write it into the plan, critique it harshly against the vision, and implement only if it passes. The same premium bar applies to VFX (owner, 2026-10-29: "as good as Duskbloods, nothing less"): effects are layered (textured beams/trails, particles, light, impact bursts), never single neon parts; review them visually before calling them done. Next world piece after the Duelist's kit: the castle hub (Roundtable-style, as big as it needs, with an open yard).
11. **The owner does not pay for anything** (owner, 2026-10-29). Always ask before using any tool, service, API, plugin or asset that could cost money, credits or quota, and say whether it might cost something. Stay fully custom: free tools, our own models, scripts and textures.
10. No Roblox AI generation for art (owner, 2026-10-29): don't use Studio's `generate_mesh` / `generate_material` / `generate_procedural_model`. We make our own: meshes are modeled in Blender (via the Blender MCP in `.mcp.json`, once connected), textures are drawn by our own scripts (`tools/`).
8. Pro-quality, modular code (owner, 2026-10-29): one job per module, no duplicated helpers, no magic strings, data over code. Follow "Code standards" in docs/engineering-plan.md section 7, and re-run the regression checks after any refactor.

## Studio facts that bite

- `Workspace.AuthorityMode` can't be read or set from MCP scripts (needs RobloxScript capability). Ask the owner to set it in the Properties panel.
- TeleportService doesn't work in Studio; teleports get tested in a published dev copy.
- Server Authority: custom state goes in attributes (first 64 per instance, names and string values ≤50 chars), written only inside `RunService:BindToSimulation`; time comes from `time()`; at most 8 playing tracks per Animator; Tools aren't fully supported (weld weapon models instead); RemoteEvents aren't on the simulation timeline.
- Studio sessions use the "Test" ProfileStore; live servers use "Live".
- MCP `execute_luau` code runs as a plugin with its own module instances, so it can't see live game state through `require`. During playtests, use the Studio-only bridge from the Server context: `game.ServerStorage.BL_Debug:Invoke("Commands")` lists what's available (Ping, NetDropped, GetData, AddBloodgems, RemoveBloodgems, ...). Services add commands with `DebugService.Register`.
- Known output noise to ignore: the ZonitoVisuals plugin's HTTP warning and `rbxassetid://203785492 ... Asset type does not match` (it's not in the place's instances or scripts).
- Workspace gravity in this place is 145.
- Roblox's own `StarterPlayer.PlayerModule.ControlModule.InputReplication` calls `Humanoid:Move` and resets `Humanoid.AutoRotate` every simulation step. Don't rely on AutoRotate staying false; set the root CFrame (lock-on facing) or velocity (dodge) yourself each step.
- `InputBinding:Fire()` only works when the binding's `Type` is `Scriptable`.
- Animations: temporary ids from `KeyframeSequenceProvider:RegisterKeyframeSequence` load in client/plugin code but NOT inside the Server Authority simulation (the server can't load them). New animations must be published by the owner (Animation Editor on `workspace.R6` → Load from RBX_ANIMSAVES.R6 → Publish) before they play in tests.
- Studio `screen_capture` is blank in edit mode but works in play mode, a moment late; capture frozen or slowed effects (spawn the `Client.Vfx` module from the Client context) instead of racing a fast projectile.
- Teammates: the owner also works with ChatGPT. Leave handoff notes in [docs/team-notes.md](docs/team-notes.md).
- Attributes: max 1024 bytes in total per instance (names count), not just 64 attributes. Stored names are 2-4 letter codes; always go through `EntityState.Attr`.
- MCP `user_mouse_input` / `user_keyboard_input` add ~0.3s per action, too slow for combo timing. For exact-timing tests, fire the Scriptable test bindings from the Client context: `LocalPlayer.BLGameplay.<Jump|Dodge|Attack|Guard|Strong|Ranged|Bite|Face|Aim>.Script:Fire(state)`.
- Combat feedback events (hit, evaded, blocked, parry, howl, guard broken, bite) are attributes on the entity's Humanoid (`EntityState.Fx`), so they don't count against the character's 1024 bytes.
- Debug bridge command `HitAfterNextDodge(playerName, delay)` queues a dummy hit a set time after the player's next dodge (i-frame tests).
- If the owner is playing in Studio during a test, their inputs show up in the logs; ask them to step away for timed tests.
- Scripts open in Studio editor tabs keep their own document text: after writing `.Source`, sync open tabs with `ScriptEditorService:UpdateSourceAsync` (or edit through it) so a stale tab can't overwrite the new code.
- The Studio MCP `studio_id` changes when Studio restarts; call `list_roblox_studios` first.
- Input-to-server delay varies between Studio sessions; timed tests (parry) should measure the delay rather than assume one.
- `Enum.Font.Garamond`'s family is `rbxasset://fonts/families/Guru.json`; build weights with `Font.new(Font.fromEnum(...).Family, weight)`.
- Tab is also the player-list key, so `InputBegan` reports it as processed; skip keys only while a TextBox is focused.
- Client context scripts can't see `ServerStorage`; put VFX templates in `ReplicatedStorage.Shared.Assets.Vfx`.
- Beam textures run their **vertical** image axis along the beam's length; draw beam art tall (see engineering-plan 11c).
- Windows **Controlled Folder Access** is on: git, Rojo, Python and PowerShell can't write anywhere under Documents (only the file Write/Edit tools can). That's why the project lives in `C:\Users\gloce\BloodsLocks`. Don't change the Windows setting. Git and Rojo commands there need the Bash sandbox disabled. Draw generated assets into the scratchpad; upload images by serving that folder with `py -m http.server` on 127.0.0.1 and calling MCP `upload_image` with the URLs. Use `py`, not `python` (the latter is the Store shim).
- Weapon models: `WeldConstraint`s inside a cloned model don't hold under Server Authority (parts stay at the template's origin). Join parts with `Weld` + explicit C0.
- To place a player for a test, set the root CFrame from the Server context; client-side CFrame writes are overridden under Server Authority.
