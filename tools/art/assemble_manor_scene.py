# Original BloodLocks manor assembly. No third-party geometry or materials.
# Keeps editable architecture in the .blend and composes corrected window modules.
import bpy,sys,math,json,bmesh
from pathlib import Path
from mathutils import Matrix,Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
BASE=Path(__file__).resolve().parents[2]/'assets/manor'
bpy.ops.wm.open_mainfile(filepath=str(BASE/'base-exterior/Vigil_ManorExterior_04.blend'))
scene=bpy.context.scene
shell=bpy.data.collections.get('ROBLOX_EXPORT')
for ob in list(shell.objects):
 if ob.name.startswith('WingWindow_'):bpy.data.objects.remove(ob,do_unlink=True)
# Keep editable source and evaluated export aligned for subsequent revisions.
for ob in list(bpy.data.objects):
 if ob.name.startswith('ShoulderTower'):
  ob.location+=Vector((-92,-47,0))
with bpy.data.libraries.load(str(BASE/'layered-windows/Vigil_LayeredWindowKit.blend'),link=False)as(src,dst):
 dst.collections=['ROBLOX_EXPORT']
kit=dst.collections[0]
windows=bpy.data.collections.new('ASSEMBLED_LAYERED_WINDOWS');scene.collection.children.link(windows)
for side in(-1,1):
 for face in(-1,1):
  for x in(75,95,116,135):
   for label,h,cx in(('Lower',6.2,-9),('Upper',37.8,9)):
    transform=Matrix.Translation((side*x,-face*21.75,h))@Matrix.Rotation(0 if face==1 else math.pi,4,'Z')@Matrix.Translation((-cx,0,0))
    for master in kit.objects:
     if master.name.startswith(label+'_'):
      ob=master.copy();ob.data=master.data
      ob.name=f'{label}_{side}_{face}_{x}_{master.name}'
      ob.matrix_world=transform;windows.objects.link(ob)
# Replace noisy preview bump with original, physically scaled masonry maps.
maps=BASE/'masonry'
def pbr(name,prefix):
 m=bpy.data.materials.new(name);m.use_nodes=True;n=m.node_tree.nodes;l=m.node_tree.links;p=n.get('Principled BSDF')
 tex={}
 for kind in('Color','Roughness','Normal'):
  image=bpy.data.images.load(str(maps/(prefix+'_'+kind+'.png')),check_existing=True);image.pack()
  if kind!='Color':image.colorspace_settings.name='Non-Color'
  node=n.new('ShaderNodeTexImage');node.image=image;tex[kind]=node
 l.new(tex['Color'].outputs['Color'],p.inputs['Base Color']);l.new(tex['Roughness'].outputs['Color'],p.inputs['Roughness'])
 normal=n.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.65;l.new(tex['Normal'].outputs['Color'],normal.inputs['Color']);l.new(normal.outputs['Normal'],p.inputs['Normal'])
 return m
wall=pbr('Original_Authored_Ashlar','VigilAshlar');trim=pbr('Original_Authored_Dressed_Stone','VigilTrim')
for ob in list(shell.objects)+list(windows.objects):
 if ob.type!='MESH':continue
 mat=wall if '_WALL' in ob.name else trim if '_STONE' in ob.name else None
 if mat:
  ob.data.materials.clear();ob.data.materials.append(mat)
  for poly in ob.data.polygons:poly.material_index=0
 # Fix winding on every disconnected stone before further exports.
 bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
cam=scene.camera;cam.location=(215,-395,130);cam.rotation_euler=(Vector((-20,0,80))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=425
scene.render.resolution_x=1800;scene.render.resolution_y=1250;scene.render.resolution_percentage=100
scene.cycles.samples=24
# Editable scene is the deliverable; runtime modules remain separate for reliable Studio placement.
(OUT/'manifest.json').write_text(json.dumps({'authorship':'Original team geometry and maps only','status':'Unapproved architecture/material review; landscape and interior still separate','windows':32,'tower_local_roblox':[-155,0,-8],'source':'tools/art/assemble_manor_scene.py','scope':'Full exterior assembly; two-floor interior not converted to meshes yet'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_Manor_Assembled.blend'))
scene.render.filepath=str(OUT/'Vigil_Manor_Assembled_Review.png');scene.render.image_settings.file_format='PNG'
bpy.ops.render.render(write_still=True)
print('MANOR_ASSEMBLY_READY',len(windows.objects),flush=True)
