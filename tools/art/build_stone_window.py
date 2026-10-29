# BloodLocks original stone-window modelling/material study, made in the owner's Blender.
# No downloaded mesh, material library, or generative service is used.
import bpy, math, sys, json
from pathlib import Path
from mathutils import Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
assets=bpy.data.collections.new('VIGIL_MASONRY_WINDOW_MASTER');scene.collection.children.link(assets)
parts=[]
def move(o):
 for c in list(o.users_collection):c.objects.unlink(o)
 assets.objects.link(o);parts.append(o);return o
def flatmat(name,color,rough=.8,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*color,1)
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
def pbr(name,prefix,roughname):
 m=flatmat(name,(.3,.3,.3));nodes=m.node_tree.nodes;links=m.node_tree.links;p=nodes.get('Principled BSDF')
 for suffix,socket,noncolor in [('Color','Base Color',False),('Roughness','Roughness',True)]:
  tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/(prefix+'_'+suffix+'.png')));tex.image.colorspace_settings.name='Non-Color'if noncolor else'sRGB';tex.extension='REPEAT'
  links.new(tex.outputs['Color'],p.inputs[socket])
 tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(OUT/(prefix+'_Normal.png')));tex.image.colorspace_settings.name='Non-Color';tex.extension='REPEAT'
 norm=nodes.new('ShaderNodeNormalMap');norm.inputs['Strength'].default_value=.55;links.new(tex.outputs['Color'],norm.inputs['Color']);links.new(norm.outputs['Normal'],p.inputs['Normal'])
 return m
ashlar=pbr('Vigil_Original_Ashlar','VigilAshlar','')
trim=pbr('Vigil_Original_DressedStone','VigilTrim','')
iron=flatmat('Vigil_BlackenedIron',(.027,.025,.03),.47,.8)
glass=flatmat('Vigil_MutedWineGlass',(.042,.025,.044),.34)
def bevel(o,width=.045):
 b=o.modifiers.new('Small_physical_edge_wear','BEVEL');b.width=width;b.segments=3;b.harden_normals=True
 return o
def box(name,loc,size,mat,b=.0):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat);move(o)
 if b:bevel(o,b)
 return o
def mesh(name,verts,faces,mat):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();o=bpy.data.objects.new(name,data);assets.objects.link(o);data.materials.append(mat);parts.append(o);return o
def prism(name,outline,depth,y,mat):
 n=len(outline);v=[(x,y+s*depth/2,z)for s in(-1,1)for x,z in outline]
 f=[tuple(range(n)),tuple(n+i for i in reversed(range(n)))]
 f.extend((i,n+i,n+(i+1)%n,(i+1)%n)for i in range(n))
 return mesh(name,v,f,mat)
def archoutline(width,bottom,spring):
 pts=[(-width/2,bottom),(width/2,bottom),(width/2,spring)]
 for i in range(1,25):
  a=math.pi/3*i/24;pts.append((-width/2+width*math.cos(a),spring+width*math.sin(a)))
 for i in range(23,-1,-1):
  a=math.pi/3*i/24;pts.append((width/2-width*math.cos(a),spring+width*math.sin(a)))
 return pts
