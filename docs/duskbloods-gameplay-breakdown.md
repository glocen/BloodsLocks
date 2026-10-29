# Duskbloods footage breakdown and BloodsLocks build direction

Prepared by ChatGPT for Claude and glocen, 2026-10-29. Gameplay research handoff; tutorials excluded.

## 1. Read this first: evidence and scope

There is enough evidence to explain the match's rhythm, progression, spatial design, HUD hierarchy and atmosphere, and to build a representative first playable slice. There is not enough evidence here to reproduce every enemy's move set, numerical balance or screen duration.

**Method:** direct visual sampling at roughly minute intervals across two match arcs, with additional selected frames, plus an edited commentary video's transcript and the team's manual summary. This is **not uninterrupted viewing of two or three complete matches**. Between-frame actions remain unknown. A source timestamp is a navigation point, not a measured game timer or proof of an uncut sequence.

Sources:

- **A:** [DePrimeYT, DUSK BLOODS FIRST WIN — Entire Playthrough](https://www.youtube.com/watch?v=GssEFxrxDtQ), 25:10. The footage itself carries a **B-roll / not live gameplay** notice. Use it for visible behavior and composition; do not derive authoritative phase lengths from its edit. Character appears to be the helmeted, axe-carrying fighter; exact identity not verified here.
- **B:** [Vosair, The Duskbloods Gameplay full 4k 60 fps](https://www.youtube.com/watch?v=8Dyw5O2zyiY), 2:49:34. This is the owner's supplied link. We examined the multiplayer arc approximately 53:56–1:17:00, with the next selection screen at 1:18:05. Earlier tutorials are outside this handoff. The sampled fighter appears to be “Senator Samir.”
- **C:** [Oroboro, I PLAYED DUSKBLOODS](https://www.youtube.com/watch?v=yV0EjPXYZQE), 30:39. Edited explanation; narrator says the shown footage was supplied by FromSoftware. Transcript statements are **reported mechanics**, not our own continuous gameplay observations.
- **M:** [Official network-test manual](https://campaign.theduskbloods.jp/manual/en/basic1.html); see also [our manual summary](duskbloods-manual-summary.md).

Evidence labels below: **V** = visible sampled frame(s), **M** = manual-supported rule, **R** = narrator report, **D** = proposed BloodsLocks design. Source-game names in quotation marks are reference labels, not proposed names for our game.

## 2. The overall experience we need to understand

The early game alternates short fights, fast travel through architecture, route choices and upgrades. It is not a continuous duel or a corridor of mandatory enemy packs. The player repeatedly leaves combat to make a strategic decision: which region, which companion, which boss, which objective, which route before the clock runs out.

The same world supports three scales at once:

1. **Immediate:** an enemy's body, attack space, dropped reward and readable exit.
2. **Regional:** a courtyard, roof chain, stair system, bridge or sewer branch with multiple approaches.
3. **Strategic:** the map, rankings, regional opportunities and approaching phase deadline.

The late game concentrates players and changes the social contract. Someone who helped defeat a boss can become a final-phase opponent. In source B the formerly allied “Nosoul5” is later a red-health-bar target. This reversal is a stronger design lesson than copying a particular spell.

**D:** Build routes and objectives together. A beautiful Victorian district with no meaningful upgrade routes or encounter choices will miss the gameplay just as much as an empty combat arena will miss the art.

## 3. Source A: minute-by-minute sampled timeline

These are approximate **video timestamps**, not elapsed phase time. Levels and Virtue are snapshots; changes between them cannot be assigned to a single kill or pickup.

| Link | Directly visible | What it teaches us |
|---|---|---|
| [0:02](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=2s) | Hub menu; player centred on a red circle; throne/canopy behind; thin top tabs, small mode card upper left, connecting status and right-side tip. | Preserve the world and character as the menu's main image. |
| [1:06](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=66s) | Full map, eight-player ranking, zero totals, phase strip, named regions and feature icons; depth/zoom/pin controls. | Map is a planning screen with information layers. Do not confuse every map opening with a spawn-selection screen. |
| [2:00](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=120s) | City, level 3, Virtue 0; close humanoid contact; damage 114 and XP +107. | Early PvE feeds progression. Exact attack classification is not established by this still. |
| [3:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=185s) | Level 4, Virtue 3; ranged companion card “Gunslinger Beatrice” level 2; purple ground effect ahead. | Companion identity/level stays legible without dominating traversal. Purple effect function unverified. |
| [3:59](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=239s) | Greatbridge region, level 5, Virtue 7; another player nearby. | Shared routes create encounters before the final. |
| [5:01](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=301s) | Clock-tower roof; axe attack on torch-bearing humanoid, damage 167. | Roofs are playable combat surfaces. |
| [6:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=365s) | Level 6, Virtue 6; torch-bearing enemies, other player, companion outline; clock 54. | Several readable actor types must coexist. Virtue has fallen since an earlier sample; cause unknown. |
| [7:00](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=420s) | Level 7; three pale humanoids in a vegetated corner; clock 0. | Dense props must leave room for melee and camera movement. |
| [8:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=485s) | Cathedral approach; broad stairs, blue distance, pink horizon, warm lamps. | A major landmark is revealed through a staged approach. |
| [9:01](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=541s) | HUD-free character presentation, including a large blue wolf-like companion. | There is visual punctuation between exploration stretches. Exact screen trigger needs closer inspection. |
| [10:06](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=606s) | Giant toad boss “Lady of the Bog” in clock-tower courtyard; broad boss HP/posture display. | Boss body and arena need to be designed together. |
| [11:00](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=660s) | Same boss close-up, allied outlines, substantially reduced boss HP. | Co-op spectacle; close camera can obscure the fight. |
| [12:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=725s) | Phase-II map; eight players; own Virtue 11, rank 8; clock 98; “Dusk's Toll” event card and clock-tower zone. | Event information is spatial and strategic, not only a toast. |
| [13:00](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=780s) | High belfry view over cathedral and mist; level 12, Virtue 11. | Height provides route choice and an orientation panorama. |
| [14:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=845s) | Map; Virtue 24, rank 5; clock 8; danger shading on lowest two ranks; objective icons in highlighted area. | Let players see their survival risk before a cull. |
| [15:00](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=900s) | Phase-III selection/intermission, six players remain; changed region features; storm event card. | The visible eight-to-six reduction supports a cull; phase boundaries refresh strategic choices. |
| [16:04](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=964s) | Cathedral, level 15, Virtue 33; humanoid fight; “Goldblood Boluses” pickup tooltip indicates gradual healing. | Reward feedback must identify both item and function. |
| [17:01](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1021s) | City, level 17; target label “Dark Leopard.” | Name alone cannot establish whether a target is a player or NPC. Do not add this to the enemy roster yet. |
| [18:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1085s) | City, level 18, Virtue 44; ally card, fellowship item, timer 119, compass objectives. | Social status, inventory and navigation coexist in the HUD. |
| [19:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1145s) | Greatbridge, clock 59; one-minute warning; gold beacon beyond arch. | Deadline plus landmark directs the next move. |
| [19:59](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1199s) | Virtue 56; pledge interaction at tall amber/gold thorn-like pillar; hand gesture and progress bar; other coloured beacons. | Capture must read in world space and through explicit progress. |
| [21:02](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1262s) | Final combat; red/pink scene; crest shows two gold life marks instead of numeric Virtue; named opponent and ranged trails. | Reuse the HUD's established anchor while changing its meaning clearly. |
| [22:07](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1327s) | Final continues; companion level 4; melee/ranged effects and another opponent. | Final retains the character's built-up combat identity. |
| [23:01](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1381s) | Continued final duel. | Exact remaining-life interpretation needs a closer check. |
| [24:05](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1445s) | HUD-free victory presentation; kneeling fighter, grail foreground, enormous red eclipse/moon. | Victory resolves the match with a strong composed image. |
| [24:48](https://www.youtube.com/watch?v=GssEFxrxDtQ&t=1488s) | Wider standing character beneath blood moon. | No final results table was verified in the inspected ending. |

## 4. Source B: second fighter and match arc

This arc demonstrates a different body silhouette, weapon and companion. It provides a useful comparison, not an exhaustive second combat analysis.

| Link | Visible observation |
|---|---|
| [53:56](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3236s) | Broad, green-armoured fighter with huge coiled/segmented weapon in a HUD-free arrival shot. |
| [55:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3305s) | Forest region label, level 1, Virtue 0; traversal through balcony/library-like interior with furniture and carpet. Region name does not mean every metre is outdoors. |
| [56:02](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3362s) | City streets, level 2; +98 XP; gate and lamplit stairs. |
| [57:00](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3420s) | Sewer, level 3; “Nia, Sister of the Briar” level 1; melee contact and damage 90. |
| [58:07](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3487s) | Sewer, level 4, Virtue 5; companion level 2; “Beastridden (Poison),” elongated greenish humanoid approximately 1.5–2 player heights. |
| [59:03](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3543s) | Giant toad encounter in confined sewer space; level 6, Virtue 7; poison buildup meter; damage 757. |
| [1:00:04](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3604s) | Low-health retreat up stairs; clock 48. Boss outcome not observed. |
| [1:01:09](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3669s) | Ornate transition image; exact heading and sequence not established. |
| [1:02:04](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3724s) | Cathedral altar encounter: approximately four smaller pale/hooded enemies and one heavier hooded figure; some carry torches. |
| [1:03:09](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3789s) | Level 10, Virtue 15; exiting through bright doorway. |
| [1:04:10](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3850s) | Greatbridge boss “Vampyr,” large black/red winged silhouette; several allied outlines; open arena with central architectural feature and cliff wall. |
| [1:05:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3905s) | Shared Trespasser-victory toast; level 15, Virtue 34, companion level 4. Exact reward cannot be isolated from these spaced samples. |
| [1:06:00](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3960s) | Forest; huge spiked wheel-like target, label appears “Nikke (Wheel)”; green cloud; ally card; low player HP. Label spelling remains provisional. |
| [1:07:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4025s) | Sewer poison enemy again; level 17, Virtue 51; damage 1803. Not a safe estimate of ordinary attack damage. |
| [1:08:08](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4088s) | Phase-III intermission; six players; player first with Virtue 64; regional icons changed. |
| [1:09:03](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4143s) | Cathedral; large luminous golden crescent/circle in masonry; vertical traversal; level 18. Precise interaction not sampled. |
| [1:10:08](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4208s) | High cathedral route; round red sac near the overhead architecture; level 19. Its exact motion/drop behavior needs a closer segment. |
| [1:11:03](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4263s) | Level 20; upgrade selection with two candidate cards, separate current passive list of five, decline/confirm controls. Examples include lightning and on-kill healing. |
| [1:12:03](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4323s) | Elevated white-flower terrace/garden, surrounding spires and cool/purple depth. |
| [1:13:07](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4387s) | Sewer fight, Virtue 97, clock 11. |
| [1:14:01](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4441s) | Final in flower terrace; two gold life marks, enlarged HP; former ally now targetable as an opponent. |
| [1:15:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4505s) | Multi-opponent final, pink flowers/red sky; large overhead weapon pose. |
| [1:16:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4565s) | Final continues with companion/ranged effects. |
| [1:17:00](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4620s) | Loading image. Outcome unverified; do not call it victory or elimination. |
| [1:18:05](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4685s) | Fresh eight-player, zero-Virtue region-selection screen, different roster. |

## 5. Enemies, bosses and encounter readability

### What is actually established

| Reference appearance | Visible scale / grouping | What is not yet established |
|---|---|---|
| Pale, hooded or torch-bearing humanoids | Human-scale; groups of three in A; about four smaller plus one heavier figure at B's cathedral altar. | Full attack list, windups, aggro radius, hit count, stagger threshold, individual loot table. |
| Poison beast-humanoid | Long limbs, greenish/furred body, roughly 1.5–2 player heights; sewer encounters, poison cloud/buildup nearby. | Which move causes poison, exact reach, combo length, recovery or drops. |
| Giant toad boss | Extremely large head/body; courtyard in A, confined sewer encounter in B; boss HP and posture UI. | Whether these have identical variants/behaviors; complete attacks, phases, telegraphs, summon trigger and reward values. |
| Winged Trespasser | Black/red winged silhouette on bridge; multiple cooperative participants; explicit shared-victory feedback afterward. | Attack list, phase changes, arena lock rules, exact invitation screen and exact individual rewards. |
| Spiked wheel-like great foe | Massive wheel silhouette and green cloud in forest; player and allied context. | Name spelling, classification, attacks, drops. |

The damage numbers captured above are **outgoing hit readouts in different builds and situations**. They do not establish enemy HP, incoming damage or baseline balancing. Single images cannot measure attack timing. Claude should not turn these into precise combat definitions.

**D: NPC first slice:** one original human-scale fodder enemy, one clearly larger elite and one readable boss. Give them deliberately different silhouettes, movement and danger zones. Start with authored telegraph → active hit → recovery states using our existing simulation conventions. Chosen prototype timings are BloodsLocks tuning values, labelled as such, not supposed measurements from this video.

Place small enemies in authored encounter groups. Give each group a useful terrain relationship: a corner to round, stairs to climb, an exposed reward, or a roof exit. Avoid filling every street with identical evenly spaced enemies.

**D: Boss encounter contract:** authoritative encounter ID, participant set, invitation state, join/leave rules, completion result and one-time rewards. The architecture must support temporary cooperation independently from persistent player alliances. The footage proves the shared-fight experience; the invitation UI still needs targeted verification.

## 6. Interactables and rewards

### Direct visual evidence

- **Pledge objective:** A 19:59. Tall gold/amber branching beacon, base on the ground, reaching gesture and progress bar. It can be recognised from a distance and interacted with close up.
- **Passive reward menu:** B 1:11:03. Two candidate cards are visually distinct from the already-equipped list. Do not mix candidate preview with committed state.
- **Healing item:** A 16:04. Named pickup and functional tooltip. Exact world pickup mesh was not isolated.
- **Large golden circle:** B 1:09:03. Distinct luminous ring/crescent silhouette in architecture; interaction outcome not directly verified.
- **Red sac:** B 1:10:08. Visible overhead red organic object; do not infer an entire swarm event or its loot from one frame.

### Text-supported mechanics, not visually reconstructed interaction sequences

The existing [manual summary](duskbloods-manual-summary.md) covers healing resources, corpse-lighting, companion pact sites, weapon-affinity forges, skill crystals, passive rewards and travel. C reports additional event and forge detail around [17:37](https://www.youtube.com/watch?v=yV0EjPXYZQE&t=1057s)–[19:07](https://www.youtube.com/watch?v=yV0EjPXYZQE&t=1147s). Keep that provenance attached.

We have not verified the exact appearance, animation, hold duration, sound or reward cadence of every chest, lantern corpse, forge or travel point. Do not invent those details to complete a table.

**D:** Give each original interactable a silhouette family and one semantic accent colour. A forge, companion circle and scoring pillar should remain distinguishable in grayscale by form alone. Use colour as reinforcement. Separate discovery glow, nearby prompt, interaction progress and completion feedback.

## 7. Match flow and screens: what Claude can implement now

The [official basics](https://campaign.theduskbloods.jp/manual/en/basic1.html) establish eight entrants, four phases, area selection between phases, repeat revival before the final, and scoring-dependent culls. Ritual objectives belong to phases II and III. The final ends alliances and allows one revival before elimination, with HP influenced by accumulated score. The manual also describes area-overcrowding relocation. These rules support a state machine; they do not establish every transition duration.

**D: integrate with Claude's existing roadmap**, not a parallel match framework:

Waiting → Countdown → Arrival → AreaSelection → PhaseActive → PhaseResolve → AreaSelection / FinalSetup → FinalActive → Results → Return.

Use server-owned phase state, start/end times, participant eligibility and score ledger. Keep UI presentation delays separate from authoritative state so an animation cannot postpone a cull or award a reward twice. Have one clear final setup step to end alliances, assign lives, apply the intended HP rule and choose spawn positions.

### Screen composition checklist

- **Hub:** environment and character remain visible; thin navigation ribbon; small matchmaking card. A 0:02 is the reference, not a giant opaque dashboard.
- **Map / area choice:** distinct modes for browsing versus selecting; player ranking and current phase; regional feature legend; selection feedback and countdown. The footage's density does not justify tiny unreadable Roblox labels.
- **Live HUD:** stable vitals and companion anchor; clock and objective direction; warnings only when relevant; avoid opening permanent panels for systems not implemented.
- **Phase resolve:** results/eligible players/next choice need clear presentation. Exact source sequence and duration are unverified.
- **Final:** life indicators replace the scoring emphasis; former allies become opponents; make the rule change explicit.
- **Victory:** a deliberate character-and-world composition, then readable results. A 24:05 supports the cinematic composition; it does not verify a complete results layout.
- **Failure / elimination:** not yet adequately inspected. Design as our own coherent screen until a targeted reference pass is needed.

**Timing caution:** minute-spaced samples cannot measure fade length, intro duration, queue time, cull animation or results dwell. Any initial values must be configurable prototype defaults.

## 8. Ambiance, regions and composition

These are visual readings and proposed art direction, not claims about the source renderer's implementation.

### Shared atmosphere

The sampled world repeatedly contrasts cool large-scale darkness with small warm sources. Blue-gray architecture and distance are interrupted by amber lamps, torches, gold objectives and red/pink celestial colour. Brightness has a purpose: entrance, reward, threat, skyline or final-stage spectacle. It is not an even blue wash over every wall.

Dark foreground masses frame brighter middle-distance routes. Successive roofs, spires and haze establish scale. Materials need to keep their identity inside this palette: stone should retain planes and joints, slate should catch selective light, timber should read through grain and broad reflections. Uniform glossy stone or globally reflective wood would flatten these distinctions.

**D:** Establish a restrained value hierarchy before adding detail. Keep our owner's red/purple/blue dusk direction, but reserve the strongest red for selected narrative or competitive focal points. Use warm inhabited interiors and cold exterior depth. Review the actual R6 camera; a beautiful aerial render does not prove a playable composition.

### Region-specific readings

| Space / evidence | Spatial and atmospheric character | BloodsLocks application |
|---|---|---|
| Cathedral approach, A 8:05 | Broad ascending route, repeated vertical stone, cool distance and warm practicals. Landmark revealed beyond the approach. | A long view with a clear architectural destination; side paths and upper routes must not obscure the main entrance. |
| Cathedral altar, B 1:02:04 | Interior focal object gathers enemies; enclosing vertical architecture makes the encounter ceremonial. | Design floor space around combat, then use piers, arches and light to frame it. Keep the camera out of columns. |
| City streets, A 2:00 and B 56:02 | Human-scale streets, gates, lamps and stair transitions connect monumental spaces. | Victorian district needs inhabited thresholds, service doors, retaining walls and roof access, not an uninterrupted grand facade. |
| Roofs and belfry, A 5:01 / 13:00 | Playable slate surfaces and high openings; skyline gives orientation. | Roof geometry must support jumps, landing areas and routes. Chimneys and dormers should create cover and silhouettes deliberately. |
| Greatbridge, B 1:04:10 and A 19:59 | Open fighting space, architectural marker, distant cliffs, objective seen through an arch. | Preserve long approach reads and multiple entry heights; landmark and objective should remain recognisable during combat. |
| Sewer, B 58:07–1:00:04 | Confined routes, stairs, green poison and very large hostile bodies; occasional camera occlusion. | Claustrophobia can be intentional, but give large encounters enough camera and escape volume. Separate poisonous green from neutral navigation light. |
| Forest / adjacent interior, B 55:05 / 1:06:00 | Vegetation and built spaces overlap; wheel enemy presents an oversized silhouette. | Region boundaries can be experiential rather than literal biome walls. Blend masonry, roots and exterior access through believable transitions. |
| Elevated flower terrace, B 1:12:03 / 1:14:01 | Pale dense flowers, stone edges, spires and a broad sky; final turns it red/pink. | Strong final arena identity can come from terrain, planting and sky composition together. Keep flowers below critical feet/attack readability. |

### What this means for the Manor

The owner's reference image remains the direct exterior composition target: off-centre tall spire, long lower roof mass, dark trees framing both sides, uneven foreground approach, cold layered depth, small warm doorway and red moon behind the skyline. This is **the supplied reference**, not evidence that the videos show the exact House of Night exterior.

The current Manor still needs stronger silhouette, architectural depth, surface scale and landscape integration. More repeated trim will not fix an empty foreground or a tower blocking the entrance. Work one complete player view: foreground framing → approach → entrance → roof/tower → distant sky. Then review an adjacent angle to ensure the composition is not a one-camera facade.

Original Blender work should retain editable structural pieces inside a coherent assembled scene. Model the important depth: wall thickness, window reveals, arch profiles, roof edges, sill projections and supports. Put wear where water, soot, feet and neglected vegetation explain it. Do not distribute generic noise across every surface.

### For the future huge Victorian map

Do not begin by duplicating a finished street across a giant terrain. First establish connected regions with distinct silhouettes, route heights, encounter types and reward opportunities. Each region needs:

- a distant landmark and a nearby route cue;
- ground, intermediate and high traversal choices where appropriate;
- readable combat spaces and quieter transitions;
- intentional focal light and local material identity;
- objective approach views from more than one route;
- plausible architectural/landscape transitions to its neighbours.

A first slice should contain one street, one interior, one roof route, one lower route and one objective court, connected into a loop. This tests the intended full-map language; it is not a reduction of the final map scope.

## 9. What reads well, and what to avoid

**Visual strengths:** regional landmarks orient fast traversal; high routes produce memorable views; gold objectives are visible across dark architecture; companion outlines help crowded co-op; map/ranking screens make the scoring race tangible; the final's palette change gives it a different emotional register.

**Observed risks:** a giant boss can fill a confined camera; overlapping companions, enemies, damage numbers and effects can bury an attack; dense map information competes for attention; tiny labels lose their value at a distance. Frame sampling cannot establish input responsiveness, netcode quality or sound quality. Do not report those as assessed.

**D:** Preserve richness through hierarchy. One dominant landmark, one near-term objective and one readable threat can coexist; ten equally bright effects cannot. For both art and UI, reveal the information the current action needs.

## 10. Practical handoff: how we make it

Claude owns engineering; ChatGPT owns custom environment/model work and reference interpretation. No gameplay or UI source was changed for this document.

1. **NPC v1:** one authored enemy group with XP and death/reward feedback. Use existing entity/combat/simulation conventions and the agreed `BL_EnemySpawn` marker with `Enemy` ID, optional `Count`/`Radius`. Confirm current marker contract in the plan before authoring.
2. **Progression and score:** XP/level feedback and a server score ledger. Keep reward sources separate; displayed total alone is insufficient to debug ranking or future tie-breaks.
3. **Match skeleton:** configurable phase rules, selection, revival, cull and final. Use a short development configuration for testing rather than waiting through a full production-length match.
4. **Healing, pickups and first scoring interaction:** enough to make route choice matter. Distinct world silhouettes, prompts, hold/progress feedback and authoritative completion.
5. **One boss / temporary co-op:** invitation lifecycle and participant/reward handling first; elaborate move set after the state flow works.
6. **Ritual site:** readable boundary, pillar capture, ownership change and competitive scoring. Define disconnect, death and phase-end behavior before visual polish.
7. **Other upgrades, events and alliances:** add against the tested loop, following Claude's roadmap. Preserve distinction between persistent alliance and encounter-specific cooperation.
8. **UI and art review together:** test one complete route from area choice to final; compare player-view screenshots, not only individual widgets or asset renders.

For each implemented mechanic, use the existing regression self-test process and add meaningful coverage for the new state changes. World art remains outside Rojo-owned gameplay code as currently agreed. Preserve the Manor Blood Table, two-floor circulation, training yard and tagged interaction spaces.

## 11. Targeted unknowns — not blockers for the first slice

- Full per-enemy and boss attack catalogues, timing, reach, recovery, stagger and incoming damage.
- Exact boss invitation presentation, acceptance window, transport and return sequence.
- Exact item meshes, pickup cadence and individual reward values.
- Phase-resolution and cull presentation, elimination/results screens and their durations.
- The second sampled match's final outcome.
- Apparent Virtue decreases: narrator C reports a death-related loss around [12:31](https://www.youtube.com/watch?v=yV0EjPXYZQE&t=751s), but a sampled decrease does not prove its cause. Do not silently assume either zero penalty or a specific penalty.
- Event particulars, including storm behavior and bell scoring: narrator reports need targeted visual confirmation before treating them as exact specs.

We have sufficient evidence to build thoughtfully now. Revisit a precise clip when a specific unresolved mechanic becomes the next implementation decision; further general video collecting is not required before starting.
