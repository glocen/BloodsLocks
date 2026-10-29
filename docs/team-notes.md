# Team notes

Handoff notes between the AI teammates working on BloodsLocks (Claude and ChatGPT) and the owner, glocen. Newest entry first. Keep entries short: what changed, where it lives, and what's next or open.

Read first: [CLAUDE.md](../CLAUDE.md) (working rules + Studio gotchas) and [engineering-plan.md](engineering-plan.md) (locked decisions, code layout in section 7, build table in section 12). The game lives in Roblox Studio (place ROLOCK); code is edited there, not in this folder.

## Ground rules that bite

- **ProfileStore first.** Never create a second ProfileStore. Go through `ServerScriptService.Data.PlayerHandlerData`.
- **Keep list.** Ask the owner before replacing or removing anything in `ServerScriptService.Data`, `ServerScriptService.Libraries` or `ReplicatedStorage.Modules`. Adding to them is fine.
- **Server Authority is on.**
  - Gameplay state lives in short-coded attributes (`EntityState.Attr`; 1024 bytes per instance) and is written only inside `RunService:BindToSimulation`.
  - Read time with `time()`.
- **Owner's process.** One verified piece at a time. Research Duskbloods when unsure (log findings in [duskbloods-reference.md](duskbloods-reference.md)). Update the build table when a step moves.

## 2026-10-29: Claude: stamina green + posture bar

- **Owner-approved HUD:** HP stays as is. Stamina is now short (250), thin (4) and **green** (`Theme.Colors.Stamina` = Moss).
- **Posture bar** (`Hud.StaggerGauge`, shown as "PostureGauge"):
  - **Orange**, in the **middle** of the screen under the character (0.5, 0.7); always shown, dimmed when empty.
  - Fills outward from a gold centre mark.
- `Theme.Colors.Warm` (ember) now drives tracers, the HOWL/STAGGERED callouts and the lock ring, which were orange before.
- **Next (owner):**
  1. Shinigami.
  2. Player vs player PvP fix.
  3. Big menu UI.
  4. The new Victorian place.

## 2026-10-29: Claude: R key fix + HUD polish

- **Howl vs strong on R** (`ActionSim`, `Config.Combat.Howl.InputGrace = 0.1`):
  - Guard + R is always a howl, never a strong attack.
  - R a split second before F still howls.
  - Guard + R mid-swing is ignored; from a cancel window it howls.
  - Verified 9 input cases.
- **HUD polish:**
  - Text gets a soft drop shadow (a sibling label, since children draw over parents).
  - Skill medallions: engraved bezel (`medallion` texture) + a coloured glow behind the emblem + the charge ring outside the bezel.
  - Bullet icon in the ammo box. **The white segments stay as they are (owner).**
  - Diamond caps and notches on the HP/stamina gauges.
- **Owner's next order:**
  1. Shinigami.
  2. PvP.
  3. Combat + HUD off in the hub.
  4. Menu UI (class select, matchmaking) for the Victorian map.

## 2026-10-29: Claude: Duskbloods manual + HUD v2

- **[docs/duskbloods-manual-summary.md](duskbloods-manual-summary.md):** the official manual, summarized and mapped to BloodsLocks. **Read it before designing any match system.** Three owner decisions are open (section 9).
- **HUD v2 on Duskbloods' layout** (`Client.UI.Hud`):
  - top-left: Vitals (Lv + XP, HP with a damage chip, stamina), with the Shinigami card under it (hidden until pacts exist);
  - bottom-left: Arsenal (SMG `rounds / mag` + segments; skill emblems with ring gauges, the big one first, small second, a name ribbon);
  - bottom-centre: the stagger gauge.
- **New kit pieces:** Gauge, RingMeter, Text, Panel, Button, Ornament.
- Skill icons are data (`Icon` in skill definitions). The ring texture is ours (`tools/vfx_textures.py` → `ring`).
- Old `Components.Bar` / `SkillSlot` removed.
- **Scope rule (owner):** HUD only for systems we already have, plus Shinigami. The other Duskbloods elements come with their systems.

## 2026-10-29: Claude: UI foundations (Step 9a, part 1)

- **Figma is dropped** (owner). UI is designed and built in Studio only, with **no external UI library**.
- **Theme v2 "Vigil gothic"** (`Client.UI.Theme`):
  - Palette + semantic Colors, Fonts (Accanthis display + Garamond body), TextSize, Space, Radius, Stroke, Motion, Layers, ReferenceResolution 1920×1080, Hud sizes.
  - The v1 flat keys stay as aliases until the components are ported.
- **`Client.UI.Core`:**
  - `Layers`: one ScreenGui per layer + a UIScale fit.
  - `Motion`: the only place tweens are made; interruptible.
  - `State`: value + Observe + Computed.
  - `Create`: declarative builder, State bindings, events, Scope cleanup.
- **Verified in play:** layer and scale, computed state, bindings, tween interrupt, scope cleanup. The HUD still runs, with 0 errors.
- **Repo:** a clone in Claude's scratch folder, with one commit ready (docs + rules + tools). The push waits on the owner signing git in to GitHub once.
- **Next:** the kit (Panel, Button, Bar...) and the HUD restyle; then the Blood Table match menu.

## 2026-10-29: Claude: UI research (Step 9a)

- [docs/ui-research.md](ui-research.md): Roblox UI engineering rules, free Figma options, the "Vigil gothic" style draft, the architecture proposal (Fusion + layered ScreenGuis + MenuController), and the screen order.
- Waiting on the owner: library choice, mockup path, style approval.
- **GitHub repo:** https://github.com/glocen/BloodsLocks (public). Docs get pushed there once git is installed on the owner's PC.

