"""Original BloodLocks porch arcade. Standalone scene, no stock assets.
Fits existing porch X+/-18, roof eave30.5. Coordinates X=across,Y=inward,Z=up.
Studio module origin=(0,0,-916), mapping (X,Z,-Y). Candidate, not approved final art.
"""
import bpy,math,json,sys,bmesh
from pathlib import Path
from mathutils import Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;art=bpy.data.collections.new('EDITABLE_ARCADE');scene.collection.children.link(art)
stage=bpy.data.collections.new('DISPLAY_ONLY');scene.collection.children.link(stage);objects=[]
def mat(name,c,r,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=(*c,1);p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=r;p.inputs['Metallic'].default_value=metal;return m
stone=mat('Grey_dressed_stone',(.265,.255,.235),.84);recess=mat('Sheltered_stone',(.205,.203,.198),.88)
iron=mat('Forged_iron',(.026,.029,.035),.48,.8);glass=mat('Old_amber_glass',(.25,.095,.025),.33)
wall=mat('Quiet_wall',(.105,.113,.125),.87);ground=mat('Worn_paving',(.16,.159,.15),.9)
def mesh(name,v,f,m,b=0,display=False):
 d=bpy.data.meshes.new(name);d.from_pydata(v,[],f);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);(stage if display else art).objects.link(o);d.materials.append(m)
 if b:
  mod=o.modifiers.new('Small_dressed_edges','BEVEL');mod.width=b;mod.segments=2;mod.harden_normals=True
 if not display:objects.append(o)
 return o
def box(name,p,s,m=stone,b=.03,display=False):
 x,y,z=p;a,c,d=[i/2 for i in s];v=[(x-a,y-c,z-d),(x+a,y-c,z-d),(x+a,y+c,z-d),(x-a,y+c,z-d),(x-a,y-c,z+d),(x+a,y-c,z+d),(x+a,y+c,z+d),(x-a,y+c,z+d)]
 return mesh(name,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],m,b,display)
def beam(name,a,b,w,d,m=stone):
 a,b=Vector(a),Vector(b);v=b-a;o=box(name,(0,0,0),(w,d,v.length),m,.025);o.location=(a+b)/2;o.rotation_euler=v.to_track_quat('Z','Y').to_euler();return o
def yzprism(name,p,x0,x1,m):
 n=len(p);v=[(x,y,z)for x in(x0,x1)for y,z in p];f=[tuple(reversed(range(n))),tuple(n+i for i in range(n))];f.extend((i,(i+1)%n,n+(i+1)%n,n+i)for i in range(n));return mesh(name,v,f,m,.025)
