# North star: Duskbloods reference vs BloodsLocks (2026-10-29)

The owner's north star: these Duskbloods shots show where we aim. Not a 1:1 copy; once we're close we'll diverge. Reference shots: the annotated in-match HUD (A–T, see ui-research.md 2c), the region-pick map, the House of Night menu, the phase clock, a ritual site, the Virtue art. Compared against our Manor yard HUD capture (Lv. 1, Kurogane summoned).

## What makes the reference premium

1. **A world lit like a painting.** Warm candle-orange against cold violet stone, deep blacks, enormous vertical gothic silhouettes.
2. **UI that barely exists.** Thin bars, a serif typeface, no frames, everything pushed to the corners; the centre is for the fight.
3. **Every system is an ornate object.** The phase clock dial, the painted map with glowing region rings, the golden pledge cross.

Our HUD layout already matches. **The biggest gaps are the world, the characters and the ornate objects**, more than the HUD.

## Findings

| Finding | Severity | Fix | Owner of the fix |
|---|---|---|---|
| Kurogane stands between the camera and the fight (a huge black block on screen) | Critical | Follow beside or behind the master, never in the camera's line | Claude (code) |
| Default Roblox avatar ("make a free account" shirt) | Critical | Gustave's own look: an R6 rig with an outfit | Owner / ChatGPT (Blender) |
| Blood Table menu dims the world and shows 6 big cards | Moderate | House of Night pattern: world visible, character on a blood circle at centre stage, thin top tab ribbon, a small mode card top-left, button hints bottom-right | Claude (Step 9a) |
| Region pick planned as "icons" | Moderate | 3+ glowing circles over a top-down painted render of the map; the chosen one turns gold with thorns, plus a reticle cursor | Claude (match flow) + a map render |
| No phase clock yet | Moderate | Layered drawn images: ring, ticks, dagger hand, a gold dot (ritual site), a red dot (phase end) | Claude (match flow, `tools/` textures) |
| No target info over the locked enemy | Minor | Red title + name + thin HP bar over the target, plus a white diamond glint | Claude |

## Rules to keep (from the reference)

- **Colour meaning:** red = blood, HP, danger. Gold = holy, objective, selected. White = neutral info. Our skill medallions' gold rims break this; make them dark blood-iron.
- **Weight:** slots are dark and matte, and nothing in the HUD is brighter than the fight. Shrink our skill medallions by about 20%.
- **Text over the world** always sits on a dark ribbon. Body text ≥ 14 px after UIScale (Roblox players are often on small screens).
- **Never colour alone:** gold vs white region rings differ by pattern too (thorns).

## Priorities

1. Characters + light before UI: a real Gustave look, and a warm candle/brazier key light in the yard against the cold violet.
2. Kurogane follow fix.
3. Menu redesign to the House of Night pattern (Step 9a).
4. The match's ornate objects, built with the match: clock, region map with rings, Virtue medallion (a big number).
5. Target info + lock glint.
