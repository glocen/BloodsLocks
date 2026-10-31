---
name: bl-asset-pipeline
description: Make a BloodsLocks model, texture map or animation through our own pipeline - headless Blender scripts on the owner's GPU, self-review renders, the BL_Import mesh channel, ModelAssembly publishing, .rbxm install, animation authoring and publishing. Use for any model, prop, kit piece, map or animation.
---

# Asset pipeline (shared by Claude and ChatGPT)

The pipeline Claude built in C1 for Gustave's machine pistol. Everything is scripted and kept in git, so every asset can be rebuilt, tuned and reviewed. For environment pieces, also follow the art method in `.agents/skills/bloodlocks-environment-art/SKILL.md`.

## 1. Model and bake in Blender (headless, on the GPU)

- Write a script in `tools/blender/<name>.py` and run it headless: `blender.exe -b --factory-startup --python <script> -- <out_dir>` (Blender 5.2, in Steam's folder). Output goes to the scratchpad, never into the repo.
- Build on `tools/blender/blcommon.py`: geometry in studs (1 unit = 1 stud), bevels and booleans, Roblox-calibrated metal and wood materials, `unwrap`, `bake_pbr` (Color, Normal, Roughness, Metalness, optional Emissive mask), `studio` and `render_views` for preview renders, `export_mesh_json` for Studio. Add new shared helpers there, not copies in each script.
- `--factory-startup` ignores the owner's Blender preferences, so the GPU must be enabled by script: `use_gpu(scene)` picks OptiX, then CUDA, on the RTX 4070. `bake_pbr` and `studio` call it already; call it in any new render or bake setup.
- Keep each asset's script and its Studio recipe (`tools/studio/Models/<Name>.luau`) in git: they are the asset's source.

## 2. Review the renders yourself

- Render the piece with `studio` + `render_views` (clay first when form is the question, then baked materials), and look at every image yourself before going further (Claude: Read the PNG; Codex: view_image).
- Critique harshly against the bar and the reference mood; fix and re-render until it passes. Only then go to Studio.

## 3. Bring it into Studio (Edit mode, through MCP)

1. **Import:** copy the exported JSON into `build/import/<Name>.txt`; Rojo syncs it to `ServerStorage.BL_Import`.
2. **Publish:** `local Assembly = require(game.ServerStorage.BL_Tools.ModelAssembly:Clone())`, then `Assembly.PublishMesh(...)` for each mesh. Always require `BL_Tools` modules as a `:Clone()` from MCP, so Rojo edits load.
3. **Maps:** upload the baked maps with MCP `upload_image`, serving the scratchpad with `py -m http.server`; put the ids in the model's recipe.
4. **Assemble:** the recipe in `tools/studio/Models/<Name>.luau` builds the model; `Assembly.Serialize` gives base64. Write that to a file, decode it with `py`, and check its adler32 against Studio's before installing the `.rbxm` in `src/shared/Assets`. World pieces go into the place's world instead, with a backup of what they replace.
5. **Clean up:** empty `build/import` afterwards; it bloats the place.

## 4. Judge it in the game

- A beautiful Blender render is no proof: judge every piece in Studio, from the player's camera, at the player's distance, in the place's real lighting (`bl-studio-test`, "Captures").
- PBR maps once rendered blank in a Studio test: confirm the maps really render before calling a material done.

## Facts that bite

- A published mesh keeps its vertex origin: export centred (`export_mesh_json` does), and place the part at the recorded centre (`Assembly.Centre`).
- Join parts with `Weld` + explicit `C0`, never `WeldConstraint` (it doesn't hold under Server Authority).
- In Roblox a metal's base colour is its reflectance: blued steel needs about 15–20 % (linear), or it renders flat black in dusk lighting. `SurfaceAppearance` supports `EmissiveMaskContent` / `EmissiveStrength`.
- HttpService is disabled for MCP plugin code too: data reaches Studio only through Rojo (`BL_Import`) and leaves only through MCP output.
- Budgets: about 20k triangles per MeshPart and 1024 px textures; split big pieces into kit modules; check StreamingEnabled.
- Studio's 3D Importer, if ever needed (FBX): scale 0.01 and a Y 180° correction; Escape cancels the importer.
- A Blender MCP may be set up in `.mcp.json` for live sessions; prefer scripts, which can be rerun and reviewed.

## Effect textures (sprites, flipbooks, trail and beam strips)

Different from a model's maps: each is a standalone image an effect references by id. Every one is tracked by `tools/vfx/textures.py`; its registry says what each texture is, which generator draws it and how it's laid out.
1. **Draw:** add or retune the generator in `tools/blender/vfx_sprites.py` (Blender: numpy shapes, Cycles volumes) or `tools/vfx_textures.py` (plain Python), and register the texture in `textures.py`. Draw art white and let the game tint it, so an uploaded image never carries a colour that could read as blood.
2. **Build:** `py tools/vfx/textures.py build [Name ...]` writes `build/vfx/` and the numbered review sheet `build/vfx/review.png`. Read the sheet and critique it; rebuild until it passes. Check every texture against AGENTS.md rules 2 and 4 before going on: uploads land on the owner's account and are moderated.
3. **Upload:** copy what's new or changed to the served scratchpad folder and call MCP `upload_image` with the `http://127.0.0.1:8765/...` URLs.
4. **Record:** `py tools/vfx/textures.py record Name=<id> ...` writes the ids, with each built file's hash, into the generated `src/client/Vfx/Textures.luau`; `Vfx/Kit` reads it (`Kit.Textures.Name`).
5. **Check:** `py tools/vfx/textures.py status` lists every texture as current, changed since its upload, never uploaded or not built. Effects use only registered textures: no Creator Store art (rule 2).

## Animations

Animate in Blender (owner, 2026-10-31: "do the animation in Blender, it should be better"):
- A clip script `tools/blender/<name>_anim.py` builds on `tools/blender/r6anim.py`:
  - an exact R6 rig from Roblox's own Motor6Ds;
  - poses in the body-space angles of `Author`, keyed with Blender's curves (Bezier, BACK overshoot, EXPO snaps);
  - `plant` keeps feet on the floor, and `contacts` solves arms, head and torso onto points of another body (`reach`, `gaze`, `lean_to`);
  - `render_sheet` reviews from the game's player camera;
  - `export` bakes one pose per frame.
- Time clips from the game's definitions (`luau_table`), never retyped numbers. Run it headless (`review`, `export` or `all`) and Read every sheet; print the contact distances and fix them.
- Copy the baked `Anim_<Name>.txt` to `build/import/`. In Edit mode through MCP:
  - `local Author = require(game.ServerStorage.BL_Tools.Animations.Author:Clone())`;
  - `Author.SaveBaked("<Name>")` writes `BL_<Name>` into `ServerStorage.RBX_ANIMSAVES.R6`;
  - `Author.Publish("<Character>", "<Name>")` returns the id for `Shared.Config.Animations`.
- Review the live clip from the player's camera: freeze tracks with `AdjustSpeed(0)` and emitters with `TimeScale = 0`, then capture.
- Older clips are body-space kits in `tools/studio/Animations/<Kit>` (`Author.Save(kit, { "<Name>" })`); they move to Blender as they're redone.
- Fallback when publishing from MCP fails: the owner publishes (Animation Editor on `workspace.R6` → Load from `RBX_ANIMSAVES.R6` → Publish).

## Always

- Log the new asset in `docs/asset-log.md` (asset, where it lives, made by, how, license).
