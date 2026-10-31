# BloodsLocks: rules for every AI teammate

PvPvE Roblox action game with a gothic Victorian mood, inspired by The Duskbloods (mood, genre and general mechanics only). Owner and director: **glocen**, final say on everything.

Codex loads this file automatically; Claude Code loads it through `CLAUDE.md`. Rules live here, details in the files linked below. Keep this file short.

## Supreme rules (above quality and everything else)

1. **Zero spend.** Never use, enable or sign up for anything that can cost money, credits or paid quota (tools, APIs, plugins, assets, paid modes, usage credits) without the owner's explicit OK, and say up front when something might cost. Approved because they're free: MemoryStore, reserved servers, PathfindingService, image uploads.
2. **Custom only.** We make every asset: models in the owner's Blender, textures and sprites with our scripts in `tools/`, our own animations, VFX and sounds. No downloaded or free models, stock or marketplace packs, scans, or AI-generated meshes and materials, including Studio's `generate_mesh`, `generate_material` and `generate_procedural_model`.
   - **Sounds** (owner, 2026-10-31: "custom only correct but u cant make sfx ... we will check roblox audio library, really a deep dive"): we synthesize what we can make at the bar (wind, magic, UI). Realistic sounds (weapons, impacts, cloth, voices) come from Roblox's own audio library, preferring Roblox's licensed uploads, which are cleared for every experience, monetized ones included. A slice of any library sound may be used (`PlaybackRegion`). Never downloaded sound packs or installers, never AI-generated audio, never ElevenLabs (its free sounds can't be monetized).
3. **IP safety** (the owner's IP Safety List). Take the vibe, the genre and general mechanics; never their names, art, characters, audio or code.
   - Never in anything players can see (in-game text, UI, asset names, game page, badges, passes, ads): Duskbloods, Bloodsworn, First Blood, moontears, Dusk/Twilight of Humanity, FromSoftware, Miyazaki, Bloodborne, Dark Souls, Elden Ring, Deadlock, Valve, Type Soul, or Bleach terms. Internal docs and code comments may name them.
   - Never recreate their characters, creatures, weapons, logos, icons, fonts, maps or HUD art, or a specific shot or location 1:1. Never make assets from their screenshots, trailer frames or concept art. Never imitate their music, sounds or voices.
   - Never use code, models, animations, VFX, UI or sounds from other Roblox games, leaks or decompiles, and never drop in an uninspected free model or plugin.
   - Their match structure + their terms + their look together reads as a clone. Our match structure follows theirs closely, so our names and our look must be clearly our own. Check any truly unusual mechanic for patents before copying it.
   - Invent original names. Describe visual goals by qualities (gothic, crimson moonlight, fog), never "like X". Check every AI-made name against the list above. **Fan test:** if a fan could name the exact thing it came from, redesign it.
   - Flag anything that breaks these rules, existing content included, to the owner with an original alternative; don't rename locked names on your own. Log every new asset in `docs/asset-log.md`.
4. **Roblox Terms of Use, always.** **NO GORE, EVER** (owner, 2026-10-31, after a blood-effect image upload put a moderation warning on the owner's Roblox account: "DONT EVER GO TO GORE").
   - **No blood effects of any kind:** no drops, drips, strings, sprays, splatter, stains, smears or pools, and nothing realistic. No wounds, severed parts or gore.
   - **A hit on a body shows as the body flashing red with a white outline** (`UI/Components/Flash`), and nothing else.
   - **This covers what we upload too:** every image, mesh, sound and asset is uploaded to the owner's account and moderated. Never upload anything that could read as gore or break the Terms of Use.
   - **If anything might be gore, or you're unsure, ask the owner first.**
   - Always check a new effect, asset or text against the Roblox Terms of Use and Community Standards before building or uploading it.

## How the owner wants work done

- **Quality over speed, always.** Work slowly, step by step, and never rush. Thinking long and hard is welcome, even for something simple, whenever it serves the vision. Models, builds, programs, effects and screens are iterated, reviewed and rebuilt until they meet the bar; never ship a quick or placeholder version to save time or tokens. We save tokens by reading less, never by thinking or doing less.
- **One piece at a time**, like a puzzle: finish and verify each piece before starting the next. No half-built pieces.
- **Never break what exists.** A lot of work lives here. Before replacing anything that took work, keep a rollback: a git commit for files, a `ServerStorage.WorldBackups.<Name>_<date>` copy for Studio content. Change one thing at a time, then prove nothing regressed (self-test, logic tests, world report, a look from the player's camera).
- **Stay organized.** Every file in its home folder, names that say what a thing is, no leftovers: delete the temp files, unused parts and dead code you created, and empty `build/import` after use.
- Locked decisions (`docs/engineering-plan.md` §2–3) change only with the owner's OK.
- The bar is premium. Every 3D space has its own atmosphere: realistic Victorian gothic, red/purple mood with blue and orange light, on the owner's lighting stack (Atmosphere, Bloom, DepthOfField, SunRays, ColorCorrection). VFX are layered (textured beams and trails, particles, light, impact bursts), never single neon parts.
- Worlds, VFX and screens: sketch (layout, landmarks, lighting, sightlines) → write it down → critique it harshly against the vision → build only what passes → review from the player's camera.
- When unsure how something should work, research first and record findings with sources in `docs/duskbloods-reference.md`, labelled OBSERVED, MANUAL or DESIGN. Never present a guess as a measurement.
- Report four facts separately: implemented, tested, visually reviewed, owner-accepted. Silence is not acceptance.

## The team

- **glocen:** owner and director, final say.
- **Claudius:** lead designer (Claude in the owner's claude.ai project "Bloodlocks"). Game design and the vision, this foundation, design specs, and reviews against the vision. Has no Studio access; hands work over as repo files that the owner or Claude commits, and signs team notes "Claudius".
- **Claude:** Claude Code on the owner's PC. Builds the game.
- **ChatGPT:** Codex on the owner's PC. World artist, when switched on.

**Team mode: Claude only** (owner, 2026-10-30). ChatGPT is off until the owner switches it on, and until then Claude does every area below, world art included. Only the owner changes the mode; when it changes, update this line and the "Now" board.

Who works on what when both are on, by what each does best:

| Area | Who |
|---|---|
| Game systems, simulation, combat, match flow, data, networking | Claude |
| UI and HUD code, VFX (code, textures, sprites), audio | Claude |
| Tests, tools, the asset pipeline, the world contract and its checkers | Claude |
| Weapons and props tied to gameplay; rigs, animations, assembly in Studio | Claude |
| Environment art: Manor and Victorian architecture, kits, materials, world Lighting, marker placement | ChatGPT |
| Character and creature models (Claude rigs, animates and assembles them) | ChatGPT |
| Reference analysis (footage frames, screenshots) and visual critique of captures | ChatGPT |
| Game design, specs, scope, reviews against the vision | Claudius, with the owner |

- Both artists build through the same pipeline (`bl-asset-pipeline`): scripted Blender models with GPU renders for self-review, published into Studio by `ModelAssembly`.
- Cross-review when both are on: ChatGPT critiques Claude's captures against the mood; Claude checks ChatGPT's worlds with the world report, the route probe and a performance budget.
- Claude may rebuild any 3D model that is below the bar (owner, 2026-10-30). Otherwise, change another teammate's area only when the owner asks, and say so in the team notes.

## Data and code

- **ProfileStore first:** never create a second ProfileStore. Read profiles through `PlayerHandlerData.Profiles` / `PlayerHandlerData.WaitForProfile`. New fields go in `ProfileTemplate`; new mutations go in `PlayerHandlerData`, in its existing style.
- **Keep list:** `ServerScriptService.Data`, `ServerScriptService.Libraries` and `ReplicatedStorage.Modules` (`src/owner/`). Adding is fine; ask the owner before replacing or removing anything there.
- Code lives in `src/` and reaches Studio through Rojo: edit the files, never Studio's script editor. Code standards: `.claude/rules/code-standards.md` (Codex: read it before editing `src/`).
- Worlds follow `worlds/world-contract.md` (what the code reads from a world; tag names and attributes in `src/shared/World/Tags.luau`). After world changes, run the world report, and `Probe.Run()` in the Cathedral Quarter.

## Shared folder and git

- The AIs work in `C:\Users\gloce\BloodsLocks`. Stage only your own paths (`git add <paths>`), never `git add -A`. Never delete or restore another teammate's files, even while it's switched off. Before `git pull --rebase`, compare any blocking local file with `origin/main` and remove only identical copies.
- A Studio playtest locks a place's Edit DataModel: never playtest a place another teammate is editing (check with the owner).

## Where the truth lives: one fact, one home

| Fact | Home | Read it |
|---|---|---|
| Rules | this file (Claude extras: `CLAUDE.md`, `.claude/rules/`) | automatic |
| Procedures | skills: `.agents/skills/` (shared), `.claude/skills/` (Claude) | when the task matches |
| Current state, open asks | `docs/team-notes.md`, "Now" | at session start |
| Next work, milestone status | `docs/production-plan.md` | when picking work |
| Locked decisions, system specs | `docs/engineering-plan.md` | only the section you touch |
| Behaviour spec for each slice | `docs/duskbloods-gameplay-breakdown.md` (the whole-game brief) | the part your slice builds |
| Tunable numbers, content | `src/shared/Config/`, `src/shared/Definitions/` | in code; never copy them into docs |
| UI bar | `docs/ui-quality-standard.md` | when building screens |
| What the code reads from a world | `worlds/world-contract.md` | when building or changing a world |
| First Victorian zone | `worlds/Victorian/CathedralQuarter/cathedral-quarter-spec.md` | when working on that district |
| Duskbloods research | `docs/duskbloods-reference.md`, `docs/duskbloods-manual-summary.md`, evidence files | when designing a mechanic |
| History | `docs/archive/`, git log | only when you need it |

Change a fact only in its home and link to it from anywhere else. Read the section a task needs (search for its heading), never whole files or archives "to be safe".

## Team notes

- Keep the "Now" board in `docs/team-notes.md` current: the team mode, each teammate's status, open asks, what waits on the owner.
- After each finished piece, add one entry at the top, at most about 10 lines: what changed, where it lives, what's open, who it's for. Details belong in the spec, not the entry.
- When the file passes about 250 lines, move the oldest entries to `docs/archive/team-notes-YYYY-MM.md`.
