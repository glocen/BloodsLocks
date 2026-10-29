import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
from mathutils.geometry import tessellate_polygon
OUT=Path(sys.argv[sys.argv.index('--')+1]); OUT.mkdir(parents=True,exist_ok=True)
# Separate background process: never touches the user's open, unsaved Blender scene.
bpy.ops.object.select_all(action='SELECT'); bpy.ops.object.delete(use_global=False)
scene=bpy.context.scene
scene.unit_settings.system='NONE'
asset=bpy.data.collections.new('Vigil_Lancet_M01_EDITABLE');scene.collection.children.link(asset)
root=bpy.data.objects.new('VIGIL_LANCET_M01',None);asset.objects.link(root)
root['design']='Original Gothic lancet study for the larger Vigil manor'
root['expected_stud_scale']=1.5;root['status']='Geometry review; Roblox import and final PBR validation pending'
objects=[]
def mat(name,color,metal=0,rough=.65,glass=False):
    m=bpy.data.materials.new(name);m.use_nodes=True
    bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1)
    bs.inputs['Metallic'].default_value=metal;bs.inputs['Roughness'].default_value=rough
    if glass:bs.inputs['Transmission Weight'].default_value=.25;bs.inputs['IOR'].default_value=1.48
    m.diffuse_color=(*color,1);return m
stone=mat('Dressed_Limestone',(.32,.30,.275),rough=.72)
stoneDark=mat('Sheltered_Recess',(.18,.185,.20),rough=.78)
iron=mat('Oxidised_Lead',(.035,.04,.05),metal=.75,rough=.47)
bronze=mat('Old_Bronze',(.20,.115,.055),metal=.75,rough=.5)
greyGlass=mat('Smoked_Glass',(.115,.15,.20),rough=.26,glass=True)
redGlass=mat('Muted_Oxblood_Glass',(.18,.025,.045),rough=.3,glass=True)
# Fine relief is subordinate to the silhouette. No artificial emissive stone or glass.
nodes=stone.node_tree.nodes;links=stone.node_tree.links
noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=33
noise.inputs['Detail'].default_value=2
bump=nodes.new('ShaderNodeBump');bump.inputs['Strength'].default_value=.16;bump.inputs['Distance'].default_value=.008
links.new(noise.outputs['Fac'],bump.inputs['Height']);links.new(bump.outputs['Normal'],nodes.get('Principled BSDF').inputs['Normal'])
def keep(obj,material,bevel=0):
    for col in list(obj.users_collection):col.objects.unlink(obj)
    asset.objects.link(obj);obj.parent=root;obj.data.materials.append(material)
    if bevel:
        mod=obj.modifiers.new('Hand-cut edge catches','BEVEL');mod.width=bevel;mod.segments=2
        mod.affect='EDGES'
        normal=obj.modifiers.new('Weighted face normals','WEIGHTED_NORMAL');normal.keep_sharp=True;normal.weight=40
    objects.append(obj);return obj
def mesh(name,verts,faces,material,bevel=.015):
    data=bpy.data.meshes.new(name+'_mesh');data.from_pydata(verts,[],faces);data.update()
    obj=bpy.data.objects.new(name,data);asset.objects.link(obj);obj.parent=root
    data.materials.append(material)
    if bevel:
        mod=obj.modifiers.new('Stone edge bevel','BEVEL');mod.width=bevel;mod.segments=2
        normal=obj.modifiers.new('Weighted normals','WEIGHTED_NORMAL');normal.keep_sharp=True
    objects.append(obj);return obj
def box(name,loc,size,material,bevel=.025):
    bpy.ops.mesh.primitive_cube_add(size=1,location=loc)
    obj=bpy.context.object;obj.name=name;obj.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return keep(obj,material,bevel)
# A real moulding section swept around the arch. Continuous geometry, not bars approximating a curve.
def sweep(name,points,normals,profile,material):
    n=len(profile);verts=[]
    for (x,z),(nx,nz) in zip(points,normals):
        for radial,depth in profile:verts.append((x+radial*nx,depth,z+radial*nz))
    faces=[]
    for j in range(len(points)-1):
        for i in range(n):faces.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    faces.extend([tuple(reversed(range(n))),tuple((len(points)-1)*n+i for i in range(n))])
    return mesh(name,verts,faces,material,.012)
def gothic(span,spring,side,steps=64):
    pts=[];norm=[]
    for i in range(steps+1):
        a=math.pi/3*i/steps;pts.append((side*(-span/2+span*math.cos(a)),spring+span*math.sin(a)))
        norm.append((side*math.cos(a),math.sin(a)))
    return pts,norm
