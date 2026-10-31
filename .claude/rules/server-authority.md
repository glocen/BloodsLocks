---
paths:
  - "src/shared/Simulation/**"
  - "src/shared/Config/**"
  - "src/shared/Definitions/**"
  - "src/server/**"
  - "src/client/Controllers/Core/SimulationController.luau"
  - "src/client/Controllers/Core/CameraController.luau"
  - "src/client/Controllers/Core/LockOnController.luau"
---

# Server Authority, simulation and combat

- `Workspace.AuthorityMode` is Server in both places. Workspace gravity is 145.
- Custom state lives in attributes, written only inside `RunService:BindToSimulation`. Time comes from `time()`. RemoteEvents aren't on the simulation timeline.
- Attribute budget: 1024 bytes per instance in total (names count), only the first 64 attributes, names and string values ≤ 50 characters. Stored names are 2–4 letter codes: always go through `EntityState.Attr`. Combat feedback events (hit, evaded, blocked, parry, howl, guard broken, bite) are attributes on the entity's Humanoid (`EntityState.Fx`), so they don't count against the character's budget. Per-player state that isn't simulated lives on the Player or in `MatchState`.
- At most 8 playing tracks per Animator. Temporary ids from `KeyframeSequenceProvider:RegisterKeyframeSequence` play in client and plugin code but not inside the simulation: publish new animations first (`/bl-asset-pipeline`, Animations). The server's `GetPlayingAnimationTracks` doesn't list simulation tracks; the client does.
- Tools aren't fully supported: weld weapon models instead. `WeldConstraint`s inside a cloned model don't hold under Server Authority (parts stay at the template's origin): join parts with `Weld` + explicit `C0`.
- `SetNetworkOwner` throws under Server Authority: never call it.
- Simulation callbacks (`BindToSimulation`) may not destroy instances: `Instance:Destroy` and `Debris:AddItem` throw there, and the error aborts the rest of that step (tested 2026-10-31). Keep instance lifetimes in a service outside the simulation (e.g. `CombatService.Apart`).
- Roblox's `StarterPlayer.PlayerModule.ControlModule.InputReplication` calls `Humanoid:Move` and resets `Humanoid.AutoRotate` every simulation step. Don't rely on AutoRotate staying false: set the root CFrame (lock-on facing) or velocity (dodge) yourself each step.
- Anything that sets a character's velocity on the ground (dodge, lunge) must also raise `Humanoid.WalkSpeed` to that speed, or Roblox's walk controller brakes it.
- Client-side CFrame writes are overridden: move or place characters from the server.
- `InputBinding:Fire()` only works when the binding's `Type` is `Scriptable`.
- Allegiance: enemies fight for `EntityState.HostileSide` (OwnerId 0), so they never hurt each other; side-less entities (training dummies) can be hit by anyone.
- `Vector.Flat` returns a unit vector: never use it for distances.
