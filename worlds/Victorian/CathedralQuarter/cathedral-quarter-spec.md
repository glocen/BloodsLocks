# Cathedral Quarter — first Victorian zone

Original BloodLocks design, 29 October 2026. **Sketch/spec delivery only.** No Victorian Studio geometry, gameplay source, map definition, tags, or Git history were changed. The owner chose the cathedral quarter as the first zone. These drawings are proposals for its construction, not approved final art or a measured reconstruction of Duskbloods.

Files are in the visualization workspace because Windows Controlled Folder Access blocked creating `Documents/ChatGPT/BloodLocks/delivery/victorian`. Do not change that protection. This delivery is now also published under `worlds/Victorian/CathedralQuarter`; keep the visualization folder as the local editable/rendered copy.

## 1. What this zone should feel like

An institution has grown above an occupied working district. People once maintained the cathedral from the bell works, lit the lanes, carried the dead through the crypt, and crossed from chapter houses through the cloister galleries. The architecture should make those activities legible. The central landmark is a long cathedral with one narrow bell tower offset west, rather than a symmetric fantasy castle. Smaller brick terraces, slate roofs, chimney groups, service doors, iron gates, and lamp brackets establish a different scale around it.

The main approach compresses between inhabited façades, opens into a processional court, and reveals the raised entrance. Side routes remain visible before the broad stair. A player can cross the nave, climb the gallery, circle on roof courts, or descend through the ossuary. Every route rejoins another route. Height should offer information, a shortcut, or an ambush angle; no rooftop should control the whole district.

Use the reference's principles: monumental silhouettes above human-scale streets, strong foreground/middle/background, cool stone and sky, selective warm practical lights, sparse objective gold, and readable shadow. The layout, names, construction and implied history here are original. The parent gameplay report carries the footage evidence; these sketches do not establish that any unseen reference floor plan exists.

## 2. Drawing set and authority

- `01-cathedral-quarter-plan.svg` / `.png`: proposal scale, route families, shelter, spawns, enemy groups, reserved interaction sites and expansion sockets.
- `02-circulation-section.svg` / `.png`: unfolded height relationships. Horizontal screen distances are schematic; the dimensions in this document control construction.
- `03-player-view-approach.svg` / `.png`: composition A, street arrival. Camera proposal `(0, 5.5, 198)` looking toward `(0, 30, -80)`.
- `04-player-view-vertical-loop.svg` / `.png`: composition B, court/bridge/crypt relationship. Camera proposal `(148, 5.5, 72)` toward `(-50, 20, -46)`.
- `cathedral-quarter-layout.json`: machine-readable **design data**, not a runtime map schema. Do not require it from gameplay code.
- `build-sketches.cjs`: original vector source and repeatable PNG renderer using bundled Node + sharp. No external models, textures, fonts or generated assets are fetched.

The plan was inspected after rendering; overlapping labels and an incorrect first crypt section were corrected. The composition drawings clarify value groups and route relationships. They do **not** prove material realism, finished stone carving, correct 3D projection, or playable camera behavior. Those need an engine blockout.

## 3. Source facts that constrain the design

Read the latest local source before building: `C:/Users/gloce/BloodsLocks/src` is the Rojo source of truth. World content stays in Studio. GitHub tree observed during this audit: `66119edad61c1dac424c6e7835d77c5f4d55589e` (main can move).

