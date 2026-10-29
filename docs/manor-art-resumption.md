# Manor art direction and resumption notes — 2026-10-29

## Owner direction (binding project preferences)

- Duskbloods' House of Night is the atmosphere target. The owner-provided exterior image is the controlling composition reference; do not invent its provenance.
- Use the owner's installed Blender. All game models and material maps must be our original work. No downloaded free models, stock material packs, paid services, paid assets or AI-generated meshes.
- The manor has two usable storeys, taller ceilings, timber floors and red runners. Keep the rear training yard, movement course, dummy stations and pact usable.
- The present manor is structural work. The owner rejected its texture as horrendous and the previous lighting as worse. Neither materials nor lighting is approved final art.
- Claude is working on game engineering/UI and the Victorian place. Our current ownership is ROLOCK manor art. Read current team notes before touching a shared generator. No unsolicited gameplay/UI changes.

## What the exterior reference actually shows

A low, angled approach toward a long Gothic building. A slender tower/spire rises left of the long roof, with the red moon behind it. Dense dark trees frame both sides and break the silhouette. Blue illumination reveals roof edges and stone, while a very small warm entrance pool provides contrast. Uneven pale ground, foreground stone markers and low mist establish foreground, middle distance and background. This framing/depth matters as much as the building.

Do not replace that hierarchy with a centred architectural catalog render, an isolated building on a rectangle, broad purple cloud bands, black ground, or local lights that look like blue flashlights.

## Immediate quality problems to solve

1. Native noisy stone is visually uniform and overwhelms architectural forms. Author restrained coursed masonry: sensible stone dimensions, recessed joints, small physical bevels and subtle face variation. Keep normal strength low on broad faces.
2. Roof slate needs consistent scale and believable broken edges/overlaps; avoid tiny specular speckles or glossy black plastic.
3. Window reveals, radial arch stones and connecting mouldings need depth. Ornament must meet something and have a structural reason.
4. Add weathering by cause: runoff below sills, damp at foundations, soot at chimney mouths, growth in neglected seams. Avoid global dirt noise.
5. Establish readable ambient/sky value structure before adding more accent lights. Preserve blue stone/roof separation and warm entrance contrast without crushing terrain to black.
6. Build deliberate foreground/side framing and terrain layers. Forest, mist and ground details are not finished.

## Actual saved work

- Original Blender source: tools/art/build_manor_reference.py. Editable local model: C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_ManorExterior_04/Vigil_ManorExterior_04.blend.
- Imported 195-mesh master: ServerStorage.WorldAssets.VigilKit.ManorExterior. Blender FBX importer used scale factor 0.01. Rotate Y 180 degrees to align Blender X,Y,Z with manor Roblox X,-Z,Y; normalized master pivot is ground-centre at origin.
- Placement: WorldTools.VigilExterior; live root workspace.Vigil.ManorExterior. It replaces wing wall/roof shells and porch roof/columns while retaining playable floors, furniture and station hierarchy.
- First stone relief: workspace.Vigil.ExteriorStonework, 1700 native parts. This does not mean artistic acceptance.
- WorldTools.VigilEstateLandscape adds terrain and hides the old rectangular ground's rendering while keeping its collider. Terrain is still too dark in the composition.
- WorldTools.VigilExteriorLighting is a provisional cool/warm lighting rig. Not accepted.
- 68 original melted candles remain under their existing fixture parents. Their master folder is VigilKit.MeltedCandles.
- Pipeline: graybox -> bay -> threshold -> manor -> estate layout -> atmosphere -> candles -> exterior -> landscape -> exterior lighting.
- Final last-session cold rebuild verified exterior, 1700 detail parts, 68 candles, BloodTable path, one combat zone and one pact tag. It did NOT verify final traversal after shell replacement.
- Menu path must remain workspace.Vigil.GreatHall.ManorHall.BloodTable.
- Terrain rollback snapshot: WorldTools.Backups.Terrain_PreVigilLandscape_20261029. Corner attributes store voxel coordinates. Other root/lighting/source backups are also in WorldTools.Backups.
- Owner materials review images: Pictures/Screenshots/Capture d'écran 2026-10-29 041156.png and Temp/codex-clipboard-f302f27d-9ec2-489f-a615-56ee5b873c50.png.

## Current original material/window study

Local folder: C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_MasonryStudy_01.
Authored stone and trim albedo/roughness/OpenGL normal maps; an original Blender window module with real aperture, bevelled jamb courses, radial voussoirs, recessed glazing, connected leadwork and one of our own candle models. Neutral and blue-night renders use the same materials and geometry. Review before spreading the material across the manor. FBX/material import and production UV validation remain to be checked.

## Workflow findings to retain

- Test materials under neutral light first, then the intended night light. Do not bake the night's blue tint or direct-light shadows into albedo.
- Colour maps use sRGB; normal/roughness maps are non-colour data. Roblox expects OpenGL tangent-space normals.
- Stone is non-metallic. Separate surface roughness from geometric relief. Glossy wood and worn wood need distinct roughness responses.
- AgX is a review transform; a beautiful Blender render is not proof of identical Studio appearance. Compare the same object/camera and do not transfer only display-grade colours.
- Apply model scale before bevel review; use small deliberate bevels and inspect shading/normals. No soft inflatable stone.
- Export only intended geometry. Keep scene lights, ground planes and fit guides out of Roblox exports. Our first central hall wall in Blender is a fit guide, not the live carved hall shell.
- Avoid retaining evaluated Blender material IDs after to_mesh_clear; use source.data.materials. That caused a Blender crash in the first exporter and is fixed.
- ScriptEditorService.UpdateSourceAsync callbacks must return only the new string; string.gsub returns TWO values, so store its result in a local before returning.
- Require caches ModuleScript instances. Cold-check a cloned generator after source edits.
- Under Server Authority, teleport for tests from Server context. Client CFrame writes get overwritten. Repeat both stairs/upper-wing entrances and the yard route after shell/material integration.
- MCP ContentProvider callbacks have reported Failure even for meshes visibly rendering in Studio. Do not treat that signal alone as a confirmed asset-loading failure.

## Research used this session

- Blender Bevel API: https://docs.blender.org/api/4.5/bpy.types.BevelModifier.html
- Blender colour management: https://docs.blender.org/manual/nl/4.5/render/color_management.html
- Blender Cycles baking: https://docs.blender.org/UATEST/manual/en/4.5/render/cycles/baking.html
- Roblox PBR: https://create.roblox.com/docs/art/modeling/surface-appearance
- Roblox texture specifications: https://create.roblox.com/docs/art/modeling/texture-specifications
- Roblox material references: https://create.roblox.com/docs/art/modeling/material-reference

Read these as engineering references, not downloaded game content. Some /latest/ Blender manual fetches were unavailable; readable official 4.5 documentation was used and API behavior is checked against the installed 5.2 Blender.
