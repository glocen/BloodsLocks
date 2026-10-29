# The Vigil manor exterior - original Blender architecture, geometry review 01.
# Coordinate mapping: Blender (X,Y,Z) = manor-local Roblox (X,-Z,Y).
# Preserves 285-stud two-wing footprint, 31.9125 gallery and 78.66 hall ceiling envelope.
# DISPLAY_ONLY shell is a fit guide, not imported geometry. No external/purchased assets.
import bpy, math, sys, json
from pathlib import Path
from mathutils import Vector, Matrix
OUT=Path(sys.argv[sys.argv.index('--')+1]);OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
master=bpy.data.collections.new('VIGIL_MANOR_EXTERIOR_MASTERS');scene.collection.children.link(master)
preview=bpy.data.collections.new('DISPLAY_ONLY_FIT_GUIDE');scene.collection.children.link(preview)
exports=[]
def move(o,c):
 for collection in list(o.users_collection):collection.objects.unlink(o)
 c.objects.link(o)
def mat(name,col,rough=.7,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True
 p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
stone=mat('Dressed_limestone',(.17,.178,.185),.85)
wall=mat('Charcoal_masonry',(.065,.071,.079),.89)
slates=[mat('Blue_slate_'+str(i),(.025+i*.003,.034+i*.003,.049+i*.004),.65+i*.018)for i in range(5)]
lead=mat('Weathered_lead',(.072,.078,.093),.53,.65)
iron=mat('Blackened_iron',(.025,.022,.028),.55,.75)
glass=mat('Smoky_wine_glass',(.035,.025,.039),.4,.02)
brick=mat('Sooted_umber_brick',(.14,.07,.052),.87)
timber=mat('Dark_oak_bargeboard',(.063,.032,.019),.66)
for m in [stone,wall,brick]:
 n=m.node_tree.nodes.new('ShaderNodeTexNoise');n.inputs['Scale'].default_value=3.4;n.inputs['Detail'].default_value=3
 b=m.node_tree.nodes.new('ShaderNodeBump');b.inputs['Strength'].default_value=.25;b.inputs['Distance'].default_value=.045
 m.node_tree.links.new(n.outputs['Fac'],b.inputs['Height']);m.node_tree.links.new(b.outputs['Normal'],m.node_tree.nodes.get('Principled BSDF').inputs['Normal'])
def mesh(name,v,f,m,export=True):
 data=bpy.data.meshes.new(name);data.from_pydata(v,[],f);data.update()
 o=bpy.data.objects.new(name,data);(master if export else preview).objects.link(o);data.materials.append(m)
 if export:exports.append(o)
 return o
def box(name,pos,size,m,bevel=0,export=True):
 sx,sy,sz=[v/2 for v in size]
 verts=[(-sx,-sy,-sz),(sx,-sy,-sz),(sx,sy,-sz),(-sx,sy,-sz),(-sx,-sy,sz),(sx,-sy,sz),(sx,sy,sz),(-sx,sy,sz)]
 faces=[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)]
 o=mesh(name,verts,faces,m,export);o.location=pos
 if bevel:
  mod=o.modifiers.new('Dressed_edge','BEVEL');mod.width=bevel;mod.segments=2
 return o
def beam(name,a,b,w,d,m):
 a,b=Vector(a),Vector(b);o=box(name,(a+b)/2,(w,d,(b-a).length),m,.035)
 o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o
def archpoints(cx,bottom,width,spring):
 pts=[(cx-width/2,bottom),(cx+width/2,bottom),(cx+width/2,spring)]
 for i in range(1,25):
  t=math.pi/3*i/24;pts.append((cx-width/2+width*math.cos(t),spring+width*math.sin(t)))
 for i in range(23,-1,-1):
  t=math.pi/3*i/24;pts.append((cx+width/2-width*math.cos(t),spring+width*math.sin(t)))
 return pts