| Source | Verified behavior |
|---|---|
| `shared/Definitions/Maps/Victorian.luau` | Place `112559855790294`; `Zones = {}` is currently empty. The proposed `CathedralQuarter` entry has **not** been added. |
| `shared/Config/Movement.luau` | Walk 18, sprint 30 studs/s; gravity 145 is the place target. Tap launch 50, full high jump 85; three additional air jumps at 45. One air dash per airtime, speed 72 for 0.18 s. |
| `shared/Config/Stamina.luau` | Base 100; air jump costs 12, dash costs 20. Sprint/ground/high jump free. Cost behavior can drain any positive remainder to zero, so stamina is not an exact hard route gate. |
| `shared/Config/Camera.luau` | Default camera distance 11, range 6–16; shoulder offset 1.4; collision radius 0.6. Lock acquisition 60, break range 80. |
| `shared/Definitions/Enemies/Victorian` | Real IDs are `Wretch` (fodder) and `Butcher` (heavy). No cathedral boss definition exists. |
| `server/Services/Core/NpcService` | Already reads `BL_EnemySpawn`: exact `Enemy` or roster `Zone`; optional `Count`, `Radius`, `Respawn`. Scatter is planar and a 50-stud downward probe finds the floor. |
| `EnemyBrain` / `server/Npc/NpcActor` | Direct `Humanoid:MoveTo`, not a path planner. Target distance is flattened before attack choice. Home arrival checks horizontal distance. It is not safe to assume stairs, stacked floors, doors or roof pursuits work. |
| `server/Services/Core/ShinigamiService` | Already reads `BL_PactCircle` plus `Shinigami` ID. `Kurogane` exists. This is different from the planned match-region contracts. |

`BL_Region` / `Region` and `BL_Spawn` are documented in the engineering plan, but there is no current consumer in inspected `src`. They are future integration contracts. Do not label region selection/respawn as working because marker parts are present. Ritual, forge, Flame corpse, pickup and boss reservations below have no invented CollectionService tag.

### Calculations, not traversal results

Using ballistic ascent `h = v² / (2g)` at gravity 145: tap jump = **8.62** studs; full high jump = **24.91**; each perfectly timed air jump adds **6.98**; ideal high jump + three apex air jumps = **45.86** studs. Dash displacement is **12.96** studs before collision. Falling gravity is multiplied by 1.25. Input timing, collision, Humanoid steering and simulation behavior will reduce or change actual route performance. No maximum horizontal jump range was established.

Consequently, a 36-stud roof is not a sealed upper floor and a 48-stud route is not a dependable barrier. Large traversal moves are welcome; prevent dominance with roofs, walls, inset courts and limited sightlines. Never depend on an invisible ceiling or on the player failing a difficult jump.

## 4. Coordinates, massing and usable dimensions

All dimensions are studs. Local proposed zone origin is `(0,0,0)` in the Victorian place; north is `-Z`. Heights in this document are **finished walking surfaces**, not character root positions. Work on a 2-stud structural grid, with 0.5-stud secondary profiles. Keep pivot axes aligned.

| Volume / surface | Position and size | Construction intent |
|---|---|---|
| Zone envelope | X `-240..240`, Z `-260..240`; proposed vertical extent `-48..148` | 480 × 500 first-zone envelope. Region part center `(0,50,-10)`, size `(480,196,500)` when the region service exists. |
| Cathedral main mass | X `-68..68`, Z `-176..-32` | Main nave outer wall. 4-stud structural thickness; buttress projection outside the envelope. |
| Nave floor | Y `8`; clear X `-48..48`, Z `-157..-55` | 96 × 102 playable interior. Central 64 × 64 at `(0,8,-124)` is kept free for a future encounter. Side piers lie outside that square. |
| Processional court | X `-50..50`, Z `14..94`, Y `0` | 100 × 80 clear court. No fountain, loose props, posts or steps inside ritual reservation. |
| Front stair | X `-56..56`, Z `-32..-16`, from Y `8` to `0` | 16 risers at 0.5; 1-stud treads; broad center; side parapet separate from the walkable collision. |
| Cloister court | X `-128..-68`, Z `18..88`, Y `0` | Western loop and pact shelter. 18-stud exit mouths; keep a 36 × 36 clear center. |
| Bell yard | X `76..138`, Z `28..106`, Y `0` | Eastern heavy encounter pocket. At least 44 × 52 of unbroken fighting floor. |
| Crypt route | Y `-18`; ceiling underside at least `-2` | 16 clear height in corridors, 18 over stair pitch. 14 wide corridors, 18-wide turns/landings, 36 × 40 chambers. Never put a jump requirement in the only return. |
| Interior gallery | Y `24` | 16 above nave; 12-wide walking ledges and 18-wide landings. Two independent doors G1/G2, not one decorative balcony. |
| Roof courts / crossing | Y `36`; selected far landing Y `48` | 12-wide traversable connections, 18-wide turns. Each landing must connect to two directions. Ridge/spire are scenery. |
| Spawn roof courts | S7 center `(-126,36,124)`, S8 center `(132,36,-128)`; each 32 × 24 | Explicit roof platforms with bearing walls below; connect to their stair headhouses. Do not leave a marker hovering between massing blocks. |
| Main street / ring | Y `0`; 28 wide main route, 22 wide side ring | Avoid prop pinch points. Secondary service passages: 14 wide, 16 high. Combat pockets open to 36+ wide. |

