"""One actual 3D-import FBX: original porch, existing original Pine03, selected original buttress.
Source files never overwritten. Temporary X offsets separate masters, not scene placements.
"""
import bpy,json,bmesh
from pathlib import Path
from mathutils import Matrix,Vector
P=Path(__file__).parent;OUT=P/'import-batch';OUT.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(P/'porch/Vigil_PorchArcade_M01.blend'))
porch=bpy.data.collections['ROBLOX_EXPORT'];parts=[]
for o in list(porch.objects):
 o.name='BL_Porch_'+o.name.split('.')[0];parts.append(o)
# One buttress master: same authored shoulder/coping profiles, centered about X0 and back face Y0.
butcol=bpy.data.collections.new('BUTTRESS_EXPORT');bpy.context.scene.collection.children.link(butcol)
for o in list(porch.objects):
 if not ('SteppedButtress'in o.name or 'ButtressWeathering'in o.name):continue
 faces=[f for f in o.data.polygons if all(o.data.vertices[i].co.x>0 for i in f.vertices)]
 verts=[];poly=[]
 for f in faces:
  off=len(verts)
  # Stretch only vertical dimensions into a wing-scale structural shoulder, retain 3.4width/7.62projection.
  verts.extend((o.data.vertices[i].co.x-15,o.data.vertices[i].co.y-5.8,o.data.vertices[i].co.z*2.7)for i in f.vertices)
  poly.append(tuple(off+j for j in range(len(f.vertices))))
 d=bpy.data.meshes.new('BL_Buttress_'+o.name);d.from_pydata(verts,[],poly);d.update()
 for m in o.data.materials:d.materials.append(m)
 bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 ob=bpy.data.objects.new('BL_Buttress_'+o.name.replace('BL_Porch_',''),d);butcol.objects.link(ob);ob.location.x=140;parts.append(ob)
# Pine03 is team-authored raw bark/needle geometry; don't import its review lights/camera.
pinepath=Path('C:/Users/gloce/AppData/Local/Temp/BloodLocks_Art/Vigil_Pine_03/Vigil_Pine_01.blend')
with bpy.data.libraries.load(str(pinepath),link=False)as(src,dst):dst.objects=[n for n in src.objects if n.startswith('Pine_')]
pinecol=bpy.data.collections.new('PINE03_EXPORT');bpy.context.scene.collection.children.link(pinecol)
for ob in dst.objects:
 if ob is None or ob.type!='MESH':continue
 pinecol.objects.link(ob);ob.name='BL_Pine03_'+ob.name;ob.matrix_world=Matrix.Translation((80,0,0))@ob.matrix_world;parts.append(ob)
# Distant master: same original branch layout, deliberately sparse needles, simplified welded bark.
# This is a labelled LOD study, not a substitute for the close master.
lodcol=bpy.data.collections.new('PINE_FAR_EXPORT');bpy.context.scene.collection.children.link(lodcol)
pineobjects=[o for o in parts if o.name.startswith('BL_Pine03_')]
barkv=[];barkf=[];needle_v=[[]for _ in range(4)];needle_f=[[]for _ in range(4)];needle_m=[None]*4;ni=0;barkmat=None
for ob in pineobjects:
 if 'BARK'in ob.name:
  off=len(barkv);barkv.extend(tuple(ob.matrix_world@v.co-Vector((80,0,0)))for v in ob.data.vertices);barkf.extend(tuple(off+i for i in f.vertices)for f in ob.data.polygons);barkmat=ob.data.materials[0]
 else:
  for f in ob.data.polygons:
   ni+=1
   if ((ni*1103515245+12345)&0xffffffff)%100>=6:continue
   mi=f.material_index;v=needle_v[mi];ff=needle_f[mi];off=len(v)
   pts=[ob.matrix_world@ob.data.vertices[i].co-Vector((80,0,0))for i in f.vertices]
   # Deliberately broaden retained original needle cards to preserve distant canopy mass.
   # Simple deletion alone was visually rejected as too bare in the first comparison.
   base=pts[0];direction=((pts[1]+pts[2])*.5-base)*1.13;spread=(pts[1]-pts[2])*.5*8
   v.extend(tuple(p)for p in(base,base+direction+spread,base+direction-spread));ff.append((off,off+1,off+2));needle_m[mi]=ob.data.materials[mi]
