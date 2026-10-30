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
  - ⚠ **Update 2026-10-29:** the game's own HUD guide (screenshots from the owner) says stamina "will decrease from actions like attacking, sprinting, and dodging", and is "not consumed while out of combat". That contradicts both "attacks are free" and "sprinting is free". Our rule stays as built until the owner decides. See docs/ui-research.md 2c.
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
- **Armament:** "Lorrik's Jeweled Saber & SMG", "a pair of weapons inlaid with ebony jewels" (Fextralife). No close-up image found. The owner's direction (2026-10-30): the blade is **black, with some gold and a jewel**.

### Albert in motion (the owner's video, 2026-10-30)

A 480p clip of the final "Grail Battle", playing Albert (`C:\Users\gloce\Videos\hqqXe55ZlnZNd6P.mov`; higher-quality clips are coming). What it shows:
- **Look:** white shirt, a dark coat with a short shoulder cape, gold buttons and embroidery, white hair. The sabre reads as a thin black curved blade at play distance; the SMG is in the left hand.
- **Light of Hayern:** he raises the gun overhead, one arm straight up. A white star flare lights at the crystal, then a white vertical beam.
- **Bite:** he grabs the target. A bright red plume shoots up from the bite, white smoke ribbons spiral around both bodies, then a big red plume rises as the victim drops.
- **Guard:** a translucent red sphere surrounds the guarding body. A parry gives a white-gold flash.
- **Hits:** thick red bursts with a pink-red mist. Red spatter stays on the floor (decals).
- **Kin:** a spectral wolf made of blue-grey smoke wisps leaps and fights beside him.
- **Arena:** round raised blood basins, gothic iron railings, black columns, a red sky with a dripping blood moon. The clip opens on a "GRAIL BATTLE" banner and ends on "You are the Victor of this Dusk".

## Match structure

- 8 players, PvPvE, about 30 minutes, phases scored by Virtue. Sources split on whether the bottom 2 or 3 are culled first.
- The final 3 fight in a closed arena under a blood-red sky with 2 lives each. The top-Virtue finalist gets an HP bonus.
- No death penalty: unlimited revives before the final phase. At the start of a phase you choose a spawn region and land at a random spot in it.
- **Virtue sources:** PvE kill leaders, most items collected, one-time throne embers, roaming boss ("Trespasser") kills, capture points at ritual sites, PvP kills inside ritual sites. Falling stars pay whoever holds them at phase end.
- Leveling is tied to Virtue, with a big character ability at level 12.
- Alliances, duos mode and optional per-character objectives ("sigils") exist.

### How a match starts and runs (research 2026-10-29)

Sources: the official manual (Game Basics 1), GameRant's explainer, and preview round-ups. No source describes a waiting lobby or an intro cutscene, so those parts of our flow are our own design.

1. **Hub:** pick a character (Sigils on or off), set the rules, matchmake from the House of Night.
2. **Intermission before every phase:** each player picks a **starting area** on the map. Too many in one area → random players are moved to another. You start at a **random spot** in your area. Phase 2 (and 3) open with a fresh pick.
3. **Phase 1:** explore, kill AI, collect items. PvP is possible but not encouraged. Virtue comes from tough enemies, skulls (Flame), and the two commendations (most AI kills, most items).
4. **Phases 2 and 3:** partway through, a **Ritual Site** activates and everyone is called to it: a PvP arena with pledge altars you hold until phase end. Standing outside its boundary slowly hurts. When the clock hits 0, the lowest-Virtue players are cut (2 after phase 2; after phase 3 only the top 3 remain).
5. **Final phase:** the top 3 fight in a smaller arena, one respawn each (2 lives), max HP boosted by earned Virtue. Last one standing wins.
- **Phase length:** sources disagree (about 5 min per Yahoo; 8–10 min per ResetEra and Console Creatures; about 30 min per match per GameSpot). Ours stays *(tune)*.
- **Critique from previews:** every match ends in PvP and side objectives repeat, so matches feel samey. We should vary regional features and events per match.

### PvE and the minute-to-minute match (network-test impressions, research 2026-10-29)

Sources: Fextralife Game Mechanics, Nintendo Life, Gaming Trend, Destructoid (links below). Note: theduskbloods.wiki's "Hunter/Prey, VP" loop contradicts the official manual and every preview, so we ignore it.

- **About 25–30 min per match**, with result screens between phases.
- **Phase 1:** explore, level up, collect items, fight mobs, light lantern corpses (Flame), find a Kin early (Kin level up with you). Players can avoid each other entirely; a PvP kill gives no Virtue yet.
- **Phase 2:** mini-bosses and bosses appear; ritual sites open. **Phase 3:** ritual sites heavily contested; PvP kills give Sword Virtue; random events more likely.
- **Enemies seen:**
  - Standard mobs that can catch new players off guard.
  - Cavalry-type mobs.
  - "Hefty" big enemies (mid-match fights).
  - Crystal lizards (loot runners).
  - Swarms of **blood sac bugs** (an event; killing them grants power-ups and passives).
  - Mini-bosses and bosses in phase 2 (a giant toad).
  - **Trespassers:** roaming raid bosses; nearby players get an alliance prompt and are teleported into the fight.
  - **Invaders:** a reward goes to whoever is still fighting when the invader dies.
- **Enemies hit very hard and can stagger the player.** Dying costs only time: a quick respawn.
- **Upgrades in a match:**
  - Blood Roses from bosses: passives such as weapon damage, stamina, or heal-on-kill.
  - Forges: iron / flame / poison affinities on your weapon.
  - Bloodsacs: skill upgrades (cooldown, damage, uses).
  - Kin circles: Kin level boosts.
  - Leveling: HP, attack, stamina, then a second class ability.
- **Map:** dense with icons. Players read them and plan routes. Free teleport between set points; spawn choice shows population density. Random events, such as **starfall**.
- **Criticisms to learn from:**
  - Limited enemy variety; bosses less fun than they look.
  - Virtue (commendations) shifts confusingly between close players.
  - Invader rewards favour last-hitters.
  - Lower areas too dark.
  - The endgame always becomes a sweaty PvP battle royale.

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
- Official manual, Game Basics 1: https://campaign.theduskbloods.jp/manual/en/basic1.html
- GameRant explainer: https://gamerant.com/the-duskbloods-explain-how-game-works/
- ResetEra preview thread: https://www.resetera.com/threads/the-duskbloods-preview-thread.1609033/
- Console Creatures hands-on: https://www.consolecreatures.com/the-duskbloods-hands-on-preview/
- Yahoo network test impressions: https://tech.yahoo.com/gaming/articles/duskbloods-youre-quick-youre-dead-150000942.html
- Fextralife Game Mechanics: https://duskbloods.wiki.fextralife.com/Game_Mechanics
- Nintendo Life first impressions: https://www.nintendolife.com/previews/first-impressions-network-issues-aside-the-duskbloods-could-wind-up-being-really-special
- Gaming Trend network test impressions: https://gamingtrend.com/impressions/the-duskbloods-network-test-impressions/
- Destructoid network test impressions: https://www.destructoid.com/duskbloods-network-test-impressions-switch-2/