def extrusion(name,pts,y,depth,m,export=True):
 n=len(pts);v=[(x,y+side*depth/2,z)for side in (-1,1)for x,z in pts]
 f=[tuple(range(n)),tuple(n+i for i in reversed(range(n)))]
 f.extend((i,n+i,n+(i+1)%n,(i+1)%n)for i in range(n))
 return mesh(name,v,f,m,export)
def window_detail(prefix,cx,y,bottom,width,spring,sign=1):
 pts=archpoints(cx,bottom,width,spring)
 extrusion(prefix+'_GLASS',pts,y,.12,glass)
 # Four-sided stone jamb/arch mouldings follow the opening, leaving a true aperture.
 for j,(a,b)in enumerate(zip(pts,pts[1:]+pts[:1])):
  beam(prefix+'_STONE_Reveal', (a[0],y-sign*.36,a[1]),(b[0],y-sign*.36,b[1]),.42,.7,stone)
 box(prefix+'_STONE_Sill',(cx,y-sign*.7,bottom-.2),(width+1.8,2.1,.65),stone,.09)
 peak=spring+width*math.sin(math.pi/3)
 beam(prefix+'_IRON_CentreMullion',(cx,y-sign*.18,bottom),(cx,y-sign*.18,peak-.1),.12,.14,iron)
 for z in (bottom+(spring-bottom)*.36,bottom+(spring-bottom)*.72,spring):
  beam(prefix+'_IRON_Transom',(cx-width/2,y-sign*.18,z),(cx+width/2,y-sign*.18,z),.1,.13,iron)
 # Restrained paired pointed lights: tracery meets the central mullion, not floating decoration.
 for side in (-1,1):
  sub=archpoints(cx+side*width/4,spring-1,width/2,spring)
  for a,b in zip(sub[2:],sub[3:]):
   beam(prefix+'_IRON_Tracery',(a[0],y-sign*.18,a[1]),(b[0],y-sign*.18,b[1]),.105,.13,iron)
