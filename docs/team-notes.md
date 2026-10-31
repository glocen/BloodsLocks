# Team notes

Handoffs between glocen, Claudius, Claude and ChatGPT. The "Now" board is the current state; entries below it are newest first. How to write here: `AGENTS.md`, "Team notes". Everything before the 2026-10-30 reorganization is in [archive/team-notes-2026-10.md](archive/team-notes-2026-10.md).

## Now

**ROBLOX TERMS OF USE FIRST: NO GORE, EVER** (owner, 2026-10-31). Blood-effect images uploaded on 2026-10-30/31 put a moderation warning on the owner's Roblox account.
- No blood effects at all: no drops, sprays, splatter, stains or smears, and nothing realistic.
- A hit shows only as the body flashing red with a white outline.
- Never upload anything that could read as gore.
- In doubt, ask the owner first.

The full rule is AGENTS.md rule 4.

**Team mode: Claude only** (owner, 2026-10-30). ChatGPT is off; Claude does every area, world art included. Planned (owner): next week a head-to-head trial, Claude and GPT-6 Astra each building the same hero piece; ChatGPT joins only if Astra is clearly better.

**Next design task:** the Victorian map ([map brief](../worlds/Victorian/map-brief.md), from Claudius), after C1 and U2 (owner, 2026-10-30). Steps 1 and 2 (reference study, three concepts) change no code or place.

**Claude:** C1, the combat rework (`docs/combat-rework.md`, "Progress"). Done:
- C1.1: SMG spread, the Blender-built machine pistol, the duelist burst, `Vfx/Gunshot`, the Manor's lighting grade.
- Sounds (2026-10-31): the 19 combat cues play slices of Roblox audio library sounds (provisional until the owner's audition); the reference's audio is measured in `docs/reference/network-test/audio.md`.
- C1.2, the M1: knockback, hitstop, the black-and-gold sabre, the slash trail.
- C1.5, the bite: the long hold (both locked and invulnerable, the biter drinks HP back), the stagger kneel, four clips animated in Blender (the new R6 pipeline, `tools/blender/r6anim.py`), the smoke-and-wind beats, the bite camera and its sounds.

- The network-test reference study: one full playthrough of the owner's 4K recording, read one frame a second, now in `docs/reference/network-test/` (topic files and the owner's open decisions in `takeaways.md`).

Next, in this order (owner, 2026-10-31):
1. A tracked VFX and texture pipeline.
2. Sounds: Claude can't upload audio (it needs a permission scripts don't have), so sounds come from Roblox's audio library. Done: the measured reference, the shortlists, the audition panel, provisional cues. The owner's picks are pending.
3. The SMG burst, the guard's shield model and a parry that costs no stamina.
4. Push.
5. Combat, movement and camera, piece by piece from the reference with full effort ("one of the core systems").
6. Then the whole UI, close to the reference's but our own.

The combat framework rework waits until C1 is at the bar, then gets planned with the owner. Sound, effects and animations are made inside each slice as it needs them (owner, 2026-10-30).

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

- **Save both places** (File → Save to Roblox): the rule cleanup lives in their open Edit copies until then. Deleted:
  - **In the Manor:** the downloaded street-lamp, castle-tower, chest and wind-spiral models, one loose mesh, two unnamed models of downloaded parts, and the downloaded sky textures in two old Lighting backups.
  - **In the Victorian place:** downloaded skies and a baseplate texture in its backups.
  - **In both:** the third-party `Assets.Vfx.Crescent`.
- **Were these made by you?** Two Manor models built from plain parts, so their origin can't be read from asset ids: a cart with a hay bale (`Workspace.Model`, about (456, -7, -530)) and a 211-piece model (about (395, -5, -446)). If they're downloads, Claude deletes them.

- **Better sounds, from tomorrow** (owner, 2026-10-31): the provisional library sounds are "really bad, not up to our standard"; they stay until replaced.
  - The owner gathers non-copyrighted music and sound effects. Zero budget: nothing that costs money.
  - After a free upload, the owner gives Claude the ids. Claude measures each one and slices and levels it for its cue (`Shortlist.CueLine`), then swaps it into `Definitions/Sounds`.
  - The audition panel (F2 in a Manor playtest) stays available for comparing candidates.
- **Delete these uploads from your account** (owner, 2026-10-31: "we don't archive, just delete"). Only the account owner can, in the Creator Hub (create.roblox.com → Creations → Development Items); if Roblox offers only Archive for a type, that's as far as it goes.
  - Blood images (rule 4): 73716442107985, 132527224441651, 89451782214064, 92466747845719, 96856818725735, 85186176840498, 76864841147756, 97751459305668, and the old "wet blood" crescent 114481905428903 with its glow 127264027665322.
  - Superseded bite animations: 88243077439906, 112074793092588, 89274358889196, 119235946587850.
- Play the bite in the Manor's yard: stagger a dummy (it kneels), bite it (E) and judge the hold, the camera and the effect.
- Review Q0: match screens v2, plates, Kurogane's pact site.
- Carried over from 10-29, confirm or close: a 2-player PvP test. (The animation batch: Howl, Bite and SMGBurst are published from Studio; BloodBlade is re-authored and published in C1.)

## Entries

### 2026-10-31 · Claude · Sounds from Roblox's library, measured against the reference
- **The reference's audio, measured** (23 minutes of the recording plus the whole Albert clip): `docs/reference/network-test/audio.md`, made with `tools/reference/audio.py` (run with Blender's Python). Inspiration only.
- **`tools/studio/Audio`:**
  - Briefs: what each cue should sound like.
  - Library: the search.
  - Waveform: `GetWaveformAsync` measures events, attack, decay, bands and loudness.
  - Shortlist: filters out gore, other games' rips and paid libraries, then ranks and slices.