Four large architectural layers should cast different shadows: structural wall, recessed opening, arch orders, projecting hood/sill. Make true openings. Window glass sits behind the reveal; doors open through thickness. Galleries bear on stone piers or corbels. Bridges have receiving walls/pier supports. Roof courts need visible gutters, retaining edges, and stair headhouses.

The entry front is deliberately slightly offset in silhouette: west bell tower, long nave roof, lower east service chapel. Do not mirror every bay. Put the worn bell service stair on the working side, formal tracery at the ceremonial front, and plainer repaired brick at the service row. Small signs, candle niches, abandoned maintenance gear and drainage tell this story after the large forms work.

## 5. Connected circulation, built in this order

Route lines in the drawing show connectivity. Build actual paths at the following surfaces and widths, rather than sweeping a tube along a sketch line.

1. **Ground circuit:** south arrival `(0,0,214)` → west court `(-142,0,84)` → west service lane `(-142,0,-94)` → north lane `(0,0,-220)` → east lane `(146,0,-64)` → bell yard `(146,0,82)` → processional court `(0,0,48)` → arrival. The north lane wraps the sealed apse; it never requires entering the cathedral.
2. **Interior alternative:** front stair → nave → west side vestibule `(-78,8,-54)` → ramp back to west ring `(-142,0,-54)`. An independent east vestibule `(98,8,-62)` returns to `(146,0,-62)`. Both ramps descend 8 over 24 studs, width 18. Doors have 14 clear width and 18 height. No door animation is required for the initial blockout.
3. **Upper western ascent U1:** entry `(-144,0,106)`. Three stair flights climb 12 each, with 24-stud horizontal run, 12 width, and an 18 × 18 landing after each flight. Fit flights around the cloister edge, not through its center. Connect Y `24` to gallery door G1 `(-70,24,-28)` and Y `36` to the west roof walk near `(-78,36,-78)`.
4. **Upper eastern ascent U2:** entry `(148,0,-118)`. Same flights/landings, with independent access via bell works. Connect `(114,36,-86)` to G2 `(76,24,-42)` and the eastern roof court. Descend the east stair to bell yard. U1 and U2 must both reach the crossing without passing through each other's bottleneck.
5. **Upper circuit:** west roof walk → supported crossing centered approximately `(0,36,14)` → east roof court → U2 return. Gallery alternatives inside the cathedral connect west/east at Y `24`. A far bridge at Z `-132` may connect upper side routes only if 3D sightline tests pass; omit its collision until those tests do. It is the dashed upper segment in the drawing.
6. **Crypt circuit:** L1 entrance `(-132,0,32)` descends to `(-112,-18,38)`; route through `(-112,-18,-42)` → `(-38,-18,-74)` → `(42,-18,-74)` → `(110,-18,-38)` → `(130,-18,28)`; L2 returns to `(140,0,16)`. At each mouth use two 9-stud flights, each run 18, width 14, separated by an 18 × 18 landing. Fold flights inside the entrance chamber; plan centerline distances are not stair runs.
7. **Crypt/interior returns:** service stairs behind the two nave side vestibules connect crypt `-18` → nave `8` using 13 + 13 rise, 26 run per flight, width 14 and 18 × 18 landing. They provide extra loops; L1/L2 remain the obvious no-puzzle returns.

For every flight: continuous collision under visible steps, no lip at either landing, ≥18 clear height measured perpendicular to the walking surface, and no pillar in the camera retreat space. Failed jump shortcuts must land in the court/street/crypt rather than outside the map. No fall damage is implemented in the inspected movement code; still build receiving surfaces and explicit out-of-world handling later.