layers=[(6.95,.40,-.38,.50),(7.85,.43,-.78,.53),(8.65,.35,-.52,.78)]
for layer,(span,w,front,back) in enumerate(layers):
    profile=[(-w/2,.12),(-w/2,front+.10),(-w*.31,front+.03),(0,front-.07),(w*.31,front+.03),(w/2,front+.10),(w/2,back),(-w/2,back)]
    for side in (-1,1):
        pts,norm=gothic(span,5,side)
        sweep(f'Arch_Moulding_{layer+1}_'+('L' if side<0 else 'R'),pts,norm,profile,stone)
        # Jambs use the exact same section and meet the arch at its spring point.
        sweep(f'Jamb_Section_{layer+1}_{side}',[(side*span/2,0),(side*span/2,5)],[(side,0),(side,0)],profile,stone)
        for z in (.22,4.78):
            box(f'Jamb_Collar_{layer}_{side}_{z}',(side*span/2,(back+front)/2,z),(w+.16,back-front+.12,.18),stone)
box('Projecting_Drip_Sill',(0,-.07,-.23),(9.55,2.25,.40),stone,.045)
box('Sill_Underside_Rebate',(0,.07,-.50),(9.15,1.80,.16),stoneDark,.015)
box('Sill_Front_Roll',(0,-1.15,-.16),(9.25,.17,.16),stone,.04)
# Deep inside reveal leaves a visible return behind the front mouldings.
for side in (-1,1):box('Deep_Reveal_'+str(side),(side*3.23,.82,2.48),(.22,1.4,5.1),stoneDark,.018)
ptsR,_=gothic(6.4,5,1)
ptsL,_=gothic(6.4,5,-1)
outline=[(-3.2,0),(3.2,0)]+ptsR+list(reversed(ptsL))
# Remove coincident apex vertices before triangulating the pane.
clean=[]
for x,z in outline:
    if not clean or (Vector((x,z))-Vector(clean[-1])).length>1e-6:clean.append((x,z))
vec=[Vector((x,1.28,z)) for x,z in clean]
tri=tessellate_polygon([vec])
faces=[]
for t in tri:faces.append(tuple(v if isinstance(v,int) else min(range(len(vec)),key=lambda i:(vec[i]-v).length_squared) for v in t))
pane=mesh('Glazing_Continuous_Arch',[tuple(v) for v in vec],faces,greyGlass,0)
solid=pane.modifiers.new('Real glass thickness','SOLIDIFY');solid.thickness=.045
# Raised stone tracery: twin internal arches, central mullion and a pierced quatrefoil.
profile=[(-.075,-.05),(.075,-.05),(.075,.25),(-.075,.25)]
for cx in (-1.60,1.60):
    for side in (-1,1):
        pts,norm=gothic(3.0,5.8,side,40);pts=[(x+cx,z) for x,z in pts]
        sweep('Sub_Lancet_'+str(cx)+'_'+str(side),pts,norm,profile,stone)
box('Central_Stone_Mullion',(0,.12,3.45),(.20,.34,6.9),stone,.025)
for side in (-1,1):box('Outer_Mullion_'+str(side),(side*1.60,.17,2.95),(.11,.22,5.9),stone,.015)
# Clover contour is one closed swept loop, so there are no overlapping decorative circles.
pts=[];norm=[]
for i in range(129):
    a=i*2*math.pi/128;r=.85+.15*math.cos(4*a)
    pts.append((r*math.cos(a),8.85+r*math.sin(a)))
for i in range(len(pts)):
    before=Vector(pts[(i-1)%128]);after=Vector(pts[(i+1)%128])
    t=(after-before).normalized();norm.append((t.y,-t.x))
sweep('Pierced_Quatrefoil',pts,norm,[(-.075,.02),(.075,.02),(.075,.28),(-.075,.28)],stone)
def tube(name,points,radius,material):
    data=bpy.data.curves.new(name,'CURVE');data.dimensions='3D';data.bevel_depth=radius;data.bevel_resolution=2;data.resolution_u=1
    spline=data.splines.new('POLY');spline.points.add(len(points)-1)
    for p,co in zip(spline.points,points):p.co=(*co,1)
    obj=bpy.data.objects.new(name,data);asset.objects.link(obj);obj.parent=root;data.materials.append(material);objects.append(obj)
for z in (1.5,3,4.5):
    tube('Horizontal_Lead_Came_'+str(z),[(-3.16,1.20,z),(3.16,1.20,z)],.025,iron)
for x in (-2.4,-.8,.8,2.4):
    tube('Vertical_Lead_Came_'+str(x),[(x,1.20,.05),(x,1.20,5.75)],.022,iron)