def lodmesh(name,verts,faces,mat):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(mat);d.update();ob=bpy.data.objects.new(name,d);lodcol.objects.link(ob);ob.location.x=220;parts.append(ob);return ob
lod=lodmesh('BL_PineFar_BARK',barkv,barkf,barkmat)
bm=bmesh.new();bm.from_mesh(lod.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.0001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(lod.data);bm.free()
mod=lod.modifiers.new('Distant_branch_simplification','DECIMATE');mod.ratio=.12
bpy.context.view_layer.update();ev=lod.evaluated_get(bpy.context.evaluated_depsgraph_get());data=bpy.data.meshes.new_from_object(ev);lod.modifiers.clear();lod.data=data
for i in range(4):lodmesh('BL_PineFar_NEEDLES_'+str(i),needle_v[i],needle_f[i],needle_m[i])
bpy.ops.object.select_all(action='DESELECT')
stats=[];bounds={}
for ob in parts:
 ob.select_set(True);ob.data.calc_loop_triangles();stats.append({'name':ob.name,'triangles':len(ob.data.loop_triangles)})
 prefix='Porch'if ob.name.startswith('BL_Porch_')else'Pine03'if ob.name.startswith('BL_Pine03_')else'PineFar'if ob.name.startswith('BL_PineFar_')else'Buttress'
 bounds.setdefault(prefix,[]).extend(tuple(ob.matrix_world@Vector(v))for v in ob.bound_box)
bb={}
for key,v in bounds.items():
 lo=[min(p[i]for p in v)for i in range(3)];hi=[max(p[i]for p in v)for i in range(3)];bb[key]={'min':lo,'max':hi,'size':[hi[i]-lo[i]for i in range(3)]}
bpy.ops.export_scene.fbx(filepath=str(OUT/'BloodLocks_ManorDepth_Pine03_Batch.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'BloodLocks_ManorDepth_Pine03_Batch.blend'))
(OUT/'manifest.json').write_text(json.dumps({'status':'Original source import batch; not placed in Studio','sources':[str(P/'porch/Vigil_PorchArcade_M01.blend'),str(pinepath)],'source_offsets_blender':{'BL_Porch_':[0,0,0],'BL_Pine03_':[80,0,0],'BL_Buttress_':[140,0,0],'BL_PineFar_':[220,0,0]},'normalization':'Split by prefix, remove X offsets80/140/220, mapping Blender X,Y,Z -> Studio X,Z,-Y. Verify bounding sizes after importer. Porch intended ground origin local(0,0,84). Pine pivot ground at0. Buttress pivot ground/backface0.','pine_note':'Dense original foliage,393984 needles; use only2 close silhouette framers and verify runtime','pine_far_note':'Labelled distant LOD study: retains original branches with welded bark decimated12percent and deterministic6percent needle retention; retained original cards broadened8x and lengthened1.13x to preserve canopy mass. First deletion-only LOD rejected. Five mesh groups; compare distant outline. Not close quality.','buttress_note':'Original stepped shoulder scaled vertically2.7 to64-stud wing scale; set collision false. Suggested front X±64.5 and±141 only, base localZ21.75. Clear window bays. Do not tile indiscriminately.','bounds_blender':bb,'geometry':stats},indent=2))
print('IMPORT_BATCH_READY',len(parts),sum(s['triangles']for s in stats),max(s['triangles']for s in stats),str(OUT),flush=True)
# Comparison at a distant-size view using the two actual masters.
for light in [o for o in bpy.context.scene.objects if o.type=='LIGHT']:light.hide_render=True
for name,x,z,power in(('TreeKey',70,110,65000),('TreeRim',220,95,70000)):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=70;o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);o.location=(x,-50,z);o.rotation_euler=(Vector((150,0,43))-o.location).to_track_quat('-Z','Y').to_euler()
cam=bpy.context.scene.camera;cam.location=(150,-230,55);cam.rotation_euler=(Vector((150,0,43))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=225
scene=bpy.context.scene;scene.world.color=(.11,.13,.17);scene.render.resolution_x=2000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100;scene.cycles.samples=20;scene.render.filepath=str(OUT/'Pine_full_left_far_right_comparison.png');bpy.ops.render.render(write_still=True)