### How we keep the roof useful without making it compulsory

- A 16–24-stud-high stair headhouse and a solid cathedral roof volume break the upper ring into **three** visible sectors. The bridge overlooks the front court; west roofs look into the cloister; east roofs look into bell yard. No one standing point sees all three.
- Do not put the only forge, pact, pickup, or regional objective on the highest route. Ground and crypt routes should get worthwhile opportunities too.
- Keep sheltered doorways outside each overhead firing angle. Courtyard exits should not align along one straight shot.
- Use roof bulk, side walls, setback parapets and angled landings as real sight blockers. Railing bars alone are not cover.
- Test jump skips from both directions. Allow skips that create movement expression; repair only skips that reach outside geometry, bypass the sole engagement boundary, or create a universal firing platform.

## 6. Spawn and world contracts

Proposed region ID: **`CathedralQuarter`**, display name **`Cathedral Quarter`**. When Claude integrates the region service, add it to `Victorian.Zones` with existing enemy IDs, e.g. Wretch weight 8 / Butcher weight 1. These weights are fallback content selection, not a replacement for authored encounter groups.

Tag region volume `BL_Region`, attribute `Region = "CathedralQuarter"` only when that source contract is consumed. Candidate spawn markers use documented `BL_Spawn`; there is no implemented marker-to-root offset contract yet. Table heights are floor surfaces. Put markers at floor +3 for initial inspection and have Claude make the spawn service's exact convention explicit before activation. Do not guess additional tags/attributes.

| ID | Floor position `(X,Y,Z)` | Shelter / exit requirement |
|---|---|---|
| S1 | `(-194,0,188)` | Western terrace rear court; masonry blocks the main approach. Two ground exits. |
| S2 | `(184,0,178)` | Service-row yard; two gate mouths to separate lanes. |
| S3 | `(-196,0,-202)` | Chapter-house court; no direct line to cathedral altar. |
| S4 | `(196,0,-208)` | Bell-works court; view north lane before stepping out. |
| S5 | `(-184,0,24)` | West terrace court; entrances face away from enemy lanes. |
| S6 | `(192,0,-14)` | Eastern service court; dogleg exits conceal the spawn. |
| S7 | `(-126,36,124)` | West roof court; headhouse occludes bridge; stair down plus separate drop to safe terrace. |
| S8 | `(132,36,-128)` | East headhouse roof court; enclosed landing faces inward; stair down plus safe ledge drop. |

The nearest two candidate **floor positions** are S1/S7, **100.08 studs apart in 3D**, calculated from these coordinates. This exceeds the engineering proposal of 60 studs, but does not establish fairness or occlusion. Each spawn needs 18 × 18 clear floor, 16 clear height and two usable exits. None may appear inside a currently aggroed enemy group. Eight candidates in one zone are a temporary test arrangement; later regional allocation must include the expanded map.

### Authored enemy groups — exact real IDs

Create individual markers with `BL_EnemySpawn`, `Enemy` as below, `Count = 1`, `Radius = 0`; marker Y = finished floor +0.25. Individual slots avoid random scatter into a wall, a stair, or the wrong stacked floor. Keep markers noncollidable/nonqueryable, as NpcService also does. Use existing default respawn values: Wretch 45 s, Butcher 90 s; do not add local balance overrides for the art blockout.

| Group | Marker floor positions | Roster / intent |
|---|---|---|
| A, lane pack | `(-104,0,142)`, `(-92,0,150)`, `(-80,0,142)` | 3 × `Wretch`. Visible on a 36 × 40 open pocket before committing. |
| B, yard approach | `(104,0,88)`, `(120,0,88)` | 2 × `Wretch`. Fodder pressure before the yard; not in its stair mouth. |
| C, east service lane | `(112,0,-38)` | 1 × `Butcher`. Give the telegraph a full camera view and two side exits. |
| D, nave | `(-38,8,-138)`, `(-28,8,-122)`, `(-44,8,-112)` | 3 × `Wretch`. Spread around the altar-side encounter, not a surprise stack behind the door. |
| E, nave heavy | `(32,8,-114)` | 1 × `Butcher`. Disable ordinary D/E group spawning while a future boss occupies R2. |
| F, lower chamber | `(-78,-18,24)`, `(-62,-18,28)` | 2 × `Wretch`, **reserved until vertical AI tests pass**. Do not apply the live tag yet. |

