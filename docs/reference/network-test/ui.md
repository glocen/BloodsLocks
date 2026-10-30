# UI: every screen and HUD element

Every screen, HUD element and notice seen in the first full playthrough (0:00–52:23). **OBSERVED** unless labelled; times are source positions, with the full frame cited where one was pulled (`build/reference/network-test/frames/ui/`, local). Our UI follows this structure as closely as the IP rules allow (owner: "95% or 99% is fine but not 100%"), in our own art, words and icons; see [takeaways.md](takeaways.md).

## 1. The style, everywhere

- **Type:** a serif throughout, warm white, mostly small. Big statements in a larger serif; banners in **wide-spaced serif capitals** ("PHASE", "PHASE END", "GRAIL BATTLE").
- **Panels:** warm near-black, translucent over the darkened, blurred world; **thin hairline borders in dim gold-brown** with small corner ornaments. No heavy boxes and no big buttons.
- **Colour:** red only for blood things (HP, the Virtue medallion, skills, counts); gold for category icons, objectives and highlights; everything else desaturated.
- **Medallions:** round and ornate: a red ring of glyphs for Virtue; a thorned silver ring for rank; roman numerals in rings for phases, joined by hairlines.
- **The band:** the big statements ("You survived the culling", "You Are Defeated", "Trespasser Felled") sit in large serif on a **full-width dark translucent band whose ends fade out**, over the live world.
- **Motion:** fades and slow slides (portrait cards slide in one by one); no bouncing. Countdown digits turn red near zero.
- **Hints:** controller glyphs with short serif labels, centred at the bottom ("Decline · OK").
- **The HUD frames the corners and leaves the centre clear.**

## 2. The HUD in a match

Reference frames: 13:48.5 (bare), 35:16.2, 36:07.2, 44:35.3, 48:33.3 (full).

**Top left: the hunter**
- **The Virtue medallion:** a round dark medallion ringed in red like a notched gear, the match's Virtue inside in white serif. It turns red while you're below the cut (MANUAL 44:04). **In the final it shows two candle-flame marks instead: your lives** (50:18).
- **"Lv. 19"** in small serif with a hairline running right; XP gains appear beside it ("+963", "+4241").
- **The HP bar:** long, red, thin-framed; fresh damage shows as a **pale lag segment** that drains after the hit (36:07.2). In the final the bar is longer and its bonus part a lighter pink (50:18).
- **The stamina bar:** **green**, shorter, just under the HP bar (confirmed by the owner, 2026-10-30).
- **Powers of Blood:** a row of small square icons under the bars, each with a small white up-triangle (35:16.2, 48:33.3).
- **The kin row:** a round **portrait medallion of the kin's face** in a gold frame, the kin's name and level in serif ("Valentius the Unwise Lv. 2"), its XP gains, and a thin HP bar under the name (36:07.2).

**Top centre**
- **The compass:** a curved ruler of ticks with cardinal letters (E, SE, S…) and a caret under its middle (14:52 on). Objective markers sit on its edge in their direction: a gold flame-like icon (a pledge pillar or goldstone) and a red one (a redstone) (crop at 42:30).
- **The notice slot** under it: Virtue toasts (the category's gold icon, the amount in a red ring, the category's name on a dark strip that fades at both ends; 14:55); "Left Ritual Site", then "Ritual Site Exit Damage" with a thin draining bar (42:24–43:30).
- **A great foe's bar** when fighting one: its name in serif over a long red HP bar with a gold stagger line under it, and the running damage total at its right (14:52, 36:07.2).

