# Research translated into modelling decisions

Sources were read on 2026-10-29. These are primary artist accounts or official documentation. No linked assets were downloaded. Techniques using other commercial software are adapted to Blender; the software/asset choices are not adopted.

## Architectural depth and modular design

[Alessia Verza: Modular Gothic Architecture](https://alessiaverza.com/modular-gothic-architecture/) describes moving from one dense Gothic arch into modular components, shared dimensions and trim profiles, with early engine tests. The useful lesson for BloodLocks is to assess profile depth and lighting in Studio before expanding the kit. A trim system can carry small repeating detail, while the real profiles still establish readable shadow and silhouette. This does not mean that every recess should become a flat texture.

[Angel Fernandes: Gothic Temple breakdown](https://80.lv/articles/gothic-temple-environment-breakdown) describes checking simple asset proportions in engine before sculpting, using consistent texture density, then finishing surfaces and environment dressing. His account also warns that a remeshing approach can smooth away the sharp stone shapes he wanted. For our next bay, preserve hard planes and intentional fractures rather than adding a uniformly rounded edge to every block. His commercial brush/tool recommendations are not part of our workflow.

[Rustam Zhukov: modular Gothic environment](https://80.lv/articles/making-of-a-modular-gothic-environment-with-procedural-systems-trim-sheets-custom-shaders) connects focal planning, modular assets, controlled variation and material cohesion. Small decals and surface effects are a later refinement, and natural elements help establish scene scale and transitions. Our adaptation is to compose tree/terrain framing and material variation deliberately instead of populating random debris. The author's use of scans, external assets and commercial software is explicitly excluded by the owner's custom-only rule.

## Blender: shape and surface are different operations

[Bevel modifier API](https://docs.blender.org/api/4.5/bpy.types.BevelModifier.html) documents edge limits, overlap control and hardened normals. Use these to preserve architectural planes and control edge treatment. Hardened/weighted normals should improve the shading of an existing shape, not masquerade as extra geometry.

[Multiresolution modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/multiresolution.html) distinguishes the base mesh from sculpted subdivision detail and explains baking the difference between levels. Its simple/linear subdivision choices avoid some smoothing of the base. For a weathered stone master, maintain a sound low-resolution form, sculpt localized damage, and bake fine relief only when it should not affect silhouette. Correct UVs and an active target image are prerequisites for a useful bake.

[Cycles baking](https://docs.blender.org/UATEST/manual/en/4.5/render/cycles/baking.html) identifies baking as a way to transfer procedural or geometric information into image maps. It is not automatic material approval: the exported maps must still be connected, scaled and tested in Roblox.

## Colour and material review

[Blender colour management](https://docs.blender.org/manual/nl/4.5/render/color_management.html) explains scene-linear processing, display transforms, exposure and false-colour inspection. AgX changes how highlights and saturation appear; it is not a neutral material data export. Review neutral colours separately from the presentation grade and inspect clipping before making darker textures.

[Roblox PBR documentation](https://create.roblox.com/docs/art/modeling/surface-appearance) separates colour, normal, roughness and metalness behavior. Colour should not contain the scene's direct lighting; normals supply small shading changes rather than new mesh silhouette. We need both genuine recess geometry and a restrained material response, not one used as a substitute for the other.

[Roblox texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications) is the import reference for texture formats, UVs and normal-map convention. The existing manor's world-projected tile UVs require actual Studio testing before claiming a production PBR workflow. Respect current importer behavior rather than assuming a Blender shader graph transfers intact.

## Specific next exercise

This is our inference and design decision, not a quoted tutorial:

Rework one window bay using an annotated section. Add a substantial reveal, two distinct arch profile orders, a supported hood moulding, connected mullions/tracery, a projecting sill with an underside drip, and several selectively worn stone variants. Test it in clay from the side and at player distance before changing the whole manor. Surface roughness should remain subordinate to those forms. Compare the completed module against the owner image's depth and material character; the existing clean window study is not the accepted standard.
