# Team notes

Handoffs between glocen, Claudius, Claude and ChatGPT. The "Now" board is the current state; entries below it are newest first. How to write here: `AGENTS.md`, "Team notes". Everything before the 2026-10-30 reorganization is in [archive/team-notes-2026-10.md](archive/team-notes-2026-10.md).

## Now

**Team mode: Claude only** (owner, 2026-10-30). ChatGPT is off; Claude does every area, world art included. Planned (owner): next week a head-to-head trial, Claude and GPT-6 Astra each building the same hero piece; ChatGPT joins only if Astra is clearly better.

**Next design task:** the Victorian map ([map brief](../worlds/Victorian/map-brief.md), from Claudius), after C1 and U2 (owner, 2026-10-30). Steps 1 and 2 (reference study, three concepts) change no code or place.

**Claude:** C1, the combat rework (`docs/combat-rework.md`, "Progress"). Done: SMG spread, Gustave's machine pistol (Blender-built), the duelist burst, `Vfx/Gunshot`, the Manor's lighting grade, the combat sounds (wired; silent until the owner's upload). Next: the M1, Blood Blade, Light Beam; then U2. Sound, effects and animations are made inside each slice as it needs them (owner, 2026-10-30).

**ChatGPT (off):** left mid-way through an owner-approved Victorian art rebuild (replacement geometry, markers and Lighting; phase I dusk, II twilight, III and the final night). W1 backup: `ServerStorage.WorldBackups.PreArtRebuild_20261030`. Its handoff (`docs/victorian-art-rebuild-handoff.md`), Manor world scripts and art tools are committed as it left them (owner, 2026-10-30); the 29 MB of `.blend`, `.fbx` and `.png` art sources in `assets/manor/` stay on the owner's PC, gitignored. Don't run the old CathedralQuarter generator once the replacement is installed.

**World to-dos** (for whoever holds world art)

| Item | Since | Status |
|---|---|---|
| Each floor's name with its Y range (crypt, street, nave, gallery, roofs), or tagged floor volumes, for the map browse | 10-30 | open |
| A `BL_Stage` marker in the Antechamber; `Dressed = true` on `BL_Antechamber` once its art lands | 10-30 | open |
| Size the Victorian rebuild for the higher jumps (numbers in `src/shared/Config/Movement.luau`; envelope rule in `worlds/world-contract.md`) | 10-30 | open |
| Phase lighting: swap the skybox faces at the blend's midpoint, not its start | 10-30 | suggestion |
| Keep the Manor's 10-30 lighting grade if a script rewrites Lighting (previous values: `ServerStorage.WorldBackups.Lighting_PreDuskbloodsGrade_20261030`) | 10-30 | FYI |
| Shorten `ArtStatus` / `ExteriorArtStatus` on `workspace.Vigil` (attribute strings over 50 characters get dropped) | 10-29 | confirm or close |
| Does the Manor still follow the Vigil layout in `docs/engineering-plan.md` §9 and §11a? If not, ask the owner to archive those sections | 10-30 | open |

**Small follow-ups (Claude)**

- Code comments that still say "Bloodsworn tab" (`Net`, `ClassService`, `Theme`, `Arsenal`): the tab is "Classes".
- IP names (owner, 2026-10-30: "I'll propose names"): bring 3–4 original names for the companions now called "Shinigami" (Bleach's core term, player-visible) and notes on the title "BloodsLocks" (near "Duskbloods" and "Deadlock"). Nothing is renamed until the owner picks.
- Self-test, logic tests and the world report return every PASS line. A compact default (counts and failures only, the full list on request) would cut tokens on every test run with no loss.

**Waiting on the owner**

- Upload the combat sound sheet: Studio, View → Asset Manager → Bulk Import → `C:\Users\gloce\BloodsLocks\build\audio\bl_combat_sounds.wav`; then right-click it under Audio → Copy Asset ID, and give Claude the id (it goes in `Definitions/SoundSheet`).
- Review Q0: match screens v2, plates, Kurogane's pact site.
- Carried over from 10-29, confirm or close: a 2-player PvP test. (The animation batch: Howl, Bite and SMGBurst are published from Studio; BloodBlade is re-authored and published in C1.)

## Entries

### 2026-10-30 · Claude · Foundation v2 applied

- Applied from `bloodlocks-foundation-v2.3.zip`, built on commit 3c30bf8, in three commits: the kit, the owner's answers, and ChatGPT's work.
- Checked against the live folder:
  - all 87 bullets of the old `CLAUDE.md` have a home;
  - every changed line of both plans is kept, archived, moved to its rule or skill, or an intended castle → Manor or status fix;
  - every link, rule glob, debug command and cited function exists.
- Owner's answers:
  - engineering-plan §11c's dated notes and production-plan §6–7 are archived (pointers left);
  - ChatGPT's text files are committed, its art binaries stay local;
  - the Victorian map comes after C1 and U2;
  - Claude proposes original IP names.

### 2026-10-30 · Claudius · Foundation v2

- Claudius is the lead designer (owner, 2026-10-30). The team mode is "Claude only" until the owner switches ChatGPT on; `AGENTS.md` lists who works on what, by strength.
- Shared rules: `AGENTS.md`. Claude's layer: `CLAUDE.md` and path-scoped `.claude/rules/`. Procedures are skills; the shared ones (`bl-asset-pipeline`, `bl-studio-test`, `bloodlocks-environment-art`) live in `.agents/skills/`, ChatGPT's session routine in `bl-world-session`.
- Docs: one fact, one home. The plans lost their history and duplicates (moved to `docs/archive/`, nothing deleted); `worlds/world-contract.md` gathers what the code reads from a world; `docs/asset-log.md` keeps the receipts.