# Inner reveal -> small roll -> recessed fillet -> large roll -> shadow channel -> drip hood.
profile=[(0,6.5),(0,.8),(.14,.65),(.28,.29),(.45,.16),(.65,.28),(.79,.62),(.88,.68),(1.08,.68),(1.10,.29),(1.29,-.04),(1.52,-.16),(1.72,-.05),(1.92,.23),(2.03,.45),(2.08,.42),(2.08,-.7),(2.26,-.98),(2.47,-.98),(2.66,-.73),(2.72,-.68),(2.72,6.5)]
half=10;radius=20;spring=9
for side in(-1,1):
 for row in range(6):
  lo=row*1.5+.018;hi=(row+1)*1.5-.018;q=len(profile);v=[(side*(half+r),depth,z)for z in(lo,hi)for r,depth in profile]
  f=[tuple(reversed(range(q))),tuple(q+i for i in range(q))];f.extend((i,(i+1)%q,q+(i+1)%q,q+i)for i in range(q));mesh('STONE_Jamb',v,f,stone,.018)
 for j in range(20):
  v=[];q=len(profile)
  for t in((j+.016)/20,(j+.5)/20,(j+.984)/20):
   for offset,depth in profile:
    r=radius+offset;a=math.acos(half/r)*t;v.append((side*(-half+r*math.cos(a)),depth,spring+r*math.sin(a)))
  f=[tuple(reversed(range(q))),tuple(2*q+i for i in range(q))]
  for ring in range(2):f.extend((ring*q+i,ring*q+(i+1)%q,(ring+1)*q+(i+1)%q,(ring+1)*q+i)for i in range(q))
  ob=mesh('STONE_RadialOrders_'+('Left'if side<0 else'Right'),v,f,stone,.014)
  if j in(2,9,15)and side<0:
   for vert in ob.data.vertices:
    if vert.co.y<-.7 and vert.index%7==0:vert.co.y+=.065
 for dx,depth,w in((12.85,1.3,.62),(13.6,2.7,.82),(14.2,4.4,.6)):box('STONE_Receiver',(side*dx,depth,12.9),(w,1.05,25.8),stone,.04)
 box('STONE_Capital',(side*12.35,2.65,8.72),(5.2,7.7,.48),stone,.035)
 box('STONE_Foot',(side*13,2.3,.43),(5.8,8.1,.86),stone,.045)
 yzprism('STONE_SteppedButtress',[(-1.35,0),(-1.35,6.3),(-.3,6.9),(-.3,14.8),(.9,15.5),(.9,22.7),(2.7,23.7),(5.8,23.7),(5.8,0)],side*15-.8,side*15+.8,recess)
 for y,z,w in((-.62,6.6,3.4),(.48,15.1,3.2),(2,23.4,3.1)):box('STONE_ButtressWeathering',(side*15,y,z),(w,2.4,.46),stone,.025)
 beam('IRON_LanternBracket',(side*14,1.1,12.3),(side*14,-.25,12.8),.11,.16,iron)
 box('IRON_LanternBack',(side*14,-.27,12.3),(1.22,.13,1.85),iron,.025);box('GLASS_Lantern',(side*14,-.7,12.2),(.98,.7,1.28),glass,.025)
 for dx in(-.54,.54):box('IRON_LanternMullion',(side*14+dx,-1.1,12.2),(.075,.075,1.5),iron,.01)
 box('IRON_LanternRoof',(side*14,-.66,13.07),(1.48,1.2,.2),iron,.025);box('IRON_LanternTray',(side*14,-.66,11.4),(1.4,1.15,.14),iron,.02)
box('STONE_Keystone',(0,-.34,28.3),(1.45,1.15,1.35),stone,.08)
for side in(-1,1):beam('STONE_KeystonePetal',(0,-.98,28.2),(side*.46,-.98,28.55),.14,.10)
box('STONE_TopFrieze',(0,3,29.16),(32,6.5,.55),stone,.04)
box('DISPLAY_Paving',(0,5,-.28),(49,42,.5),ground,.03,True)
for side in(-1,1):box('DISPLAY_WallReturn',(side*21,6.8,15),(11.8,2.1,30),wall,.02,True)
for x in range(-20,21,4):box('DISPLAY_PavingJoint',(x,0,-.012),(.025,34,.012),wall,0,True)
for y in range(-15,22,4):box('DISPLAY_PavingJoint',(0,y,-.011),(42,.025,.01),wall,0,True)
# Evaluated, normals-correct export groups with physical-scale planar UVs.
bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get();groups={}
for ob in objects:groups.setdefault(ob.name.split('.')[0],[]).append(ob)
export=bpy.data.collections.new('ROBLOX_EXPORT');scene.collection.children.link(export);out=[]
for name,items in groups.items():
 v=[];f=[]
 for ob in items:
  ev=ob.evaluated_get(deps);d=ev.to_mesh();off=len(v);v.extend(tuple(ob.matrix_world@p.co)for p in d.vertices);f.extend(tuple(off+i for i in p.vertices)for p in d.polygons);ev.to_mesh_clear()
 d=bpy.data.meshes.new(name);d.from_pydata(v,[],f);d.materials.append(items[0].data.materials[0]);d.update();bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free();d.update();uv=d.uv_layers.new(name='WorldTrimUV')
 for p in d.polygons:
  axis=max(range(3),key=lambda i:abs(p.normal[i]));axes=([1,2]if axis==0 else[0,2]if axis==1 else[0,1])
  for li in p.loop_indices:
   vv=d.vertices[d.loops[li].vertex_index].co;uv.data[li].uv=(vv[axes[0]]/8,vv[axes[1]]/8)
 ob=bpy.data.objects.new(name,d);export.objects.link(ob);out.append(ob)