wall=box('StoneWindow_Wall',(0,0,6),(16,1,12),ashlar,.025)
cutter=prism('TEMP_Opening',archoutline(4,2,7),4,0,ashlar)
bpy.context.view_layer.objects.active=wall
mod=wall.modifiers.new('Real_pointed_aperture','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
# Difference must precede finishing bevels.
bpy.ops.object.modifier_move_up(modifier=mod.name);bpy.ops.object.modifier_apply(modifier=mod.name)
parts.remove(cutter);bpy.data.objects.remove(cutter,do_unlink=True)
for side in(-1,1):
 for j in range(5):
  stone=box('StoneWindow_JambCourse',(side*2.35,-.38,2.5+j),(.68,1.6,.955),trim,.025)
 # Individual radial voussoirs leave genuine mortar gaps at their joints.
 for j in range(16):
  t0=(j+.027)/16;t1=(j+.973)/16
  def point(t,outer):
   r=4.65 if outer else 4
   angle=(math.acos(2/4.65)if outer else math.pi/3)*t
   return (side*(-2+r*math.cos(angle)),7+r*math.sin(angle))
  q=[point(t0,False),point(t1,False),point(t1,True),point(t0,True)]
  if side<0:q.reverse()
  stone=prism('StoneWindow_RadialVoussoir',q,1.65,-.35,trim);bevel(stone,.018)
box('StoneWindow_RecessedSill',(0,-.48,1.8),(5.65,2.35,.55),trim,.07)
for x in(-7.4,7.4):
 for j in range(12):
  box('StoneWindow_Quoin',(x,-.14,.5+j),(.95,1.5,.955),trim,.045)
for z in(.35,11.65):box('StoneWindow_StringCourse',(0,-.28,z),(16.25,1.65,.38),trim,.045)
glazing=prism('StoneWindow_RecessedGlass',archoutline(3.9,2.05,7),.08,.38,glass)
# Leadwork is connected to actual openings, not floating circles or spikes.
for x in(-.96,0,.96):
 top=7+math.sqrt(max(0,16-(2+abs(x))**2))
 box('StoneWindow_IronMullion',(x,.27,(2+top)/2),(.065,.09,top-2),iron,.009)
for z in(3.8,5.7,7.0):box('StoneWindow_IronTransom',(0,.27,z),(3.9,.09,.065),iron,.009)
# A small genuinely modelled holder/candle ties the material scale to existing authored props.
box('Sconce_Backplate',(5.2,-.59,3.8),(.42,.18,1.4),iron,.06)
box('Sconce_Arm',(5.2,-1.15,3.3),(.12,1.0,.12),iron,.035)
lib=Path(r"C:\Users\gloce\AppData\Local\Temp\BloodLocks_Art\Vigil_Candles_01\Vigil_MeltedCandles_01.blend")
with bpy.data.libraries.load(str(lib),link=False)as(data_from,data_to):
 data_to.objects=[name for name in data_from.objects if name.startswith('Vigil_Candle_Short')]
for o in data_to.objects:
 if o:
  assets.objects.link(o);o.location+=Vector((6.5,-1.65,3.45));parts.append(o)
# Stable world-projected tile scale. Exported study uses the same eight-stud surface rhythm.
bpy.context.view_layer.update()
for o in parts:
 if o.type!='MESH':continue
 data=o.data;uv=data.uv_layers.active or data.uv_layers.new(name='StoneTileUV')
 for poly in data.polygons:
  worldnormal=o.matrix_world.to_3x3()@poly.normal
  axis=max(range(3),key=lambda i:abs(worldnormal[i]));axes=([1,2]if axis==0 else[0,2]if axis==1 else[0,1])
  for loop in poly.loop_indices:
   co=o.matrix_world@data.vertices[data.loops[loop].vertex_index].co
   uv.data[loop].uv=(co[axes[0]]/8,co[axes[1]]/8)
# Render objects/lights remain outside the export collection.
displaymat=flatmat('DISPLAY_ONLY_Ground',(.065,.07,.078),.85)
bpy.ops.mesh.primitive_plane_add(size=80,location=(0,0,-.03));bpy.context.object.data.materials.append(displaymat);bpy.context.object.name='DISPLAY_ONLY_Ground'
lights=[]
def area(name,loc,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color
 o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,6))-o.location).to_track_quat('-Z','Y').to_euler();lights.append(o);return o
key=area('DISPLAY_Key',(-9,-12,16),1800,9,(1,.94,.86))
fill=area('DISPLAY_Fill',(10,-7,10),1000,8,(.78,.85,1))
rim=area('DISPLAY_Rim',(2,4,16),1300,8,(1,.85,.7))
camera_data=bpy.data.cameras.new('MaterialReview');cam=bpy.data.objects.new('MaterialReview',camera_data);scene.collection.objects.link(cam);cam.location=(13,-26,15);cam.rotation_euler=(Vector((0,-.1,6))-cam.location).to_track_quat('-Z','Y').to_euler();camera_data.type='ORTHO';camera_data.ortho_scale=22;scene.camera=cam
scene.world.color=(.08,.085,.095);scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1350;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
bpy.ops.object.select_all(action='DESELECT')
for o in parts:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_StoneWindow_Study.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',bake_space_transform=True,bake_anim=False,add_leaf_bones=False,path_mode='COPY',embed_textures=True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_StoneWindow_Study.blend'))
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'Vigil_StoneWindow_Neutral.png');bpy.ops.render.render(write_still=True)
key.data.color=(.56,.72,1);key.data.energy=1650;fill.data.color=(.65,.73,.88);fill.data.energy=420;rim.data.energy=600;rim.data.color=(.56,.69,1)
warm=area('DISPLAY_EntranceBounce',(5.2,-2.1,5.0),22,1.1,(1,.52,.22))
scene.world.color=(.018,.025,.045)
scene.render.filepath=str(OUT/'Vigil_StoneWindow_Night.png');bpy.ops.render.render(write_still=True)
(OUT/'model-manifest.json').write_text(json.dumps({'authorship':'Entirely original geometry, materials and candle assets; built in installed Blender','review':'One material/window module; owner acceptance and Studio comparison pending','lighting':'Neutral and cool-night renders use the same materials and mesh','files':['Vigil_StoneWindow_Study.blend','Vigil_StoneWindow_Study.fbx','Vigil_StoneWindow_Neutral.png','Vigil_StoneWindow_Night.png']},indent=2))
print('STONE_WINDOW_STUDY_RENDERED',len(parts),flush=True)