**Top right: place and time**
- **The area's name** in serif with a hairline running left under it, and a small **region-feature icon** beside it (a purple "i" in one phase, a red badge in another; MANUAL 35:09).
- **The clock:** a large **circular dial** cut off by the corner. A hand sweeps a ring of ticks toward a red dot on its rim (the phase's end); a shining dot marks the ritual site's opening; a pendulum glyph hangs under it. After the site opens, and in the last minute, a number counts the seconds down in its centre. States in [match-flow.md](match-flow.md).

**Left middle: objectives**
- A short checklist: small square checkboxes and serif lines ("Go to the ritual site", "Obtain redstone or goldstone", "Earn Virtue at a ritual site"); done items are ticked (13:55, 48:33.3). Hints for new controls appear under it ("Hold Y: Function Menu").

**Bottom left: weapons and items**
- **Ammo:** a bullet icon, "40/40", and a segmented tick bar.
- **Stakes:** a small red shield banner with the heal count; it rises with Goldblood and falls with each heal.
- **Two round emblems** joined by an ornamented stem: the **skill** (its glyph and uses, "4/4"; a small inset at its lower left shows the other skill) and the **quick item** (its icon and count, its name in serif beside it; an inset shows the next item). Small arrows at both sides cycle them.
- Small icons above the ammo (an oval ring, a goblet; purpose unconfirmed).

**Bottom centre**
- **The posture bar:** a thin red line with a **yellow-gold segment growing from its centre**, under the hero, while it fills (confirmed by the owner, 2026-10-30: the yellow bar is posture).
- **Requests and notices:** compact strips with a small emblem on top: the co-op request (two hold options), "Alliance requested" (Check · Close), sigil notices, "Left co-op battle".
- **Subtitles:** small white serif, centred low, no box.

**Right edge**
- **Pickup tips:** the item's name in serif, one line of description, a count, "Pick up" (7:44).
- **Item notices and Power toasts:** the name and icon on a dark strip that fades to the left; they linger while you move (8:00, 15:10).
- **Progress notices:** "Required level achieved" with the skill's name (24:43).

**Over targets (in the world)**
- **Ordinary foes:** a thin red HP bar over the head, the running damage total beside it (3:32).
- **Rivals:** the name in red serif over the bar; a counterpart's role ("Sworn Enemy") in small red above the name (28:21).
- **Lock-on:** a circular reticle on the target (6:18).
- **Interaction prompts:** a red ring around the button letter and dim serif text, by the object ("Swear to the blood pledge pillar", "Gain Power of Blood", 14:55).
- **Allies** (co-op partners, the kin, thralls) get a thin pale outline.

## 3. Banners and bands

| Element | Layout | Seen |
|---|---|---|
| **"PHASE" / "PHASE END" / "GRAIL BATTLE"** | Wide-spaced serif capitals over (or through) a round medallion holding the phase numeral or a red moon; thin hairlines run out to both sides; a thin arc over the word | 13:48.5, 36:47.5, 50:18 |
| **Statements on the band** | Large warm serif on the full-width dark band: "You survived the culling", "You were beckoned by the grail", "You Are Defeated", "You are the Victor of this Fleeting Dusk", "Trespasser Felled", "Training Battle Completed" | 36:47.5, 49:38, 38:39.5, 51:42, 17:05.5, 19:25 |
| **"Ritual Site Established"** | A long thin gold hairline across the screen; two concentric arc brackets close on the text from both sides, glowing yellow | 17:27.5 |
| **"1 Minute Remaining"** | Small serif centred in the upper middle on a thin hairline | 35:45 |
| **The Virtue breakdown** | Under "PHASE END": rows of gold category icon, red-ringed count and name, joined by a thin red vertical spine; a hairline; the phase's total; the match total in the big red medallion at the bottom centre | 36:56.5 |

## 4. Screens

**Title, terms, loading** (0:00–0:36): the logo upper centre over black, a low band of glowing amber cloud, "Press any button"; a status line with a spinner at the top right; the terms in a dark framed panel; **loading is black with a small red ritual emblem turning in the lower right**.

**The hub menu** (12:29–12:59, 52:04–52:09):
- **Top bar:** tabs in serif, Dusk Battle · Bloodsworn Selection · Battle Remembrance · Archive · System, switched with the shoulder buttons; the current tab sits in a lighter box with corner ornaments.
- **Left column:** a narrow list under a small label; each row a thin translucent strip; the selected row lighter with a thin border; finished items carry a checkmark.
- **Right panel:** the title in serif, a wide illustration in a thin frame, two short paragraphs.
- **Modals:** a dark bar, the question centred, OK · CANCEL as small bars.

**Bloodsworn Selection** (the class screen; 52:09, 52:12.5):
- **The roster:** "Bloodsworn Selection" top left on a dark band; **six tall portrait panels side by side**. Each panel: the name centred at the top on a dark strip, a faint crest ornament behind the head, a waist-up render on a dark red-black field, a "No Sigil" strip, and the sigil row (a small square icon and the sigil's name). The focused panel shows small up and down arrows to change the sigil.
- **The detail view:** the hub's tabs at the top; at the left the character's name and a selected row; **a large render in the centre**; at the right three groups under small ornate glyph headers: the armament (one row), the two skills (icon rows; a level requirement in red on the icon), the two aspects; "Equipment/skill details" at the bottom right.

**Travel between hub rooms** (13:06): a small list at the top left ("Hall", "Courtyard"), a preview picture at the lower left, OK · Close.

**The intro card** (13:34, 29:30): a painted matte of the map filling the screen; "Dusk Battle" small over the mode's name in large serif at the top left; tall portrait cards side by side, sliding in one by one; the player in colour, the rivals dark (in the full match, silhouettes).

**The info screen (the map)** (full frames 14:06, 20:23.2, 44:07):
- **The world stays visible, heavily darkened, behind it.**
- **Top left:** the player's name in a long dark strip ending in a gold compass-rose emblem; under it the Virtue breakdown (the red medallion with the total, then five gold category icons, each over a small ring with its count).
- **The standings:** a small round class sigil, the name in serif (the player's own in pink-red), and each hunter's Virtue in a red ring at the right; a rank number at the left of each row. A hunter below the cut shows dimmed and red.
- **Top centre:** the phase strip, medallions I · II · III and a red moon (the final), joined by hairlines; the current phase haloed; under each, a small ring with how many entrants it admits.
- **Centre, the map:** a **sepia, desaturated relief** of the city from above, cut out against the dark; region names as serif labels on hairline leaders; the player as a gold ring marker; the cursor a ring reticle with four ticks; icons for the ritual site, pledge pillars, trespassers (a pink skull) and travel points.
- **Right:** a column of slots (sigils and goals) and a large frame for the selected item's details.
- **Bottom:** the legend (Legend · Zoom · Pin · **Change depth**: the map has floors) and the mode's instruction.
- **Modes:**
  - **browse** (the default);
  - **start area** ("Select starting phase area"): one soft circle per region with a pale rim, the focused one gold, the countdown in the dial;
  - **revival** ("Select revival point", 38:44).

**Tutorial cards** (4:08 and throughout): a large framed dark panel; the title centred at the top; a text column at the left; an illustration at the right; page dots and arrows at the bottom; Close at the bottom right.

**The reward choice** ("Select what to receive"; full frame 15:01):
- the title on a dark band at the top centre between two fading hairlines;
- **two large choice cards stacked at the left**: dark wine-red panels with a thin border; a square illustrated icon (a small white up-triangle in its corner for a boost); a small category label, the name in larger serif, a hairline with a tiny diamond; one line of description; the focused card brighter;
- **at the right, "Power manifested":** five rows; the focused choice shown in place, empty slots as "-";
- Decline · OK at the bottom; the world dimmed behind.

**The skill enhancement choice** ("Select Bloodsworn skill to strengthen"; 31:18, 43:07): two wide dark cards, each with the skill's icon, its name, the stat and its old and new values (the new value in green with a small up arrow); "Do not enhance" · OK.

**The inventory** (8:48, 42:11): two tabs ("Powers of Blood" | "Quick Items"), a row of square slots, a details panel with the name, description and count, the list of held items; "Unmanifest" at the bottom right.

**Game options** (8:45): a dark list with category icons in a column at the left; values right-aligned; sliders as thin lines.

**The culling card** (44:04.5): a rules card with a standings illustration: the player's row and number in red, a big medallion with the number in red.

**The finalists card** (49:55): at the left, the final's event card (its face turning to show a crimson moon emblem, its name and two lines of lore); at the right, three tall portrait panels side by side, each finalist's Virtue in a red medallion below.

**The Outcome screen** (19:34.5 after a tutorial; 51:52.5 after the full match):
- **Tabs** at the top: Outcome · Dusk Record (the record of placements and the Bloodsworn met).
- **The winner's mark:** a **gold grail** with a red gem under a gold sunburst (51:52.5); after the tutorial, the rank "1" in a thorned silver medallion with a red line falling from it (19:34.5).
- **Virtue:** the total in the big red medallion; a **thin red spine** links five rows (a gold diamond category icon, a red-ringed count, the category's name on a faint strip).
- **The character:** a large 3/4 render filling the right half, over a dark red-black field with faint red vein cracks.
- **"Return to the House of Night"**: a dark button with a thin border at the bottom right.

## 5. Unconfirmed

- The small icons at the bottom left (an oval ring, a goblet): their purpose isn't clear from these frames.
- The Dusk Record tab's layout (not opened in this footage).