Initial enabled content A–E = 10 NPCs (8 Wretch + 2 Butcher); F brings the design to 12 when implemented. Their current rigs/animations are engineering placeholders; the existence of a spawn does not make enemy art finished.

**Concrete AI integration request for Claude:** validate target/home floor or add navigation before activating F/roof enemies. Current attacks select range from flattened distance; a target directly above can look close while being unreachable. Current home arrival can accept matching X/Z on the wrong floor. Direct MoveTo may run into retaining walls. Tests must cover a player standing over the crypt, running up stairs, dropping behind a wall, and leaving the leash on a different floor. Do not fix an AI issue by sealing every interesting route.

## 7. Interaction and encounter reservations

These are authored **locations**, not invented live tags. Only O1 has a compatible existing gameplay contract.

| Marker | Position / clear area | Intended function |
|---|---|---|
| R1 | center `(0,0,48)`; radius 32 clear | Future ritual site. Keep boundary readable and floor continuous; reserve multiple exits. No runtime ritual marker exists yet. |
| R2 | center `(0,8,-124)`; central 64 × 64 within the larger nave | Future boss/Trespasser encounter option. No boss ID or move set exists. Arena size is provisional until body scale, camera and attacks are authored. Never activate simultaneously with normal D/E packs. |
| O1 | `(-112,0,38)`; 18 × 18 clear | Shinigami pact. Existing compatible marker would be `BL_PactCircle`, `Shinigami = "Kurogane"`. Preserve prompt access and the companion's exit route. No marker was created here. |
| O2 | `(112,0,48)`; 18 × 18 clear | Future forge in a brick service niche. Warm ember pool and wall tools identify the function. No forged tag/schema. |
| O3 | `(-44,-18,-72)`; 18 × 18 clear | Future exploration pickup/relic in crypt chamber, placed beside the through-route. Do not use it to disguise a dead end. |
| O4 | `(-120,0,-122)`; 18 × 18 clear | Future Flame corpse/shrine in sheltered ossuary threshold. Gold/blood response is active feedback later; silhouette must identify it without glow. |

The final arena and Antechamber are **not** squeezed into this district. Reserve them as separate match systems/locations in the wider map plan; no generic `BL_FinalArena`, `BL_Boss`, `BL_Forge` or ritual tags are introduced by this package.

## 8. Expansion sockets

Keep construction inside the envelope. Build 40-stud-deep transition seams so future geography can join without moving the cathedral or replacing the zone.

| Socket | Center, width, height | Future direction / reserved behavior |
|---|---|---|
| West | `(-240,0,66)`, 28 wide × 20 high | Bell-maintenance route toward future industrial/workers' district. Reserve a ground street plus a parallel upper tie at Y 36. |
| East | `(240,0,52)`, 28 wide × 20 high | Service road toward future waterside/lake district. Leave ground elevation adjustable beyond the seam, not inside the court. |
| North | `(0,0,-260)`, 24 wide × 20 high | Quiet lane toward a future moor/woodland district. Preserve a distant silhouette gap behind the apse. |

Future labels are planning names, not new region IDs. Close unfinished sockets with authored gates or a turn into an unbuilt passage; do not show a finished road ending against an invisible wall. No third-party scenery is needed.

## 9. Light, material and charm instructions

Preserve the owner's lighting stack while making an isolated world-light study. Lock exposure before comparing locations. Make the quarter readable in three or four broad value groups; check grayscale at the actual 11-stud camera, then at 6 and 16. The drawings deliberately keep the sky brighter than distant stone and practical lights small.

