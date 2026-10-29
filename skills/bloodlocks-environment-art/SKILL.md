---
name: bloodlocks-environment-art
description: "Research, model and critically review original Gothic environments for BloodLocks in Blender and Roblox Studio, including architectural depth, sculpted stone, materials and scene composition."
---

# BloodLocks environment art

Use this for the manor, yard and related original environmental assets. Read [the project brief](references/bloodlocks.md) before editing a shared scene. Consult [the research notes](references/research.md) for the modelling/material decision being made. This is a workflow and quality rubric, not a claim of artistic mastery.

## Authorship and coordination

Use the owner's installed Blender. Make geometry, sculpted detail, materials and foliage ourselves. Existing BloodLocks assets made by this team may be reused. Do not download free models, stock material packs, scans, paid assets or generated meshes. Studying another artist's work does not authorize adopting their asset-acquisition workflow or paid software.

Read current Git team notes and inspect the live Studio place/mode before game edits. Keep editable masters outside generated workspace.Vigil. Coordinate art ownership in Git; do not overwrite Claude's gameplay, menu or Victorian work. A study or rejected prototype must never be described as owner-approved final art.

## Diagnose the actual weakness

Separate three problems before changing an asset:

- **Form:** silhouette, proportions, wall thickness, true openings, reveal depth and connection logic.
- **Surface:** stone scale, wear, roughness, texture density, normals and material identity.
- **Composition:** focal hierarchy, camera, foreground framing, value groups, light direction and atmospheric depth.

If a clay render is flat, fix geometry. If an edge is smooth in silhouette, a normal map cannot repair its contour. If the shapes work in clay but disappear in engine, inspect lighting, maps and shading before adding more geometry. Do not answer “too smooth” by scattering noise everywhere.

State one specific improvement and how it will be judged. Inspect the actual result before generating the entire building again.

## Research and translate

Use owner references first, architectural references for construction, artist-authored breakdowns for production decisions, and official Blender/Roblox documentation for API behavior. Record what was read and what was inferred. Do not claim to have watched footage from reading a transcript.

Break a reference into silhouette, large/medium/small forms, depth layers, material families, warm/cool balance, value groups and environmental framing. Distinguish a visible image feature from an invented unseen floor plan. Draw a section/profile when depth is the issue; a front elevation alone can conceal shallow geometry.

Use artist techniques as principles adapted to Blender and Studio. Do not copy their brush packs, scans or models. Existing primary-source research is in the linked notes; browse again for changed APIs or new uncertainty.

## Model depth deliberately

Develop primary masses, then architectural profiles, then localized sculpting.

For a Gothic window or doorway, explicitly examine the wall thickness, external frame, recessed reveal, secondary arch order, hood/drip edge, sill projection, mullion/tracery and recessed glazing. Choose the layers the reference justifies. They should make different shadows and silhouettes, not merely occupy parallel lines on one plane.

Model mouldings from meaningful cross-sections: changes between flat fillet, convex roll and concave recess matter more than adding many identical bars. Terminate arches, ribs and columns at plausible receiving points. Tracery must meet frames and mullions; do not leave ornaments floating.

Create openings and negative space, not black shapes pasted onto solids. Inspect roof valleys, flashing, eaves, chimney seating, stair headroom and door clearances. Repeating a misplaced profile multiplies the error.

Use bevel widths proportional to the material and actual asset scale. Preserve broad stone planes. Uniform large bevels, indiscriminate subdivision and smooth shading can make masonry inflatable. Weighted normals change shading; they do not replace a physical profile.

## Sculpt age with causes

For stone variants, preserve the main volume and load-bearing contacts, then work on selected corners, fractures, tool marks and surface loss. Prefer irregular planes and a few meaningful chips to equal wear on every edge. Keep intact and damaged variants.

Use Blender sculpting/multires or explicit geometry where the detail changes silhouette, contact or close-range shadow. Use baked normals for smaller relief that does not need those effects. Apply sparse displacement through masks; unmasked noise over the whole building is not weathering.

Put soot near combustion, runoff beneath exposed ledges, damp near foundations, wear on traffic edges, and growth in sheltered seams. A trim asset, old exterior wall and sheltered interior stone should not have identical damage.

## Materials and colour

Set a consistent physical texture scale before comparing assets. Keep albedo largely free of directional lighting. Use sRGB for colour maps and non-colour data for normals/roughness. Verify OpenGL tangent-space normals and imported tangents in Studio.

Review stone, timber, iron, slate, glass and wax as separate substances. Material roughness is not geometric depth. Wet patches are local; do not turn an entire Gothic building into glossy plastic.

Use neutral light to judge material colour, then the intended cool-night/warm-fixture balance. Do not bake blue night illumination into stone colour to compensate for a weak lighting rig. Compare the same object in Blender and Studio; a tone-mapped Blender beauty render does not prove engine equivalence.

For PBR maps, verify actual rendering. White/blank output is a failed material test even when IDs exist. A diffuse-only fallback must be labelled as such. Do not diagnose asset privacy from a single generic preload failure.

## Compose an environment

For the supplied manor reference, prioritize the approach, long roof, slender tower/red-moon relationship, side-tree framing, uneven foreground and layered mist. Keep a readable ground plane and entrance. Large black areas and broad purple cloud bands do not automatically establish atmosphere.

Work in large value groups before small colour accents. Use warm pools for occupation/interaction, cool illumination for exterior form, and limited atmospheric separation for distance. Break repetition with purposeful silhouettes, wear and scene placement rather than random rotation.

Judge at the actual player camera as well as the hero angle. Preserve routes, duel/practice space and station readability. Do not hide awkward junctions with dense fog or foreground props.

## Review before replication

For a new architectural standard, produce evidence appropriate to the problem:

- Neutral clay and grazing-light views, including an oblique or section view that exposes depth.
- Material review with colour and roughness separated, then the same asset under intended night light.
- Close, player-distance and broader scene views.
- Studio verification of scale, pivots, normals, openings, seams and map rendering.

Reject a module if it only looks detailed in a close beauty render, reads as a flat frame from player distance, has uniform rounded edges or relies on noisy stone textures to look old. Iterate that module before spreading it. Continue authorized work autonomously; ask the owner only where their artistic choice is needed. Never infer acceptance from silence.

Record the files, actual changes, unresolved weaknesses and next decision in Git. Keep source and rollback assets. Do not overwrite existing unsaved Blender work; use a separate scene/process or explicitly saved project.
