# Match screens (U1, U2): design

Claude, 2026-10-29. Built on the [UI quality standard](ui-quality-standard.md) (Theme v2, exact tokens, gates in section 6) and the whole-game brief section 8. Every screen reads `ReplicatedStorage.MatchState` (attributes); none reads world markers, which may not be streamed in.

## Foundations

- **Focus owner (`UI.Core.Focus`):** one stack of input owners. The top owner decides whether the cursor is free, whether gameplay input runs and whether the combat HUD shows. Releasing it restores the one below, so a death, a phase change or an interrupted screen can never leave a stuck cursor or a disabled context. `CameraController` asks Focus whether to free the mouse, and the Blood Table menu moves onto it.
- **Legible text:** `Text.new` labels keep their rendered size at 16 px minimum (captions 14) whatever the window: when the UI scale drops, the authored size rises to compensate (`Layers.ScaleChanged`). Containers on the new screens leave room for that.

## U1 screens

| Screen | When | Where | Contents |
|---|---|---|---|
| **Clock** | every non-idle state | top right, 112 px | The phase dial is a ring that fills over the phase, with a gold diamond at the ritual point (phases with `Ritual`, at `Ritual.ActivateAt`) and a red diamond at the end. A roman numeral sits in the centre and a short state line underneath ("Phase II · 3:12", "Choose a region · 0:09"). The last 10 s of any deadline go blood red. |
| **Antechamber panel** | Waiting, Countdown | left, under the margin | The map's name, the rule, then "Waiting for hunters 1 / 2" or "The hunt begins in 0:12", "Joins are closed" once locked, then the roster (name, class, "arrived"). |
| **Intro** | Intro | full screen | A fade from black: "THE DUSK HUNT" with the world's name, the rule, then the field: 8 names with class and an AI mark, revealed one by one. Gameplay input is off. |
| **Region map** | RegionChoice; and when dead in a phase ("revival") | full screen over a darkened world | A relief of the district (a live 3D model of the world from above, in a ViewportFrame, so it always matches the world) with each region outlined and named. Hover lights a region; a click chooses it (it turns gold, with a "Chosen" mark). The heading says the mode: "Choose where to begin Phase II" or "Choose where to rise". The deadline counts down, and it says what happens without a choice. Standings sit on the left (rank, name, Renown; from phase 2 a line marks the cut). Keys: click or 1–4, nothing else. |
| **Region banner** | entering a region in a phase | top centre, below the compass slot | The region's name on a dark ribbon with gold rules: 0.35 s in, 2 s hold, 0.5 s out; it won't repeat for the same region within 6 s. |

The server publishes what the screens need:
- `MatchState.Regions.<id>` with `DisplayName` and box bounds;
- `MatchState.Relief`, a light copy of the district's geometry for the map.

## Critique before building

1. **A full-screen map steals the fight.** It only opens in RegionChoice, when nobody can be hurt, and when you're dead. It never opens mid-combat. It closes the moment the state moves on.
2. **A relief made of grey blocks can look cheap.** Light the viewport like a model on a table: a warm key light and violet ambient, the region tint underneath, a vignette. Show the regions as clear shapes; never use colour alone to mark a choice (the chosen region also gets a ring and a label).
3. **The clock competes with the skill ring** if both look the same. The dial is larger, uses the gold bezel and a numeral, and sits alone in the top right (the north-star layout).
4. **The Intro is dead time on match 10.** It's short (8 s), and skipping it by vote is noted for later.
5. **Text over bright sky** (the clock's state line) sits on a dark ribbon; nothing floats bare.
6. **Small windows:** all text goes through legible sizing; the map scales to the screen's height; the standings column wraps names.

## Gates to show (UI standard section 6)

Screenshots of each screen at 1920×1080 and 1366×768; region choice with a choice made and with none; revival mode; the clock in a phase, near its end, and between phases; a death during RegionChoice can't happen (protected), and a phase change closes the map.
