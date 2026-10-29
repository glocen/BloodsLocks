# BloodLocks — exact UI standard, current Theme v2

For Claude and glocen, 29 October 2026. Read from `src/client/UI/Theme.luau`, Hud modules and MenuController at approximately22:30 Europe/Paris. **This preserves the current palette and foundation; it is not approval to replace Theme.** Tables labeled CODE describe current values. Review gates and new-state guidance are DESIGN requirements, not claims of implemented widgets or measured source-game timing.

Use with [whole-game engineering brief](duskbloods-gameplay-breakdown.md). The player's world and character are part of the UI composition. Ornament frames information; it never competes with threats, text, interaction or navigation.

## 1. Exact current palette and semantic use

CODE `Theme.Palette`:

| Token | RGB | Hex | Use |
|---|---|---|---|
| Ink |11,8,14|#0B080E|Near-black violet background |
| InkSoft |22,15,27|#160F1B|Soft surface |
| Velvet |34,20,38|#221426|Panel body |
| Bone |232,222,205|#E8DECD|Primary text |
| Ash |150,138,140|#968A8C|Secondary/disabled text |
| Gold |201,164,98|#C9A462|Focus, hairline, restrained rarity |
| GoldDim |110,86,52|#6E5634|Quiet engraving/stroke |
| Blood |176,22,44|#B0162C|Danger/primary action accent |
| BloodDeep |88,8,24|#580818|Deep blood accent |
| BloodMuted |142,34,40|#8E2228|Actual HP fill |
| BloodMutedDeep |64,14,20|#400E14|Actual HP track |
| Ember |222,140,60|#DE8C3C|Posture, warm feedback |
| EmberDeep |130,66,22|#824216|Posture darker edge |
| Moon |110,146,220|#6E92DC|Information/cool accent |
| Verdant |120,196,128|#78C480|Healing feedback |
| Moss |128,178,84|#80B254|Actual stamina fill |
| MossDeep |46,84,32|#2E5420|Actual stamina track |

**Do not confuse HP, stamina and posture:** HP uses BloodMuted; stamina uses Moss; posture uses Ember. The old raw Ember comment mentioning stamina is not the semantic mapping. Effects have brighter separate colors; do not brighten the whole HUD to the VFX palette.

CODE `Theme.Colors` mappings:

| Semantic tokens | Value |
|---|---|
| Background / Overlay |Palette.Ink|
| Panel / PanelSoft |Velvet / InkSoft|
| Stroke / Hairline / Focus |GoldDim / Gold / Gold|
| Text / TextMuted / TextOnAccent |Bone / Ash / Ink|
| Health / HealthDark |BloodMuted / BloodMutedDeep|
| HealthLag |RGB200,140,130; #C88C82|
| Stamina / StaminaDark |Moss / MossDeep|
| Posture / PostureDark |Ember / EmberDeep|
| Warm / Accent / Danger / Heal |Ember / Moon / Blood / Verdant|
| Primary / Disabled |Blood / Ash|
| Blood (effect alias) |RGB196,18,48; #C41230|
| Radiance (effect alias) |RGB255,226,160; #FFE2A0|

Screens use semantic tokens. A new semantic role is added centrally with an explicit reason; do not paste near-matching RGB literals into each screen. Existing source still has some local numeric/color literals; that is implementation history, not a mandate to duplicate them.

CODE transparency is Roblox **transparency, not opacity**: Panel .12, PanelSoft .35, Overlay .35, Hairline .25, Disabled .55. A panel at .12 is88% opaque. Surface readability must be tested over bright sky, candle highlights and dark masonry; one nominal alpha does not prove contrast.

### Current menu and portrait colors

| CODE token | RGB / hex |
|---|---|
| Menu.StageLight |255,196,150 / #FFC496|
| Menu.CircleGlow |150,20,34 / #961422|
| Menu.RibbonTint |88,42,44 / #582A2C|
| Menu.RibbonShade |150,140,145 / #968C91|
| Menu.RibbonActive |104,70,72 / #684648|
| Menu.TabText |236,226,214 / #ECE2D6|
| Menu.Panel |46,20,24 / #2E1418|
| Portrait.Ambient |150,130,140 / #96828C|
| Portrait.Light |255,220,190 / #FFDCBE|
| Portrait.SealedAmbient |30,22,30 / #1E161E|
| Portrait.SealedLight |120,40,50 / #782832|
| Portrait.Silhouette |8,6,10 / #08060A|
| Portrait.CardShade |70,34,44 / #46222C|
| PanelShade |150,140,155 / #968C9B|

