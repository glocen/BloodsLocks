# Manor depth: art implementation checkpoint

29 October 2026. This is an original design candidate and a tested Blender export, not owner-approved finished art. No Studio geometry or scripts were mutated by this task.

## Source truth and fit

- Main source repo: `C:/Users/gloce/BloodsLocks`; world generators in `worlds/Manor`, original authoring scripts in `tools/art`, saved source under `assets/manor`.
- The long roof and slender shoulder tower remain the exterior identity. Two playable storeys, timber floors, red runners, the Blood Table and rear yard remain functional constraints.
- Hub origin `(0,0,-1000)`, north `-Z`. Wing footprint spans approximately `X ±142.5`. Wing façades have true apertures and 32 corrected layered windows.
- Current porch source has roof `X ±18`, local `Z 61..87`, eave `Y30.5`, ridge `Y46.5`; four columns at `(X±14, Z65/84)`, shaft1.75² and base2.9². Live Studio read-only inspection confirmed roof and support sizes.
- Gallery floor source `Y31.9125`; great-hall ceiling envelope `Y78.66`. Sketches use those source anchors; their perspective is schematic, not a measured reconstruction of Duskbloods.

## Authored files

- `manor-arrival-study.svg/.png`: low diagonal, framed sides, readable uneven foreground, slender tower against a restrained red moon, one warm occupied doorway.
- `manor-hall-study.svg/.png`: dark timber fields, stone supports, gallery depth, low warm Blood Table, cool rear-yard doorway.
- `manor-depth-sections.svg/.png`: porch elevation and meaningful section profile.
- `build_manor_depth_study.py`: entirely original Blender script. `porch/` has editable .blend, FBX, evaluated mesh JSON, manifest, neutral/night/clay renders.
- `assemble_depth_proposal.py`: composes a new copy of our existing manor assembly with the new arcade. It never saves over either source. Its `assembly/` output remains a Blender composition study.
- `batch_export.py` and `import-batch/`: finalized single FBX with porch, one original Pine03 close master, one reduced distant pine master, and one wing-scale buttress. All geometry derives from our originals. The batch is not Studio placement.

## Specific production improvement

The previous porch uses thin isolated columns supporting a timber gable. The new arcade makes an occupied threshold with a clear20-stud opening,26.3205-stud pointed apex,6.5-stud reveal and1.82-stud maximum front projection including feet/fixtures. It fits under the existing30.5-stud eave; max module height29.435. Evaluated bounding size is33.4 wide ×8.32 deep ×29.435 high.

The section alternates an inner reveal, small convex roll, recessed fillet, wider convex roll, shadow channel and projecting drip hood. Radial voussoirs use that complete profile. Jamb courses continue it to the ground. Clustered receivers and stepped side buttresses provide a receiving structure; the hood is not floating trim. Plain broad stone faces remain, with sparse outer-edge chips. Two small iron lanterns provide a believable warm source.

This is a geometry-first study. Plain authored materials allow depth to be assessed. It has no baked ageing/PBR claim. The night render uses the identical geometry/materials with cool fill and warm lantern pools.

## Import and placement

1. Do not open or overwrite the owner's unsaved Blender scene. The supplied file is separate.
2. Take a backup of `VigilKit`, generator source, live root and lighting before integration. Keep the old imported shell and new master separately.
3. Use Studio's actual3D Importer with the FBX. Existing manor import used `.01` normalization and a Y180 correction; verify this new module's measured bounding size rather than blindly applying that history.
4. Source module coordinates are Blender `(X,Y,Z)` with X across the route, Y inward and Z up. Intended Studio mapping is `(X,Z,-Y)`; module origin is world `(0,0,-916)`, i.e. manor-local `(0,0,84)`.
5. Semantic export has17 mesh groups,36,322 triangles total, max12,922 in one group. Arch halves were split to stay below the20k-per-mesh project guideline. Lamps are original meshes, not imported assets.
6. Clone into an editable master `ServerStorage.WorldAssets.VigilKit.PorchArcade`. Apply through a new WorldTools generator after exterior/composition placement. Keep mesh collision off; use existing route/floor collision. No game API or Rojo-owned source needs changing.
7. Start by retaining old columns for an engine fit comparison. The old four-column shaft/base/capital groups are merged meshes, so do not delete them assuming they are one front column. If replaced, explicitly author rear supports at X±14, localZ65 before removal.
8. Preserve `workspace.Vigil.GreatHall.ManorHall.BloodTable` exactly and keep one combat-zone tag and one pact tag. Master/backup copies must not carry active runtime tags.
9. Cold-require the modified builder, rebuild twice, compare tag counts, routes, master presence and module counts. Test both stairs, gallery entries, porch center and rear doorway with actual player input; a screenshot does not prove traversal.

