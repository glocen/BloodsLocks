"""Shared helpers for BloodsLocks' Blender scripts (run headless: blender.exe -b --factory-startup --python <script> -- <out_dir>).

Geometry is built in studs (1 Blender unit = 1 stud): X right, Y forward, Z up. Each builder makes plain mesh
objects, so modifiers (bevels, booleans) are applied straight away and nothing depends on operator context.
Materials are procedural Principled setups (Cycles), meant to be baked into one texture set before export.
"""

import math
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector


def out_dir() -> Path:
    """The folder given after `--` on the command line (created if missing)."""
    path = Path(sys.argv[sys.argv.index("--") + 1]) if "--" in sys.argv else Path.cwd()
    path.mkdir(parents=True, exist_ok=True)
    return path


def reset_scene() -> bpy.types.Scene:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "NONE"
    return scene


# --- objects -----------------------------------------------------------------------------------------------

def object_from_bmesh(name: str, bm: bmesh.types.BMesh, material: bpy.types.Material | None = None) -> bpy.types.Object:
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    if material:
        obj.data.materials.append(material)
    return obj


def place(obj: bpy.types.Object, location=(0, 0, 0), rotation=(0, 0, 0), scale=(1, 1, 1)) -> bpy.types.Object:
    """Bakes a transform into the mesh (the object itself stays at the origin)."""
    matrix = Matrix.LocRotScale(Vector(location), _euler(rotation), Vector(scale))
    obj.data.transform(matrix)
    obj.data.update()
    return obj


def _euler(rotation):
    from mathutils import Euler
    return Euler(tuple(math.radians(a) for a in rotation), "XYZ")


def cylinder(name, radius, depth, segments=32, material=None, radius_top=None, caps=True) -> bpy.types.Object:
    """A cylinder (or cone, with radius_top) along Z, centred on the origin."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=caps, cap_tris=False, segments=segments,
                          radius1=radius, radius2=radius if radius_top is None else radius_top, depth=depth)
    return object_from_bmesh(name, bm, material)


def box(name, size, material=None) -> bpy.types.Object:
    """A box of `size` (x, y, z), centred on the origin."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    return object_from_bmesh(name, bm, material)


def sphere(name, radius, segments=24, rings=12, material=None) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    return object_from_bmesh(name, bm, material)


def torus(name, major, minor, major_segments=48, minor_segments=12, material=None, arc=360.0) -> bpy.types.Object:
    """A torus in the XY plane (axis Z), optionally only `arc` degrees of it."""
    bm = bmesh.new()
    rings = []
    closed = arc >= 359.9
    steps = major_segments if closed else max(2, int(major_segments * arc / 360)) + 1
    for i in range(steps):
        a = math.radians(arc) * i / (major_segments if closed else steps - 1)
        centre = Vector((math.cos(a) * major, math.sin(a) * major, 0))
        outward = Vector((math.cos(a), math.sin(a), 0))
        ring = []
        for j in range(minor_segments):
            b = 2 * math.pi * j / minor_segments
            ring.append(bm.verts.new(centre + outward * math.cos(b) * minor + Vector((0, 0, math.sin(b) * minor))))
        rings.append(ring)
    count = len(rings) if closed else len(rings) - 1
    for i in range(count):
        a, b = rings[i], rings[(i + 1) % len(rings)]
        for j in range(minor_segments):
            bm.faces.new((a[j], a[(j + 1) % minor_segments], b[(j + 1) % minor_segments], b[j]))
    if not closed:
        bm.faces.new(list(reversed(rings[0])))
        bm.faces.new(rings[-1])
    return object_from_bmesh(name, bm, material)