# Sparse original heraldic accents; subdued glass remains unlit until the lighting art pass.
for x in (-1.60,1.60):
    verts=[(x,1.18,2.05),(x+.44,1.18,2.75),(x,1.18,3.45),(x-.44,1.18,2.75)]
    mesh('Oxblood_Diamond_'+str(x),verts,[(0,1,2,3)],redGlass,0)
    tube('Diamond_Lead_Border_'+str(x),verts+[verts[0]],.028,iron)
# Stable shared origin at the lower centre; Blender Z is the asset's vertical axis.
root.scale=(1.5,1.5,1.5)
# Explicit UVs on every mesh. Final game PBR maps will be baked after geometry review.
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    if obj.type=='MESH':
        bpy.context.view_layer.objects.active=obj;obj.select_set(True)
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.02)
        bpy.ops.object.mode_set(mode='OBJECT');obj.select_set(False)
# Export a separate evaluation copy: preserve modifiers and editable geometry in the master collection.
export=bpy.data.collections.new('ROBLOX_EXPORT');scene.collection.children.link(export)
exports=[]
bpy.context.view_layer.update()
for source in objects:
    clone=source.copy();clone.data=source.data.copy();export.objects.link(clone)
    clone.parent=None;clone.matrix_world=source.matrix_world.copy()
    bpy.context.view_layer.objects.active=clone;clone.select_set(True)
    if clone.type=='CURVE':bpy.ops.object.convert(target='MESH');clone=bpy.context.object
    for mod in list(clone.modifiers):
        if mod.type in ('BEVEL','WEIGHTED_NORMAL','SOLIDIFY'):
            try:bpy.ops.object.modifier_apply(modifier=mod.name)
            except RuntimeError:pass
    clone.select_set(False);exports.append(clone)
asset.hide_render=True;asset.hide_viewport=True
bpy.ops.object.select_all(action='DESELECT')
for obj in exports:obj.select_set(True)
bpy.context.view_layer.objects.active=exports[0]
bpy.ops.export_scene.fbx(filepath=str(OUT/'Vigil_Lancet_M01.fbx'),use_selection=True,object_types={'MESH'},apply_unit_scale=True,apply_scale_options='FBX_SCALE_UNITS',axis_forward='-Z',axis_up='Y',bake_space_transform=True,use_mesh_modifiers=True,bake_anim=False,add_leaf_bones=False)
# Neutral inspection presentation. These lights are not imported into Roblox or applied to its Lighting.
groundMat=mat('DISPLAY_ONLY_Ground',(.038,.042,.052),rough=.86)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.82));ground=bpy.context.object;ground.name='DISPLAY_ONLY_Ground';ground.data.materials.append(groundMat)
def area(name,position,power,size,color):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size;data.color=color
    ob=bpy.data.objects.new(name,data);scene.collection.objects.link(ob);ob.location=position
    ob.rotation_euler=(Vector((0,0,8))-ob.location).to_track_quat('-Z','Y').to_euler()
area('DISPLAY_KEY',(8,-12,21),2400,9,(1,.88,.73))
area('DISPLAY_FILL',(-11,-5,12),1600,8,(.68,.79,1))
area('DISPLAY_RIM',(2,7,18),2600,6,(1,.76,.58))
cameraData=bpy.data.cameras.new('InspectionCamera');camera=bpy.data.objects.new('InspectionCamera',cameraData);scene.collection.objects.link(camera)
camera.location=(18,-29,15);camera.rotation_euler=(Vector((0,0,8.1))-camera.location).to_track_quat('-Z','Y').to_euler();cameraData.type='ORTHO';cameraData.ortho_scale=24
scene.camera=camera
scene.world.color=(.065,.07,.09)
scene.render.engine='CYCLES';scene.cycles.device='CPU';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1100;scene.render.resolution_y=1350;scene.render.resolution_percentage=100
scene.view_settings.view_transform='AgX'
stats=[]
for obj in exports:
    obj.data.calc_loop_triangles();stats.append({'name':obj.name,'triangles':len(obj.data.loop_triangles)})
manifest={'asset':'Vigil_Lancet_M01','status':'Geometry review; not yet imported or accepted as final art','free_custom_asset':True,'source_units':'Authored against studs, verify FBX scale in Studio','objects':stats,'pbr_status':'Procedural stone preview; bake game maps after geometry acceptance','files':['Vigil_Lancet_M01.blend','Vigil_Lancet_M01.fbx','Vigil_Lancet_M01_preview.png']}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'Vigil_Lancet_M01.blend'))
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'Vigil_Lancet_M01_preview.png')
print('BLOODLOCKS_MODEL_SAVED',json.dumps({'objects':len(exports),'triangles':sum(x['triangles'] for x in stats),'max_mesh_triangles':max(x['triangles'] for x in stats)}),flush=True)
bpy.ops.render.render(write_still=True)
print('BLOODLOCKS_RENDER_COMPLETE',str(OUT),flush=True)
