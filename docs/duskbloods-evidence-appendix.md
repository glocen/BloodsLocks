# Duskbloods evidence appendix — 29 October 2026

Read [the engineering brief](duskbloods-gameplay-breakdown.md) first and [the UI quality standard](ui-quality-standard.md) when implementing presentation. This appendix records evidence and uncertainty; it is not a second competing game specification.

## Evidence status and coverage

Source: [Vosair — The Duskbloods Gameplay full 4k 60 fps, 2:49:34](https://www.youtube.com/watch?v=8Dyw5O2zyiY). This is the owner's original recording. A local 1280×720 video stream was obtained for inspection. The stream is **video only**. Sound, music and the absence of commentary were not independently assessed.

The entire recording's timeline was surveyed using **341 timestamped frames** at 30-second intervals from 00:00 through 2:49:30, plus 2:49:33, assembled into 29 sheets. Pages 1–14 were inspected by the primary researcher and pages 15–29 by the second researcher. Selected events were then extracted at 2-second intervals and inspected as sequences. This closes broad timeline coverage gaps in the older study, but **it is not an uninterrupted audiovisual watch**. The owner subsequently asked to stop playback/research and hand the findings to Claude immediately to conserve usage. Do not call it a complete real-time watch later.

Labels: **OBSERVED** means visible in inspected images; **MANUAL** means a rule described by the official guide; **DESIGN** means our proposed BloodLocks adaptation. A sampled before/after change does not prove its cause. Two-second sequences cannot measure subsecond windups, i-frames, sound cues or exact effect curves. Never turn extraction intervals into asserted action durations.

Local study assets and reproducible extraction scripts: `C:/Users/gloce/.codex/visualizations/2026/10/29/01a1894d-1ea3-7272-a667-17d74cd6c8e1/reference`. Source video and reference screenshots are study evidence, not original game assets to import or redistribute in BloodLocks. Git stores explanatory notes and our own designs.

### Dense sequence coverage actually inspected by the primary researcher

| Source interval | Inspected material | Confidence/limit |
|---|---|---|
| 15:21–16:07 | Co-op tutorial/invitation, acceptance transition, arrival and opening boss fight | 2-second images; no exact hold or attack timing |
| 18:11–18:55 | Cathedral approach, pledge prompt, pose, score change, follow-up tutorial | Entire extracted 2-second sequence inspected |
| 34:51–35:59 | Reward selection, route, circle, pact/summon presentation and tutorial cards | Entire extracted 2-second sequence inspected |
| 42:35–42:57 | Exit-damage warning, clock countdown, traversal while penalized | Subsection inspected; not a measured damage formula |
| 54:15–54:59 | Eight-character introduction, selection, timeout, transition, Phase I arrival | Selection pages 2–3; earlier extracted page not relied upon |
| 1:00:36–1:01:46 | Co-op fight, Phase I end, categories, event card, area selection, Phase II arrival | Last two extracted frames not needed; roster at1:01:16 inspected at full resolution |
| 1:13:30–1:13:52 | Phase III summary, finalist portraits/card, black transition, garden final | Inspected subsection |
| 1:17:00–1:17:22 | Return to House of Night, menu, six portrait selections | Inspected subsection; does not establish first match placement |
| 1:21:25–1:21:47 | Boss encounter defeat, leaving co-op, disappearance, revival and return toward encounter | Inspected subsection; no loss formula inferred |

Additional extracted but uninspected frames are not additional evidence. See [second-half notes](duskbloods-evidence-second-half.md) for its exact surveyed and dense-inspected intervals.

## Source sequence: opening, tutorials and first multiplayer match

Times below are source positions, not our desired game durations. Thirty-second samples bracket transitions rather than establish their precise boundaries.

| Interval | OBSERVED | Useful engineering/art consequence |
|---|---|---|
| 00:00–02:30 | Loading/opening story: restrained body/hand close-ups, a blood mark, cool moon through an opening | Ceremony can use composition and one meaningful gesture. Do not make repetitive compulsory cinematics from this opening. |
| 03:00–04:30 | Player enters a ruined arch framing a distant Gothic landmark, then moves through misty broken terrain and fights small humanoids | A landmark is first introduced through a threshold; fog separates layers while the immediate route remains readable. |
| 05:00–08:00 | Cathedral/training sequence, firearm use, close-up healing animation; later stake tutorial visible | Teach one action in context. Healing is a readable committed action, not an invisible HP jump. Exact commitment/recovery remains our configurable choice. |
| 08:30–11:00 | Cold approach gives way to orange burning terrain, small foes, drink-blood instruction, then a large marked wolf-like figure | Space can change emotional temperature while retaining material cohesion. Large creatures establish scale by silhouette and framing. |
| 11:30–13:30 | Red-lit House of Night, character on raised floor sigil, thin top menu and tutorial selection | Keep the world and character visible. Distinguish training content from live matchmaking. |
| 14:00–17:30 | Map tutorial; Nether Gate Lake; Power of Blood choice; co-op invitation and large amphibian boss | Reward choice, map browsing and accepting encounter transport are separate UI states. |
| 18:00–19:30 | Cathedral ritual tutorial and outcome screen | These are training outcomes; do not use their reward values as live-match balance. |
| 20:30–29:00 | Sigil instructions and hunt across streets, stairs, cathedral interior, upper route and white-flower terrace; explicit training-completion banner at29:00 | Tutorial route demonstrates linked vertical circulation. It is not a full competitive match. |
| 30:00–37:30 | Another training selection/route, fights, item choice, Kin circle, flame-chair interaction, phase/end-clock teaching | Early footage contains staged rules lessons. Do not infer live random event distribution from it. |
| 38:00–49:30 | Mounted enemies and combat on streets; tall drops and stairs; ritual boundary warning, cathedral combat, pledge outside on a terrace | Combat and progression happen across route layers. The ritual is a spatial commitment with clear feedback. |
| 50:00–52:00 | Final-phase tutorial and flower-garden combat, then loading | Separate training final from real multiplayer results. |
| 52:30–54:00 | House of Night with a heavy diver-like character; courtyard and target-selection UI | Training opponents and hub class choice belong to preparation. |
| 54:15–54:59 | Eight portraits over an orange skyline; map selection and a passive Sigil popup; chosen area ring becomes gold; black transition; red floor sigil/Phase I arrival | The map is an authored relief with feature icons and outlined regions, not a row of generic cards. |
| 55:00–56:30 | Forest-to-street route, white impact burst, green forge interaction and weapon-affinity confirmation | Present enhancement at a world object, then confirm the changed weapon state. |
| 57:00–1:00:30 | Sewer combat with humanoid and larger poison-associated foe, large amphibian encounter, exploration and a new co-op invitation | Enemies need encounters tied to terrain, not evenly scattered spawns. Lower spaces differ in height, light and materials. |
| 1:00:54–1:01:46 | Phase I ends, survival banner/categories/event card/selection/Phase II arrival | Important culling conflict below. Display separate result, event and destination-selection steps. |
| 1:02:00–1:05:30 | Cathedral looting, Vampyr co-op battle on a broad bridge; reward banner and continued traversal | Temporary encounter co-op is separate from alliance state. Player-side outlines and companion information remain relevant. |
| 1:06:00–1:08:30 | Forest/sewer encounters; score sharing message, map intermission, cathedral-side ascent | Map screen also communicates standings and social links. Do not confuse ordinary browsing with forced spawn selection. |
| 1:09:00–1:13:00 | Cathedral enemies, stair connections, exterior roof traversal, reward choice, lower combat | Interior and roof routes must connect as actual circulation. Combat/upgrade opportunities create reasons to change level. |
| 1:13:30–1:13:52 | Phase III categories, three finalists and score medallions, final-event card, then garden final | Final is a distinct presentation/rules state. Preserve accumulated build and show lives clearly. |
| 1:14:00–1:17:22 | Garden final, attacks and movement between pale flowers and raised paths; later return to House of Night and class selection | First match placement was not established by our inspected outcome subsection. Do not repeat the older 'winning arc' label as fact for this source. |
| 1:18:00–1:23:30 | Next multiplayer introduction, new character, streets/forge, boss co-op defeat/revival, reward choice and alliance request | Death can terminate encounter participation while the broader match continues. Exact score-loss policy remains unresolved. |

Later source through2:49:33 is recorded in the companion second-half notes. It includes further matches, a sixth-place outcome, a garden final, and a different paved circular final arena. A single fixed garden arena is therefore our v1 simplification, not the full reference's only setting.

## Concrete presentation observations Claude can implement from text

### Co-op invitation and encounter transport

[15:25–15:53](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=925s): a tutorial explains the request on a dimmed map. The underlying map carries an encounter indicator and notice; after closing it, the player remains in the world with a compact lower-center accept/decline request naming the trespasser. At15:47 the image is black; at15:49 the player appears in the watery encounter space with a pale vertical arrival effect and boss bar. The next tutorial explains protection between co-op participants and contribution-linked rewards.

**DESIGN translation:** invitation state owns encounter ID, expiry and button hints. Accept validates the still-active encounter before travel; decline/expiry dismisses the card. Snapshot the safe return location. Encounter team protection ends when the encounter ends; it must not create a permanent alliance. Store participation/contribution separately from damage ownership. See the brief for lifecycle and race-condition tests. Fade length and key bindings are BloodLocks choices, not measured here.

### Pledge object, pose and reward

[18:25–18:37](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=1105s): the player approaches a raised, candle-ringed ritual object. A hold prompt appears within approach range. The luminous gold object is taller than the player, with radiating ornament and a circular floor outline. During the interaction the player faces it with arms extended. A gold body mark and reward notification appear; the top-left score changes from8 to16 in this **tutorial**. The world object and floor outline remain after the player moves away.

**DESIGN translation:** range/prompt eligibility, channel pose/progress, successful ownership, and replacement are separate states. Anchor light/ornament to the site and the short successful body mark to the player. Award once on completion, not on pressing the key. Losing ownership must reverse only that pledge's score contribution. Do not make8 points the live reward merely because the tutorial used it.

### Kin circle and presence

[35:09–35:39](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=2109s): the circle's tall pale-gold sign can be seen from an upper path. Close to it, a large upright eye/radial emblem fills the local silhouette. At35:19 a bright red-white center and orange/red sweep surround the player; by35:23 the player has moved away and the Kin name/level is under the vitals. Tutorials explain recall, death cooldown, healing and replacement of an existing compact. A separate purple flame-chair object nearby gives its own score notification; do not merge it with the pact system.

**DESIGN translation:** keep a distant landmark layer, local interaction layer, brief pact confirmation, persistent companion HUD and physical companion presence. Switching, dismissed, dead/recovering and summoned states need different feedback. Kurogane is our supported original companion, not permission to copy the pictured Kin.

### Phase end → next region → spawn

[1:00:54–1:01:40](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=3654s): combat view gains an upper-center Phase End I marker and a wide dark survival ribbon. Category rows then overlay the still-visible player/world; a round cumulative-score medallion sits lower. The screen fades; an illustrated event card follows. Next comes the relief map with standings left, event explanation right, phase rail above and countdown in the clock corner. Selected region rings shift to gold. The last countdown digits are red; after zero, a black transition precedes the next phase's arrival/title.

**DESIGN translation:** serialize these states; do not stack all overlays. Server freezes the scoring cutoff once. Client plays presentation from that immutable summary. Region choice has a deadline, validation and timeout fallback. Use a single input owner at a time and cancel stale selection UI on death/phase change/return.

### Ritual exit warning and final qualification

[42:35–42:57](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=2555s): a narrow red warning remains visible during movement outside the ritual area while the corner timer counts down. It is not just a brief toast. [1:13:30–1:13:52](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4410s): category summary is followed by three finalist portraits with individual score medallions, an illustrated final card, black transition, then a pale-flower garden under a crimson sky. Exact boundary-drain tick and final HP scaling are not visually measured.

### Defeat, co-op exit and revival

[1:21:25–1:21:47](https://www.youtube.com/watch?v=8Dyw5O2zyiY&t=4885s): a boss is close to the camera; a co-op-exit strip appears, then a large defeat ribbon. The character dissolves with a vertical pale effect; a black transition follows. By1:21:39 the character is back on the bridge with restored HP and can head toward the encounter again. This is evidence that boss failure is not automatically match elimination. It does not establish ordinary PvP death penalties, universal revival duration or a free escape exploit.

## Critical conflicts and unknowns

1. **Cull schedule:** the first live match shows8 entrants at54:17, Phase I ending at1:00:54, and exactly6 standings entries at1:01:16. The top phase rail labels6 under II and3 under III. The current BloodLocks locked plan culls at the ends ofII andIII. Preserve the existing rule until the owner changes it, but do not describe it as an exact reference match. The brief calls this out first.
2. **Death/scoring:** later survey images show changing scores around defeat, but ownership changes, rewards and other events can also change a score. No numeric death-loss rule was measured. Our existing no-score-loss rule remains a BloodLocks choice.
3. **XP and score:** current source separates them and caps player level at20. Older plan passages describing score-driven level15 are stale. Do not add a duplicate progression system.
4. **Kin replacement:** tutorial explicitly says the old compact breaks and level is reduced. Current Kurogane behavior mirrors player progression. Document this difference instead of claiming exact fidelity.
5. **Final arena variety:** later source shows at least two distinct settings. Our cathedral/garden choice is a first production scope, not a reference limitation.
6. **Exact combat timing:** no subsecond windup, recovery, cancel, i-frame, damage or attack-range measurement is justified by this survey. Claude should keep shared action definitions/configuration and verify feel through playtests.
7. **Audio:** unassessed. All audio layers, priority/ducking and timing in the implementation brief/UI standard are proposed original sound design.

## Official rules cross-check

Primary sources: [official gameplay guide](https://campaign.theduskbloods.jp/p/event/networktest/gameplayguide/?lang=en&locate=US&region=the_americas) and [official manual](https://campaign.theduskbloods.jp/manual/en/basic1.html). The gameplay guide was read again this session. It supports four phases; repeated revival before elimination; ritual-specific player-kill scoring; overwriteable pledge ownership; mutually exclusive ritual stones; final extra health and two lives; encounter co-op; Kin recovery/recall restrictions; region features and restricted instant travel. Standard alliances share ritual earnings and end before the final; the paired rule differs. These factual relationships inform our designs. They do not supply our unmeasured timings, input mapping, server architecture or balance numbers.

Use existing `duskbloods-manual-summary.md` alongside the brief. Where an old summary and direct footage conflict, keep the conflict visible and preserve locked BloodLocks decisions pending an explicit change.

## Lasting implementation notes

- A state can exist without its final content. Show unavailable features honestly and avoid dead menu rows.
- A visual state must follow authoritative gameplay state; client decoration never grants points, immunity or pact ownership.
- A visible gold light can mean several different interactions. Give each its own silhouette, prompt, icon and outcome; color alone is insufficient.
- Strong verticality combines routes, cover, encounter placement and objectives. More roof height alone does not create good circulation.
- Preserve current working source and re-audit before implementing: Claude was actively adding progression and scoring while this document was prepared.
- Keep extensive source evidence here; give Claude the engineering brief and UI standard as his daily working documents.