RibbonShade/PanelShade multiply the underlying fill through gradients; they are not independent opaque card colors. The Menu.StageLight is a local presentation light, not the global Manor lighting preset.

### Current VFX palette for consistent icons/effects

| CODE Theme.Vfx token | RGB / hex |
|---|---|
| BloodDark / BloodDeep |34,0,6 #220006 /104,0,14 #68000E|
| BloodWet / Blood |140,0,18 #8C0012 /196,18,48 #C41230|
| BloodCore |240,52,62 #F0343E|
| RadianceDeep / Radiance |230,90,10 #E65A0A /255,160,50 #FFA032|
| RadianceCore |255,232,180 #FFE8B4|
| Fire / FireDeep |255,120,40 #FF7828 /190,40,20 #BE2814|
| FireCore |255,220,150 #FFDC96|
| Smoke / SmokeDark |70,40,35 #462823 /25,18,18 #191212|

## 2. Type, spacing, edges, motion and layers

### Exact CODE foundation

- `Fonts.Display` and DisplayBold use `Font.fromEnum(Enum.Font.Bodoni).Family`, Regular/Bold. The source comment calls it Accanthis; the actual code contract is Enum.Font.Bodoni, not an assumed external font file.
- `Fonts.Body`, BodyBold and Numeric use `Font.fromEnum(Enum.Font.Garamond).Family`, respectively Regular/Bold/SemiBold. No unapproved font download/replacement.
- `TextSize`: Caption14, Body18, Label20, Title30, Display48.
- `Space`: XS4, S8, M12, L20, XL32, XXL48.
- `Radius`: None0, Small2px, Medium4px. Gothic cards have restrained edges; circles are reserved for medallions/gauges.
- `Stroke`: Hairline1px, Thin1.5px, Bold2px. Never outline every text label with heavy black strokes.
- `Motion`: Fast .12s, Base .20s, Slow .35s; Quart Out. Weighted, calm motion; no spring bounce.
- `Layers`: HUD10, Menus20, Overlay30, Toasts40, Transition100. Whole-screen curtains live in Transition; tooltip/interactive stacking is explicit within a layer.
- ReferenceResolution1920×1080; current layers scale from this reference.

Legacy aliases still exist: Font/FontBold, Corner2px, StrokeThickness1.5, BarHeight8, BarWidth300, CrosshairSize4, LockMarkerSize14, SkillSlotSize56. Prefer structured tokens for new work. Their existence does not make every current component use the same dimensions.

### Exact CODE menu dimensions

Menu.Margin64; Top72; TabHeight58; TabTextSize26; HintTextSize22; HintGlyph32; CardWidth460; CardHeight248; ButtonHeight58; ButtonTextSize24; RowTextSize21. Every layer ignores GUI inset; the ribbon starts at72px reference units so it clears Roblox chrome. Verify the actual window rather than assuming a fixed offset covers every top-bar variant.

### Legibility requirement — do not merely shrink1920×1080

DESIGN gate: at the final displayed resolution, interactive body/rule text renders at least16px, normal explanatory text aims18px, and optional captions at least14px. Vital action/key/count information cannot shrink to an8px label. Existing skill badges and some HUD caption literals currently fail this if uniformly scaled to a small window; this is a known review item, not a claim of current compliance.

At1366 width, uniform scale1920→1366 makes18px text12.8px and12px badges8.5px. Use adaptive component sizing/reflow and token-based sizes to satisfy the rendered minima. A large reference number alone is not proof. At narrow widths reduce side margins, wrap rule text and compact/reflow the ribbon; preserve focus and hit areas. No TextScaled solution that makes a long sentence unpredictably tiny.

## 3. Current HUD layout and exact state behavior

The following are current component values at reference resolution; new screens fit around this hierarchy. The Theme.Hud nominal dimensions differ from some local component dimensions. Preserve visual intent and centralize when touching them, rather than asserting Theme already controls every literal.

| Component | CODE layout |
|---|---|
| Vitals |Upper-left offset(36,26); medallion68; bar start60px inside component|
| Level / XP |Level(72,5) within Vitals, text18; XP120×3 at(130,15)|
| HP / stamina |HP370×8 at(60,29); stamina200×3 at(60,41)|
| Shinigami |Upper-left(40,104),300×40; crest34; name area250×22; HP180×4 at(44,26)|
| Arsenal |Anchor(0,1), offset(36,-30) from lower-left;420×220|
| Ammo |Within Arsenal(8,52),196×36; segmented strip172×6; white/bone segments retained|
| Skills |Large96px center(84,150); small56px center(28,196); ring1.32×disc; name ribbon240×28 at(140,150)|
| Player posture |Center(.5,.7);320×6 track, center-out fill; group340×22|
| Crosshair / lock |Theme nominal4 /14px; center aim information|

