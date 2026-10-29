# BloodLocks: original melted-wax candle study. No external assets, paid services or AI generation.
# One Blender unit is one planned Roblox stud. Base pivot is Z=0.
# Preview shading is not claimed to be baked into the FBX.
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
asset=bpy.data.collections.new('VIGIL_CANDLE_MASTERS');scene.collection.children.link(asset)
def move(obj,collection):
 for c in list(obj.users_collection):c.objects.unlink(obj)
 collection.objects.link(obj)
def material(name,color,rough=.5,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
wax=material('Ivory_beeswax',(.69,.56,.36),.43)
p=wax.node_tree.nodes.get('Principled BSDF');p.inputs['Subsurface Weight'].default_value=.065
noise=wax.node_tree.nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=34;noise.inputs['Detail'].default_value=2
bump=wax.node_tree.nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.14;bump.inputs['Distance'].default_value=.007
wax.node_tree.links.new(noise.outputs['Fac'],bump.inputs['Height']);wax.node_tree.links.new(bump.outputs['Normal'],p.inputs['Normal'])
pool=material('Warm_recessed_wax_pool',(.48,.34,.17),.27)
wick=material('Charred_cotton_wick',(.018,.012,.008),.93)
iron=material('Dark_aged_iron',(.035,.03,.028),.47,.78)
ember=material('Wick_ember',(.36,.035,.006),.6)
ep=ember.node_tree.nodes.get('Principled BSDF');ep.inputs['Emission Color'].default_value=(1,.12,.008,1);ep.inputs['Emission Strength'].default_value=.5
exports=[]
def mesh(name,verts,faces,mats,indices=None):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
 obj=bpy.data.objects.new(name,data);asset.objects.link(obj)
 for m in mats:data.materials.append(m)
 for i,poly in enumerate(data.polygons):
  poly.use_smooth=True
  if indices:poly.material_index=indices[i]
 exports.append(obj);return obj
def line(name,points,radius,mat):
 c=bpy.data.curves.new(name,'CURVE');c.dimensions='3D';c.resolution_u=12;c.bevel_depth=radius;c.bevel_resolution=3
 s=c.splines.new('BEZIER');s.bezier_points.add(len(points)-1)
 for p,co in zip(s.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
 obj=bpy.data.objects.new(name,c);asset.objects.link(obj);obj.data.materials.append(mat)
 bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.convert(target='MESH');obj.select_set(False);exports.append(obj);return obj
def candle(label,x,r,h,seed):
 N=96;rows=44;verts=[];faces=[];indices=[]
 # A radial displacement field grows individual wax runs out of the body.
 drips=[(.3+seed*.17,.58,.055), (2.1+seed*.11,.37,.065),(4.1-seed*.09,.22,.045),(5.4+seed*.07,.48,.05)]
 def top(t):return h-.035+.038*math.sin(3*t+seed)+.024*math.cos(5*t+.7*seed)
 for j in range(rows+1):
  f=j/rows
  for i in range(N):
   t=2*math.pi*i/N;z=f*top(t)
   rr=r*(.984+.013*math.sin(t*3+seed))+.008*math.sin(7*t+f*3)
   for angle,length,bulge in drips:
    d=math.atan2(math.sin(t-angle),math.cos(t-angle))
    k=(h-z)/length
    if 0<k<1:
     # Narrow hanging run with a rounded terminal bead; keeps a joined wax surface.
     width=.11+.035*math.sin(math.pi*k)
     rr+=bulge*math.exp(-.5*(d/width)**2)*(math.sin(math.pi*k)**.35)
   if j==0:rr*=.94
   verts.append((x+rr*math.cos(t),rr*math.sin(t),z))
 for j in range(rows):
  for i in range(N):
   faces.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i));indices.append(0)
 faces.append(tuple(reversed(range(N))));indices.append(0)
 # Slumped irregular lip folds down into a visibly recessed wax pool.
 last=rows*N
 for fraction,drop in ((.83,.025),(.65,.11),(.3,.14),(.1,.145)):
  start=len(verts)
  for i in range(N):
   t=2*math.pi*i/N
   rr=r*fraction*(1+.035*math.sin(3*t+seed))
   z=(top(t) if fraction>.8 else h)-drop
   verts.append((x+rr*math.cos(t),rr*math.sin(t),z))
  for i in range(N):
   faces.append((last+i,last+(i+1)%N,start+(i+1)%N,start+i));indices.append(1 if fraction<.7 else 0)
  last=start
 faces.append(tuple(last+i for i in range(N)));indices.append(1)
 obj=mesh(label+'_Wax',verts,faces,[wax,pool],indices)
 line(label+'_Wick',[(x,0,h-.145),(x+.012,0,h-.035),(x+.048,.01,h+.035)],.018,wick)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=8,radius=.021,location=(x+.048,.01,h+.035))
 tip=bpy.context.object;tip.name=label+'_Ember';move(tip,asset);tip.data.materials.append(ember);exports.append(tip)
 # Drip catcher has a raised rim and a real concave profile.
 profile=[(0,0),(r*1.72,0),(r*1.84,.035),(r*1.88,.10),(r*1.76,.13),(r*1.65,.065),(r*.86,.055),(0,.055)]
 v=[];f=[]
 for rad,z in profile:
  for i in range(64):
   t=2*math.pi*i/64;v.append((x+rad*math.cos(t),rad*math.sin(t),z-.07))
 for j in range(len(profile)-1):
  for i in range(64):f.append((j*64+i,j*64+(i+1)%64,(j+1)*64+(i+1)%64,(j+1)*64+i))
 tray=mesh(label+'_IronDripTray',v,f,[iron])
 # Small pooled wax skirt, asymmetric instead of a perfect disk.
 points=[]
 for i in range(96):
  t=2*math.pi*i/96;rad=r*(1.13+.08*math.sin(3*t+seed)+.06*math.cos(5*t))
  points.append((x+rad*math.cos(t),rad*math.sin(t),.021))
 skirt=mesh(label+'_WaxFoot',points,[tuple(range(96))],[wax])
 # Preview flame deliberately stays out of the asset export.
 flameMat=bpy.data.materials.get('DISPLAY_ONLY_Flame')
 if not flameMat:
  flameMat=material('DISPLAY_ONLY_Flame',(1,.49,.06),.4)
  fp=flameMat.node_tree.nodes.get('Principled BSDF');fp.inputs['Emission Color'].default_value=(1,.26,.025,1);fp.inputs['Emission Strength'].default_value=3
 vs=[];fs=[]
 for k,(z,rad,offset) in enumerate(((0,.02,0),(.08,.068,0),(.18,.052,.01),(.30,.028,.025),(.43,0,.06))):
  for i in range(24):
   a=2*math.pi*i/24;vs.append((x+offset+rad*math.cos(a),rad*math.sin(a),h+.05+z))
 for j in range(4):
  for i in range(24):fs.append((j*24+i,j*24+(i+1)%24,(j+1)*24+(i+1)%24,(j+1)*24+i))
 fl=mesh('DISPLAY_ONLY_'+label+'_Flame',vs,fs,[flameMat]);exports.remove(fl)
 data=bpy.data.lights.new('DISPLAY_ONLY_'+label+'_Glow','POINT');data.energy=2;data.color=(1,.48,.16);data.shadow_soft_size=.14
 ob=bpy.data.objects.new(data.name,data);scene.collection.objects.link(ob);ob.location=(x,0,h+.2)
 return obj
