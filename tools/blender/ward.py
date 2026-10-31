"""The ward (C1.6): the guard's crimson glass buckler, built headless in Blender (our own model).
  Lens  a shallow glass lens 1.9 studs across: a domed face toward the attacker, a flatter back, a thin edge. Its UVs
        project the face straight on (u from X, v from Z), the way the game's tracery Decals project onto it.
  Rim   a thin torus round the lens: the hot edge.
Forward (toward the attacker) is Blender +Y, Roblox's -Z. Writes Lens.json and Rim.json for ModelAssembly (studs,
centred), and review renders: the clay form, then the glass with the tracery as it should read in the game.

Run: blender.exe -b --factory-startup --python tools/blender/ward.py -- <out_dir> [tracery.png]
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bc  # noqa: E402
import bmesh  # noqa: E402
import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

OUT = bc.out_dir()
ARGS = sys.argv[sys.argv.index("--") + 2:] if "--" in sys.argv else []
TRACERY = Path(ARGS[0]) if ARGS else None

RADIUS = 0.95  # studs: the lens is 1.9 across (about a third of a body's height, as in the reference)
FACE_DOME, BACK_DOME = 0.10, 0.045  # how far the face and the back bulge at the centre
EDGE = 0.05  # the thickness at the edge
SEGMENTS, RINGS = 72, 14
RIM_TUBE = 0.045  # the rim's tube radius
CRIMSON_GLASS = (0.11, 0.004, 0.012)  # dark: the ward is darker at its centre
GOLD_RED = (1.0, 0.36, 0.16)  # the tracery's lines


def lens():
    """The lens as rings of quads: a fan at each centre, face and back joined by a short edge wall (kept sharp)."""
    bm = bmesh.new()
    uv = bm.loops.layers.uv.new("UVMap")

    def surface(sign, dome):
        centre = bm.verts.new((0, sign * (EDGE / 2 + dome), 0))
        rings = []
        for i in range(1, RINGS + 1):
            r = RADIUS * i / RINGS
            y = sign * (EDGE / 2 + dome * (1 - (r / RADIUS) ** 2))
            rings.append([bm.verts.new((r * math.cos(a), y, r * math.sin(a)))
                          for a in (2 * math.pi * j / SEGMENTS for j in range(SEGMENTS))])
        faces = []
        for j in range(SEGMENTS):
            k = (j + 1) % SEGMENTS
            tri = (centre, rings[0][j], rings[0][k])
            faces.append(bm.faces.new(tri if sign < 0 else tuple(reversed(tri))))
        for inner, outer in zip(rings, rings[1:]):
            for j in range(SEGMENTS):
                k = (j + 1) % SEGMENTS
                quad = (inner[j], outer[j], outer[k], inner[k])
                faces.append(bm.faces.new(quad if sign < 0 else tuple(reversed(quad))))
        return rings[-1], faces

    face_edge, face = surface(1, FACE_DOME)
    back_edge, back = surface(-1, BACK_DOME)
    wall = []
    for j in range(SEGMENTS):
        k = (j + 1) % SEGMENTS
        wall.append(bm.faces.new((face_edge[j], face_edge[k], back_edge[k], back_edge[j])))
    bm.normal_update()
    for f in face + back + wall:
        f.smooth = f not in wall
        for loop in f.loops:
            co = loop.vert.co
            loop[uv].uv = (0.5 + co.x / (2 * RADIUS), 0.5 + co.z / (2 * RADIUS))
    for e in bm.edges:  # the wall meets face and back at a crisp edge
        e.smooth = not (len(e.link_faces) == 2 and (e.link_faces[0] in wall) != (e.link_faces[1] in wall))
    return bc.object_from_bmesh("Lens", bm)


def rim():
    obj = bc.torus("Rim", RADIUS, RIM_TUBE, major_segments=SEGMENTS, minor_segments=10)
    bc.place(obj, rotation=(90, 0, 0))  # the torus's axis from Z to Y: round the lens's edge
    return bc.smooth_by_angle(obj, 60)


def glass_material():
    """Dark crimson glass with the tracery glowing in it (review only: in the game the tracery is a Decal)."""
    material = bpy.data.materials.new("Ward_Glass")
    bsdf, nodes, links = bc._principled(material)
    bsdf.inputs["Base Color"].default_value = (*CRIMSON_GLASS, 1)
    bsdf.inputs["Roughness"].default_value = 0.04
    bsdf.inputs["Transmission Weight"].default_value = 0.65
    bsdf.inputs["IOR"].default_value = 1.5
    if TRACERY and TRACERY.exists():
        image = nodes.new("ShaderNodeTexImage")
        image.image = bpy.data.images.load(str(TRACERY))
        coords = nodes.new("ShaderNodeUVMap")
        coords.uv_map = "UVMap"
        links.new(coords.outputs["UV"], image.inputs["Vector"])
        links.new(image.outputs["Alpha"], bsdf.inputs["Emission Strength"])
        bsdf.inputs["Emission Color"].default_value = (*GOLD_RED, 1)
    return material


def rim_material():
    material = bpy.data.materials.new("Ward_Rim")
    bsdf, _, _ = bc._principled(material)
    bsdf.inputs["Base Color"].default_value = (0.6, 0.05, 0.03, 1)
    bsdf.inputs["Emission Color"].default_value = (1.0, 0.18, 0.08, 1)
    bsdf.inputs["Emission Strength"].default_value = 6.0
    return material


def main():
    scene = bc.reset_scene()
    lens_obj, rim_obj = lens(), rim()
    lens_tris = bc.export_mesh_json(lens_obj, OUT / "Lens.json")
    rim_tris = bc.export_mesh_json(rim_obj, OUT / "Rim.json", uv=False)
    print(f"BL_WARD lens {lens_tris} triangles, rim {rim_tris}")
    bc.studio(scene, samples=64, size=(1200, 900))
    for obj in (lens_obj, rim_obj):
        obj.location = Vector((0, 0, 1.0))  # above the backdrop
    views = [("face", 180, 8, 50), ("player", 20, 14, 50), ("edge", 90, 0, 50)]
    clay = bpy.data.materials.new("Clay")
    bc._principled(clay)[0].inputs["Base Color"].default_value = (0.5, 0.48, 0.46, 1)
    for obj in (lens_obj, rim_obj):
        obj.data.materials.append(clay)
    bc.render_views(scene, (0, 0, 1.0), 1.3, OUT, "clay", views)
    bc.assign_only(lens_obj, glass_material())
    bc.assign_only(rim_obj, rim_material())
    bc.render_views(scene, (0, 0, 1.0), 1.3, OUT, "glass", views[:2])


main()