def profile(name, outline_yz, thickness, material=None, x=0.0) -> bpy.types.Object:
    """A flat shape drawn in the YZ plane (a side view: (y, z) points in order) extruded `thickness` along X,
    centred on x. The way gun frames and blades are drawn: silhouette first."""
    bm = bmesh.new()
    near = [bm.verts.new((x - thickness / 2, y, z)) for y, z in outline_yz]
    far = [bm.verts.new((x + thickness / 2, y, z)) for y, z in outline_yz]
    bm.faces.new(near)
    bm.faces.new(list(reversed(far)))
    count = len(outline_yz)
    for i in range(count):
        j = (i + 1) % count
        bm.faces.new((near[i], near[j], far[j], far[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return object_from_bmesh(name, bm, material)


def smooth_path(points, samples=24):
    """A Catmull-Rom curve through 2D or 3D control points (tuples or Vectors), resampled to `samples` points."""
    pts = [Vector(p) for p in points]
    pts = [pts[0] * 2 - pts[1]] + pts + [pts[-1] * 2 - pts[-2]]
    out = []
    spans = len(pts) - 3
    for i in range(samples):
        t = i / (samples - 1) * spans
        k = min(int(t), spans - 1)
        u = t - k
        p0, p1, p2, p3 = pts[k], pts[k + 1], pts[k + 2], pts[k + 3]
        out.append(0.5 * ((2 * p1) + (-p0 + p2) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u * u + (-p0 + 3 * p1 - 3 * p2 + p3) * u ** 3))
    return out


def band_along(name, path_yz, width, thickness, material=None) -> bpy.types.Object:
    """A flat bar bent along a side-view path (y, z): `width` across the path in the YZ plane, `thickness` along X.
    The way trigger guards and hand guards are forged."""
    bm = bmesh.new()
    pts = [Vector((p[0], p[1])) for p in path_yz]
    quads = []
    for i, p in enumerate(pts):
        tangent = (pts[min(i + 1, len(pts) - 1)] - pts[max(i - 1, 0)]).normalized()
        normal = Vector((-tangent.y, tangent.x)) * (width / 2)
        quads.append([bm.verts.new((x, (p + s * normal).x, (p + s * normal).y)) for x, s in
                      ((-thickness / 2, -1), (-thickness / 2, 1), (thickness / 2, 1), (thickness / 2, -1))])
    for i in range(len(quads) - 1):
        a, b = quads[i], quads[i + 1]
        for k in range(4):
            bm.faces.new((a[k], a[(k + 1) % 4], b[(k + 1) % 4], b[k]))
    bm.faces.new(list(reversed(quads[0])))
    bm.faces.new(quads[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return object_from_bmesh(name, bm, material)


def tube_along(name, points, radii, sides=16, material=None) -> bpy.types.Object:
    """A capped tube through `points` (Vectors) with a radius per point."""
    bm = bmesh.new()
    rings = []
    for i, (p, r) in enumerate(zip(points, radii)):
        tangent = (points[min(i + 1, len(points) - 1)] - points[max(i - 1, 0)]).normalized()
        helper = Vector((0, 0, 1)) if abs(tangent.z) < 0.95 else Vector((1, 0, 0))
        a = tangent.cross(helper).normalized()
        b = tangent.cross(a).normalized()
        rings.append([bm.verts.new(p + r * (a * math.cos(2 * math.pi * k / sides) + b * math.sin(2 * math.pi * k / sides)))
                      for k in range(sides)])
    for i in range(len(rings) - 1):
        for k in range(sides):
            bm.faces.new((rings[i][k], rings[i][(k + 1) % sides], rings[i + 1][(k + 1) % sides], rings[i + 1][k]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    return object_from_bmesh(name, bm, material)


# --- modifiers, applied at once ----------------------------------------------------------------------------

def apply_modifiers(obj: bpy.types.Object) -> bpy.types.Object:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(depsgraph))
    old = obj.data
    obj.modifiers.clear()
    obj.data = mesh
    bpy.data.meshes.remove(old)
    return obj


def bevel(obj, width, segments=3, angle=35.0) -> bpy.types.Object:
    mod = obj.modifiers.new("Bevel", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.limit_method = "ANGLE"
    mod.angle_limit = math.radians(angle)
    mod.profile = 0.6
    return apply_modifiers(obj)


def subtract(obj, cutters) -> bpy.types.Object:
    """Cuts every cutter object out of `obj`, then deletes the cutters."""
    cutter = join(list(cutters), obj.name + "_Cut") if len(cutters) > 1 else cutters[0]
    mod = obj.modifiers.new("Cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.solver = "EXACT"
    mod.object = cutter
    apply_modifiers(obj)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return obj


def join(objs, name) -> bpy.types.Object:
    target = objs[0]
    with bpy.context.temp_override(active_object=target, selected_editable_objects=objs, object=target):
        bpy.ops.object.join()
    target.name = name
    target.data.name = name
    return target


def smooth_by_angle(obj, degrees=32.0) -> bpy.types.Object:
    """Smooth shading, with edges sharper than `degrees` kept sharp."""
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    limit = math.radians(degrees)
    for face in bm.faces:
        face.smooth = True
    for edge in bm.edges:
        edge.smooth = not (edge.is_manifold and edge.calc_face_angle(0) > limit) and edge.is_manifold
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return obj


# --- materials ---------------------------------------------------------------------------------------------

def _principled(material):
    material.use_nodes = True
    nodes = material.node_tree.nodes
    return nodes.get("Principled BSDF"), nodes, material.node_tree.links


def _noise(nodes, scale, detail=6.0, roughness=0.55):
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = scale
    noise.inputs["Detail"].default_value = detail
    noise.inputs["Roughness"].default_value = roughness
    return noise


def _ramp(nodes, stops):
    ramp = nodes.new("ShaderNodeValToRGB")
    elements = ramp.color_ramp.elements
    elements[0].position, elements[0].color = stops[0][0], (*stops[0][1], 1)
    elements[1].position, elements[1].color = stops[-1][0], (*stops[-1][1], 1)
    for position, colour in stops[1:-1]:
        element = elements.new(position)
        element.color = (*colour, 1)
    return ramp


def _socket(sockets, identifier):
    """A node socket by identifier: Mix nodes repeat names ("A", "Result") across their float/vector/colour modes."""
    return next(s for s in sockets if s.identifier == identifier)


def _mix_colour(nodes, links, factor, a, b):
    """Mixes colour sockets/values `a` and `b` by `factor` (a socket); returns the colour output."""
    mix = nodes.new("ShaderNodeMix")
    mix.data_type = "RGBA"
    links.new(factor, _socket(mix.inputs, "Factor_Float"))
    for value, identifier in ((a, "A_Color"), (b, "B_Color")):
        if isinstance(value, tuple):
            _socket(mix.inputs, identifier).default_value = value
        else:
            links.new(value, _socket(mix.inputs, identifier))
    return _socket(mix.outputs, "Result_Color")


def _edge_mask(nodes, links, sharpness=(0.52, 0.6)):
    """1 on convex edges (Cycles pointiness), 0 on flat faces: where wear shows."""
    geometry = nodes.new("ShaderNodeNewGeometry")
    ramp = _ramp(nodes, [(sharpness[0], (0, 0, 0)), (sharpness[1], (1, 1, 1))])
    links.new(geometry.outputs["Pointiness"], ramp.inputs["Fac"])
    return ramp


def _box_mask(nodes, links, box, mirror_x=True):
    """1 inside an object-space box ((x0, x1), (y0, y1), (z0, z1)), 0 outside; with mirror_x the X range applies to |x|."""
    coords = nodes.new("ShaderNodeTexCoord")
    split = nodes.new("ShaderNodeSeparateXYZ")
    links.new(coords.outputs["Object"], split.inputs["Vector"])
    product = None
    for axis, (low, high) in zip(("X", "Y", "Z"), box):
        value = split.outputs[axis]
        if axis == "X" and mirror_x:
            absolute = nodes.new("ShaderNodeMath")
            absolute.operation = "ABSOLUTE"
            links.new(value, absolute.inputs[0])
            value = absolute.outputs[0]
        for bound, operation in ((low, "GREATER_THAN"), (high, "LESS_THAN")):
            test = nodes.new("ShaderNodeMath")
            test.operation = operation
            links.new(value, test.inputs[0])
            test.inputs[1].default_value = bound
            if product is None:
                product = test.outputs[0]
            else:
                multiply = nodes.new("ShaderNodeMath")
                multiply.operation = "MULTIPLY"
                links.new(product, multiply.inputs[0])
                links.new(test.outputs[0], multiply.inputs[1])
                product = multiply.outputs[0]
    return product


def _guilloche(nodes, links, spacing):
    """Engine-turned engraving: two families of fine wavy lines crossing, 0..1 (1 = the cut)."""
    coords = nodes.new("ShaderNodeTexCoord")
    lines = []
    for rotation in (0.5, -0.5):
        mapping = nodes.new("ShaderNodeMapping")
        mapping.inputs["Rotation"].default_value = (rotation, 0.0, 0.0)
        links.new(coords.outputs["Object"], mapping.inputs["Vector"])
        wave = nodes.new("ShaderNodeTexWave")
        wave.wave_type = "BANDS"
        wave.bands_direction = "Z"
        wave.wave_profile = "SIN"
        wave.inputs["Scale"].default_value = 1.0 / spacing
        wave.inputs["Distortion"].default_value = 1.2
        wave.inputs["Detail"].default_value = 0.0
        links.new(mapping.outputs["Vector"], wave.inputs["Vector"])
        cut = _ramp(nodes, [(0.0, (1, 1, 1)), (0.18, (0, 0, 0))])
        links.new(wave.outputs["Fac"], cut.inputs["Fac"])
        lines.append(cut.outputs["Color"])
    union = nodes.new("ShaderNodeMath")
    union.operation = "MAXIMUM"
    links.new(lines[0], union.inputs[0])
    links.new(lines[1], union.inputs[1])
    return union.outputs[0]


def steel_material(name="Steel_Blackened", engrave_box=None):
    """Blued, blackened gun steel: a dark mirror, faintly mottled, polished bright where edges wear. With `engrave_box`
    (object space, mirrored in X) the surfaces inside carry fine engine-turned engraving, its cuts silvered.
    Calibrated for Roblox: a metal's base colour is its reflectance, and Roblox's dusk worlds give little to reflect,
    so blued steel sits near 15-20 % (a 3-6 % "black" steel renders flat black in game) and stays glossy."""
    material = bpy.data.materials.new(name)
    bsdf, nodes, links = _principled(material)
    bsdf.inputs["Metallic"].default_value = 1.0
    mottle = _noise(nodes, 18.0)
    tint = _ramp(nodes, [(0.3, (0.135, 0.140, 0.160)), (0.7, (0.200, 0.200, 0.228))])
    links.new(mottle.outputs["Fac"], tint.inputs["Fac"])
    edges = _edge_mask(nodes, links)
    colour = _mix_colour(nodes, links, edges.outputs["Color"], tint.outputs["Color"], (0.56, 0.56, 0.58, 1))
    rough = _ramp(nodes, [(0.35, (0.20, 0.20, 0.20)), (0.75, (0.32, 0.32, 0.32))])
    links.new(mottle.outputs["Fac"], rough.inputs["Fac"])
    roughness = _mix_colour(nodes, links, edges.outputs["Color"], rough.outputs["Color"], (0.13, 0.13, 0.13, 1))
    if engrave_box:
        mask = _box_mask(nodes, links, engrave_box)
        cut = nodes.new("ShaderNodeMath")
        cut.operation = "MULTIPLY"
        links.new(_guilloche(nodes, links, 0.011), cut.inputs[0])
        links.new(mask, cut.inputs[1])
        colour = _mix_colour(nodes, links, cut.outputs[0], colour, (0.30, 0.30, 0.32, 1))
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Strength"].default_value = 0.6
        bump.inputs["Distance"].default_value = 0.002
        bump.invert = True
        links.new(cut.outputs[0], bump.inputs["Height"])
        links.new(bump.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(colour, bsdf.inputs["Base Color"])
    links.new(roughness, bsdf.inputs["Roughness"])
    return material


def brass_material(name="Brass_Aged"):
    """Aged brass: warm, darker in recesses (ambient occlusion), bright on worn edges; polished enough to catch
    every light in a Roblox night."""
    material = bpy.data.materials.new(name)
    bsdf, nodes, links = _principled(material)
    bsdf.inputs["Metallic"].default_value = 1.0
    occlusion = nodes.new("ShaderNodeAmbientOcclusion")
    occlusion.inputs["Distance"].default_value = 0.05
    shade = _ramp(nodes, [(0.0, (0.22, 0.13, 0.05)), (0.85, (0.76, 0.54, 0.22)), (1.0, (0.92, 0.74, 0.40))])
    links.new(occlusion.outputs["AO"], shade.inputs["Fac"])
    links.new(shade.outputs["Color"], bsdf.inputs["Base Color"])
    mottle = _noise(nodes, 25.0)
    rough = _ramp(nodes, [(0.3, (0.15, 0.15, 0.15)), (0.75, (0.28, 0.28, 0.28))])
    links.new(mottle.outputs["Fac"], rough.inputs["Fac"])
    links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    return material


def walnut_material(name="Walnut_Oiled", across="Y"):
    """Oiled dark walnut: fine straight grain whose stripes vary along the object-space axis `across` (so the fibres
    run the other way along the surface), gently wavy, with darker figure; a thin coat of oil on top."""
    material = bpy.data.materials.new(name)
    bsdf, nodes, links = _principled(material)
    coords = nodes.new("ShaderNodeTexCoord")
    wave = nodes.new("ShaderNodeTexWave")
    wave.wave_type = "BANDS"
    wave.bands_direction = across
    wave.inputs["Scale"].default_value = 26.0
    wave.inputs["Distortion"].default_value = 2.2
    wave.inputs["Detail"].default_value = 6.0
    wave.inputs["Detail Scale"].default_value = 1.5
    links.new(coords.outputs["Object"], wave.inputs["Vector"])
    figure = _noise(nodes, 6.0, 4.0, 0.5)
    links.new(coords.outputs["Object"], figure.inputs["Vector"])
    grain = _ramp(nodes, [(0.15, (0.042, 0.019, 0.009)), (0.5, (0.098, 0.045, 0.022)), (0.85, (0.155, 0.076, 0.037))])
    links.new(wave.outputs["Fac"], grain.inputs["Fac"])
    shade = _ramp(nodes, [(0.3, (0.55, 0.55, 0.55)), (0.7, (1.0, 1.0, 1.0))])
    links.new(figure.outputs["Fac"], shade.inputs["Fac"])
    multiply = nodes.new("ShaderNodeMix")
    multiply.data_type = "RGBA"
    multiply.blend_type = "MULTIPLY"
    _socket(multiply.inputs, "Factor_Float").default_value = 1.0
    links.new(grain.outputs["Color"], _socket(multiply.inputs, "A_Color"))
    links.new(shade.outputs["Color"], _socket(multiply.inputs, "B_Color"))
    links.new(_socket(multiply.outputs, "Result_Color"), bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.36  # the oil's sheen: Roblox gets this map, not the coat below
    bsdf.inputs["Coat Weight"].default_value = 0.3
    bsdf.inputs["Coat Roughness"].default_value = 0.3
    return material


def crystal_material(name="Crystal_Light", tint=(1.0, 0.93, 0.78)):
    """A pale warm crystal with a faint inner light."""
    material = bpy.data.materials.new(name)
    bsdf, nodes, links = _principled(material)
    bsdf.inputs["Base Color"].default_value = (*tint, 1)
    bsdf.inputs["Roughness"].default_value = 0.05
    bsdf.inputs["Transmission Weight"].default_value = 0.9
    bsdf.inputs["IOR"].default_value = 1.6
    bsdf.inputs["Emission Color"].default_value = (1.0, 0.85, 0.55, 1)
    bsdf.inputs["Emission Strength"].default_value = 0.6
    return material


# --- texture baking ----------------------------------------------------------------------------------------

def use_gpu(scene):
    """Cycles on the GPU (OptiX, else CUDA) when there is one."""
    scene.render.engine = "CYCLES"
    prefs = bpy.context.preferences.addons["cycles"].preferences
    for kind in ("OPTIX", "CUDA"):
        try:
            prefs.compute_device_type = kind
            prefs.get_devices()
            if any(d.type == kind for d in prefs.devices):
                for d in prefs.devices:
                    d.use = d.type == kind
                scene.cycles.device = "GPU"
                return
        except Exception:
            continue


def _select_only(obj):
    layer = bpy.context.view_layer
    for other in layer.objects:
        other.select_set(False)
    obj.select_set(True)
    layer.objects.active = obj


def unwrap(obj, angle=60.0, margin=0.012):
    """Smart UV projection of the whole mesh into one 0..1 atlas. The margin (12 px at 1024) keeps islands apart
    down the mip chain: at 4 px a garnet's red bled into the gun's barrel slots seen from a few studs away."""
    _select_only(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(angle), island_margin=margin)
    bpy.ops.object.mode_set(mode="OBJECT")


class _Emitting:
    """While active, every material shows one Principled input (its link or value) as pure emission, for baking it."""

    def __init__(self, materials, input_name):
        self.materials, self.input_name, self.saved = materials, input_name, []

    def __enter__(self):
        for material in self.materials:
            tree = material.node_tree
            bsdf = next(n for n in tree.nodes if n.type == "BSDF_PRINCIPLED")
            output = next(n for n in tree.nodes if n.type == "OUTPUT_MATERIAL")
            surface = output.inputs["Surface"]
            previous = surface.links[0].from_socket if surface.links else None
            emission = tree.nodes.new("ShaderNodeEmission")
            source = bsdf.inputs[self.input_name]
            if source.links:
                tree.links.new(source.links[0].from_socket, emission.inputs["Color"])
            else:
                value = source.default_value
                emission.inputs["Color"].default_value = tuple(value) if hasattr(value, "__len__") else (value, value, value, 1)
            tree.links.new(emission.outputs["Emission"], surface)
            self.saved.append((tree, surface, previous, emission))
        return self

    def __exit__(self, *_):
        for tree, surface, previous, emission in self.saved:
            tree.nodes.remove(emission)
            if previous:
                tree.links.new(previous, surface)


class _Glowing:
    """While active, every material is pure emission: white for the names in `lit`, black for the rest (a mask)."""

    def __init__(self, materials, lit):
        self.materials, self.lit, self.saved = materials, set(lit), []

    def __enter__(self):
        for material in self.materials:
            tree = material.node_tree
            output = next(n for n in tree.nodes if n.type == "OUTPUT_MATERIAL")
            surface = output.inputs["Surface"]
            previous = surface.links[0].from_socket if surface.links else None
            emission = tree.nodes.new("ShaderNodeEmission")
            value = 1.0 if material.name in self.lit else 0.0
            emission.inputs["Color"].default_value = (value, value, value, 1)
            tree.links.new(emission.outputs["Emission"], surface)
            self.saved.append((tree, surface, previous, emission))
        return self

    __exit__ = _Emitting.__exit__


def bake_pbr(obj, size, folder: Path, prefix: str, samples=64, emissive=()) -> dict:
    """Bakes the object's materials into one PBR texture set for a Roblox SurfaceAppearance: Color (sRGB), Normal
    (OpenGL tangent space), Roughness and Metalness (linear). With `emissive` (material names) also an Emissive mask,
    white where those materials are (SurfaceAppearance.EmissiveMaskContent). Needs UVs. Returns {kind: path}."""
    scene = bpy.context.scene
    use_gpu(scene)
    scene.cycles.samples = samples
    scene.render.bake.margin = 16  # pads each island with its own colours, out into the gap the unwrap left
    images = {}
    kinds = [("Color", "sRGB"), ("Normal", "Non-Color"), ("Roughness", "Non-Color"), ("Metalness", "Non-Color")]
    if emissive:
        kinds.append(("Emissive", "Non-Color"))
    for kind, space in kinds:
        image = bpy.data.images.new(f"{prefix}_{kind}", size, size, alpha=False)
        image.colorspace_settings.name = space
        images[kind] = image
    materials = [slot.material for slot in obj.material_slots if slot.material]
    targets = []
    for material in materials:
        node = material.node_tree.nodes.new("ShaderNodeTexImage")
        material.node_tree.nodes.active = node
        targets.append(node)
    _select_only(obj)

    def bake(kind, bake_type, **options):
        for node in targets:
            node.image = images[kind]
        bpy.ops.object.bake(type=bake_type, use_clear=True, **options)

    bake("Normal", "NORMAL", normal_space="TANGENT")
    bake("Roughness", "ROUGHNESS")
    with _Emitting(materials, "Base Color"):
        bake("Color", "EMIT")
    with _Emitting(materials, "Metallic"):
        bake("Metalness", "EMIT")
    if emissive:
        with _Glowing(materials, emissive):
            bake("Emissive", "EMIT")
    paths = {}
    for kind, image in images.items():
        path = folder / f"{prefix}_{kind}.png"
        image.filepath_raw = str(path)
        image.file_format = "PNG"
        image.save()
        paths[kind] = path
    return paths


EMISSIVE_PREVIEW = 4.0  # preview emission strength; match the model's SurfaceAppearance.EmissiveStrength


def baked_material(name, paths: dict) -> bpy.types.Material:
    """A material made only of the baked maps: what the object will look like in Roblox."""
    material = bpy.data.materials.new(name)
    bsdf, nodes, links = _principled(material)

    def texture(kind, non_colour):
        node = nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(str(paths[kind]))
        if non_colour:
            node.image.colorspace_settings.name = "Non-Color"
        return node

    colour = texture("Color", False).outputs["Color"]
    links.new(colour, bsdf.inputs["Base Color"])
    if "Emissive" in paths:  # as Roblox draws it: the colour map, lit by the mask times EMISSIVE_PREVIEW
        strength = nodes.new("ShaderNodeMath")
        strength.operation = "MULTIPLY"
        strength.inputs[1].default_value = EMISSIVE_PREVIEW
        links.new(texture("Emissive", True).outputs["Color"], strength.inputs[0])
        links.new(colour, bsdf.inputs["Emission Color"])
        links.new(strength.outputs[0], bsdf.inputs["Emission Strength"])
    links.new(texture("Roughness", True).outputs["Color"], bsdf.inputs["Roughness"])
    links.new(texture("Metalness", True).outputs["Color"], bsdf.inputs["Metallic"])
    normal_map = nodes.new("ShaderNodeNormalMap")
    links.new(texture("Normal", True).outputs["Color"], normal_map.inputs["Color"])
    links.new(normal_map.outputs["Normal"], bsdf.inputs["Normal"])
    return material


def assign_only(obj, material):
    obj.data.materials.clear()
    obj.data.materials.append(material)


# --- preview renders ---------------------------------------------------------------------------------------

def studio(scene, samples=96, size=(1600, 1000)):
    """A dark studio: warm key, cool rim, soft fill, a matte backdrop. Cycles on the GPU when there is one."""
    use_gpu(scene)
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("Studio")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.012, 0.010, 0.014, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 1.0
    scene.world = world
    backdrop = cylinder("Backdrop", 30, 0.1, 64)
    place(backdrop, location=(0, 0, -1.2))
    matte = bpy.data.materials.new("Backdrop")
    bsdf, _, _ = _principled(matte)
    bsdf.inputs["Base Color"].default_value = (0.035, 0.030, 0.038, 1)
    bsdf.inputs["Roughness"].default_value = 0.8
    backdrop.data.materials.append(matte)
    _area("Key", (2.6, -2.2, 3.0), (1.0, 0.86, 0.72), 900, 2.5)
    _area("Rim", (-2.4, 3.0, 2.2), (0.62, 0.72, 1.0), 700, 2.0)
    _area("Fill", (-3.0, -2.6, 0.6), (0.9, 0.85, 0.95), 160, 3.0)


def _area(name, location, colour, power, size):
    light = bpy.data.lights.new(name, "AREA")
    light.color = colour
    light.energy = power
    light.size = size
    obj = bpy.data.objects.new(name, light)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = location
    direction = Vector((0, 0, 0)) - Vector(location)
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def render_views(scene, target_center, radius, folder: Path, prefix: str, views):
    """Renders each (name, azimuth°, elevation°, lens mm) view of a subject of `radius` around `target_center`."""
    camera_data = bpy.data.cameras.new("Camera")
    camera = bpy.data.objects.new("Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    written = []
    for name, azimuth, elevation, lens in views:
        camera_data.lens = lens
        distance = radius * lens / 18.0
        a, e = math.radians(azimuth), math.radians(elevation)
        offset = Vector((math.cos(e) * math.sin(a), -math.cos(e) * math.cos(a), math.sin(e))) * distance
        camera.location = Vector(target_center) + offset
        camera.rotation_euler = (-offset).to_track_quat("-Z", "Y").to_euler()
        path = folder / f"{prefix}_{name}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        written.append(path)
    return written


def save_blend(path: Path):
    bpy.ops.wm.save_as_mainfile(filepath=str(path))


# --- export for Roblox (EditableMesh) ------------------------------------------------------------------------------

def export_mesh_json(obj, path: Path, uv=True):
    """Writes the mesh as JSON for Studio's EditableMesh, in Roblox's frame: Roblox X = Blender X, Roblox Y = Blender Z,
    Roblox Z = -Blender Y (so Blender's +Y, a gun's muzzle, becomes Roblox's look direction -Z); V flipped (Roblox's
    UV origin is top left). Triangles carry per-corner normal and UV indices (split normals and seams survive).
    Positions are centred on their bounding box (a published mesh keeps its vertex origin as the part's position, so an
    off-centre mesh would draw outside its part's bounds); "c" gives that centre in the model's frame, where the part
    goes. {"c": [x,y,z], "p": [x,y,z,...], "n": [...], "t": [u,v,...], "f": [p0,p1,p2, n0,n1,n2, t0,t1,t2, ...]}"""
    import json
    mesh = obj.data
    mesh.calc_loop_triangles()
    corner_normals = mesh.corner_normals
    uv_layer = mesh.uv_layers.active.uv if uv and mesh.uv_layers.active else None
    roblox = [Vector((v.co.x, v.co.z, -v.co.y)) for v in mesh.vertices]
    low = Vector((min(p.x for p in roblox), min(p.y for p in roblox), min(p.z for p in roblox)))
    high = Vector((max(p.x for p in roblox), max(p.y for p in roblox), max(p.z for p in roblox)))
    centre = (low + high) / 2
    positions = []
    for p in roblox:
        positions += [round(p.x - centre.x, 5), round(p.y - centre.y, 5), round(p.z - centre.z, 5)]
    normals, normal_index = [], {}
    uvs, uv_index = [], {}
    faces = []

    def index_of(table, store, key):
        found = table.get(key)
        if found is None:
            found = len(store) // len(key)
            table[key] = found
            store.extend(key)
        return found

    for tri in mesh.loop_triangles:
        corners = list(tri.loops)
        p = [mesh.loops[c].vertex_index for c in corners]
        n = []
        t = []
        for c in corners:
            normal = corner_normals[c].vector
            n.append(index_of(normal_index, normals, (round(normal.x, 4), round(normal.z, 4), round(-normal.y, 4))))
            if uv_layer:
                coord = uv_layer[c].vector
                t.append(index_of(uv_index, uvs, (round(coord.x, 5), round(1 - coord.y, 5))))
            else:
                t.append(0)
        faces += p + n + t
    if not uvs:
        uvs = [0.0, 0.0]
    record = {"c": [round(centre.x, 5), round(centre.y, 5), round(centre.z, 5)], "p": positions, "n": normals, "t": uvs, "f": faces}
    path.write_text(json.dumps(record, separators=(",", ":")))
    return len(mesh.loop_triangles)
