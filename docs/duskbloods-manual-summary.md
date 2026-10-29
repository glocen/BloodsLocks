# The Duskbloods: official manual, summarized

Source: the official online manual for *The Duskbloods Network Test Ver.* ([campaign.theduskbloods.jp/manual/en](https://campaign.theduskbloods.jp/manual/en/basic1.html), pages: Controls, Game Screen, Game Basics 1 and 2, House of Night, Actions, Menus). Read 2026-10-29.

This is our **main source of inspiration**, not a blueprint. We don't copy 1:1: names, art and lore are our own, and the owner decides what we keep. Each section ends with **→ BloodsLocks**: what we have, what we'll adapt, and what's open.

Our names for their things:
- Kin → **Shinigami**
- House of Night → **The Vigil**
- Bloodsworn → classes (Duelist first)
- Goldblood Stake → our heal (name TBD)

---

## 1. The match: "Dusk Battle"

- **8 players, 4 phases.** You battle for **Virtue**; whoever has the most Virtue fights for victory in the final phase.
- **Starting area:** during the intermission before each phase, every player picks a starting **area** and spawns at a random spot in it. If too many choose the same area, some get moved elsewhere at random.
- **Exploration and strengthening** is the core of the early phases: kill enemies to level up, search for items, and read the map's **regional features** (what each area offers that phase).
- **Experience and levels:** kills give XP; levelling raises HP and attack power. Big character abilities at level 12 come from earlier press coverage.
- **Death:** you revive and keep playing. You pick a **revival point on the map**. If you have fewer than 2 heal uses when you die, they're topped back up to 2.
- **Clock** (top-right dial): shows phase progress. When the hand reaches the **shining dot**, a **ritual site** appears; at the **red dot**, the phase ends.
- **Culling:** in phases 2 and 3, the lowest-Virtue players are eliminated.
- **Final phase, "Moon Blood Bestowal":** last one standing wins. Alliances end. Everyone has **2 lives**, and **max HP is boosted by the Virtue you earned**.

→ **BloodsLocks:** matches our locked match rules (plan §3: 4 phases, culling, top 3 final with 2 lives). New details to adopt: area picks with overflow relocation, revival-point choice, the heal top-up on death, the clock with a ritual-site marker, and the final-phase HP bonus from Virtue.

## 2. Virtue (how you win)

The amount you can earn rises as phases progress. Six kinds, **ranked by value**, which breaks ties:

| Rank | Virtue | How |
|---|---|---|
| 1 | **Sword** | Killing players **at a ritual site** (not outside one) |
| 2 | **Pledge** | Swearing to a **blood pledge pillar** at a ritual site; lost if someone overwrites your pledge |
| 3 | **Repulsion** | Killing great foes, more for **trespassers** (roaming bosses) |
| 4 | **Flame** | Lighting the skulls of corpses sitting in chairs. Big lantern corpses give more, first player only |
| 5 | **Commendation** | At each phase end, the top 2 in **Bloodfang** (kills) and the top 2 in **Collector** (items; rare and new items count more) get Virtue. Rankings update during the phase |
| 6 | **Other** | Sigil goals, events |

- **Ritual sites** appear in phases 2 and 3. They're the PvP hotspot. **Leaving one after entering costs HP.**
- **Redstone / goldstone** plinths at ritual sites: a redstone boosts Sword Virtue, a goldstone boosts Pledge Virtue. You can hold only one.

→ **BloodsLocks:** this is Step 11's design. Ritual sites plus Sword/Pledge make PvP the main way to score, with PvE (Repulsion, Flame, Commendation) as the steady income.

## 3. Shinigami (their "Kin")

- **Summoning circles** are scattered around the map. Enter a **compact** (pact) there, and the companion fights by your side.
- **Summon/dismiss** from the Function menu (hold the action button).
- A companion that dies is dismissed and **can't be resummoned until a cooldown passes**.
- It **regenerates HP slowly** while dismissed or out of combat.
- Making a pact with a **new** one at another circle **breaks the old pact**, and the old one's level drops if you had raised it.
- **Kin Enhancement** is a regional feature (some areas strengthen your companion).
- HUD: name, level and HP card under your bars.
- The courtyard lets you pick a companion to pact with for practice.
- From earlier press coverage: melee, ranged and support types; they level up with you.

→ **BloodsLocks (Step 10a, next big system):**
- pact at circles, one active, summon/dismiss, death cooldown, regen while dismissed, level loss on switching;
- the HUD card is already built (`Client.UI.Hud.ShinigamiCard`);
- practice pacts at The Vigil's yard circle.

## 4. Alliances, co-op, Sigils

- **Alliances:** petition a player from the Function menu. Allies:
  - can't hit each other;
  - **share Sword and Pledge Virtue**;
  - get a **Fellowship Medal** that teleports you to allies.
  - You can leave an alliance at a phase end, **at the cost of max HP**. Alliances end in the final phase.
- **Co-op battles:** when a trespasser fight starts, nearby players get a request. Accepting **teleports you into the fight**, where participants can't hit each other. A win gives Repulsion Virtue and Powers of Blood; then you're sent back.
- **Sigils:** secret player-vs-player relationships with unique goals that earn Virtue. You find your target via items or proximity sensing, and check by locking on. "Passive" Sigils can appear because of other players' Sigils.
- **Match modes:** Casual or Ranked, with three rule sets: **Standard** (alliances allowed), **No Alliances**, **Bloodbound Alliance** (fixed duos who win or lose together, even in the final).

→ **BloodsLocks:** alliances and duos are already locked in our plan. Co-op trespasser fights and Sigils are later features. Ranked waits until after launch.

## 5. Growth inside a match

- **Powers of Blood:** blood roses grow from the bloodstains of fallen great foes. You can manifest **up to 5** and swap between them.
- **Weapon enhancement:** **Alchemy Forges** give your main weapon an affinity (iron, fire, lightning, poison). Affinity attacks cause the matching **status affliction**.
- **Bloodsworn Skill enhancement:** **blood crystals**, from **Bloodsacs** (enemies) or found while exploring.
- **Goldblood Stake** (heal): recovered by gathering **Goldblood** from kills and corpses.
- **Items:** up to **6 quick items**, swapped freely.
- **The map's regional features** say where each upgrade is available that phase (skill / Kin / iron / fire / lightning / poison enhancement, Flame Virtue).

→ **BloodsLocks:** passives ("Powers of Blood") and weapon affinities are in the vision. The heal stake, items, forges and crystals are Step 11+ content.

## 6. Combat and movement (their exact rules)

- **Move / sprint;** a sprinting attack exists.
- **Jump; hold for a high jump; up to 3 air jumps.** ⚠ The manual says 3; we built 4, from earlier press. **Owner's call.**
- **Air dodge.** Attacks, guards and dodges all work **in the air**.
- **Climbing:** grab ivy and other grips.
- **Lock-on:** you always face the target while moving.
- **Attack;** hold the strong attack for a **charged attack** (we built this).
- **Ranged:** reloadable; some ranged attacks use **aim/zoom**.
- **Guard** makes a **shield** that blocks frontal attacks. Repeated hits break it, and **broken shields repair over time.**
- **Guard counter:** attack right after a block. **We don't have this yet.**
- **Howl** (guard + strong): a gust that interrupts attacks timed with it and **greatly increases their stagger**. It also **deflects some ranged attacks**.
- **Stagger + drinking blood:**
  - Hits build the target's stagger gauge; when full, they're staggered. Biting a staggered enemy deals big damage and heals you.
  - **Weak-willed foes become "spellbound":** they follow and fight for you (minions).
- **Bloodsworn Skills** have a cooldown. The HUD shows it as a **ring gauge** (we built this).
- **Stamina** (from the HUD guide): drained by **attacking**, sprinting and dodging; regenerates; **not consumed out of combat.** ⚠ Our rule is "attacks and sprint are free". **Owner's call.**

→ **BloodsLocks:** most of this is built (Step 4–8). Open items: guard counter, howl deflecting projectiles, shield regen, climbing, aim/zoom, the spellbound minions, and the two ⚠ decisions above.

## 7. The hub: "House of Night" → The Vigil

The **Wheel of Blood** opens the hub menu:
- **Dusk Battle:** pick rules and join online matches.
- **Bloodsworn Selection:** pick a character, and toggle whether to have Sigils.
- **Battle Remembrance:** tutorial missions for controls and rules.
- **Archive:** gameplay info.
- **Courtyard:** practise on targets. Its menu picks the **target type**, a **Kin to pact with**, and character settings.
- **Travel menu:** move around the hub.

→ **BloodsLocks:** The Vigil already has the yard (our courtyard: dummies, practice Shinigami circle). The Blood Table menu becomes our "Dusk Battle". The class altar is Bloodsworn Selection. A tutorial ("Battle Remembrance") is a good later addition.

## 8. Screens and menus

- **HUD:** see docs/ui-research.md §2c (all 20 elements, A–T). Ours already follows that layout.
- **Info screen** (in match):
  - player info (rank, Sigil role, Virtue), **ranking**, an **encountered Bloodsworn** list (petition alliances from it), character status, event and Sigil details;
  - the **phase**, with how many players pass the culling;
  - the **map** with pins and depth layers.
- **Instant travel** from the map. It's blocked right after a phase starts, after reviving, during combat, and for a cooldown after travelling. A HUD icon shows whether it's possible.
- **Blood Manifestation and Quick Items menu:** set the 5 Powers of Blood and the 6 items.
- **Function menu** (hold the action button): alliance petition, observer view, pins, summon/dismiss Kin.
- **Emote wheel.** Emotes matter for some Sigils.
- **Observer view:** lock on to other players to see their info.
- **System:** game, camera, image, sound, network and controller settings, plus quit. Leaving a multiplayer match early can bring a **penalty**.

## 9. Owner decisions flagged by this manual

1. **Air jumps:** the manual's **3** versus our current **4**.
2. **Stamina:** does attacking (and sprinting in combat) drain it, as in the manual, or keep ours free?
3. Add the **guard counter** and **howl deflects projectiles** to the Duelist kit?
