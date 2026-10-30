# BloodLocks original layered Gothic window kit. Built in installed Blender, no external assets.
# Blender X/Y/Z -> manor X/-Z/Y. Wall outer face is local Y=0; positive Y recesses inward.
import bpy,math,sys,json,random
from pathlib import Path
from mathutils import Vector
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene;col=bpy.data.collections.new('EDITABLE_LAYERED_WINDOW_MASTERS');scene.collection.children.link(col)
objects=[];specs={}
def material(name,color,rough,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
stone=material('Cool_worn_dressed_stone',(.24,.235,.22),.83)
iron=material('Blackened_lead_and_iron',(.022,.023,.029),.52,.8)
glass=material('Deep_wine_glazing',(.026,.017,.033),.35)
# Cross-section: deep reveal -> small inner roll -> recessed fillet -> wider roll -> hood shadow recess.
profile=[(0,1.82),(0,.12),(.12,-.02),(.22,-.18),(.37,-.23),(.51,-.13),(.57,-.04),(.77,-.04),(.84,-.2),(.99,-.38),(1.17,-.43),(1.34,-.34),(1.43,-.2),(1.55,-.22),(1.61,-.67),(1.77,-.82),(1.95,-.82),(2.04,-.64),(2.13,-.64),(2.13,1.82)]
def mesh(name,v,f,mat,bevel=0):
 data=bpy.data.meshes.new(name);data.from_pydata(v,[],f);data.update()
 o=bpy.data.objects.new(name,data);col.objects.link(o);data.materials.append(mat);objects.append(o)
 if bevel:
  mod=o.modifiers.new('Restrained_edge_rounding','BEVEL');mod.width=bevel;mod.segments=2;mod.harden_normals=True
 return o
def prism(name,polygon,y0,y1,mat,bevel=0):
 n=len(polygon);v=[(x,y,z)for y in(y0,y1)for x,z in polygon]
 f=[tuple(range(n)),tuple(n+i for i in reversed(range(n)))]
 f.extend((i,n+i,n+(i+1)%n,(i+1)%n)for i in range(n))
 return mesh(name,v,f,mat,bevel)
def cube(name,pos,size,mat,b=.02):
 x,y,z=pos;a,c,d=[v/2 for v in size]
 v=[(x-a,y-c,z-d),(x+a,y-c,z-d),(x+a,y+c,z-d),(x-a,y+c,z-d),(x-a,y-c,z+d),(x+a,y-c,z+d),(x+a,y+c,z+d),(x-a,y+c,z+d)]
 return mesh(name,v,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,b)
def window(label,cx,spring):
 half=3.8;radius=7.6;peak=spring+radius*math.sin(math.pi/3)
 specs[label]={'centre_x':cx,'opening_width':7.6,'spring':spring,'peak':peak,'recess':1.82,'outer_projection':.82}
 # Individual jamb courses with the same deep profile as the arched orders.
 n=math.ceil(spring/1.62);h=spring/n
 for side in(-1,1):
  for row in range(n):
   z0=row*h+.025;z1=(row+1)*h-.025
   section=[(cx+side*(half+r),y)for r,y in profile]
   verts=[(x,y,z)for z in(z0,z1)for x,y in section];q=len(section)
   faces=[tuple(reversed(range(q))),tuple(q+i for i in range(q))]
   faces.extend((i,(i+1)%q,q+(i+1)%q,q+i)for i in range(q))
   if side<0:faces=[tuple(reversed(f))for f in faces]
   mesh(label+'_STONE_Jamb',verts,faces,stone,.016)
  # Radial stones sweep a real multi-order cross-section; apex is mitred at X=centre.
  for j in range(18):
   t0=(j+.025)/18;t1=(j+.975)/18
   verts=[]
   for t in(t0,(t0+t1)/2,t1):
    for r,y in profile:
     rr=radius+r;angle=math.acos(half/rr)*t
     verts.append((cx+side*(-half+rr*math.cos(angle)),y,spring+rr*math.sin(angle)))
   q=len(profile);faces=[tuple(reversed(range(q))),tuple(2*q+i for i in range(q))]
   for ring in range(2):
    for i in range(q):faces.append((ring*q+i,ring*q+(i+1)%q,(ring+1)*q+(i+1)%q,(ring+1)*q+i))
   if side>0:faces=[tuple(reversed(f))for f in faces]
   ob=mesh(label+'_STONE_Arch'+('Right'if side>0 else'Left'),verts,faces,stone,.014)
   # Sparse chipped facets at exposed outer hood edges; preserve main load-bearing planes.
   if j in(3,10,15):
    for vertex in ob.data.vertices:
     if vertex.co.y<-.6 and abs(vertex.co.x-cx)>1.0:
      vertex.co.y+=.035+.018*math.sin(vertex.index*1.7)
 # Sloping sill and underside drip form a profile rather than one rectangular strip.
 sill_section=[(-2.18,-.22),(-2.18,-.55),(-1.72,-.76),(-.62,-.73),(-.48,-.57),(-.16,-.57),(.02,-.72),(.22,-.72),(.22,-.12)]
 # section stores Y,Z; extruded across X.
 n=len(sill_section);verts=[(cx+x,y,z)for x in(-6.15,6.15)for y,z in sill_section]
 faces=[tuple(range(n)),tuple(n+i for i in reversed(range(n)))]
 faces.extend((i,n+i,n+(i+1)%n,(i+1)%n)for i in range(n))
 mesh(label+'_STONE_Sill',verts,faces,stone,.022)
 for dx in(-4.25,4.25):
  cube(label+'_STONE_Corbel',(cx+dx,-.58,-1.12),(.95,1.6,.85),stone,.035)
  cube(label+'_STONE_CorbelFoot',(cx+dx,-.2,-1.68),(.7,.82,.32),stone,.025)
 # Glazing is well inside the reveal; connected lead follows the actual pointed aperture.
 pts=[(cx-half+.04,.03),(cx+half-.04,.03),(cx+half-.04,spring)]
 for j in range(1,33):
  a=math.pi/3*j/32;pts.append((cx-half+radius*math.cos(a),spring+radius*math.sin(a)))
 for j in range(31,-1,-1):
  a=math.pi/3*j/32;pts.append((cx+half-radius*math.cos(a),spring+radius*math.sin(a)))
 prism(label+'_GLASS',pts,1.72,1.8,glass)
 for dx in(-1.9,0,1.9):
  top=spring+math.sqrt(radius**2-(half+abs(dx))**2)
  cube(label+'_IRON_Lead',(cx+dx,1.66,top/2),(.11,.13,top),iron,.009)
 for z in(spring*.32,spring*.67,spring):
  cube(label+'_IRON_Lead',(cx,1.66,z),(7.52,.13,.11),iron,.009)
 # Two inset pointed lights close into their receiving mullions.
 for side in(-1,1):
  c=cx+side*1.9
  for arm in(-1,1):
   last=Vector((c+arm*1.9,1.65,spring))
   for j in range(1,17):
    a=math.pi/3*j/16;point=Vector((c+arm*(-1.9+3.8*math.cos(a)),1.65,spring+3.8*math.sin(a)))
    tangent=(point-last).normalized();axis=Vector((0,1,0));right=tangent.cross(axis).normalized()*.055
    front=axis*.065;vv=[]
    for p in(last,point):
     for a_,b_ in((-1,-1),(1,-1),(1,1),(-1,1)):vv.append(tuple(p+a_*right+b_*front))
    mesh(label+'_IRON_Tracery',vv,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],iron)
    last=point
