# Takeaways: what we build from the study (DESIGN)

Our adaptation of everything in this folder, slice by slice. All of it is **DESIGN**, ruled by AGENTS.md (IP safety, custom only, no gore) and the owner's direction (2026-10-30):
- **ROBLOX TERMS OF USE FIRST: NO GORE, EVER** (AGENTS.md rule 4; owner, 2026-10-31, after a moderation warning on the owner's account). The reference's blood is never reproduced: no blood effects of any kind. A hit shows as the body flashing red with a white outline. In doubt, ask the owner.
- **The structure follows the reference closely** (layouts, flows, timings: "95% or 99% is fine but not 100%"); **every visible asset is ours:** art, icons, type, words, names and sounds.
- **The rendering is ours:** stylized like Type Soul but more detailed and deeper, never their realistic graphics.
- **The order:** C1 first (skills, VFX, SFX, the blade) to the bar; then the owner and Claude plan the combat framework rework together; the UI rework; the Victorian map.

## 1. C1 now: the effects to rebuild

Measured references in [vfx.md](vfx.md) and [animation.md](animation.md). Our current effects live in `src/client/Vfx`.

| Effect | What we have | What the reference shows | Our rebuild |
|---|---|---|---|
| **Sabre hit** | `SlashTrail` (a pale motion smear, rebuilt 2026-10-31); the body's red flash with a white outline (`UI/Components/Flash`) | A pale motion smear on the blade for 2–3 frames; the target flinches and slides on the same frame (their blood: never reproduced) | The pale smear for the fast frames; the red body flash; knockback and hitstop. **No blood effects** (owner, 2026-10-31) |
| **SMG burst** | One thin pale tracer at 700 studs/s | 5–6 thick orange-gold rays at once, fanned by the spread, fading in ≈0.2 s; a big orange-white muzzle bloom; brass casings | Instant thick rays per round with a white-hot core, fanned by the real spread; a bigger layered muzzle bloom; ejected casings |
| **Blood Blade** (players see "Crimson Crescent") | A crescent effect (`Vfx/BloodBlade`, its drips and splatter removed 2026-10-31), animation unpublished | The free hand rises (≈0.3–0.5 s); a huge crescent thrown from it, thinning to a streak in ≈0.5 s | A new cast animation (the raised free hand) and a stylized crimson energy crescent (light, sparks, mist; never liquid). **Ask the owner about its look before building it** |
| **Light Beam** | A warm gold beam from the crystal (the brief's direction) | Raise overhead (≈0.2 s); a white star flare at the crystal (≈1.1 s); aim (≈0.2 s); a white burst; a thin straight white ray with swirl rings at its root; planted | A cold white beam (owner to confirm, §2): the raise-hold-aim animation, the star flare with long streaks, the root rings, the planted brace |
| **Bite** | A heal number over the biter; no effect of its own | Grab; a white-glitter drain; white smoke ribbons on release (their blood: never reproduced) | **Ask the owner first** (the action itself is a bite). If approved: grab, a white-glitter drain, white smoke ribbons; no blood |
| **Guard, howl** | Call-outs and flashes in `CombatFxController`; no layered effect | A dark-red translucent disc (a sphere for some); an orange-gold block flash; the howl a pale shockwave sphere with a heat-haze edge | Rebuild both as layered effects |
| **Movement** | No trails | White streak bursts under air jumps, ribbon trails on high jumps, afterimages on dodges | Add all three |
| **Sound** | 14 synthesized cues, waiting for the owner's upload | Not assessed: the study looked at frames only | A listening pass on the recording's audio before we redo the cues |

## 2. Decisions for the owner

1. **Blood: none, ever** (owner, 2026-10-31, overriding 2026-10-30's droplet plan after the moderation warning). A hit is the body flashing red with a white outline.
2. **The Light Beam's colour:** cold white (2026-10-30).
3. **Floor splatter: never** (2026-10-31).
4. **"Blood Blade"** is shown to players as **"Crimson Crescent"** (`Definitions/Skills/Gustave.luau`); internal ids keep `BloodBlade` (2026-10-30).
5. **Open: the Blood Blade's look and the bite's effect.** Ask the owner before building either.

## 3. The match screens (U2 and polish)

Sequence and timings in [match-flow.md](match-flow.md); layouts in [ui.md](ui.md).
- **Phase end:** the banner and a statement on a full-width band over the live world (≈6–8 s); then the breakdown (the categories joined by a red spine, the phase's total, the match total in a big medallion; ≈5 s); black (≈2 s); the next intermission.
- **The cut:** the Renown number turns red while you're below the cut; hunters below it show red in the standings.
- **Qualifying for the final:** a statement of its own (not the plain survival line).
- **Before the final:** the finalists card (the final's event card and the finalists' portraits with their Renown); a rules card; a short black; an arrival banner of its own.
- **The final's HUD:** the Renown medallion shows **two life marks** (our U2 plan already says so); the HP bar shows its Renown bonus in a lighter tint; no clock, no compass.
- **Victory:** the camera rises to the sky's moon; a statement on the band (≈8 s); a sigil on the winner's back.
- **Outcome:** tabs (Outcome · a record of the hunters met); the winner's emblem; Renown by category on a spine; a big character render; a return button.
- **Death:** the defeat statement on the band (≈4 s), then the revival map.

## 4. The UI rework

From [ui.md](ui.md), to map onto our HUD (`src/client/UI/Hud`: Vitals, StaggerGauge, Arsenal, Objectives, ShinigamiCard, PromptCard, Subtitle):
- **Corner framing, centre clear;** serif type, hairlines, translucent warm-black panels, red only for blood things, gold for categories (all through `UI/Theme`).
- **Top left:** the Renown medallion, level and XP gains, HP with a lag chip, a green stamina bar, Power icons, the companion row (portrait medallion, name, level, HP).
- **Top centre:** a compass ruler with objective markers; one notice slot (score toasts, ritual-site warnings); a great foe's bar.
- **Top right:** the area name with a feature icon; the clock dial (states in [match-flow.md](match-flow.md) §5).
- **Bottom left:** ammo, the heal count, the skill and item emblems with insets.
- **Bottom centre:** the posture bar (yellow, growing from the centre) while it fills; requests.
- **Right edge:** pickup tips and toasts.
- **Screens:** the class roster (tall portrait panels side by side), the class detail (render in the centre, kit at the right), the map with soft region circles (Q0.4 already draws them), tutorial cards, the reward choice (two cards and the held list), the enhancement choice.

## 5. The Victorian world

From [scenery.md](scenery.md):
- **Phase presets:** dusk (amber sky, brown cloud, warm haze, deepening through the phase), twilight (blue-violet sky with a pink-orange horizon band), night (a saturated violet-purple light over everything, a crimson glow low on the horizon, a moon in eclipse), and the final's blood moon. The existing `VictorianPhaseLighting` presets should be checked against these.
- **District archetypes, in our own design:** a cathedral with real interior verticality (galleries, a walkable chandelier, a ritual dais, a roof plaza of braziers and spires); a rooftop city with chimney smoke; a great bridge; a lake district with castle ruins and seas of mist; gardens of white flowers as quiet value fields.
- **Dressing:** candle clusters on floors, dust sheets, biers, braziers in urns, iron fire cages, black carriages, bare trees, ivy.
- **Routes:** the roofs are the fast lane; long falls are free; vistas open at the edges.

## 6. Input for the combat framework rework (to plan with the owner, not to build now)

Mechanics seen that we don't have yet: the posture bar on screen for the player; thralls from drinking blood; three kinds of companion circle and companion levels to 5; Powers of Blood (five slots, a choice of two at each blood rose); skill enhancement from crystals (bloodsacs); a second skill unlocked by level; instant travel; co-op bosses; alliances; redstones and goldstones; ritual-site desertion damage; lantern corpses (the Flame category); sigils (personal goals); six kinds of quick item; heals that refill from drops; climbing, ledge grabs and wall jumps; observation.

## 7. Names to invent

Their systems need our own names before they reach players (with the companion rename the owner already has pending):

| Their term | Ours |
|---|---|
| Virtue | Renown (ours already) |
| House of Night; Wheel of Blood | the Manor; the Blood Table (ours already) |
| Kin; kin summoning circles | our companions, today "Shinigami" (rename pending); pact circles (ours already) |
| Bloodsworn | hunters (ours already) |
| Blood Blade (skill) | to name (§2) |
| Goldblood stakes; Powers of Blood; blood roses; blood crystals; bloodsacs | to name |
| Ritual sites; blood pledge pillars; redstones and goldstones | to name ("ritual site" is a plain phrase, already in our rules) |
| Great foes; trespassers; lantern corpses | to name |
| Sigils; the Grail Battle; the culling | to name |

## 8. Not yet studied

The rest of the recording (52:23–2:49:34): more matches with other characters (Zork and others), an eight-hunter match start (54:15), a second final arena (a round colonnade around a crimson pool, 2:43:30), more great foes and trespassers (a Vampyr, a wheeled skeleton, a dark feline), a sixth-place outcome. Study it when a slice needs it (owner, 2026-10-30).