candle('Vigil_Candle_Short',-1.3,.27,1.12,1)
candle('Vigil_Candle_Medium',0,.25,1.75,2)
candle('Vigil_Candle_Tall',1.3,.28,2.48,3)
# UVs and editable geometry are preserved; each candle group is exported separately at a base-centred origin.
bpy.ops.object.select_all(action='DESELECT')
for obj in exports:
 bpy.context.view_layer.objects.active=obj;obj.select_set(True);bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.1,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT');obj.select_set(False)
for label,x in [('Short',-1.3),('Medium',0),('Tall',1.3)]:
 chosen=[o for o in exports if o.name.startswith('Vigil_Candle_'+label)]
 for o in chosen:o.location.x-=x;o.select_set(True)
 bpy.context.view_layer.update()
 bpy.ops.export_scene.fbx(filepath=str(OUT/('Vigil_Candle_'+label+'.fbx')),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
 for o in chosen:o.location.x+=x;o.select_set(False)
# Inspection presentation only.
ground=material('DISPLAY_ONLY_Table',(.037,.029,.025),.6)
bpy.ops.mesh.primitive_cube_add(size=1,location=(0,0,-.2));o=bpy.context.object;o.name='DISPLAY_ONLY_Table';o.dimensions=(200,200,.25);o.data.materials.append(ground)
def area(name,pos,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1))-o.location).to_track_quat('-Z','Y').to_euler()
area('DISPLAY_KEY',(2,-4,6),360,4,(1,.85,.67))
area('DISPLAY_FILL',(-4,-2,3),170,3,(.61,.72,1))
area('DISPLAY_RIM',(1,3,5),450,2,(1,.7,.41))
camdata=bpy.data.cameras.new('InspectionCamera');cam=bpy.data.objects.new('InspectionCamera',camdata);scene.collection.objects.link(cam);cam.location=(4,-8,5.2);cam.rotation_euler=(Vector((0,0,1.3))-cam.location).to_track_quat('-Z','Y').to_euler();camdata.type='ORTHO';camdata.ortho_scale=5.7;scene.camera=cam
scene.world.color=(.055,.06,.08);scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1500;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
stats=[]
for o in exports:o.data.calc_loop_triangles();stats.append({'name':o.name,'triangles':len(o.data.loop_triangles)})
(OUT/'manifest.json').write_text(json.dumps({'status':'Original geometry study; not yet imported in Studio','base_pivot':'Z=0; one Blender unit targets one stud; validate import scale','preview_only':'Flames, lights, table and procedural wax micro-bump are not baked/exported','geometry':stats},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_MeltedCandles_01.blend'))
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'Vigil_MeltedCandles_01_preview.png')
print('CANDLE_MODELS_SAVED',len(exports),flush=True);bpy.ops.render.render(write_still=True);print('CANDLE_RENDER_COMPLETE',flush=True)
