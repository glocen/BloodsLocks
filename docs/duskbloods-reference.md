# Duskbloods reference notes

Research for BloodsLocks design decisions. Sources are network-test and preview coverage from 2026, so details may change. Where sources conflict, the note says which one we followed.

## Movement

- Sprint is infinite and never drains stamina. (Game Informer, GoNintendo, Games24)
- Jumps: up to 4 before landing (Game Informer, Checkpoint, Games24); Inven says 3. **We use 4.**
- Hold jump on the ground for a high jump ("charging the first jump lets you fly upward"), reaching 2–3× normal height.
- Air dash / aerial dodge exists, and the jump button in the air performs an air jump.
- No fall damage; some maps have instant-death drop zones.
- Lock-on is on the right stick (press to lock, flick to switch targets).
- Fast-travel points; very vertical maps (rooftops, bell tower, sewers).

## Stamina

- **Costs stamina:** dodging, mid-air dashes, air double-jumps (VGC: "not something you can spam"), and some skills (one character's continuous roar).
- **Free:** sprinting and every attack, melee and ranged (Inven, VGC, GameRant). Game Informer says attacks drain it; **we follow the majority: attacks are free.**
- **Evasion cancel (tentative name):** a dodge timed right after an attack costs no stamina. Mastering it lets you alternate attacks and dodges with zero stamina use.
- **Guard counter:** counterattack right after blocking. Whether guarding costs stamina is unknown.

## Combat

- Each character has fixed melee and ranged weapons (no weapon switching), skills, and passives ("aspects").
- **Controls (Switch 2):** R attack, ZR strong (hold = charged), ZL ranged, L guard, guard + ZR = howl, X skill, D-pad left swaps skills, A dodge, B jump, L3 sprint, R3 lock-on.
- **Strong attacks (2026-10-29 search):**
  - Testers confirm a light, heavy and ranged attack per character; ZR is strong, hold to charge.
  - No public frame data. We follow FromSoftware convention: slower, heavier, fills stagger, crushes guards; charging can be dodge-cancelled.
- Perfect block = parry. A howl timed before a hit staggers the attacker and can interrupt player attacks. On minor mobs it causes a brief stagger.
- **Stagger gauge:** filled by attacks; guns are good at filling it. Biting a staggered enemy deals big damage and heals; on fodder it creates a minion. Minions vanish at phase transitions.
- **Flasks** (golden-blood stakes): 2 to start, max 4; fodder kills fill a gauge for +1; refilled at phase transitions; the max can grow during a match.
- Forges and chests imbue weapons with fire, lightning or poison.
- Boss kills drop random enhancements (stronger skills, elemental enchants).

## Albert (the model for our class 1)

- All-rounder: saber + submachine gun that fires short bursts. The SMG does chip damage and builds stagger from range.
- Skills: a blood blade projectile used between normal attacks, and a light beam unlocked by leveling. The beam is multi-hit but leaves him immobile while firing.
- Passives boost blood-skill uses and stagger against high-score players.
- **Skill visuals (2026-10-29 search):**
  - Blood Blade is officially "a blade formed of the wielder's blood", a forward projectile that can be charged for extra damage and stagger.
  - Light of Hayern (the beam) charges a crystal on his weapon, then "shines forth a beam of light". It staggers targets even mid-skill, and guides say to save it for enemy skill activations.
  - No frame-level visual breakdown was found. We follow the FromSoftware blood look (dark, wet, viscous; Bloodborne lineage) and a warm golden light.

## Match structure

- 8 players, PvPvE, about 30 minutes, phases scored by Virtue. Sources split on whether the bottom 2 or 3 are culled first.
- The final 3 fight in a closed arena under a blood-red sky with 2 lives each. The top-Virtue finalist gets an HP bonus.
- No death penalty: unlimited revives before the final phase. At the start of a phase you choose a spawn region and land at a random spot in it.
- **Virtue sources:** PvE kill leaders, most items collected, one-time throne embers, roaming boss ("Trespasser") kills, capture points at ritual sites, PvP kills inside ritual sites. Falling stars pay whoever holds them at phase end.
- Leveling is tied to Virtue, with a big character ability at level 12.
- Alliances, duos mode and optional per-character objectives ("sigils") exist.

## Kin (companions)

- Summoned by making a pact at circles marked with light pillars (yellow symbols). They stay for the match.
- Three types: melee, ranged, support. Kin have their own skills and level up with you.
- They can be recalled and resummoned. A dead Kin is on cooldown; switching to a new Kin resets it to level 1.

## Hub (House of Night)

- Pick a character, practice in a training space, queue for matches. Everyone returns there after a match.
- Matchmaking starts after picking a character. Private lobbies for friends are confirmed.

## Sources

- Game Informer hands-on: https://gameinformer.com/preview/2026/08/20/a-hands-on-breakdown-of-from-softwares-exciting-surprising-and-dense-take-on
- GoNintendo blowout: https://gonintendo.com/contents/64002-the-duskbloods-blowout-reveals-gameplay-mechanics-characters-content-and-more-plus
- Inven Global: https://www.invenglobal.com/articles/24964/no-death-penalty-stress-free-8-player-pvpve-the-duskbloods
- VGC (Miyazaki feature): https://www.videogameschronicle.com/features/the-duskbloods-hidetaka-miyazaki/
- Fextralife Controls: https://duskbloods.wiki.fextralife.com/Controls
- Fextralife Combat: https://duskbloods.wiki.fextralife.com/Combat
- Fextralife Online: https://duskbloods.wiki.fextralife.com/Multiplayer_Coop_and_Online
- Albert guide: https://www.gamerfuzion.com/duskbloods-albert/
- Mobalytics characters: https://mobalytics.gg/gamebase/guides/the-duskbloods-characters
- Mobalytics first impressions: https://mobalytics.gg/gamebase/previews/the-duskbloods-first-impressions