HUD is visible in Match or Manor combat zone; Manor noncombat/menu state hides combat sections. Do not accidentally make a map overlay re-enable combat outside the yard. Current Player posture uses a small CanvasGroup for fading; the quality prohibition concerns blurring whole text-rich menus, not assuming every isolated CanvasGroup is defective.

### Component states

| Component/state | Exact meaning and appearance |
|---|---|
| HP normal/hit/heal |BloodMuted fill over BloodMutedDeep track; confirmed loss immediate, HealthLag chip delayed; healing uses separate Verdant feedback without changing permanent HP color|
| Stamina normal/empty |Moss/MossDeep; empty has brief clear empty state; recovery visible; do not use red HP semantics|
| Posture empty/active/full |Ember center-out; CODE group transparency .55 idle,0 active (> .005); full shows stagger vulnerability; not a health depletion bar|
| Medallion Manor/Match/Final |Manor crest; Match Renown total from Config.Score; Final explicitly labeled two life marks, not unexplained numeric disappearance|
| Skill ready |Visible emblem, Hairline ring, key, charge count if max>1; CODE glow transparency .35|
| Skill recharging |Ring progress/count advances from authoritative deadline; CODE emblem transparency .55 and glow .85 when unavailable|
| Skill level-locked |CODE emblem .8 transparency, no progress; text Lv threshold; key still understandable|
| Ammo loaded/empty/reloading |Bone segments lit for remaining rounds; CODE unused .75 transparency versus .05 loaded; numeric rounds/mag or Reloading; no fake full magazine during reload|
| Companion no pact |Card hidden; interaction explains obtaining one|
| Companion summoned |Name/level/HP clear; no summon instruction over normal state|
| Companion dismissed/cooldown |Dimmed name, actual HP, T summon or Returns in Ns; keep long status out of clipped250px line|
| Status buildup |Icon+named status+progress near vitals; decay/trigger/expiry explicit; color is supplementary|
| Target lock |Marker follows valid target; no marker after death/unload; actor remains visible through minimal ornament|

Current Shinigami name/level/status are concatenated into one250px label; long names/cooldown can overflow. DESIGN fix: separate bounded name/level and short second-line status or grow the reserved card height. Do not fix by shrinking text below legibility minima.

## 4. Screen and control standards for the whole game

Every screen has a clear active mode, one primary action and visible exit/back behavior. Screen state follows server eligibility. Dead/culled/phase-changed requests close or become a clear pending result; they don't continue behind a stale modal.

| Screen | Composition and information | Interaction/failure |
|---|---|---|
| Blood Table |World/character center, thin ribbon, current tab/card left, tips only if useful, key hints bottom-right|G opens; Q/E tabs; Enter available primary; Backspace close; camera/input restored on interrupted transition|
| Hunt |Map/rule card, party/private choice, selected state, pending travel|One pending request; invalid/full/expired/failure reason; retry usable|
| Classes |Original portraits, name/role/current selection; sealed cards visually honest|Pending→saved; failure returns previous valid selection; no false unlock|
| Waiting/countdown |Roster/arrivals, map identity, minimum/countdown and lock status|Countdown cancellation clear; no active PvP; practice stays usable|
| Region selection |Map center/right, roster/standings left, selected region/opportunity explanation right; deadline and confirm|Selection and browse modes differ; overflow relocation explained; fallback on timeout|
| Map browse |Location/height, phase, ranking/cutoff, opportunities, pin/legend/layers|Closing restores input; browse never confirms spawn/travel by accident|
| Boss request |Compact bottom-center threat/request with Accept/Decline/expiry; world still visible|Invalid/expired closes; accepted transport pending; doesn't become persistent alliance|
| Boon/item replacement |Candidates distinct from currently equipped; effect/replacement before commit|Confirm/decline; capacity explicit; eligibility/cost denied cleanly|
| Phase resolution |Award reason→score/category totals→cutoff/survivors/cull→next action; portrait can occupy right|Animation does not decide eligibility; culled gets Spectate/Return|
| Final setup |Rule change/lives/arena; remaining contestants|No stale alliance/sigil panels; combat only after authoritative setup|
| Results |Winner/placement, score/source, kills, reward/settlement state, return countdown|Return failure leaves retry; repeated view does not repay|
| System/Archive/Relics |Only actual functionality; clear sealed state where design pending|No mock slider/clickable row presented as implemented|

