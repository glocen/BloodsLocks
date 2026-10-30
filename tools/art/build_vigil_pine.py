# BloodLocks original weathered estate conifer study: tapered bark, supported branches, individual needle sprays.
# No external geometry, foliage atlases or downloaded materials.
import bpy,math,random,sys,json,bmesh
from mathutils import Vector
from pathlib import Path
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;rng=random.Random(28029)
def mat(name,col,rough):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=rough;return m
bark=mat('Original_fissured_umber_bark',(.075,.055,.042),.92)
needles=[mat('Needle_'+str(i),(.019+i*.004,.035+i*.006,.030+i*.004),.83)for i in range(4)]
objects=[];V=[];F=[];NV=[];NF=[];NI=[]
def tube(points,radii,sides=8):
 start=len(V)
 for j,(p,r)in enumerate(zip(points,radii)):
  tangent=(points[min(j+1,len(points)-1)]-points[max(0,j-1)]).normalized()
  axis=Vector((0,0,1))if abs(tangent.z)<.95 else Vector((1,0,0))
  a=tangent.cross(axis).normalized();b=tangent.cross(a).normalized()
  for i in range(sides):
   angle=i*2*math.pi/sides
   groove=1+.10*math.sin(i*3.1+j*.47)+rng.uniform(-.045,.045)
   V.append(tuple(p+r*groove*(a*math.cos(angle)+b*math.sin(angle))))
 for j in range(len(points)-1):
  for i in range(sides):
   k=start+j*sides+i;q=start+j*sides+(i+1)%sides;F.append((k,q,q+sides,k+sides))
 F.append(tuple(start+i for i in reversed(range(sides))))
 F.append(tuple(start+(len(points)-1)*sides+i for i in range(sides)))
def needle(base,direction,width,colour):
 direction=Vector(direction);axis=direction.cross(Vector((0,0,1)))
 if axis.length<.01:axis=Vector((1,0,0))
 axis.normalize();k=len(NV);NV.extend([tuple(base),tuple(base+direction+axis*width),tuple(base+direction-axis*width)]);NF.append((k,k+1,k+2));NI.append(colour)
def pine():
 H=86
 trunk=[Vector((.75*math.sin(j*.22),.4*math.sin(j*.4),H*j/24))for j in range(25)]
 tube(trunk,[max(.06,2.25*(1-j/25)**1.22)for j in range(25)],18)
 for i in range(9):
  a=i*2*math.pi/9
  tube([Vector((math.cos(a)*7,math.sin(a)*7,-.4)),Vector((math.cos(a)*3,math.sin(a)*3,.8)),trunk[1]],[.16,.64,1.1],8)
 for level in range(13):
  zbase=12+level*5.7;spanbase=(1-(zbase-12)/83)*22
  count=6 if level<7 else 5
  for j in range(count):
   z=zbase+rng.uniform(-3.0,3.0);span=spanbase*rng.uniform(.63,1.28)
   a=j*2*math.pi/count+level*2.39+rng.uniform(-.32,.32);radial=Vector((math.cos(a),math.sin(a),0));side=Vector((-math.sin(a),math.cos(a),0))
   centre=Vector((.75*math.sin(z/H*24*.22),.4*math.sin(z/H*24*.4),z))
   points=[]
   for k in range(8):
    t=k/7;points.append(centre+radial*(span*t)+side*math.sin(t*3)*.75+Vector((0,0,-3*math.sin(t*math.pi)+t*2)))
   tube(points,[.41*(1-k/8)**1.25+.025 for k in range(8)],7)
   # Alternating secondary twigs carry dense, separate needle combs.
   for k in range(3,22):
    t=k/22;p=centre+radial*(span*t)+Vector((0,0,-3*math.sin(t*math.pi)+t*2))
    for hand in(-1,1):
     length=(1-t)*span*.34+1.1
     tip=p+radial*.7+side*(hand*length)+Vector((0,0,rng.uniform(-1.3,2.4)+t*.7))
     tube([p,p.lerp(tip,.55),tip],[.095,.052,.015],5)
     twig=(tip-p).normalized();normal=twig.cross(Vector((0,0,1))).normalized();binormal=twig.cross(normal).normalized()
     for n in range(24):
      u=.10+.90*n/24;centre_=p.lerp(tip,u)
      for fan in range(6):
       for h in(0,):
        phase=fan*math.pi/3+rng.uniform(-.6,.6)
        direction=(twig*.34+normal*math.cos(phase)*.85+binormal*math.sin(phase)*.85).normalized()
        needle(centre_+Vector((0,0,rng.uniform(-.08,.08))),direction*(1.05+rng.random()*.8),.065,rng.randrange(4))
 # Dead lower limbs are bent and irregular rather than a cone hidden inside foliage.
 for i in range(8):
  a=i*2.27;z=8+i*1.15;d=Vector((math.cos(a),math.sin(a),0))
  tube([Vector((0,0,z)),d*3+Vector((0,0,z-.7)),d*(5+rng.random()*2)+Vector((0,0,z-1.8))],[.23,.12,.025],7)
pine()
def obj(name,verts,faces,materials,indices=None):
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update()
 for m in materials:data.materials.append(m)
 if indices:
  for p,i in zip(data.polygons,indices):p.material_index=i
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
 ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);objects.append(ob);return ob
for start in range(0,len(F),3500):
 faces=F[start:start+3500];verts=[];newfaces=[]
 for f in faces:
  off=len(verts);verts.extend(V[i]for i in f);newfaces.append(tuple(off+j for j in range(len(f))))
 obj('Pine_BARK_'+str(start//3500),verts,newfaces,[bark])
# Separate small semantic modules preserve editability and keep each upload below mesh face limits.
for start in range(0,len(NF),7000):
 faces=NF[start:start+7000];verts=[];newfaces=[]
 for f in faces:
  off=len(verts);verts.extend(NV[i]for i in f);newfaces.append((off,off+1,off+2))
 obj('Pine_NEEDLES_'+str(start//7000),verts,newfaces,needles,NI[start:start+7000])
bpy.ops.object.select_all(action='DESELECT')
for ob in objects:ob.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_Pine_01.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
# Neutral silhouette review before scene placement.
world=scene.world;world.color=(.13,.15,.18)
for name,pos,power,size in [('Key',(40,-55,110),42000,45),('Rim',(-40,30,85),56000,35),('Fill',(-30,-30,45),18000,35)]:
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=size;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,44))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('TreeReview');cam=bpy.data.objects.new('TreeReview',d);scene.collection.objects.link(cam);cam.location=(90,-140,65);cam.rotation_euler=(Vector((0,0,43))-cam.location).to_track_quat('-Z','Y').to_euler();d.type='ORTHO';d.ortho_scale=98;scene.camera=cam
scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=1200;scene.render.resolution_y=1500;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG'
(OUT/'manifest.json').write_text(json.dumps({'authorship':'Original Blender bark, branch and needle geometry','height_studs':86,'needle_triangles':len(NF),'modules':len(objects),'status':'Silhouette review; art acceptance pending'},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_Pine_01.blend'))
scene.render.filepath=str(OUT/'Vigil_Pine_01_Review.png');bpy.ops.render.render(write_still=True)
print('PINE_READY',len(objects),len(NF),flush=True)
