"""Append original porch study into a copy of the team's saved manor assembly.
This preserves the two source .blend files and never changes Studio.
"""
import bpy,sys,json
from pathlib import Path
from mathutils import Vector,Matrix
P=Path(__file__).parent;OUT=P/'assembly';OUT.mkdir(exist_ok=True)
base=Path('C:/Users/gloce/BloodsLocks/assets/manor/assembled/Vigil_Manor_Assembled.blend')
bpy.ops.wm.open_mainfile(filepath=str(base));scene=bpy.context.scene
with bpy.data.libraries.load(str(P/'porch/Vigil_PorchArcade_M01.blend'),link=False)as(src,dst):dst.collections=['ROBLOX_EXPORT']
col=dst.collections[0];scene.collection.children.link(col);col.name='PORCH_DEPTH_CANDIDATE'
for ob in col.objects:ob.matrix_world=Matrix.Translation((0,-84,0))@ob.matrix_world
# Retain four original supports until engine fit/traversal is checked. They remain behind the new arcade.
cam=scene.camera;cam.location=(165,-310,83);cam.rotation_euler=(Vector((-12,-4,72))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='PERSP';cam.data.lens=45
scene.render.resolution_x=1700;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.cycles.samples=24
scene.render.image_settings.file_format='PNG';bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_Manor_DepthProposal.blend'))
scene.render.filepath=str(OUT/'Vigil_Manor_DepthProposal.png');bpy.ops.render.render(write_still=True)
(OUT/'manifest.json').write_text(json.dumps({'status':'Unapproved depth/composition proposal, not Studio integration','authorship':'Existing team manor plus new original porch arcade','retains':'All source geometry preserved; existing front/rear columns retained during fit study','incomplete':'Original tree/terrain framing, engine lighting, PBR verification, route checks remain','sources':[str(base),str(P/'porch/Vigil_PorchArcade_M01.blend')]},indent=2))
print('ASSEMBLY_DEPTH_PROPOSAL_READY',flush=True)