## 2026-10-29: Claude: owner direction update

- **Budget:** 0 € until revenue. Everything is custom and free; ask before anything that might cost.
- **Roles:** Claude does engineering (systems, infrastructure, UI code). ChatGPT likely takes 3D world building in Blender (Blender MCP added by the owner).
- **Companions are renamed Shinigami** (they work like Duskbloods' Kin). The plan is updated throughout.
- **Order:** 9a UI research + kit → 10 match launch to the Victorian place → 10a Shinigami (tested in the hub yard) → match rules.
- **Hub graybox:** the owner judged it not good enough. World art goes to Blender (likely ChatGPT's job); no Studio AI meshes.
- **GitHub:** the owner made a repo; it will become the shared home for these notes once the link and git access are sorted.

## 2026-10-29: Claude: castle hub "The Vigil" design + graybox

- **Design:** engineering-plan.md 11a (v2, critiqued). The owner approved it as a prototype.
- **Graybox:**
  - Lives in `workspace.Vigil` at (0, 0, −1000) and is built by `ServerStorage.WorldTools.VigilGraybox.Build()`. Change the layout numbers there and rebuild; don't hand-edit `workspace.Vigil`.
  - The spawn and both dummy spots now live in the hub; the old positions are in the plan.
- **Next:**
  - The owner walks it.
  - Then step B: a modular architecture kit plus one finished bay.
- **Communication:** the owner will name a Studio script where ChatGPT leaves notes. Check it once known.

## 2026-10-29: Claude: drawn VFX textures + published saber animations

- **Textures:** `tools/vfx_textures.py` draws our own textures: blood crescent, rim glow, beam core, beam energy, glint, soft glow. They're uploaded, and the ids are in `Client.Vfx.Kit.Textures` under "Drawn for BloodsLocks". The process (scratch output dir, local http server, `upload_image`) is in engineering-plan.md 11c.
- **Blood Blade:** now a crescent sprite on a thin plane (SurfaceGuis, both faces, LightInfluence 0).
- **Light Beam:** uses the drawn band and strands. Beam art must be drawn tall, because Roblox runs a beam texture's vertical axis along its length.
- **Animations:** the owner published the 8 saber animations (Light1-4, Strong1/2, Charge, Charged); their ids are in `Config.Animations`, and all of them play in tests.
- **Still unpublished:** Howl, Bite, SMGBurst, BloodBlade, LightBeam.
- **Owner verdict:** still below the bar. The VFX revisit is parked for later (engineering-plan 11c); don't polish VFX further unless the owner asks.

## 2026-10-29: Claude: charge telegraph + saber weld fix

- **Charge telegraph:**
  - `Client.Vfx.BloodCharge`: blood gathers in, the blade glows, mist pools at the feet; a glint when armed, a flare on release.
  - An action opts in with `Hold.Fx = "<module name>"`. `CombatFxController.CHARGE_LOOKS` maps the name to the module.
  - A look exposes `Spawn(model)`, `Update(visual, progress, armed, clock)` and `Release(visual, fired)`.
- **Bug fixed:**
  - `WeldConstraint`s inside a cloned weapon model don't hold under Server Authority: the parts stayed at the template's origin.
  - The saber template now uses `Weld`s with explicit C0. Use `Weld` in every future weapon model.

## 2026-10-29: Claude: strong and charged attacks

- **What:** Strong attacks on R (Guard + R is still Howl). Tap does Strong1 → Strong2; hold for the charge stance, release for the Charged blow.
- **Where:**
  - `Definitions.Weapons.Saber` (`Strong`, `Saber.Strong1/2`, `Saber.StrongCharge`, `Saber.Charged`).
  - New generic action fields: `Button`, `Charge`, `Hold`, `Hit.GuardDrain`. They are documented at the top of Saber, validated in `Registry`, run in `ActionSim`, and guard drain is applied in `CombatSim`.
- **Verified:** with scripted input against TrainingDummy2. Teleport the player from the **Server** context; client CFrame writes get overridden under Server Authority.
- **Open:**
  - Charge telegraph VFX.
  - The owner must publish `BL_SaberStrong1/2`, `BL_SaberCharge` and `BL_SaberCharged` and paste the ids into `Config.Animations`.
  - Guard drain is not yet tested against a guarding target.

## 2026-10-29: Claude: Duelist skill VFX overhaul

- **What changed:** replaced the placeholder Blood Blade and Light Beam visuals.
- **Where:** `StarterPlayer.StarterPlayerScripts.Client.Vfx`:
  - `Kit` (shared helpers + texture ids).
  - `Projectile` (generic client flight).
  - `BloodBlade`, `LightBeam`.
  - Colors in `UI.Theme.Vfx`; the crescent mesh in `ReplicatedStorage.Shared.Assets.Vfx.Crescent`.
- **Adding a new projectile look:** make a module with `Spawn(cframe)`, `Move(visual, cframe)` and `Impact(visual, position, direction)`, then register it in `CombatFxController.PROJECTILE_LOOKS` under the visual name the server sends.
- **Style rules:** see engineering-plan.md section 11c. Blood is dark and wet with a thin hot edge, not neon. Light is warm gold. Glow textures need LightEmission 1. Beams use onion layering. Crescents face the camera.
- **Verified:** real casts hit the dummy, 0 errors, 0 leaked parts.
- **Open:**
  - Owner review: "alright, a little buggy, not up to our standard yet". The slash is now vertical (`ROLL` in `BloodBlade`). A quality revisit is logged in engineering-plan.md 11c.
  - Next up: strong/charged attacks, then a charged Blood Blade variant.

