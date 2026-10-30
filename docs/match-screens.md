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

## Q0 · v2 (2026-10-30)

After the owner's U1 review, the screens were rebuilt to Duskbloods' reference frames (`roster6116.png` and the selection, phase, death and exit sequences). U1's panel, region map and lobby are gone.

| Screen | Now |
|---|---|
| **Passage** (ReplicatedFirst) | Our loading and teleport screen replaces Roblox's: ink, the turning ritual circle, the destination, one rule tip, a progress line. It holds until the client has booted and has a body. |
| **Antechamber** | A full menu screen while the hunt gathers. Your hunter is staged on the blood circle (`UI.Core.Stage`). A ribbon sits on top; the mode card, status and roster are on the left, rule tips on the right, and the leave hint bottom right. The step-out key appears once the room is dressed. |
| **Intermission** | One screen, three modes: Choose, Rise, Browse (M). Standings sit top left, with the cut opening a gap in the list. The phase strip with entrant counts sits top centre and the dial top right. The map is a height-banded relief with fading edges. Each region gets a fine ring, a numbered plate and its marks. Hover gives a bone ring and a warm glow; the chosen region turns gold with "◆ CHOSEN" and one pulse. The region panel is on the right; the instruction, the fallback line and the keys are at the bottom. The frame holds every ring, so none crosses the text. |
| **Arrival** | You face the spawn's most open sightline, the camera swings behind you, dark-red mist rises at your feet, and a cool outline shows while you're protected. |
| **Falling** | Your body breaks into the same mist and fades. "You fell" shows on a band over the dimmed world, then the Rise map opens. |
| **HUD** | Objectives (Definitions/Objectives) sit on a dark band under the Shinigami card. A line that needs a world feature says where it is: "Kurogane · The Cloister". The clock shows the current area. |
| **Plates** | Plates are drawn in the World layer, not BillboardGuis. They appear for: your lock; anything hit in the last 6 s; an enemy that noticed you in the last 8 s; enemies within 32 studs; people within 48. They need line of sight and stop at 90 studs. Fodder plates have no name line. |
| **Pact site** | `PactSiteController` dresses every `BL_PactCircle` marker: a soft moonlight shaft, the glowing blood sigil, a cold pool of light, and the Shinigami waiting in it. On the pact it breaks into mist, the sigil flares, and it speaks its line (`UI/Hud/Subtitle`, white serif, bottom centre). |

## Q0.9 capture walk: critique (2026-10-30)

Each capture was compared with its reference frame. Status says what happened to each item.

| # | Found | Status |
|---|---|---|
| 1 | Region rings were images, so big regions got heavy 25 px rings; the bottom ring ran across the instruction text | Fixed: constant 1.5 px strokes; the map frames every ring |
| 2 | The relief ended in a hard rectangle | Fixed: its edges fade into the backdrop |
| 3 | The cut label sat on rank 7's score ring | Fixed: the list opens a gap for the cut line |
| 4 | A lone spire in the top height band read as a map mark | Fixed: the top band is toned down |
| 5 | The Antechamber framed the hunter against the near wall | Fixed: the fallback grid faces across the room |
| 6 | Objectives were lost over lit façades | Fixed: a dense band from the screen edge covers the whole line |
| 7 | **Every unnamed plate printed Roblox's "Label" twice** (owner: "the NPCs have no plates") | Fixed at the root: `Text.new` defaults to empty text; the UI lint now fails any visible "Label" |
| 8 | Your companion's plate read "Kurogane_glocen" | Fixed: plates use the definition's name |
| 9 | The camera could snap to its lowest pitch when a menu closed (the cursor's jump back to the centre counts as mouse movement) | Fixed: 2 settle frames ignore the mouse after the lock or a spawn snap |
| 10 | A fallen hunter stood upright under "You fell" | Fixed: the body breaks into mist and fades |
| 11 | AI hunters stood frozen in the streets (owner: "legacy NPCs") | Fixed: no AI bodies in the phases (`Config.Match.AiBodies`); they still count in the standings and the cut |
| 12 | Kurogane's pact circle was an invisible 1-stud marker | Fixed: the pact site |
| 13 | Culled players see a dark world with a dial | U2: spectate or return |
| 14 | Browse can't say which floor you're on | Waiting on world data: the rebuilt quarter's floor heights (requested from ChatGPT) |
| 15 | The fast profile is too quick for MCP captures (protection lasts 3 s) | Process: capture with `MatchStart(nil, false)` and `MatchSkip` |
| 16 | The Shinigami card's text sits bare over the world | U2 (card fix) and UI-R |

Not yet checked: a real 1366×768 capture (the owner's Device Emulator) and the twilight phase lighting (needs a long run).