- **`Definitions/Audition`:** 19 shortlists, 140 candidates, all loading. The Studio-only panel is `AuditionController` with `UI/Dev/Audition` (F2).
- **`Sfx`:** levels every slice (`Level`), and handles swaps and previews.
- **Cues:** every cue is now a library slice (provisional), and the synthesized sheet pipeline is deleted.
- **Tests:** self-test 116/116 (Manor) and 117/117 (Victorian), logic tests 63/63 in both. One full Victorian run failed "Strong attack" once (0 damage); it passed 3 of 3 alone, so it's a timing flake to watch.
- **Owner's verdict:** the provisional sounds are below the bar; they stay until the owner's gathered sounds replace them (from 2026-11-01). `Shortlist.CueLine(id, cue)` prints the line to paste for any sound.
- **Open:** the replacements and their asset-log rows. For glocen.

### 2026-10-31 · Claude · The effect texture pipeline; rule-breaking art deleted

- **Pipeline:** `tools/vfx/textures.py` tracks every effect texture: build, numbered review sheet, MCP upload, ids with build hashes in the generated `Client.Vfx.Textures`, and a status that flags anything stale. Procedure in `bl-asset-pipeline`, "Effect textures".
- **Deleted** (owner: "delete everything that violates our rules"): the seven Creator Store textures (rule 2) and the "wet blood" crescent with its glow (rule 4).
- **Replaced** with our own: an energy crescent and halo (drawn white, tinted crimson), an energy wisp and a Cycles fire flipbook. The Crimson Crescent, its charge, the Light Beam, Gōka's fire nova, the arrival and the pact site now use only our textures.
- **Uploads on the owner's account:** listed in "Waiting on the owner" for deletion.
- **Self-test:** fails a run on any script error on either side. It caught `Destroy`/`Debris` throwing inside simulation callbacks (rule in `server-authority.md`). 103–104 pass in both places, logic 63/63.

### 2026-10-31 · Claude · The long bite and the stagger kneel (C1.5)

- **What:** a stagger now drops the body to one knee. The bite seizes it from there into a 2.75 s hold (`Simulation/Bite`): both bodies locked and invulnerable, 5 drain pulses heal the biter, then the victim is thrown and knocked down. Owner's asks: "a bit long, both can't move, iframes for both, the one who bites recovers HP"; "down on his knee then grabbed".
- **Animations:** made in Blender, through a new R6 pipeline (`tools/blender/r6anim.py`, `bite_anim.py` → `Author.SaveBaked`). `Staggered`, `Bite`, `BiteHold` and `Bitten` are published.
- **ToS:** no blood. It's staged as a hostile grab, never an embrace (Roblox bans romantic gestures).
- **Effects and sound:** dark smoke and cold light run on the hold's clock (`Vfx/BiteWind`), with the bite camera (sleitnick's CameraShaker). Five synthesized cues were added, and the old wet sound layers were removed.
- **Tests:** self-test 100–101/100–101 in both places, logic 63/63. Spec and the open items: `docs/combat-rework.md` C1.5.

### 2026-10-31 · Claude · No gore: every blood effect scrapped

- Blood textures Claude uploaded put a moderation warning on the owner's Roblox account.
- **Removed:**
  - `Vfx/BloodHit` and `Vfx/BloodSplat`;
  - the drips, splatter and droplets in `Vfx/BloodBlade` and `Vfx/BloodCharge` (now crimson sparks);
  - the blood generators in `tools/blender/vfx_sprites.py`;
  - the blood texture ids in `Kit.Textures`.
- **A hit now** is the body flashing red with a white outline (`UI/Components/Flash`, one Highlight per body).
- **The rule** is in AGENTS.md rule 4, the VFX rule, the Now board and Claude's memory.
- **For the owner:** archive the uploaded blood images in the Creator Dashboard: 73716442107985, 132527224441651, 89451782214064, 92466747845719, 96856818725735, 85186176840498, 76864841147756, and the red smear 97751459305668.
- **Also:** velocity-aligned particles lead with their texture's left edge. The Spark was redrawn: every spark before was sideways.

### 2026-10-30 · Claude · The network-test study

- The owner's full recording (`C:\Users\gloce\Videos\duskbloodsfullreference.mp4`) read one frame a second for 0:00–52:23: one full playthrough. The owner stopped it there; the rest is more matches.
- The notes are in `docs/reference/network-test/` (README, timeline, match flow, scenery, combat, movement, VFX, animation, UI, enemies, takeaways). Frames are local in `build/reference/network-test/` (gitignored); `tools/reference/frames.py` makes more.
- ChatGPT's 30-second survey is superseded for that span (owner); the old docs carry a pointer.
- Open for the owner (`takeaways.md` §2): the colour of blood, the Light Beam's colour, floor splatter, and our skill's name "Blood Blade" (the reference's exact name).

### 2026-10-30 · Claude · C1.2: the sabre and the slash

- The owner's direction: the blade is black with gold and a jewel, after Albert. Study frames from the owner's Albert video and the findings are in `docs/duskbloods-reference.md`.
- The sabre is two meshes from `tools/blender/saber.py`: a gold hilt, and a black blade with a gold inlay drawn by the script. The recipe is `tools/studio/Models/Saber.luau`.
- Weapon models name their points in `Equipment.Points` (Grip, Muzzle, CrystalTip, BladeBase, BladeTip, Jewel). `Vfx/SlashTrail` and `Vfx/BloodCharge` read them.
- Trail textures run like beams: up the image is along the trail (newest at the top), left to right is Attachment0 to Attachment1 (`.claude/rules/vfx.md`).
- `blcommon.tube_along` now carries its rings without twisting: re-running `smg.py` would smooth its tubes too.

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