Reference-only visual checks newly reported by ChatGPT's viewing pass: at 15:30 an in-world bottom-center co-op prompt is visible; 19:30 has category totals with portrait at right; 54:30 has a multiplayer area-pick composition. Earlier content includes tutorial/training and 29:00 explicitly says Training Battle Completed. Treat these as contextual presentation evidence, not proof of production match timings/rules. The [evidence appendix](https://github.com/glocen/BloodsLocks/blob/main/docs/duskbloods-evidence-appendix.md) records coverage: a 30-second survey and selected 2-second image sequences, not continuous watching. Audio is not assessed from a video-only stream.

The multiplayer Phase-I end at 1:00:54 and six-player roster at 1:01:16 now directly establish a source-plan discrepancy: source phase strip has eight entering I, six II, three III. Our locked plan culls later, at ends II/III. Screen artwork must use the actual chosen BloodLocks rules; copying the source phase strip would silently change the promised cull schedule. Flag this to the owner before changing gameplay.

### Button/row/input states

- Idle: quiet panel/stroke, Bone text, no permanent bright halo. Hover: one modest focus cue. Keyboard focus has the same strength and remains visible without a mouse.
- Selected: persistent RibbonActive/focus detail, label readable; selection differs from transient hover. Pressed: .12s restrained settle, no layout jump.
- Pending: visible progress/status and disabled duplicate action, but back/cancel follows its real allowed policy. Disabled: Ash/disabled transparency plus actual reason on relevant focus; no fake clickable promise.
- Invalid/error: concise text with Danger accent and reason; avoid a full-screen red wash. Success: accepted state + small gold/warm confirmation, not a full victory animation.
- Long text wraps intentionally. Tooltips stay inside viewport and don't cover the focused key/action. Text entry consumes its hotkeys; gameplay does not fire behind it.

## 5. Original ornament and effect discipline

Use the team's drawn assets in Theme.Images: RitualCircle, Ribbon, TabFlourish, HuntCard, Medallion, Ring, BloodCrescent, Glint, Bullet and SoftGlow. These come from original texture scripts; no downloaded decorative pack or paid image is needed. Use nine-slice/tile/fitted image behavior appropriate to the asset so filigree isn't stretched into mush. A ring gauge shows a meaningful fraction; it isn't a spinning loading ornament everywhere.

Reserve gold flourish for active/important hierarchy. Keep ordinary dividers subdued. Every panel does not need a crest, two chains, four corners and a bright gradient simultaneously. Class portraits may be ornate at selection scale; their tiny HUD symbol must simplify. Crisp text/accurate state comes before extra embellishment.

DESIGN timing defaults follow the main brief: Focus .12s, base .2s, slow .35s; level toast1.8s, compact pickup2s; source/rank award merging; objective completion .25s+residue .8s. Authoritative action/phase timing is separate. Sounds are original or explicitly available; don't claim audio was heard in silent/video-only inspection.

## 6. A UI screen passes only when all gates pass

1. **Semantic truth:** every count/lock/cooldown/owner/rank/life/reward is tied to actual state. A repeated packet doesn't replay rewards. A visually disabled button cannot execute.
2. **Legibility:** test1920×1080,1366×768 and a narrow resizable window. Critical text at least16px rendered, captions14px; no top-bar overlap, clipping, offscreen tooltip or unreadable alpha over bright/dark world.
3. **Hierarchy:** at a glance identify current state, next action and exit. In gameplay the threat/landing remains visible; boss bar/player posture/notification never occupy the same anchor.
4. **Input/focus:** mouse and keyboard work; focus visible; text fields don't fire actions; close/death/phase restores input/camera/cursor. Back behavior is consistent.
5. **State completeness:** idle/hover/selected/pressed/pending/disabled/error/empty/locked/success are reviewed, including long names, two-digit levels, long cooldowns, score growth and full inventory.
6. **Craft:** current exact palette/type/motion retained, original ornament crisp at real display size, no unapproved Theme replacement, arbitrary neon gradients, bounce or blurry full-menu text.
7. **Evidence:** screenshot each screen on bright and dark world backing; record one complete interaction and one denial/interruption. Label implemented/tested/visually reviewed/owner-accepted separately.

Failing one gate is a concrete review task. Code existing, a screenshot looking ornate, and owner acceptance are three different facts.

