# BloodLocks — whole-game engineering brief for Claude

Prepared for Claude and glocen, 29 October 2026. Source audit: **22:23–22:30 Europe/Paris**. Re-read live source before implementing: Claude's work is advancing during this research pass.

## 1. The goal and how to read this handoff

The owner wants the whole PvPvE game prepared coherently, including the small presentation details that give it character. Claude is the engineer; ChatGPT supplies reference interpretation, custom world/model work and art direction. **A video link is evidence, not an assignment for Claude to watch.** The behavior below should be understandable without opening footage.

The owner has repeatedly rejected rushed environment work, weak Shinigami effects and underdeveloped UI. Current menu/NPC progress is useful, but implementation does not imply artistic acceptance. The Manor needs depth, personality and revised lighting. The Victorian map needs ground, interior, elevated and lower routes that create choices and leave space for future regions. The outdoor training yard remains required.

The intended loop is **fight → gain strength/rewards → choose a route or opportunity → read time/rank → risk an objective or player fight → survive the cull → resolve the final**. Combat, exploration, upgrades, social state and presentation must support this same loop.

Labels used here:

- **CODE:** present in files at audit time, not a new claim of playtest success.
- **LOCKED:** owner/engineering-plan rule to preserve unless changed explicitly.
- **DESIGN:** proposed configurable BloodLocks behavior; not a video measurement.
- **REFERENCE:** previously sampled footage or official manual, with evidence limits attached.

