# The Vigil: larger estate layout

Owner direction, 2026-10-29: the current manor and yard are placeholders, too small, and must improve. Two usable floors, timber floors, red carpet and an outdoor training court remain. Finish building before a wider sky/contrast/reddish-window-lighting pass. Remaining animation work is deferred; LightBeam 135123828939357 is installed.

## Layout pass

- Enlarge the architectural shell by 1.5: central hall 120 studs across, two floors with gallery at27. Wings follow the same layout transform.
- Keep the Blood Table and hand-use furniture at R6 scale. Keep the exact ManorHall.BloodTable lookup path used by MenuController.
- Re-lay normal-width ground-floor boards so architectural scale does not produce giant planks.
- Yard: 240 wide, training bounds from64 to340 studs north of centre. Manor ends60 north, so the tagged combat box stays outside the house.
- Duel centre (0,-185), dummy line(-90,-280), pact(86,-280), movement courseNW and ruinsE. Preserve8/16/24-stud training ledges. Bell tower beyond the north boundary at-370.
- Back up the current root and generator before applying; integrate the layout through Build() and Spots(). Verify tag counts, safe-house/training membership, station path, both floors, routes and a rebuild.

## Research applied

[Roblox: Beyond the Dark architecture](https://create.roblox.com/docs/resources/beyond-the-dark/building-architecture) supports proving scale/layout with Parts and then updating reusable meshes/materials. [Modular environment assembly](https://create.roblox.com/docs/tutorials/use-case-tutorials/modeling/assemble-modular-environments) explains stable pivots, coherent kit dimensions and variation. The octagonal angles stay computed rather than forced onto a square grid.

[Roblox Blender export settings](https://create.roblox.com/docs/art/modeling/export-requirements) are the technical reference for the custom kit. Check physical dimensions after import; an attractive Blender render alone is not proof of a successful Roblox asset.

[Official Duskbloods manual](https://campaign.theduskbloods.jp/manual/en/basic1.html) and docs/duskbloods-manual-summary.md remain gameplay context. They establish the base/preparation and match flow; they are not proof of an unseen manor floor plan. House of Night is the artistic target; the current estate is not accepted final art.

## Blender follow-up

First custom review piece: deep stone lancet with continuous mouldings, proper tracery, bevels, UVs and separated glass/iron. Use our own geometry/materials and free installed Blender. No paid assets or AI-generated Roblox meshes. Review under neutral and intended dusk light before repeating. Full roof forms, manor exterior, courtyard ground/vegetation/ruins and richer material storytelling remain required.