art.hide_render=True;art.hide_viewport=True;bpy.ops.object.select_all(action='DESELECT')
for ob in out:ob.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_PorchArcade_M01.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
stats=[];serial=[]
for ob in out:
 ob.data.calc_loop_triangles();tri=[list(t.vertices)for t in ob.data.loop_triangles];stats.append({'name':ob.name,'triangles':len(tri)});serial.append({'name':ob.name,'vertices':[list(v.co)for v in ob.data.vertices],'triangles':tri,'color':list(ob.data.materials[0].diffuse_color),'material':ob.data.materials[0].name})
(OUT/'Vigil_PorchArcade_meshes.json').write_text(json.dumps(serial,separators=(',',':')))
(OUT/'manifest.json').write_text(json.dumps({'status':'Original candidate, not yet imported or accepted','authorship':'Original Blender geometry and authored flat materials','physical':{'opening_width':20,'spring':9,'opening_apex':26.320508,'reveal_depth':6.5,'front_projection':1.82,'max_height':29.435,'bounding_size_blender':[33.4,8.32,29.435],'placement_manor_local':[0,0,84]},'replacement':'Retain old 4-column porch group for fit review; replace only with rear supports preserved','not_done':['Studio import','route traversal','PBR baking','owner art acceptance'],'geometry':stats},indent=2))
def light(name,loc,target,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler();return o
key=light('Key',(-18,-22,35),(0,2,14),4200,14,(1,.9,.78));fill=light('Fill',(24,-10,22),(0,2,14),2400,14,(.7,.8,1));rim=light('Rim',(0,19,31),(0,2,14),5000,9,(.86,.91,1))
cd=bpy.data.cameras.new('DepthCamera');cam=bpy.data.objects.new('DepthCamera',cd);scene.collection.objects.link(cam);scene.camera=cam;cam.location=(35,-48,24);cam.rotation_euler=(Vector((0,2,14))-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=50
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.world.color=(.085,.09,.1);scene.render.resolution_x=1500;scene.render.resolution_y=1100;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_PorchArcade_M01.blend'))
scene.render.filepath=str(OUT/'Vigil_PorchArcade_neutral.png');bpy.ops.render.render(write_still=True)
scene.world.color=(.025,.031,.052);key.data.color=(.47,.61,1);key.data.energy=2400;fill.data.energy=800;rim.data.energy=1800
for side in(-1,1):light('LanternPool',(side*14,-1.25,12.1),(side*11,-7,3),220,2.1,(1,.38,.11))
scene.render.filepath=str(OUT/'Vigil_PorchArcade_night.png');bpy.ops.render.render(write_still=True)
clay=mat('Inspection_clay',(.48,.48,.48),.8)
for ob in out:ob.data.materials.clear();ob.data.materials.append(clay)
scene.world.color=(.07,.07,.07);key.data.color=(1,1,1);key.data.energy=4500;fill.data.energy=1700;rim.data.energy=4000;cam.location=(40,-32,19);cam.rotation_euler=(Vector((0,3,14))-cam.location).to_track_quat('-Z','Y').to_euler();cd.ortho_scale=48
scene.render.filepath=str(OUT/'Vigil_PorchArcade_clay_oblique.png');bpy.ops.render.render(write_still=True)
print('PORCH_ARCADE_READY',len(out),sum(s['triangles']for s in stats),max(s['triangles']for s in stats),flush=True)