There is no existing headless FBX-upload/import helper in `tools`. The earlier imports used Studio3D Importer. `Vigil_PorchArcade_meshes.json` contains the exact original evaluated vertices/triangles as a fallback transport, not proof that Roblox has published mesh assets.

## Review and limitations

- Neutral render: genuine recess width and projecting outer orders read clearly. Right oblique exposes the6.5-stud tunnel depth; this is stronger than flat bands on a wall.
- Night render: small warm pools and cool main forms are visible. It is a Blender test, not equivalent engine lighting.
- The initial bracket function rotated world-space vertices around the origin, creating stray slivers. Corrected by building beams at local origin before applying translation/rotation. Rerendered exports use the fixed geometry.
- Initial arch grouping exceeded20k triangles. Split left/right semantic groups and rerendered; total detail preserved.
- The profile is still quite regular and stone is still clean. A restrained ageing bake plus a few unique hand-shaped breaks remains necessary; do not mask that with noisy global textures.
- The whole manor still needs uneven ground, deliberate original tree framing and controlled atmospheric layering. The approach drawing specifies them but is not built terrain.
- A portal alone cannot solve every flat wall. Use it as the reviewed threshold unit, then vary major wall massing and selected buttress bays rather than repeat it32 times.
- Exact moon/sky work, material maps and Studio lighting are root-task work. This task did not assert they were done.

## Final import batch and foliage review

Final import path: `import-batch/BloodLocks_ManorDepth_Pine03_Batch.fbx`,28,589,484 bytes,92 mesh groups,544,667 triangles total, max12,922 per group. SHA256 `fc7a98f126dbde55e4613f394d0f378d7be79eca3db75ebbcfb0919f912abfdf`. The .blend beside it is the editable batch copy. Offsets are staging offsets only:

| Prefix | Blender X offset to remove | Groups / triangles | Intended use |
|---|---:|---:|---|
| `BL_Porch_` |0|17 /36,322|One front porch threshold, manor-local origin(0,0,84)|
| `BL_Pine03_` |80|68 /474,492|Two close silhouette framers, verify actual engine cost|
| `BL_PineFar_` |220|5 /33,297|Distant outline/framing; labelled LOD study|
| `BL_Buttress_` |140|2 /556|Selected wing supports, not universal repetition|

The original Pine03 source remains `C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_Pine_03/Vigil_Pine_01.blend`. The trunk is86 studs; needle extent reaches88.95. Its branches carry separate supported sprays, creating a convincing irregular outline, but it is extremely dense and has no LOD/runtime signoff. The far variant keeps the original branching, welds/simplifies bark to12% and retains6% of original needle triangles deterministically. Deletion alone was visually rejected as too bare. Retained original needle cards were then broadened8× and lengthened1.13× to recover canopy mass; the second actual render preserves a similar branch silhouette while visibly using coarse cards. It has five groups and33,297 triangles. The actual side-by-side PNG is `Pine_full_left_far_right_comparison.png` (full left, far right, buttress in middle). Use the far master only at distant screen coverage, approximately≤200 pixels tree height; do not call it equal close quality. Single needle triangles may require two-sided rendering in Roblox; inspect before mass placement.

Wing buttress master is3.4 wide ×7.62 projected ×63.99 high, scaled vertically from the original porch shoulder profile. Pivot is at ground/back face. Suggested placements are front wing X±64.5 and±141, base at localZ21.75, with projection facing outward. These avoid the32 window openings and add structural shadow at selected ends/junctions. Keep collision off and inspect intersections. Do not place them across the front porch or training routes.

All sketches, standalone renders and the whole-manor Blender copy were inspected. The latter confirms the arcade sits beneath the retained porch roof, but the central broad wall still lacks enough hierarchy and the whole view lacks landscape. Do not describe a threshold improvement as a finished manor rebuild.

Final state: root's attempted Studio import was interrupted by physical Escape before the importer dialog; no new asset was imported, no place was rebuilt, and no further app interaction followed. All supplied sources and render outputs are saved. Continue from the finalized batch when computer use is authorized again.

## Resume

Inspect neutral, night and clay images. Import/fit the FBX into ROLOCK, test center passage and hero/player views, then integrate idempotently into the world builder. Reassess whether front columns can be simplified. Keep this candidate separately until the owner's artistic review; never label it approved based on silence.

