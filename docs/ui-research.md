# UI research (Step 9a)

Research for the BloodsLocks UI overhaul (2026-10-29). The goal is extremely well-made UI: gothic, readable and premium, built in a way that survives frequent restyles. Budget is 0 €, so everything here is free.

## 1. What we have today

| Piece | Size | Notes |
|---|---|---|
| `Client.UI.Theme` | 40 lines | Colours, Garamond fonts, corner, stroke, a few sizes, the `Vfx` palette |
| `Client.UI.Components` | Bar 53, Crosshair 27, FloatingText 46, Flash 24, Tracer 32, SkillSlot 105 | Imperative builders; each creates its own instances |
| `Controllers.Core.HudController` | 96 lines | HP/stamina bars, ammo, crosshair, skill slots |
| StarterGui | empty | All UI is created from code (good: restyles are code changes) |

It's fine for a HUD. It won't scale to full menus (match browser, party, class altar, shop, results) without a state and layout layer: imperative code gets tangled once screens have many states.

## 2. Roblox UI engineering rules (what the platform rewards)

- **Scale, not pixels, plus one root UIScale.** Size and position with Scale; keep shapes with `UIAspectRatioConstraint` / `UISizeConstraint`. A common pro pattern: author everything at a 1920×1080 reference, then set one `UIScale` per ScreenGui to `min(viewport.X/1920, viewport.Y/1080)`. That keeps pixel-exact strokes and paddings proportional, and `AutomaticSize` keeps working. ([DevForum: UI tips](https://devforum.roblox.com/t/3074034), [DevForum: same size on every screen](https://devforum.roblox.com/t/how-do-you-make-ui-stay-the-same-size-while-scaling-up-down-automatically-with-different-screen-sizes/3924753))
- **UIStroke is offset-only.** Under a root UIScale it scales with everything else, which solves the "strokes too thick on small screens" problem. ([DevForum: UI tips](https://devforum.roblox.com/t/3074034))
- **Safe areas.** Interactive UI uses `ScreenInsets = CoreUISafeInsets` (it avoids notches and Roblox's top-bar buttons). Only full-screen art uses `None`. `GuiService.TopbarInset` gives the free space inside the top bar. ([ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets), [ScreenGui.ScreenInsets](https://create.roblox.com/docs/reference/engine/classes/ScreenGui/ScreenInsets))
- **Reserved zones:** the top bar, chat and leaderboard. Persistent HUD hugs the edges; decisions go in modals; management goes full-screen; brief info goes in toasts. ([DevForum: UI tips](https://devforum.roblox.com/t/3074034))
- **Test with the Device Emulator** at several resolutions before calling a screen done. ([HUD meters tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/ui/create-hud-meters))
- **Roblox's design principles:**
  - Show only what matters right now, and make things contextual.
  - Guide the eye with colour, size, space and subtle motion, sparingly.
  - Keep one visual language, follow genre conventions, and give feedback for every action (visual, sound, motion).
  - Use the fewest steps to a goal.
  - Write a style guide so the team stays consistent. ([Roblox UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design))
- **Craft notes (engine behaviour we rely on):**
  - 9-slice panels via `ImageLabel.ScaleType = Slice` + `SliceCenter`, so ornate frames stretch without distorting corners.
  - `CanvasGroup` gives whole-group fades and tints but renders to a texture, so use it only for transitions.
  - `UIGradient` for vignettes and bar sheen.
  - Avoid `TextScaled` for body text: use fixed sizes under the root UIScale, with `UITextSizeConstraint` where needed.
  - `ViewportFrame` for 3D previews (class altar, skins).
  - One ScreenGui per layer, ordered by `DisplayOrder`, with `ResetOnSpawn = false`.

## 2b. Duskbloods UI reference (researched 2026-10-29)

- **No public UI breakdown exists.**
  - The network test (Aug 21–23, 2026, Switch 2 only) produced impressions, not HUD analyses. The reveal trailer showed no UI at all.
  - What is known: a stamina bar drained only by movement and dodges, character select from 6 pre-made characters, queues for casual/ranked and solo/duo, one map in the test. ([Fextralife: network test](https://duskbloods.wiki.fextralife.com/Duskbloods_Network_Test_and_Demo), [AU Review](https://www.theaureview.com/games/the-duskbloods-network-test-impressions/), [Men's Journal](https://www.mensjournal.com/entertainment/the-duskbloods-network-test-review-youve-never-played-anything-like-this), [Nintendo Life](https://www.nintendolife.com/previews/first-impressions-network-issues-aside-the-duskbloods-could-wind-up-being-really-special))
- **A lesson from the test:** reviewers found the compass and UI unhelpful for navigation ([GamesRadar](https://www.gamesradar.com/games/action-rpg/the-duskbloods-network-test-was-not-good-between-lag-stuttering-and-bad-pvp/)). Our in-match navigation (compass, objectives, Virtue sources) has to be clearer than theirs.
- **Closest visual lineage:** Bloodborne. Press called Duskbloods "Bloodborne-looking" ([Wikipedia](https://en.wikipedia.org/wiki/The_Duskbloods)).
  - Screenshot reference: [Interface In Game: Bloodborne](https://interfaceingame.com/games/bloodborne/).
  - Bloodborne's reading type is a legible serif/semi-serif chosen for TV distance; FromSoftware never published the font name ([Made Good Designs](https://madegooddesigns.com/bloodborne-font/)).
  - We use that lineage as **inspiration only**: thin bars top-left, quick items at the bottom corners, dark translucent panels, serif type. The art is our own.

## 3. Figma → Roblox (optional)

- **Free importers exist:**
  - [roimport](https://devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967): free; tags decide the Roblox class, plus auto layout, rich text and images.
  - [Figma Importer Assistant](https://devforum.roblox.com/t/2961561): free and open source.
  - [UILint v2](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869) has a free manual tier, but paid sync features. **Avoid** [UI Designer Pro](https://devforum.roblox.com/t/plugin-ui-designer-pro/4685902), which is paid.
- **Known pain:** imports land as fixed layouts that need rework for scaling and states ([DevForum: importing from Figma](https://devforum.roblox.com/t/importing-ui-from-figma-sucks/3381689)).
- **Our Figma connector** needs the owner to authorize it (`/mcp`). Some Figma features (Dev Mode) need a paid seat, so we only use what's free.
- **Figma MCP on the free Starter plan:** limited to about **6–20 MCP tool calls a month** per account. Figma staff quote both numbers; the cap is per account and resets monthly. Some write tools are reported as exempt. Paid seats don't help if the file sits in a Starter team. ([Figma forum: Starter limit](https://forum.figma.com/report-a-problem-6/figma-mcp-tool-call-limit-not-resetting-on-starter-plan-with-full-seat-57439), [Figma forum: when it resets](https://forum.figma.com/report-a-problem-6/when-does-the-figma-mcp-tool-call-limit-reset-55405), [Scalekit summary](https://www.scalekit.com/blog/figma-mcp-server))
- **What the DevForum says about doing it well:**
  - Figma auto layout does **not** become UIListLayout; positions arrive absolute ([Framewisp](https://devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239)).
  - Pros build with offsets, then convert to Scale or use one root UIScale. The choice depends on HUD vs fixed dialog ([GuiForge](https://devforum.roblox.com/t/guiforge-roblox-ui-editorfigma-export/4834077)).
  - 9-slice suits symmetric frames ([DevForum: 9-slicing use cases](https://devforum.roblox.com/t/9-slicing-use-cases/667672)).
  - Strokes get simplified on import, and mixed corner radii collapse.
  - Clean layer names before export ([UILint v2](https://devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869)).
  - [roimport](https://devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967) (free) uses name tags (`_UIList`, `_Slice`, `_Scroll`, `_Image`) to choose the Roblox class.

### Decided workflow (Claude, 2026-10-29, at the owner's "whatever you think is best")

1. **Figma is the visual board, code is the source of truth.**
   - Screens are designed in one Figma file at a 1920×1080 frame size, with layers named after our kit components (Panel, Button/Primary, Bar/HP...).
   - Every colour and type style in Figma mirrors a Theme v2 token of the same name.
2. **Art exports, not layout imports.**
   - From Figma we export only the **images**: ornaments, frame corners, icons, as PNGs.
   - Layout is rebuilt in code with the kit, so scaling, states and motion are right. Auto-layout imports would have to be redone anyway.
   - If a quick structural import helps, roimport (free) is the tool.
3. **Spend MCP calls only where they matter.** About one read per finished screen (a screenshot plus measurements), never for exploration. Mockups and iterations happen in chat as rendered previews, which are free and unlimited.
4. **Everything free:** the Figma Starter plan, free plugins only, and Roblox image uploads (free).

## 4. Visual direction: "Vigil gothic"

References: FromSoftware's UI language (Bloodborne / Elden Ring / Nightreign), the genre we're in.

- **What FromSoftware gets right:**
  - A sparse HUD: thin bars top-left, equipment bottom-left, nothing in the centre except what you act on ([Kotaku: Elden Ring's sparse UI](https://kotaku.com.au/?p=1261119)).
  - Serif typography, thin gold hairlines, dark translucent gradients instead of boxes.
  - Restrained motion and a strong sense of ceremony.
- **What it gets wrong, and we must not copy:**
  - Opaque menus and coy descriptions, called "a massive obstacle" in Nightreign's co-op context ([PC Gamer via Yahoo](https://tech.yahoo.com/gaming/articles/fromsoftwares-clunky-ui-coy-descriptions-160000426.html)).
  - Little guidance ([Automaton](https://automaton-media.com/en/news/20220310-10432/)).
  - Matchmaking, party and rewards in a PvP game must be instantly clear.
- **Our style rules (draft style guide → Theme v2 tokens):**
  - **Colour:**
    - Ink background (near-black violet) with translucent panels on top.
    - Bone/parchment text.
    - Blood red for danger, HP and primary actions; gold for hairlines, focus and rarity.
    - Moon blue for info, cooldown-ready and the cold side.
    - Every colour is a token; no literals in screens.
  - **Type:**
    - A display serif (our Garamond family) in small caps for titles; the same family for body text at readable sizes. Numbers in a clean face.
    - At most 2 families. Fonts get checked in Studio's font list before locking.
  - **Ornament:**
    - 1-px gold hairlines with diamond terminals.
    - Corner filigree as our own drawn 9-slice textures (`tools/` script, like the VFX textures).
    - A subtle vignette and grain behind menus.
  - **Motion:**
    - Weighted and calm: fades and slides of 0.15–0.35 s with quad/quint easing, no bouncy springs.
    - Hover: the hairline grows plus a soft glow. Press: a quick dip and a sound. Menus open from black.
  - **Sound:** a soft click on hover/press, a low bell on confirm, a muffled thud on error. Use free Roblox library sounds, with an ask before anything that isn't free.
  - **HUD layout:**
    - HP and stamina thin and ornamented, top-left.
    - Skills, weapon and Blood Blade charges bottom-left; SMG ammo bottom-right.
    - Prompts bottom-centre; Virtue/phase info top-centre in matches.
    - Lock-on marker on the target.

## 5. Architecture proposal

- **A reactive UI library for menus:** [Fusion](https://github.com/dphfox/Fusion), MIT-licensed, free, Luau-native and widely used. Screens declare UI from state, so a menu with 6 states stays readable. The current imperative HUD components can stay as they are and be ported later.
  - Alternative: React-lua (Roblox's own; heavier, JS-style).
  - Or no library: our own small state + builder layer. That's cheaper now and costly later.
  - Lives in `ReplicatedStorage.Packages` (new; not on the owner's keep list).
- **Layers:**
  - `HUD` (DisplayOrder 10), `Menus` (20), `Overlay` (30: modals and confirms), `Toasts` (40), `Transition` (100: fades for teleports and loading).
  - One `UIScale` per layer from a shared scaler.
- **Kit (Theme v2 driven):** Panel (9-slice ornate), Button (primary/secondary/ghost, with hover, press, disabled and focus states), Tabs, List, Slider, Toggle, Modal, Toast, Tooltip, Bar, Countdown and PlayerCard. Each is one module with all of its states.
- **Flow controller:** one `MenuController` owns which screen is open. It handles input focus (Esc/back), blocks gameplay input while a menu is open (the `BLGameplay` context is disabled), and opens screens from world prompts (Blood Table, altar, atelier).

## 6. Screens, in build order

1. **Theme v2 + kit + HUD restyle.** It's visible all the time and proves the style.
2. **Blood Table match menu:** Quick Join · Create · Private (code) · Party. It has a player count and a 30 s countdown lobby inside the match server.
3. **Transition screen:** fade, a "Departing for the Victorian quarter" card with tips, then the teleport (hub → match → hub).
4. **Class altar:** class list, 3D preview (ViewportFrame), stats and kit.
5. **Atelier shell:** skins grid, Bloodgem balance, preview (real purchases come in Step 13).
6. **In-match:** Virtue/phase banner, level-up pick, the Shinigami pact prompt, and the results screen with Bloodgems earned.

## 6b. DevForum craft tips we adopt

- **Hover gets three cues:** a sound, a slight size or glow change, and a tween. Easing is Quart/Expo Out, the closest match to Roblox's own core UI feel ([UI designing tips](https://devforum.roblox.com/t/ui-designing-tips/2423307), [hover thread](https://devforum.roblox.com/t/some-advice-on-uis-needed/598157)).
- **Clear navigation beats polish:** buttons where players expect them and logically nested submenus. Every screen closes with Esc/back.
- **Centre-anchored layouts** (AnchorPoint 0.5, 0.5) hold across aspect ratios. Test in the Device Emulator.
- **Tweens must be interruptible:** a new hover cancels the old tween. One small `Motion` helper owns this, so screens never call TweenService directly.

## 7. Decisions (made 2026-10-29; the owner delegated: "whatever you think is best")

> **Update, same day:** the owner dropped Figma ("let's not use Figma but Roblox Studio"). Section 3 stays as background only.

1. **Library: our own**, no external packages. A small reactive layer in `Client.UI.Core`: `State` (value + changed signal), `Computed`, and a `Create` builder that binds props to states and cleans up with the screen. It's fully custom, there's nothing to download, and it covers what menus need. Fusion was the alternative, rejected to stay dependency-free.
2. **Workflow: Roblox Studio only.**
   - Screens are built in code with the kit and reviewed in play via screenshots (the owner's camera, several resolutions with the Device Emulator).
   - Ornaments and icons are drawn by our own scripts (`tools/`) and uploaded, as with the VFX textures.
3. **Style:** the "Vigil gothic" draft in section 4 becomes Theme v2. The owner can veto any token at review.
4. **First deliverable:** Theme v2 tokens + `Motion` helper + the kit's Panel/Button/Bar, shown as one restyled HUD in play. Then the Blood Table match menu.