This brief supplies architecture, system behavior and a delivery order. The owner explicitly asks Claude to plan and prepare the whole game from this study, beyond separate NPC/Shinigami tasks, then implement the next verified slice now. Preserve locked defaults; do not block core work on speculative later-content decisions. Further video research was stopped by the owner to conserve usage. The companion [UI quality standard](ui-quality-standard.md) gives exact current colors, typography, component states and review gates. Footage coverage/timestamps belong in the [evidence appendix](https://github.com/glocen/BloodsLocks/blob/main/docs/duskbloods-evidence-appendix.md): a 30-second source survey and selected dense 2-second image sequences are sampling, not uninterrupted viewing. Video-only inspection does not assess audio.

## 2. Current truth and whole-game dependencies

The engineering source is **`C:\Users\gloce\BloodsLocks\src`**, synced by Rojo. The Documents art folder contains older environment work. World builds, Lighting, WorldTools, WorldAssets and place-role attributes stay in Studio. Do not edit Rojo-owned script source inside Studio. Preserve the owner's single ProfileStore and protected Data/Libraries/Modules; add fields and mutations through the existing data layer.

| Subsystem | CODE at audit | Remaining work |
|---|---|---|
| Player kit | R6/shared simulation; Gustave saber/SMG/two skills; charge, guard/howl/bite, movement, lock-on, HUD | Complete/publish animations, two-player checks, ultimate, pending combat decisions |
| Shinigami | Kurogane pact/toggle/AI/regen/death cooldown/level mirror/Gōka | Accepted model/effects/animations, switch-level reconciliation, ranged/support content |
| Enemies | Wretch/Butcher, NpcActor, brains, tagged spawns, credit/refill | Original models, broader roster, bosses, spellbinding |
| Growth | ProgressionService, Leveling, player lv/xp; cap 20 | Match reset/feedback and upgrade integration |
| Score | Renown ledger, enemy reward, ranking/time tie-break | Eligible participant ledger, objectives, cutoff, final/results |
| Menu/travel | Menu v2, class saving, public Victorian travel/return | Reserved admission, party/private flow, match screens; several tabs remain placeholders |
| World/match | Victorian map definition/test markers; Zones empty | Region contract, map build, lifecycle, respawn/culls/final/results/rewards |

Latest published commit `66119edad61c1dac424c6e7835d77c5f4d55589e` reports **44/44 self-tests in Victorian**, including leveling/kill rewards. The older36/36 team note is stale. These are Claude-reported tests, not tests run for this brief.

Prepare these dependencies as one design before expanding content:

1. World registry + lifecycle establish phase opportunities and eligible participants.
2. Entity/action/combat death events feed XP, Renown, healing, drops and phase metrics once.
3. Score/phase metrics feed standings, culls, final and settlement.
4. Shared allegiance resolves companions, minions, persistent alliances and encounter truces.
5. Authoritative state/events feed client presentation, Theme, effects and sound.
6. Route/height/opportunity data feed region choice, map, compass and objective directions.

### Extend these integration points

- `Shared.Definitions.Registry` validates/looks up class, weapon, action, enemy, Shinigami and map content. Stable IDs are distinct from display names.
- `Shared.Simulation.Runner`, `EntityState`, `PlayerState`, `ActionSim`, `CombatSim` own simulation contracts. Gameplay state writes under Server Authority belong in the existing simulation context. Remote handlers and UI cannot directly apply damage/resource changes.
- `Server.Npc.NpcActor` executes shared action helpers; brains choose intentions instead of implementing parallel damage.
- `NpcService.Died(model, def, killer?, sharesByPlayer)` emits once; companion damage credits its master. `SpawnAt`/`Despawn` already exist.
- `ProgressionService.AddXp/Level/Reset/LevelUp` and `Leveling.XpToNext/MaxHealth/MaxStamina/DamageMultiplier` keep formulas unified.
- `ScoreService.Add/Total/Ranking/BySource` is the ledger to extend. Current Ranking includes all connected Players and removes leavers' books: make it participant-aware without building a second score service.
- `Shared.Net` centrally declares remotes and rate limits. Retain SeekHunt/HuntStatus/ReturnToManor/SelectClass/ShinigamiToggle as integration points.
- `Client.UI.Theme`, Core/Layers/Motion, Hud/Menu/Kit, CombatFxController and Client.Vfx remain reusable presentation foundations.

## 3. From the Manor to a completed match

### Manor and loadout

**Input/state:** G at BloodTable opens the existing staged character menu; Q/E changes tab, Enter confirms, Backspace closes. The real character/world remains the composition. Gameplay input and combat HUD pause while open. Class selection stays Manor-only and saves through the existing profile.

**Outcome/failure:** pending selection/travel becomes saved/accepted or a concise reason. Do not advertise sealed class cards as playable. Relics/Atelier/Archive/System placeholders must state availability honestly. Repeated Enter cannot reserve repeated journeys. Failed teleport restores a usable retry state, not an endless connecting message.

**Presentation:** thin current ribbon, crisp text, current Theme, world visible; see UI companion. Restore camera type, cursor/mouse, input, HUD and prompt after close, respawn or interrupted opening. Clean staging lights/circle.

**Acceptance:** open/close repeatedly, die during transition, change class then travel, fail travel, reopen. No duplicate stage, stuck camera/input or misleading saved state.

### Reserved admission, parties and private lobbies

**LOCKED:** reserved match servers, max 8/min 2, parties/private lobbies in v1. Current TravelService public-place teleport is a temporary bridge, not completed matchmaking.

Hunt intent names a map/rule; server validates and reserves slots atomically for the whole party, or creates a reserved server. Private six-character codes identify private matches and stay out of the public listing. Profile data supplies class/loadout; TeleportData is only routing context. Keep party identity separate from in-match alliances.

Failed teleport releases reservations. Expire stale registry entries, reject joins after lock and handle leader/member failure visibly. A party retry must not silently split friends or double-allocate. Display waiting/arriving/failed members and a concise retry result.

**Acceptance:** two accounts arrive together, capacity cannot overbook, wrong/full/expired code is explained, stale servers disappear, late arrival returns safely and failed travel can retry. Test real teleport/MemoryStore flow in the published experience, not Studio.

### One authoritative lifecycle

Use one Match-role service and participant records independent of character models. Each record owns eligibility, region choice, death/revival, score/phase metrics, final lives, placement and settlement. Respawn replaces a body, not the match participant.

| State | Existing plan duration | Behavior |
|---|---:|---|
| Waiting | Until 2+ | Antechamber roster, safe movement/practice, no player damage |
| Countdown | 30 s; 10 when full | Cancel below 2; delist and lock at T−5 |
| Intro | 8 s DESIGN | Brief landmarks/hunters presentation; gameplay input suspended |
| Region choice | 20 s first, 15 s later | Opportunities, rankings, selected region and deadline |
| Phase 1 | 6 min | Explore/grow; no ritual/cull |
| Phase 2 | 5 min | Ritual, then first cull |
| Phase 3 | 5 min | Ritual, then second cull |
| Phase resolve | 8 s DESIGN | Cutoff, awards, standings/cull, next action |
| Final | 4 min, then sudden death | Up to three finalists, two lives, one winner |
| Results | 12 s DESIGN | Placement/rewards, then return |

Use server deadlines; transitions and awards run once. UI fades cannot extend scoring eligibility. Provide a short Studio-only configuration to test a complete match quickly.

**Region choice:** no choice gets a valid random region; planned capacity is `ceil(players/regions)+1`, keeping parties together and explaining relocation. Spawn aims for planned 60-stud player separation when possible, checks ground/occupied danger, and grants 3 seconds of protection ending on attack. Validate empty region lists and missing required sites before starting a match.

**Acceptance:** cancel/restart countdown, full lobby, late join, timeout/all choose one region, disconnect during transition, death at cutoff. All clients agree on phase and eligible roster.

### Death, revival and culling

**Before final:** HP zero → consume death once → end actions/targeting → show revival map and planned 5-second delay → spawn validly. Preserve match XP/level and Renown. **LOCKED current plan: no score deduction on ordinary death. This is our rule, not a claim about Duskbloods.** Manual top-up-to-two heal uses is an explicit adoption choice, not an unnoticed change.

For starting participant count n, finalists f=min(3,n), cut=n−f. Phase 2 removes floor(cut/2), phase 3 the remainder: eight becomes six, then three. Departed players must count coherently rather than forcing an obsolete eight-player cull quota. Snapshot after valid phase awards; locked tie-break is first to reach the total, with a stable fallback for genuinely identical timestamps.

**REFERENCE CONFLICT, newly verified:** in the owner's multiplayer footage, the match begins around 54:55 with eight; the Phase-I end at 1:00:54 says the player survived the culling; at 1:01:16 the next roster contains six, and the phase strip shows six entering II and three entering III. This supports earlier source-game culls than our locked plan. It does **not** validate our end-II/end-III timing. Preserve the current plan until the owner changes it, but present this discrepancy clearly when aligning the match design. Exact source-screen evidence is in the appendix.

Culled state disables combat/revival/region choice and offers spectate or return. Spectate follows valid living targets, recovers when targets leave/die, and restores camera on exit. Keep sealed result/reward records after a Player leaves; current ScoreService removal must not erase settlement.

**Acceptance:** 2/3/4/8 entrants, no phase-1 cull, dead-but-eligible participant survives, culled never respawns, ties stable, simultaneous death/cutoff produces no repeated kill or post-cutoff award.

### Final, settlement and return

Setup ends Standard alliances, clears temporary truces/minions, freezes earlier results, chooses safe separated starts, assigns two lives and the planned Renown-related HP bonus. State the rule change before combat. Keep level/skill/companion identity. HP-bonus formula, sudden-death policy and simultaneous-death resolution still need explicit configurable rules; footage has not established exact values.

First final defeat removes one life and revives safely; second eliminates. Server life decrement drives the extinguished life mark. The Renown emblem visibly changes meaning to lives. At the time cap show/enter the configured sudden death; the state machine must terminate even on simultaneous deaths/leaves.

One immutable result drives placements, score breakdown, kills and rewards. **LOCKED reward default:** 15 participation + placement (60/40/30 first/second/third, 15 otherwise) + floor(earned score/50) + 2/player kill, capped 150. Settle through existing data with persistent match/participant award identity. An early culled return settles that participant; it must not rerun global results. Teleport failure leaves return/retry usable without duplicate currency.

**Acceptance:** exactly two defeats to elimination, former Standard allies targetable, last simultaneous death consistent, leavers/culled still in results, replay/rejoin/retry cannot pay twice, Manor class/currency intact, only match state resets.

## 4. One combat contract for players, NPCs, bosses and Shinigami

### Player kit/input

Use the existing Input Action System; press/release state stays in simulation. Input currently reads Jump/Dodge/Sprint/Attack/Guard/Strong/Ranged/Bite/Skill1/Skill2 and script-fed Face/Aim. New combat inputs such as healing extend this contract; don't add disconnected raw-key combat listeners.

**CODE:** Gustave is the class ID; do not resurrect Duelist IDs. Saber lights/strong/charge, burst SMG, BloodBlade and LightBeam exist. Unlocks come from definitions. Ultimate is planned, not authored. E is bite in current engineering notes; actual world/menu prompts use G. Read the binding template rather than copying the stale generic E-interact table.

All actions use eligible intent → resource reservation → telegraph/windup → active window → recovery → allowed cancel/end. Hit processing uses existing allegiance/i-frame/defence/modifier/HP/stagger/reaction logic. Death/interruption ends ongoing actions and attached presentation. A client sends intention, never authoritative damage/reward.

**Acceptance:** current suite plus two-player guard/parry/howl/bite, charge/dodge cancel, skill recharge through death, destroyed lock target and companion kill credit. Stamina/guard-counter/projectile-deflect changes remain explicit decisions, not polish side effects.

### Reusable enemy definition and brain

Keep definitions in `Definitions/Enemies/<Map>/<Id>`: identity/tier, model/animation identity when added, body stats, senses, telegraph/attack/recovery tuning, weighted range-valid attacks, rewards/refill, spellbinding eligibility, action definitions. Registry validates references. An action describes duration, animation, tracking/lunge, hit timing/shape/damage/stagger/reaction. Avoid name-specific branches in shared NpcActor.

**CODE examples, not footage measurements:**

| Enemy | Body | Awareness | Actions/reward |
|---|---|---|---|
| Wretch | Fodder, 260 HP, walk/chase 8/19 | Aggro/leash 45/90; .6 s alert, .4 s telegraph, 1.8 s interval | Rake/pounce; 25 XP, 5 score; 45 s refill |
| Butcher | Heavy, scale1.35, 1400 HP, 6/13 | 40/70; .9 s alert, .7 s telegraph, 2.8 s interval | Cleave/overhead; 120 XP, 20 score; 90 s refill |

These still use a training-dummy template: framework placeholder, not completed enemy art. Incoming real models must preserve authored collision/reach and distinct readable silhouettes.

Brain sequence: idle/patrol → alert/turn → chase → choose valid weighted action → telegraph → act → recover; target loss/departure → leash/home/heal. Keep sticky targets, sight/range validation, simultaneous attacker cap and sleeping distant brains. The brain chooses; NpcActor/action runner executes. Animation, damage, VFX and sound follow one action clock.

Lifecycle: register entity/brain/owner → record contributors → one death → one Died event → remove target/action → fade → refill slot when allowed. Destroying for cleanup is not a kill. Removing a marker cleans slots/actors without rewards. Stable encounter/spawn IDs support debugging and reward idempotency.

`BL_EnemySpawn` supports Enemy exact ID or Zone weighted roster, Count/Radius/Respawn. Use exact IDs for authored important groups. Small scatter radii and height-specific markers avoid a roof spawn falling to the street. Ground/navigation checks respect floors, railings and landing platforms.

**Acceptance:** correct aggro approach, fair telegraph, no wall hits, punishable recovery, attacker cap, leash, master credit, one death award, clearance refill, marker removal, no growing brain/track count.

### Shinigami pact, roles and lifecycle

Use the owner's name Shinigami and the same Entity→Action→Hit→Damage/OwnerId allegiance. Role changes brain intent, not the damage engine. Existing definitions cover weapon/body/reach, follow/aggro, attack list, skill unlock/cooldown/telegraph, death cooldown and regen.

**Pact:** BL_PactCircle with Shinigami ID; CODE G hold .6 s, range12. Validate distance/state at server acceptance. Same pact is idempotent; new pact despawns old companion and publishes card. Keep `MakePact`/`Toggle`. Simultaneous requests cannot produce two owned companions.

**Summon:** existing T/remote; no pact gives a concise find-circle reason, cooldown shows remaining time, valid summon picks safe nearby ground. Follow beside/ahead without covering camera, fight valid threats, recover from stuck displacement safely, dismiss on master death/departure. No friendly fire to owner/allies or their actors.

**CODE Kurogane:** 600 base HP, 30-second death cooldown, 2%/s regen; Gōka at Lv3/cooldown12 is currently one 20×8×20 hit for90 damage/30 stagger. Those are not accepted final balance. Owner wants greater area/impact/lingering fire. Damaging lingering fire requires a server zone/tick/expiry definition; particles alone cannot implement it.

**Level/card:** derive from pact/player state; show identity, level, HP, summoned/dismissed/dead/cooldown and summon key. A level-up highlights the card once. Preserve HP fraction on max-HP changes. Current reset-to1 on new pact conflicts with immediate master-level mirroring; reconcile explicitly.

Prepare melee approach/strike/recover, ranged distance/sight/fire and support valid-ally-need/bounded-heal/buff strategies using common targeting, cooldown/actions, allegiance, death, credit, cleanup and card publication. Adding a Role enum does not finish ranged/support content.

**Acceptance:** toggle spam, death during summon/Gōka, master death, high-level pact switch, respawn card, friendly fire, cooldown expiry. Destroyed companion has no orphaned effect/damaging zone.

### Spellbound minions

Successful bite on staggered eligible fodder changes ownership/brain role; heavy/elite/boss denies through definitions. Validate pairing/range/state. Do not both convert and award normal death. Interrupted/invalid bite leaves no partial conversion or duplicate.

Follower credits owner, cannot hurt owner/allies, has visible friendly identity and expires at phase/master departure. Cap/duration need explicit tuning before unlimited conversion is enabled. It is match state, not persistent profile content.

**Acceptance:** two simultaneous bites, target dies/stagger expires, phase resolves during conversion, minion plus spawn-refill duplication, targeting/alliance update together and cleanup after owner leaves.

## 5. Growth, healing, items and world interactions

### XP, Renown and metrics

**CODE:** separate XP/Renown on PlayerState survives respawns. Cap20; XP-to-next50+30×(level−1); +4% maxHP/+2% damage per level; stamina from Config.Stamina. These are our tuning values. AddXp does not add score. Resetting a character must not reset the match record.

Committed death supplies killer/shares once; existing listeners award. Boss/alliance rules choose recipients explicitly, avoiding multiplied listeners. Level change applies in simulation, feedback fires once and unlocks follow definitions. Define whether leveling heals; do not accidentally refill HP from changing maxHP.

Extend ledger entries with match/phase/event identity as needed. Keep reward-source categories for auditing/results. Provisional pledge/commendation contributions need replacement/removal: current positive-only Add cannot implement overwritten ownership by endlessly adding. Standings only include eligible participants; completed/leaver records persist until settled.

**Acceptance:** multi-level grant/cap, companion kill, assist/boss share, respawn, disconnect, event replay, ownership overwrite, tied totals and cutoff eligibility.

### Healing resource

**LOCKED plan default:** begin2/max4 uses; kills fill gauge/add uses; phase refill; C requests35% maxHP over .6 s, interruptible. Healing is absent from current IAS button list, so add its action coherently.

State includes uses/max/gauge/heal action. Validate alive/action/resources, choose a single spend commit and define interruption semantics. No delayed healing after cancellation/death. Empty use gets small empty feedback; DESIGN full-HP default rejects without spending. Manual revival top-up is an explicit adoption decision.

Presentation: use count/refill gauge, authored body action, localized recovery particles, HP rise/soft confirmation. Don't make interruptible healing look like immunity.

**Acceptance:** empty/fullHP, rapid C, lethal hit mid-heal, phase refill mid-action, death/revive, cap gauge and no duplicate spend.

### Shared interactable behavior

Each chest/lantern/forge/boon/pact/travel point has discovery silhouette → nearby name/action → hold/confirm → authoritative commit → used/completed world state. Color reinforces form, never replaces an explanation. G is current world-prompt convention; binding changes stay central.

Server validates ID/distance/phase/eligibility/availability/cost. Cancel a hold on release/range/hit/death/invalid phase where applicable. Claim reservation/commit prevents competing first-use rewards. The client animates progress but cannot award. A used world object visibly changes.

**DESIGN defaults:** prompt .12 s fade, .2 s collection confirmation,1 s ordinary chest/scoring claim unless definition overrides. Timings are not footage measurements; availability reasons are concise.

**Acceptance:** two claimants, leave range, hit/die during hold, phase cutoff, stream unload/reload, replay request and used-state persistence.

### Pickups, chests and quick items

Committed pickup/chest grants defined loot to match inventory and collection metric once; show name/function/count. Planned quick capacity is six. Full belt exposes replace/decline rather than silent deletion. Item use validates target/action/resources, spends on commit and applies once. World drops, chest rewards and boss rewards use the same inventory API.

**Failure/feedback:** no-room/invalid-target/unavailable state explains itself; pending use cannot create phantom count; death/respawn reconciles to server inventory. Concrete loot tables/effects remain original content definitions, not guesses from sampled images.

**Acceptance:** simultaneous chest claim, full slots, last charge, invalid target, interruption, repeat pickup and death/phase while choice is open.

### Scoring lantern/corpse

Unlit→claiming→lit. Server commits one-time score; client then lights flame, plays confirmation and updates total. Another player sees used state. Large first-player-only objects reward only the committed claimant. Existing throne-corpse plan starts60; other amounts/scaling belong in score definitions.

**Acceptance:** two holders, death/hit, cutoff, repeated request, streaming reload; world state and ledger agree. Place risk/escape space around claim, not just a glow in a dead end.

### Boons, forges and skill enhancement

**Boon:** valid boss/great-foe completion exposes personal encounter/player claim. Candidate preview is separate from equipped passives; commit once. Our existing plan offers1-of3 even though sampled footage showed two; use configured our-game count. At planned five-active limit choose replacement/decline. Apply through shared modifiers and reset with match state.

**Forge:** discover→inspect affinity→confirm replacement/cost→server enhancement→weapon/attack feedback. State what is replaced before commit. Physical/fire/lightning/poison status needs damage/buildup/duration/stacking definitions; colored metal is not mechanics. Interrupted hold cannot spend without enhancement.

**Crystal/bloodsac:** authored kill/drop grants upgrade resource; server validates upgrade for the current class skill, applies and explains the changed effect. Skill, player and companion levels remain distinct. One red-sac image does not establish its moves/guaranteed drop.

**Acceptance:** repeated personal claim, replacement at capacity, dead/culled choice, saved/reopened offers, affinity replacement, expired status and upgrade during skill recharge. Prepare modifier/reward interfaces now; deliver content after the basic match/loot works.

## 6. Boss encounters, rituals, alliances and events

### Boss/Trespasser

Extend enemy/action data with encounter identity, arena, membership, phase/attack choice and rewards. High HP alone is not a boss. Original model/move language is an art/animation task; complete source attack catalogs/timings are unverified.

Trigger/arena entry→encounter created→nearby invite→accept/decline/expire→transport accepted players→fight→victory/failure/cancel→reward/return→cleanup. Remember safe return transforms. Define death, cutoff, last participant leaving and boss reset outcomes. Invalid/expired acceptance cannot strand a player or reopen a finished encounter.

**Temporary cooperation** is an encounter-scoped truce, not persistent alliance. Participants and their actors cannot hit one another in that fight; remove truce on exit/end while preserving real alliances. Return safely after resolution.

Attacks use ranges/weights/cooldowns and one action clock. Telegraph footprint agrees with hit shape; recovery is readable. Arena camera/cover/height fits the body; phase conditions cross once. Avoid wall hits, stuck pathing and indefinite invulnerability.

Existing boss starting score120 split by damage share requires documented rounding/remainder/participant eligibility. Personal boon claim is one-time. Cleanup is not a kill. HUD invitation names the threat and Join/Decline/expiry; boss name/HP/posture has distinct anchor from player posture; shared success notice plus personal reward, not repeated global toasts.

**Acceptance:** accept at expiry, death/phase in transport, all leave, companion final blow, simultaneous death/finish, disconnect before award, blocked return point. Truce/actor/reward cleanup survives each branch.

### Ritual and pledge

**LOCKED plan:** phases2/3, activation40% into phase; clock/map/compass announce; entering then leaving drainsHP. Amount and final bonus formulas are tuning, not inferred measurements.

Dormant→announced→active→closed. Own bounds, owner and each participant's entered flag. Outside-never-entered is distinct from leaving. Choose death/revival/reset policy explicitly; avoid stale character flags. Tall branching pillar reads from afar; approach/hold cancels on release/range/hit/death. Commit changes owner/name/accent and provisional score. Overwrite revokes old contribution before new; permanent kill score stays separate. Freeze transactions before resolving standings.

Existing plan grants player kills30; manual's Sword category is ritual-only. Preserve our plan pending explicit policy reconciliation and record kill location/category now. Manual red/gold plinth bonuses can follow later; don't block first ritual implementation on them.

**Acceptance:** enter/exit/reenter including roofs, stacked-floor bounds, revive outside, two claimants, overwrite at cutoff, owner disconnect, killed while holding. Drain warning and authoritative damage agree.

### Commendations

Committed enemy/item events update per-phase defeat/collection metrics; rarity/newness weight is data. Planned top2 each category get phase-end score before cull; tie handling is deterministic. Show current progress in info and awarded reason at resolution. Manual provisional score swings differ from our current end-only promise; don't turn repeated rank refreshes into permanent grants.

**Acceptance:** companion credit, repeat chest denied, same player wins both without duplicate event processing, dead eligible player included, all clients see same final snapshot.

### Alliances, Bound duos and Sigils

Standard petition→recipient accepts/declines/expires→server alliance→allegiance/card/sharing updates together. Valid players only; no alliance because a UI row was highlighted. Actors follow membership. Resolve simultaneous petitions, phase cutoff and departure. End Standard alliance before final.

Solo refuses requests clearly. Bound is fixed-duo identity and needs explicit team life/result rules; don't run free-for-all final beneath a Bound label. **Party=admission, alliance=gameplay, truce=encounter.** Keep their identities separate.

Planned ally travel validates target/phase/combat/cooldown/safe destination. Alliance leave/maxHP cost/sharing values and Bound final require full rules before enabling. Sigils later need assignment, authorized secret target discovery, goal state, one-time success and reward; no hardcoded damage exceptions.

**Acceptance:** ally/companion/minion friendly fire, simultaneous requests, timeout, target leaves, final begins during acceptance, Solo, Bound final, truce expires while real alliance persists, secret target data protected.

### Random events

Map-authored candidates + phase schedule→select valid event→announce place/time→activate objective/effect→settle→cleanup. Regional icons must match real opportunities. Initial content can stay absent while interface is prepared; no guessed storm/bell behavior is labeled observed.

**Acceptance:** cutoff mid-event, missing site, unload, no eligible participant, replay completion and canceled presentation cleanup.

## 7. World, navigation and map information

ChatGPT supplies first-zone street/interior/roof/lower/objective loop and reserved expansion exits. Zone IDs/names follow that sketch; current empty Zones is not a playable map. Routes and rewards are authored together.

**CODE estimates:** gravity145, walk/sprint18/30; normal velocity50 (~8.6-stud rise), charged85 (~25), three air jumps45 (~7 each), air dash72×.18 (~13 studs). These are ballistic estimates, not guaranteed safe gaps. Verify live R6 landings/camera. No base grappling.

Existing tags: BL_Region+Region; BL_Spawn; BL_EnemySpawn+Enemy/Zone/Count/Radius/Respawn; BL_PactCircle+Shinigami; Manor BL_CombatZone. Final/Antechamber/ritual marker names are not yet implemented contracts: publish a shared list before stamping them. Markers are invisible/anchored/noncolliding; validate unknown IDs, required sites and landing surfaces at boot.

Map browse shows location/height, region, phase, opportunities, standings/cutoff, pins/zoom/layers; browsing never teleports. Region/revival choice clearly says choose, shows selection/deadline and commits eligible input. Distinguish street/roof/lower routes. Closing restores prior control. Compass uses height cues and only relevant opportunities. Region names fade without covering combat. Instant travel later validates phase/combat/revival/cooldown/destination server-side and explains denial.

**Acceptance:** loop both directions, return from lower route, every roof link, fight in doors/stairs, companion follow, floor-correct spawn, streaming, map height correspondence. Through art rebuild preserve BloodTable path, two floors, outdoor yard/practice/combat/pact markers.

## 8. Presentation details that create character

Exact palette/type/layout states and review gates are in [ui-quality-standard.md](ui-quality-standard.md); use current Theme, not an unapproved replacement. All timing below is **DESIGN**, except existing Theme motion .12/.20/.35 and explicitly named CODE actions. It is not measured Duskbloods timing.

| Event | Required information | DESIGN presentation |
|---|---|---|
| Focus/confirm/deny | One active target, pending/accepted/reason | .12 s focus, .20 settle, distinct dry tick/confirmation/denial |
| Damage | Immediate HP, readable damage chip | .15 s chip delay, .35 s drain; local impact |
| Skill ready | Charges/ring/lock reason | .2 s glint, once per new charge |
| Level | New level/unlock, XP state | .35 s medallion pulse,1.8 s toast |
| Renown | Amount+source+stable total | .15 in/1.2 hold/.35 out; merge same-source bursts |
| Pickup | Name/count/function/replace | Compact2 s notice |
| Companion | HP/level/state/cooldown | .35 s level highlight; dim dead card |
| Region | Name, nonblocking | .35 in/2 hold/.5 out, boundary debounce |
| Timer | Phase/dial/ritual marker | One cue per threshold; subtle bell |
| Objective | Progress/owner/outcome | Completion flash .25 s, residue .8 s |
| Boss invite | Threat/Join/Decline/expiry | Proposed8 s response window; cancel if invalid |
| Final | Changed rule, two lives | 1.5 s setup banner; extinguish on server defeat |
| Results | Placement/score/kills/reward/return | One reveal within planned12 s |

Menus own cursor/input; text entry doesn't fire hotkeys; invalidated modals close on death/phase. Stable HUD anchors: upper-left vitals/level/XP/companion, lower-left ammo/skills, bottom-center posture, center crosshair, top-right clock. Boss bar cannot collide with posture. Status buildup uses icon/label, not unexplained stripe. Final explicitly changes score to lives.

### Effects: windup → active shape → confirmed contact → residue

Each layer has a purpose: shape/silhouette, core/edge, texture/trail/particles, short local light, surface contact, optional residue. Single neon solids do not meet the bar. Footprint and danger duration match damage. All effect parts are noncolliding/nonquerying; actor/action-instance identity and cleanup/cancel handles prevent replay/leaks.

- Saber: authored active trail, impact-oriented spark/blood, restrained hitstop/shake. No full hit flash on a miss. Existing plan baseline ~60ms hitstop needs simulation-safe/capped handling.
- Charged saber: current BloodCharge inward motes/glow/mist→armed glint→release; canceled charge drains, not explodes. Readiness and impact are different events.
- BloodBlade: dark wet crescent/crimson edge, restrained drips/mist, cast and impact; travel/termination follows projectile state.
- LightBeam: convergence→layered scrolling core→contact flare→collapse; CODE1.2s channel. No visual false active window or beam surviving interruption.
- Summon: ground pact motif, localized upward wisps, silhouette resolution, arrival sound. DESIGN .45s reveal/.6s residue; denied summon creates no phantom.
- Gōka: grounded heat/ember buildup, blade-ground contact, expanding ring, textured flame at meaningful positions, smoky cooling. Cosmetic lingering flames cannot imply hidden damage; real lingering damage gets authoritative owner/ticks/expiry and boundary. Keep feet/opponent windup visible.
- Spawn: shallow blood mist, body reveal/protection contour. DESIGN .6s reveal; contour ends when protection ends, including early attack.
- Pledge/lantern: readable unlit form→modest discovery→concentrated claim→committed ownership name/accent; old ownership visibly withdraws on overwrite.
- Poison/weather: local buildup/source/expiry; atmosphere cannot hide attacks or become the only navigation cue.

**Acceptance:** ordinary camera distance, crowded three-actor fights, recorded windup/active/residue compared to hitbox debug. Cancel/destroy at each stage;50 casts/toggles leave no growing light/part/trail/audio count. Threat animation remains readable.

### Audio/ambience

Use custom/team-owned or explicitly free available assets. Missing original audio is labeled missing, not called completed. Separate cue definitions from simulation outcomes; each loop has cleanup/fade.

Manor: quiet wind/exterior gaps, localized candle/wood/room tone, material footsteps and restrained distant bell. Victorian: outdoor wind and sparse metal/lantern movement, exterior filtered by interiors, distinct wet lower-space tone. Different emitters must not all play equally loud. Audio priority: threat/guard break > contact/skill > objective/phase > reward/UI > ambience. Merge rapid reward chimes. Boss music follows encounter end/cancel/return; no stuck beam hum or permanent duck.

**Acceptance:** move between spaces, menu transitions, canceled encounter, teleport failure, death during channel, rapid reward stream. No doubled loops/bells; settings affect real master/music/effects levels before System is called complete.

## 9. Persistent systems and later content

**Bloodgems/skins, v1:** server catalog/class/price/ownership→inspect→purchase→validate→atomic debit/grant→equip. Client price is untrusted. Duplicate request doesn't double-charge; insufficient funds explains. Profile reload/travel preserves it; cosmetics don't change combat.

**Relics, owner-requested and design pending:** persistent earned inventory/equippable slots/passives. Slot count/rolls/rarity/reward source/modifiers are not approved definitions. Prepare inventory/equipment/modifier compatibility; don't call the existing tab implementation. Keep relic effects separate from match boons and class innate/aspect. A concrete relic design precedes shipping that system.

Further class/companion content should fit definitions/models/actions/controllers without core rewrites. Ranged/support Shinigami, aspects, ultimate, Sigils, richer events/Ranked remain later/unfinished. Parties/private are already v1 and cannot move silently to later. Settings/archive need actual useful behavior; sealed tabs are honest. Preserve Gustave data migration and saved profiles.

## 10. Delivery order and acceptance

1. Re-audit/reconcile rules and world/participant/ledger interfaces; retain working kit/NPC/XP/score.
2. Reserved admission + complete short match lifecycle with understandable UI on valid test world.
3. Healing + one chest/pickup/lantern + growth/score/collection feedback along connected routes.
4. One original boss including invite/truce/reward/return/boon, not just fight AI.
5. Ritual/pledge/drain + player-kill policy/commendations/cull presentation.
6. Upgrade/minion/event content; alliances/duos; complete party/private tests; reward/skin persistence. Relic design follows decisions.
7. Accepted Manor/lighting/Victorian integration, real models/animations and effects/audio quality passes.

Prepare the whole dependency graph now while delivering one verified piece at a time. Each feature above has its own acceptance; run cross-system tests too:

| Scenario | Required outcome |
|---|---|
| Fresh profile→class→party/private Hunt | Persisted loadout, one admission, together, readable retry |
| Two-player short full match | All transitions, one winner, correct lives, one award/player, return |
| Eight-player load | Capacity,8→6→3, stable standings, claims and spawn spread |
| Death at phase boundaries | No stale action/HUD/camera; correct preserved eligibility/progress |
| Boss co-op→competitive play | Scoped truce, credit, safe return, former cooperator targetable |
| Pledge overwrite at cutoff | One owner/contribution/result, consistent warning/standings |
| NPC/companion/minion cleanup | Correct credit/allegiance, no duplicate slots/actors/rewards |
| Inventory/forge/boon races | One commit/cost, explicit replace/deny/cancel, correct modifiers |
| Published data/travel failure | No duplicate currency, released reservation, intact profile/retry |
| Player-camera route/presentation | Threats/landings/objectives/UI readable at required resolutions |

Run current `ReplicatedStorage.BL_SelfTest:Invoke()` in Client context after code changes, add meaningful new mechanic cases, preserve Test/Live separation. DebugService bridge is test control, not client production authority. Real teleport/MemoryStore/multi-account behavior requires published verification. Report implemented/tested/visually reviewed/owner-accepted separately.

## 11. Explicit conflicts: don't guess silently

| Issue | Instruction |
|---|---|
| Old plan Lv15/from Virtue versus CODE Lv20/separateXP | Preserve current architecture; document reconciled decision, don't revert automatically |
| Virtue prose versus Renown code label | Use Config.Score.DisplayName; no duplicate counters |
| Source tie-break versus first-to-reach | Keep locked rule; choose stable equal-time fallback |
| Source shows8 enteringI,6 enteringII,3 enteringIII; our plan culls at endII/endIII | Explicit owner decision required to move culls earlier; don't describe the footage as validating late culls |
| Death deduction unverified | Keep current no-deduction plan; absence in samples is not evidence |
| Player kill everywhere versus ritual-only source category | Preserve plan pending choice; record context |
| Pact reset1 versus immediate master mirroring | Choose intended loss/mirroring rule; high-level test |
| Free attacks/sprint versus manual | Preserve current costs pending owner decision |
| Counter/deflect/repair/ultimate | Pending gameplay, not effects-only polish |
| FinalHP/drain/sudden death/simultaneous deaths | Explicit Config numeric policy before production enablement |
| Bound final/alliance sharing/leave penalty | Explicit ruleset, not Standard under another label |
| Minion cap/relic rolls/status rules | Interfaces now; promised content decisions before enablement |
| Heal commit/interruption/revival top-up | Define action semantics; distinguish reference adoption |
| Moving live source | Re-read before edits; stage only owned paths |

## Appendix: evidence and coordination

- [CLAUDE.md](https://github.com/glocen/BloodsLocks/blob/main/CLAUDE.md), [engineering-plan.md](https://github.com/glocen/BloodsLocks/blob/main/docs/engineering-plan.md), [team-notes.md](https://github.com/glocen/BloodsLocks/blob/main/docs/team-notes.md).
- The earlier [sampled gameplay breakdown](archive/duskbloods-sampled-breakdown-2026-10-29.md) is archived for traceability; this brief supersedes it. Snapshot damage is not balance evidence.
- Owner source: [Vosair full gameplay](https://www.youtube.com/watch?v=8Dyw5O2zyiY). Actual inspected coverage belongs in the [new evidence appendix](https://github.com/glocen/BloodsLocks/blob/main/docs/duskbloods-evidence-appendix.md), not inferred from its 2:49:34 runtime. Early segments include explicit training/tutorial content; don't apply every early screen as a production multiplayer rule.
- Official manual checked29 October: [Basics1](https://campaign.theduskbloods.jp/manual/en/basic1.html) for broad phase/revival/ritual/final distinctions; [Basics2](https://campaign.theduskbloods.jp/manual/en/basic2.html) for cooperation versus alliance and upgrade families. Reference rules do not automatically replace locked BloodLocks rules.
- [Art resumption](https://github.com/glocen/BloodsLocks/blob/main/docs/manor-art-resumption.md) preserves gameplay paths/rollback masters.
- Deliver via shared repo document and concise team/Issue#2 handoff. State files, real checks, limitations and next step. Put detailed evidence in its appendix; the first page remains behavior/dependencies.

