# BloodLocks project context

Read current Git notes before shared edits:
- https://github.com/glocen/BloodsLocks/blob/main/docs/team-notes.md
- https://github.com/glocen/BloodsLocks/blob/main/docs/manor-art-resumption.md
- https://github.com/glocen/BloodsLocks/issues/2

## Owner requirements

Original Gothic manor inspired by Duskbloods' House of Night. Two usable floors with taller storeys, natural dark timber and red runners; an outside training yard. The owner-provided image controls exterior atmosphere/composition. Its exact game provenance is not established.

Zero spending. Use the installed Blender and our own geometry/materials. No downloaded free models, scans, stock material packs or paid services. Artist breakdowns are for learning, not asset sourcing.

Current feedback: the building lacks depth/detail, the replacement stone study is still too smooth/regular, and the existing manor's stone texture is noisy and unattractive. Lighting/composition remain unapproved. Do not describe the structural prototype or current clean material sample as final art.

## Existing work and boundaries

ROLOCK place ID 76593217243342 contains the hub. The Victorian place is separate. Enumerate Studio instances each session; IDs change. Claude owns game engineering/UI work; coordinate through Git.

Hub origin is (0,0,-1000); north is -Z. Current gallery surface is approximately 31.9125 studs. Footprint and two-floor routes are existing constraints, not measurements proven by the art reference.

Masters: ServerStorage.WorldAssets.VigilKit. Generator: ServerStorage.WorldTools.VigilGraybox.Build()/Spots(). Preserve workspace.Vigil.GreatHall.ManorHall.BloodTable and the combat/pact tags. Source edits need cold require testing. Do not replace protected gameplay/Data/Libraries/ReplicatedStorage.Modules.

Current original models: 195-mesh ManorExterior and three melted-candle masters used for 68 fixtures. The shell import used FBX factor 0.01 and an orientation correction. Central Blender wall fit guides were not exported; Studio's carved wall shells still exist.

The native stone relief pass has 1700 parts, which is not evidence of good depth or visual quality. Review where it adds silhouette/contact versus repetitive seams.

Local originals:
- C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_ManorExterior_04/
- C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_Candles_01/
- C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_MasonryStudy_01/

Blender executable: C:/Program Files (x86)/Steam/steamapps/common/Blender/blender.exe.
Use a separate saved/background scene; the owner's open Blender scene may be unsaved.

## Composition reference

Tall narrow spire left of a long roof, red moon behind it, dark tree framing, cool readable roof/stone, a small warm entrance, uneven pale ground/stone markers and low layered mist. Two floors and gameplay yard are our functional adaptation. Forest, weathering, material character and lighting remain unfinished.

## Recent verification limits

A cold hub rebuild preserved imported exterior, stone relief, 68 candles, table path, one combat zone and one pact tag. Full traversal after shell replacement is pending; under Server Authority, test teleports must come from Server context.

Current native PBR test: uploaded original albedo images render correctly through MeshPart.TextureID. Programmatically assigned MaterialVariant/SurfaceAppearance tests produced blank/incorrect output. The cause is unresolved; image ownership was verified as the owner. Do not claim the PBR maps are complete or diagnose permission issues without evidence.

A diffuse-only candidate is stored at VigilKit.MaterialStudies.EastWing_MasonryDiffuse_Review. The live test wall was restored before the owner's research-first phase. The clean Blender window study is a learning artifact, not an approved replacement.

## Session restart

Read the notes, inspect the current scene, identify the highest-impact weakness, and write a small specific plan before editing. Keep learning tied to a visible before/after comparison. Do not claim permanent personal learning; persistence comes from these files and project notes.
