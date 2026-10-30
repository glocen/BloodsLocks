---
name: bl-world-session
description: ChatGPT's BloodsLocks world-art session - the first-session setup after the owner switches ChatGPT on, then the start, build-and-review loop and finish of every world-art piece. Use at the start of every session. Not for Claude.
---

# World-art session (ChatGPT)

The rules are in `AGENTS.md`. Check its team mode first: if it still says "Claude only", stop and tell the owner.

## First session after being switched on

1. **Pull safely** (AGENTS.md, "Shared folder and git"). Then quote the four supreme rules back to the owner, to prove `AGENTS.md` loaded. If it didn't, the project folder probably isn't trusted in Codex: tell the owner.
2. **Catch up, don't redo.** Read the "Now" board and the team-notes entries since you were switched off (2026-10-30), then `worlds/world-contract.md`. Claude did the world art meanwhile; never redo or undo its work without the owner.
3. **Your old work.** Ask the owner before committing anything of yours still uncommitted in the folder (for example `docs/victorian-art-rebuild-handoff.md`). If you have an installed copy of the `bloodlocks-environment-art` skill in your Codex skills folder, compare it with `.agents/skills/bloodlocks-environment-art/`, merge anything newer into the repo copy, and ask the owner before removing the installed one: one version only.
4. **GPU check.** Run a tiny headless script that imports `tools/blender/blcommon.py`, builds a cube, calls `studio(scene)` and `render_views(...)`, and writes one PNG to the scratch folder: `blender.exe -b --factory-startup --python <script> -- <out_dir>` (Blender 5.2 in Steam's folder). Confirm in Blender's output that Cycles rendered on the GPU (`use_gpu` picks OptiX, then CUDA, on the RTX 4070).
5. **Eyes check.** Open that PNG with view_image. If it fails on Windows with "apply deny-read ACLs", tell the owner: it's a known Codex sandbox issue (openai/codex #31248) and the sandbox setting is the owner's call. You can't review art you can't see.
6. **The trial.** Your first piece is a head-to-head trial: you and Claude each build the same hero piece the owner picks, through `bl-asset-pipeline` with the `bloodlocks-environment-art` method. The owner judges both in Studio from the player's camera.

## Every session

1. Pull safely. Read the "Now" board and the newest entries. Check with the owner that nobody is playtesting the place you'll edit.
2. Work on one piece. Sketch it (layout, landmarks, lighting, sightlines), write the plan into the piece's doc under `worlds/`, critique it harshly against the vision, and build only what passes. Take the time it needs.
3. Build through `bl-asset-pipeline`: scripted Blender models, GPU renders that you look at and critique yourself, then publishing into Studio with `ModelAssembly`. Follow `bloodlocks-environment-art` for form, surface and composition.
4. Before replacing world content in Studio, keep a `ServerStorage.WorldBackups.<Name>_<date>` copy.
5. Judge it in Studio from the player's camera, at the player's distance, in the place's real lighting (`bl-studio-test`, "Captures"). A Blender render is no proof.
6. Check: the world report after any marker change, `Probe.Run()` in the Cathedral Quarter, and a part and light budget.

## Finish a piece

1. Log new assets in `docs/asset-log.md`.
2. Update the "Now" board and add one team-notes entry at the top (at most about 10 lines): what changed, where it lives, what's open, who it's for.
3. Commit only your own paths; push when the owner says go.
4. Tell the owner, each stated separately: implemented, tested, visually reviewed, owner-accepted.