window('Lower',-9,13.4);window('Upper',9,15.8)
bpy.context.view_layer.update();deps=bpy.context.evaluated_depsgraph_get()
# Preserve editable masters, export evaluated semantic modules with tiled world-scale UVs.
outcol=bpy.data.collections.new('ROBLOX_EXPORT');scene.collection.children.link(outcol);out=[]
groups={}
for o in objects:groups.setdefault(o.name.split('.')[0],[]).append(o)
for name,group in groups.items():
 verts=[];faces=[]
 for ob in group:
  ev=ob.evaluated_get(deps);data=ev.to_mesh();offset=len(verts)
  verts.extend(tuple(v.co)for v in data.vertices);faces.extend(tuple(offset+i for i in p.vertices)for p in data.polygons);ev.to_mesh_clear()
 data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.update();data.materials.append(group[0].data.materials[0])
 import bmesh
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free();data.update()
 uv=data.uv_layers.new(name='OriginalTrimUV')
 for poly in data.polygons:
  axis=max(range(3),key=lambda i:abs(poly.normal[i]));axes=([1,2]if axis==0 else[0,2]if axis==1 else[0,1])
  for loop in poly.loop_indices:
   v=data.vertices[data.loops[loop].vertex_index].co;uv.data[loop].uv=(v[axes[0]]/8,v[axes[1]]/8)
 ob=bpy.data.objects.new(name,data);outcol.objects.link(ob);out.append(ob)
col.hide_render=True;col.hide_viewport=True
bpy.ops.object.select_all(action='DESELECT')
for o in out:o.select_set(True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_LayeredWindowKit.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
for o in out:o.select_set(False)
# Clay and oblique inspection expose geometric depth without textures concealing mistakes.
def area(name,loc,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,10))-o.location).to_track_quat('-Z','Y').to_euler()
area('Inspection_Key',(-18,-18,29),4400,12,(1,.91,.8));area('Inspection_Fill',(21,-9,18),2300,12,(.68,.79,1));area('Inspection_Rim',(0,9,26),3500,10,(1,.84,.65))
cd=bpy.data.cameras.new('DepthReview');cam=bpy.data.objects.new('DepthReview',cd);scene.collection.objects.link(cam);cam.location=(35,-55,28);cam.rotation_euler=(Vector((0,0,11))-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=42;scene.camera=cam
scene.world.color=(.075,.08,.095);scene.render.engine='CYCLES';scene.cycles.samples=28;scene.cycles.use_denoising=True
scene.render.resolution_x=1600;scene.render.resolution_y=1250;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
stats=[]
for o in out:o.data.calc_loop_triangles();stats.append({'name':o.name,'triangles':len(o.data.loop_triangles)})
(OUT/'manifest.json').write_text(json.dumps({'authorship':'Original Blender geometry; no imported stock assets','specs':specs,'status':'Layered geometric depth review; material ageing remains to be refined','objects':stats},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_LayeredWindowKit.blend'))
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'Vigil_LayeredWindowKit_Depth.png');bpy.ops.render.render(write_still=True)
print('LAYERED_WINDOW_KIT_READY',len(out),max(v['triangles']for v in stats),flush=True)