- Cathedral: cool dressed stone, dark roof, warm light at the usable entrance. Deep reveals create the local contrast; avoid blue paint masquerading as moonlight. Interior timber, shadowed side aisles and selective votive clusters distinguish it from exterior masonry.
- Terraces: restrained red/brown brick under cool dusk, patched slate, soot above chimneys, damp at foundations. Each corner gets a purpose: lamplighter bracket, shutter repair, drain, worn threshold or working sign.
- Crypt: less saturated, damp lower stone and pale directional spill from stair mouths. One muted warm memorial niche. Fog is localized and low; players must see floor edges and the next exit.
- Upper circuit: roof silhouettes and cool exposure explain height. Warm windows below remind the player of the street. Chimney bulk interrupts sightlines; a lamp at each descent signals a return.
- Keep red for blood/danger and gold for active objectives/selection. Decorative windows should not look like available pickups. Shinigami/objective VFX must remain distinguishable from environmental candles.
- Model sparse causal chips, run-off below ledges, sheltered moss and local wet patches. Do not coat the whole district in noise, uniformly rounded bevels or glossy stone.
- Audio locations to reserve for Claude: bell-tower direction; muffled exterior bell in crypt; gutter/drip near lower entrances; small iron-sign creak and isolated lamp hiss in street. Use original/authored audio later, not downloaded effects without a rights decision. Do not pretend sound was judged from silent diagrams.

Small details that earn their place: a hand-worn stair rail at U1; patched bell rope opening at U2; water stain that continues from gutter to wall to drain; one extinguished lamp before a lit junction; a hearse-width service door into the ossuary. Repeated rubble, random tilted props and dense smoke will not supply identity.

## 10. Acceptance before art replication

1. Construct a neutral blockout and compare the two named camera views. The landmark, broad stair, side route mouths and lower exit must read without texture or fog. Do not call the vector drawings finished environment art.
2. Walk the entire ground loop at zero stamina. Walk both upper stair routes and both crypt returns without jumps. Check turn/ceiling clearance with R6 and the 1.35-scale Butcher. Test camera 6/11/16, lock-on, dodge and Shinigami following at every turn.
3. Test tap jump, full charge, three air jumps and dash at shortcut pairs. Record achieved landing positions; do not tune movement to rescue bad geometry. No critical route needs a maximum-chain jump.
4. Verify every spawn is on its intended floor, has two exits, avoids initial aggro and cannot be watched from a common roof perch. Test simultaneous eight-player candidates, not only one character in an empty place.
5. Test A–E in their pockets. Attacks must hit or miss for understandable reasons; enemies must return home correctly after a wall/height break. Hold F inactive until the four vertical AI cases above pass.
6. Stand at each upper sector with ranged aim. It may threaten a portion of one court, never every spawn/objective. Test return fire and concealed ground exits. Rework actual geometry where dominance appears.
7. Only after circulation passes: one representative street/cathedral corner in clay + grazing light → material review → dusk lighting → localized detail → player view. Compare before replicating the kit across the quarter.

No Studio tests were run for this sketch package. Verified now: source contracts read; four SVGs generated and four PNG previews visually inspected; corrected section/label issues; analytic jump heights and spawn separation calculated. Remaining work: engine geometry, traversal, camera, NPC navigation, spawn service, encounter systems, materials, audio and visual acceptance.

## 11. Notes for the next session

- Read Claude's newest team notes and re-enumerate both Studio instances. Their IDs change. This task did not touch the existing Victorian NPC test layout.
- Keep Manor work first in the owner's execution order. This zone is ready as a sketch handoff after that review, not a reason to silently switch places.
- `CathedralQuarter` is proposed, while `Victorian.Zones` is still empty. Coordinate the source addition with Claude; do not write Rojo-owned source in Studio.
- Do not turn a diagram promise into a completion claim. A line labelled stairs must become properly measured flights and survive the camera test.
- The greatest design risks are a universal roof perch, a ritual court dominated by a bridge, and AI fighting across stacked floors. Test those early, before carvings and textures.
- The composition A façade remains intentionally schematic. It needs asymmetrical chapel/service massing, deeper architecture and convincing masonry in 3D. More little windows on a flat shell will not solve that.
- Save editable Blender masters outside generated workspace content. Keep before/after captures and the source of any value chosen. Do not overwrite the owner's unsaved Blender file.