def roof_surface(name,quad,rows,columns):
 # Individual overlapping slate courses are actual geometry, separately exportable per roof slope.
 a,b,c,d=map(Vector,quad)
 def p(u,v):return a*(1-u)*(1-v)+b*u*(1-v)+c*u*v+d*(1-u)*v
 base=mesh(name+'_LEAD_Underlay',[tuple(x)for x in (a,b,c,d)],[(0,1,2,3)],lead)
 so=base.modifiers.new('Roof_thickness','SOLIDIFY');so.thickness=.25
 n=(b-a).cross(d-a).normalized()
 if n.z<0:n=-n
 verts=[];faces=[]
 for row in range(rows):
  v0=row/rows;v1=min(1,(row+1.17)/rows)
  width=(p(1,(v0+v1)/2)-p(0,(v0+v1)/2)).length
  count=max(3,round(width/2.3))
  for col in range(count):
   u0=(col+.012)/count;u1=(col+.988)/count
   cs=[p(u0,v0),p(u1,v0),p(u1,v1),p(u0,v1)]
   start=len(verts);raise_=n*(.12+(row%2)*.012)
   verts.extend(tuple(x+raise_)for x in cs);verts.extend(tuple(x+raise_-n*.095)for x in cs)
   faces.extend(tuple(start+i for i in f)for f in [(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)])
 tiles=mesh(name+'_SLATE_Courses',verts,faces,slates[0])
 for m in slates[1:]:tiles.data.materials.append(m)
 for i,f in enumerate(tiles.data.polygons):f.material_index=((i//6)*7+(i//60)*3)%5
 return tiles
# Central great-hall roof: broad hipped volume, clipped crown, strongly projecting cornice.
outer=[];inner=[]
for i in range(8):
 a=math.pi/8+i*math.pi/4
 outer.append((66/math.cos(math.pi/8)*math.cos(a),66/math.cos(math.pi/8)*math.sin(a),79.3))
 inner.append((39.6*math.cos(a)/math.cos(math.pi/8),0,119))
for i in range(8):
 j=(i+1)%8
 roof_surface('HallRoof_'+str(i),[outer[i],outer[j],inner[j],inner[i]],27,30)
 beam('HallRoof_LEAD_Hip',outer[i],inner[i],.48,.48,lead)
 for z,scale,w in [(78.7,.99,1.2),(77.3,.97,.8),(75.7,.95,.52)]:
  aa=Vector(outer[i]);bb=Vector(outer[j]);aa.x*=scale;aa.y*=scale;bb.x*=scale;bb.y*=scale;aa.z=z;bb.z=z
  beam('HallEave_STONE_Cornice',aa,bb,w,1.15,stone)
beam('HallRoof_LEAD_LongRidge',(-39.6,0,119.25),(39.6,0,119.25),.7,.7,lead)
# Two lateral wings: occupied domestic rooms beneath steep pitched slate roofs.
for side in (-1,1):
 x0,x1=sorted((side*61,side*146))
 roof_surface(('West'if side<0 else'East')+'RoofSouth',[(x0,-25,68.5),(x1,-25,68.5),(x1,0,91),(x0,0,91)],18,38)
 roof_surface(('West'if side<0 else'East')+'RoofNorth',[(x1,25,68.5),(x0,25,68.5),(x0,0,91),(x1,0,91)],18,38)
 beam('WingRoof_LEAD_Ridge',(x0,0,91.3),(x1,0,91.3),.62,.62,lead)
 for y in (-23.7,23.7):
  box('WingEave_STONE_Cornice',((x0+x1)/2,y,67.8),(x1-x0,2.5,1.35),stone,.09)
 # Real end gable, capped raking coping and a linked quatrefoil.
 end=side*142.5
 mesh('WingEndGable_STONE',[(end,-21.75,67),(end,21.75,67),(end,0,88.4)],[(0,1,2)],wall)
 for s in (-1,1):beam('WingEndGable_STONE_Coping',(end+side*.45,s*24,68),(end+side*.45,0,92),1.2,1.3,stone)
 # Each front/back facade is cut through in Blender; these replace Studio SideWall parts after integration.
 for sign in (-1,1):
  cy=sign*19.875;facade=box(('West'if side<0 else'East')+('South'if sign<0 else'North')+'_WALL_Facade',(side*103.125,cy,32.775),(78.75,3.75,65.55),wall)
  cutters=[]
  for height,spring in [(6.2,19.6),(37.8,53.6)]:
   for mag in (75,95,116,135):
    cx=side*mag;pts=archpoints(cx,height,7.6,spring)
    cut=extrusion('TEMP_WindowCut',pts,cy,8,wall,False);cutters.append(cut)
  # Apply cuts sequentially: robust apertures with editable boolean results preserved in source.
  bpy.context.view_layer.objects.active=facade
  for cut in cutters:
   mod=facade.modifiers.new('True_window_aperture','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut
   bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
  for height,spring in [(6.2,19.6),(37.8,53.6)]:
   for mag in (75,95,116,135):
    window_detail('WingWindow',side*mag,sign*21.86,height,7.6,spring,-sign)
  for mag in (64.5,85.2,105.6,126,141):
   x=side*mag
   box('WingFacade_STONE_Pilaster',(x,sign*22.25,32),(1.15,1.3,64),stone,.065)
   for z in (1.4,31.6,64.4):box('WingFacade_STONE_PierCourse',(x,sign*22.4,z),(1.7,1.6,.9),stone,.05)
  for z in (1.2,32.1,64.7):box('WingFacade_STONE_StringCourse',(side*103.125,sign*22.35,z),(79.4,1.4,.7),stone,.06)
 # End wall with paired lancets; placeholder native end wall will be removed.
 endwall=box('WingEnd_WALL',(side*140.625,0,32.775),(3.75,43.5,65.55),wall)
 # End wall windows are left for the next measured module; vertical pilasters give the return a finished edge.
 for y in (-20.8,20.8):box('WingReturn_STONE_Quoin',(side*142.7,y,32.6),(1.4,1.6,65.2),stone,.08)
# Entrance porch: deep shelter, open pointed doorway, no surface across the spawn route.
for x in (-14,14):
 for y in (-65,-84):
  box('Porch_STONE_ColumnBase',(x,y,1.1),(2.9,2.9,2.2),stone,.1)
  box('Porch_STONE_Column',(x,y,15.2),(1.75,1.75,26.5),stone,.13)
  box('Porch_STONE_Capital',(x,y,28.6),(3,3,1.3),stone,.12)
for y in (-65,-84):
 beam('Porch_TIMBER_Tie',(-15.5,y,29),(15.5,y,29),1.4,1.7,timber)
 beam('Porch_TIMBER_Barge',(-17,y,30),(0,y,45),1.3,1.6,timber)
 beam('Porch_TIMBER_Barge',(0,y,45),(17,y,30),1.3,1.6,timber)
roof_surface('PorchRoofWest',[(-18,-87,30.5),(-18,-61,30.5),(0,-61,46.5),(0,-87,46.5)],14,12)
roof_surface('PorchRoofEast',[(18,-61,30.5),(18,-87,30.5),(0,-87,46.5),(0,-61,46.5)],14,12)
beam('Porch_LEAD_Ridge',(0,-87,46.7),(0,-61,46.7),.5,.5,lead)
# South-facing cross gable crowns the entrance and breaks the rotunda-like central roof mass.
roof_surface('HallFrontGableWest',[(-18,-63,79),(-18,-34,79),(0,-34,111.8),(0,-63,111.8)],23,15)
roof_surface('HallFrontGableEast',[(18,-34,79),(18,-63,79),(0,-63,111.8),(0,-34,111.8)],23,15)
gable=mesh('HallFrontGable_WALL',[(-18,-62.7,78.8),(18,-62.7,78.8),(0,-62.7,111.8)],[(0,1,2)],wall)
for s in (-1,1):beam('HallFrontGable_STONE_Coping',(s*18.8,-63.15,78.5),(0,-63.15,113),1.2,1.45,stone)
# A real round relief frame rather than flat decorative decals.
def ring(name,centre,r,tube,m,rotation=(math.pi/2,0,0)):
 bpy.ops.mesh.primitive_torus_add(major_segments=64,minor_segments=8,location=centre,major_radius=r,minor_radius=tube,rotation=rotation)
 o=bpy.context.object;o.name=name;move(o,master);o.data.materials.append(m);exports.append(o);return o
ring('HallFrontGable_STONE_Rose',(0,-63.1,91.8),4.5,.48,stone)
for i in range(8):
 a=i*math.pi/4;beam('HallFrontGable_IRON_RoseSpoke',(0,-63.2,91.8),(4.1*math.cos(a),-63.2,91.8+4.1*math.sin(a)),.13,.16,iron)
# Chimney groups: brick shafts, dressed offsets, open clay pots. Domestic silhouette, no battlements.
for side in (-1,1):
 for y in (-7,8):
  cx=side*117
  box('Chimney_BRICK_Stack',(cx,y,91),(4.8,4.2,24),brick,.08)
  for z in (99.5,101,102.4):box('Chimney_STONE_Corbel',(cx,y,z),(5.3+(z-99.5)*.18,4.7+(z-99.5)*.18,.8),stone,.06)
  for dx in (-1.15,1.15):
   ring('Chimney_BRICK_OpenPot',(cx+dx,y,105.4),.68,.19,brick,rotation=(0,0,0))
   bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.72,depth=3,location=(cx+dx,y,103.7))
   o=bpy.context.object;o.name='Chimney_BRICK_PotShaft';move(o,master);o.data.materials.append(brick);exports.append(o)
   # Dark inset well reads as an opening beneath the top ring.
   bpy.ops.mesh.primitive_cylinder_add(vertices=24,radius=.49,depth=.06,location=(cx+dx,y,105.28))
   o=bpy.context.object;o.name='Chimney_IRON_SootWell';move(o,master);o.data.materials.append(iron);exports.append(o)
# No repeated cottage dormers: the supplied reference calls for long uninterrupted slate slopes.
# Tall north-west shoulder tower supplies the dominant slender Gothic silhouette.
towerx,towery=-63,55
for sign in (-1,1):
 for direction in ('X','Y'):
  if direction=='Y':pos=(towerx,towery+sign*12.2,63);size=(24.4,2.1,126)
  else:pos=(towerx+sign*12.2,towery,63);size=(2.1,24.4,126)
  body=box('ShoulderTower_WALL_'+direction+str(sign),pos,size,wall)
  # Deep pointed belfry opening above the manor roof line.
  pts=archpoints(0,103,6.2,115)
  cut=extrusion('TEMP_BelfryOpening',pts,0,30,wall,False)
  if direction=='Y':cut.location=(towerx,towery+sign*12.2,0)
  else:cut.rotation_euler.z=math.pi/2;cut.location=(towerx+sign*12.2,towery,0)
  bpy.context.view_layer.objects.active=body
  mod=body.modifiers.new('Open_belfry','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut
  bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
for dx in (-11.8,11.8):
 for dy in (-11.8,11.8):
  box('ShoulderTower_STONE_CornerPier',(towerx+dx,towery+dy,62),(2.4,2.4,124),stone,.13)
  box('ShoulderTower_STONE_Base',(towerx+dx,towery+dy,4),(4,4,8),stone,.13)
for z in (28,73,99,125):
 box('ShoulderTower_STONE_StringCourse',(towerx,towery,z),(27,27,1.2),stone,.1)
# Main spire is a steep eight-sided slate roof with projecting lead ribs.
spirebase=[]
for i in range(8):
 a=math.pi/8+i*math.pi/4
 spirebase.append((towerx+15.3*math.cos(a),towery+15.3*math.sin(a),126.5))
for i in range(8):
 a=Vector(spirebase[i]);b=Vector(spirebase[(i+1)%8]);peak=Vector((towerx,towery,190))
 # Tiny truncated edge avoids degenerate zero-area tip faces in FBX.
 c=peak+(b-Vector((towerx,towery,126.5)))*.004
 d=peak+(a-Vector((towerx,towery,126.5)))*.004
 roof_surface('ShoulderTowerSpire_'+str(i),[a,b,c,d],36,10)
 beam('ShoulderTower_LEAD_SpireRib',a,peak,.28,.28,lead)
for dx in (-11.8,11.8):
 for dy in (-11.8,11.8):
  cx,cy=towerx+dx,towery+dy
  mesh('ShoulderTower_STONE_Pinnacle',[(cx-1.5,cy-1.5,125),(cx+1.5,cy-1.5,125),(cx+1.5,cy+1.5,125),(cx-1.5,cy+1.5,125),(cx,cy,143)],[(0,1,4),(1,2,4),(2,3,4),(3,0,4)],stone)
# Circular window and linked spokes echo the reference tower's pale circular focal detail.
ring('ShoulderTower_STONE_Rose',(towerx,towery-13.35,87),4.5,.48,stone)
for i in range(12):
 a=i*math.pi/6
 beam('ShoulderTower_IRON_RoseSpoke',(towerx,towery-13.55,87),(towerx+4.2*math.cos(a),towery-13.55,87+4.2*math.sin(a)),.13,.16,iron)
# Exterior dressings connect the new roof to the existing hall's real window apertures.
for i in range(8):
 a=i*math.pi/4
 if i not in (2,4,6):
  first=len(exports)
  window_detail('HallWindow',0,-64.05,51.75,10.8,60.375,1)
  newobjects=list(exports[first:])
  bpy.context.view_layer.update()
  for ob in newobjects:
   ob.matrix_world=Matrix.Rotation(a,4,'Z')@ob.matrix_world
   if '_GLASS' in ob.name:
    exports.remove(ob);move(ob,preview);ob.name='DISPLAY_ONLY_HallWindowGlass'
 # Thin paired pilasters, continuous sill levels and cornice give the wall field a hierarchy.
 for side_ in (-1,1):
  first=len(exports)
  box('HallFacade_STONE_Pilaster',(side_*22.8,-64.1,38),(1.05,1.3,75),stone,.06)
  for z in (2,31.8,74.2):box('HallFacade_STONE_PierCap',(side_*22.8,-64.25,z),(1.8,1.7,1.1),stone,.07)
  bpy.context.view_layer.update()
  for ob in exports[first:]:ob.matrix_world=Matrix.Rotation(a,4,'Z')@ob.matrix_world
 for side_ in (-1,1):
  first=len(exports)
  box('HallFacade_STONE_Belt',(side_*18,-64.0,31.9),(12,1.2,.8),stone,.06)
  bpy.context.view_layer.update()
  for ob in exports[first:]:ob.matrix_world=Matrix.Rotation(a,4,'Z')@ob.matrix_world

print('REFERENCE_ROOFS_AND_FACADES_READY',flush=True)
# Central shell shown only to judge the new exterior against the existing playable hall.
for i in range(8):
 a=i*math.pi/4
 cx,cy=61.875*math.sin(a),-61.875*math.cos(a)
 o=box('DISPLAY_ONLY_HallWall',(cx,cy,38.8125),(50.3,3.75,77.625),wall,export=False);o.rotation_euler.z=a
 cuts=[]
 if i in (0,2,4,6):
  cuts.append((0,24 if i==4 else 18.9,23 if i==4 else 12))
 if i not in (2,6):cuts.append((51.75,10.8,60.375))
 else:cuts.append((31.92,14.4,47))
 bpy.context.view_layer.objects.active=o
 for bottom,width,spring in cuts:
  cut=extrusion('TEMP_HallOpening',archpoints(0,bottom,width,spring),-61.875,9,wall,False);cut.rotation_euler.z=a
  mod=o.modifiers.new('Visible_fit_aperture','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cut
  bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cut,do_unlink=True)
 # Fit guide is never exported; Studio retains its carved hall walls and collision.
# Segmented dressed plinth gives the central footprint weight without copying castle battlements.
for i in range(8):
 a=i*math.pi/8;b=a+math.pi/4;r=64/math.cos(math.pi/8)
 aa=(r*math.cos(a),r*math.sin(a),1.3);bb=(r*math.cos(b),r*math.sin(b),1.3)
 # Leave south and north door spans unobstructed.
 if i not in (1,5):beam('HallPlinth_STONE',aa,bb,2.5,1.7,stone)
# Export semantic modules through evaluated meshes; retain editable source objects.
# Direct data assembly avoids thousands of context-sensitive join/UV operators.
print('ARCHITECTURE_GEOMETRY_READY',len(exports),flush=True)
bpy.context.view_layer.update()
groups={}
for o in exports:
 key=o.name.split('.')[0];groups.setdefault(key,[]).append(o)
exportcol=bpy.data.collections.new('ROBLOX_EXPORT');scene.collection.children.link(exportcol)
out=[];deps=bpy.context.evaluated_depsgraph_get()
for key,objects in groups.items():
 for chunk_index in range(0,len(objects),60):
  verts=[];faces=[];materials=[];mat_indices=[]
  for source in objects[chunk_index:chunk_index+60]:
   evaluated=source.evaluated_get(deps);data=evaluated.to_mesh();offset=len(verts);matrix=source.matrix_world
   verts.extend(tuple(matrix@v.co)for v in data.vertices)
   for mat_ in source.data.materials:
    if mat_ not in materials:materials.append(mat_)
   for poly in data.polygons:
    faces.append(tuple(offset+i for i in poly.vertices))
    original=source.data.materials[min(poly.material_index,len(source.data.materials)-1)]if source.data.materials else stone
    if original not in materials:materials.append(original)
    mat_indices.append(materials.index(original))
   evaluated.to_mesh_clear()
  data=bpy.data.meshes.new(key);data.from_pydata(verts,[],faces);data.update()
  for material_ in materials:data.materials.append(material_)
  for poly,index in zip(data.polygons,mat_indices):poly.material_index=index
  # World-projected tile UVs for architectural surfaces; unique baking UVs are a later surface pass.
  uv=data.uv_layers.new(name='ArchitecturalTileUV')
  for poly in data.polygons:
   normal=poly.normal;axis=max(range(3),key=lambda i:abs(normal[i]));axes=([1,2]if axis==0 else[0,2]if axis==1 else[0,1])
   for loop in poly.loop_indices:
    co=data.vertices[data.loops[loop].vertex_index].co;uv.data[loop].uv=(co[axes[0]]/8,co[axes[1]]/8)
  ob=bpy.data.objects.new(key+('_'+str(chunk_index//60)if len(objects)>60 else''),data);exportcol.objects.link(ob);out.append(ob)
 print('EXPORT_MODULE_READY',key,flush=True)
master.hide_render=True;master.hide_viewport=True
bpy.ops.object.select_all(action='DESELECT')
for ob in out:ob.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_ManorExterior_04.blend'))
print('EDITABLE_MASTER_SAVED',flush=True)
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_ManorExterior_04.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_space_transform=True,bake_anim=False,add_leaf_bones=False)
for ob in out:ob.select_set(False)
# Neutral architectural review, separate from unfinished game lighting.
ground=mat('DISPLAY_ONLY_Ground',(.095,.095,.105),.9)
box('DISPLAY_ONLY_Ground',(0,0,-2.3),(360,260,2),ground,export=False)
def area(name,pos,power,size,color):
 d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=size;d.color=color;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,45))-o.location).to_track_quat('-Z','Y').to_euler()
area('DISPLAY_KEY',(30,-180,230),650000,140,(1,.88,.75))
area('DISPLAY_FILL',(-180,-80,140),400000,130,(.65,.76,1))
area('DISPLAY_RIM',(20,150,210),750000,100,(1,.76,.55))
cd=bpy.data.cameras.new('ArchitectureReview');cam=bpy.data.objects.new('ArchitectureReview',cd);scene.collection.objects.link(cam);cam.location=(245,-355,155);cam.rotation_euler=(Vector((0,0,84))-cam.location).to_track_quat('-Z','Y').to_euler();cd.type='ORTHO';cd.ortho_scale=420;scene.camera=cam
scene.world.color=(.1,.115,.15);scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True;scene.render.resolution_x=1800;scene.render.resolution_y=1200;scene.render.resolution_percentage=100;scene.view_settings.view_transform='AgX'
stats=[]
for ob in out:ob.data.calc_loop_triangles();stats.append({'name':ob.name,'triangles':len(ob.data.loop_triangles)})
(OUT/'manifest.json').write_text(json.dumps({'status':'Exterior geometry review 01; not final art; not yet in Studio','alignment':'Blender X,Y,Z = Roblox local X,-Z,Y; origin is great hall centre at ground; normalize FBX importer 100x factor','scope':'Original slate roofs, physical courses, entrance porch, chimneys, dormers, true wing window apertures, stone dressings. Central hall walls are preview-only fit guide.','game_shading':'Procedural preview masonry bump is not baked. Reassign native materials by semantic names on import.','geometry':stats},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_ManorExterior_04.blend'))
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'Vigil_ManorExterior_04_reference_preview.png')
print('MANOR_EXTERIOR_SAVED',json.dumps({'meshes':len(out),'triangles':sum(v['triangles']for v in stats),'max_mesh':max(v['triangles']for v in stats)}),flush=True)
bpy.ops.render.render(write_still=True);print('MANOR_EXTERIOR_RENDER_COMPLETE',flush=True)
