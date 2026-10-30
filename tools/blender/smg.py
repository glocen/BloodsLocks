"""Gustave's machine pistol: a one-handed Victorian burst gun for the left hand (our own design, after the brief of
Duskbloods' saber-and-SMG Bloodsworn, never a copy). Blackened steel, aged brass, oiled walnut, and an amber light
crystal in a jeweller's setting on top: the Light Beam leaves from it.

Run: blender.exe -b --factory-startup --python tools/blender/smg.py -- <out_dir>
Writes <out_dir>/smg.blend and preview renders smg_<view>.png. Studs, X right, Y forward (muzzle), Z up; the grip,
where the hand closes, is at the origin.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bmesh  # noqa: E402
import blcommon as bc  # noqa: E402
from mathutils import Vector  # noqa: E402

OUT = bc.out_dir()
scene = bc.reset_scene()

HAND = Vector((0, -0.47, -0.20))  # the middle of the grip: the model's origin once assembled
STEEL = bc.steel_material()
BRASS = bc.brass_material()
WOOD = bc.walnut_material(across="Y")  # the grip panels lie in the YZ plane, their fibres running down the grip
AMBER = bc.crystal_material("Crystal_Amber", tint=(1.0, 0.62, 0.22))
AMBER.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (1.0, 0.55, 0.18, 1)
AMBER.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = 0.45
GARNET = bc.garnet_material()

BORE_Z = 0.22  # the barrel's axis height
HALF = 0.065  # half the frame's thickness
body = []  # every piece but the crystal; joined at the end


def keep(obj):
    body.append(obj)
    return obj


def along_y(obj, y, z=BORE_Z):
    """Turns a Z-axis primitive to lie along the barrel (Y) and moves it to (0, y, z)."""
    return bc.place(obj, location=(0, y, z), rotation=(90, 0, 0))


# --- the frame: receiver, rear hump and raked grip in one side profile ----------------------------------------
FRAME = [
    (0.56, 0.31), (-0.22, 0.31), (-0.26, 0.335), (-0.36, 0.335), (-0.42, 0.31), (-0.455, 0.27), (-0.465, 0.18),
    (-0.47, 0.10), (-0.50, 0.00), (-0.545, -0.20), (-0.585, -0.40), (-0.585, -0.45), (-0.565, -0.48), (-0.45, -0.49),
    (-0.42, -0.44), (-0.385, -0.25), (-0.36, -0.08), (-0.34, 0.0), (-0.31, 0.045), (0.50, 0.045), (0.56, 0.10),
]
PANEL_Y, PANEL_Z = (-0.27, 0.45), (0.115, 0.255)  # the sunken flank panel's inner edges


def filigree(side):
    """A fine brass border inset in the flank panel, its corners rolled into small scrolls."""
    x = side * (HALF - 0.004)
    inset = 0.016
    (y0, y1), (z0, z1) = PANEL_Y, PANEL_Z
    y0, y1, z0, z1 = y0 + inset, y1 - inset, z0 + inset, z1 - inset
    curl = 0.022

    def scroll(cy, cz, dy, dz):
        """A quarter-turn spiral tucked into a corner (dy, dz point into the panel)."""
        points = []
        for k in range(14):
            t = k / 13
            angle = math.pi * 1.6 * t
            radius = curl * (1 - 0.75 * t)
            points.append(Vector((x, cy + dy * (curl - radius * math.cos(angle)), cz + dz * (curl - radius * math.sin(angle)))))
        return points

    corners = [(y0, z0, 1, 1), (y1, z0, -1, 1), (y1, z1, -1, -1), (y0, z1, 1, -1)]
    parts = [bc.tube_along(f"Border{side}", [Vector((x, y0 + curl, z0)), Vector((x, y1 - curl, z0))], [0.0042, 0.0042], 8, BRASS),
             bc.tube_along(f"BorderTop{side}", [Vector((x, y0 + curl, z1)), Vector((x, y1 - curl, z1))], [0.0042, 0.0042], 8, BRASS),
             bc.tube_along(f"BorderBack{side}", [Vector((x, y0, z0 + curl)), Vector((x, y0, z1 - curl))], [0.0042, 0.0042], 8, BRASS),
             bc.tube_along(f"BorderFront{side}", [Vector((x, y1, z0 + curl)), Vector((x, y1, z1 - curl))], [0.0042, 0.0042], 8, BRASS)]
    for i, (cy, cz, dy, dz) in enumerate(corners):
        parts.append(bc.tube_along(f"Scroll{side}{i}", scroll(cy, cz, dy, dz), [0.0042 * (1 - 0.5 * k / 13) for k in range(14)], 8, BRASS))
    return bc.join(parts, f"Filigree{side}")


frame = bc.bevel(bc.profile("Frame", FRAME, HALF * 2, STEEL), 0.016, 3, 30)
insets = [bc.place(bc.box(f"Inset{s}", (0.012, 0.74, 0.16)), location=(s * HALF, 0.09, 0.185)) for s in (-1, 1)]
keep(bc.subtract(frame, insets))  # a shallow sunken panel on each flank frames the medallion

GRIP_SCALE = [(-0.475, 0.06), (-0.51, -0.05), (-0.555, -0.38), (-0.545, -0.44), (-0.465, -0.455), (-0.43, -0.42),
              (-0.40, -0.24), (-0.38, -0.06), (-0.39, 0.03)]
for s in (-1, 1):
    keep(bc.bevel(bc.profile(f"GripScale{s}", GRIP_SCALE, 0.022, WOOD, x=s * (HALF + 0.011)), 0.009, 3, 30))
    keep(bc.place(bc.cylinder(f"GripScrew{s}", 0.017, 0.01, 24, BRASS), location=(s * (HALF + 0.023), -0.475, -0.20), rotation=(0, 90, 0)))
    for z in (0.065, 0.295):  # brass rails along the flanks
        keep(bc.tube_along(f"Rail{s}{z}", [Vector((s * (HALF + 0.003), -0.42, z)), Vector((s * (HALF + 0.003), 0.54, z))], [0.0075, 0.0075], 10, BRASS))
    for y, z in ((-0.38, 0.12), (-0.38, 0.25), (0.50, 0.12), (0.50, 0.25)):
        keep(bc.place(bc.sphere(f"Rivet{s}{y}{z}", 0.010, 12, 6, BRASS), location=(s * (HALF + 0.001), y, z)))
    keep(bc.place(bc.cylinder(f"Medallion{s}", 0.060, 0.012, 40, BRASS), location=(s * (HALF - 0.002), 0.09, 0.185), rotation=(0, 90, 0), scale=(1.0, 1.35, 1.0)))
    keep(bc.place(bc.torus(f"MedallionRim{s}", 0.058, 0.007, 48, 10, BRASS), location=(s * (HALF + 0.004), 0.09, 0.185), rotation=(0, 90, 0), scale=(1.0, 1.35, 1.0)))
    keep(bc.place(bc.sphere(f"Garnet{s}", 0.022, 8, 4, GARNET), location=(s * (HALF + 0.004), 0.09, 0.185), scale=(0.55, 1.0, 1.0)))  # few, large facets catch the light
    keep(filigree(s))

# --- barrel and its jacket -------------------------------------------------------------------------------------
jacket = along_y(bc.cylinder("Jacket", 0.080, 0.92, 48, STEEL), 1.00)
bore = along_y(bc.cylinder("JacketBore", 0.066, 1.0, 48), 1.00)
slots = []
for angle in (0, 58, -58):  # three rows of oval cooling slots, each cut through both walls
    for i in range(7):
        slot = bc.cylinder(f"Slot{angle}_{i}", 0.017, 0.3, 16)
        slots.append(bc.place(slot, location=(0, 0.66 + i * 0.113, BORE_Z), rotation=(0, angle, 0), scale=(1.0, 2.3, 1.0)))
keep(bc.smooth_by_angle(bc.subtract(jacket, [bore] + slots)))
keep(bc.smooth_by_angle(along_y(bc.cylinder("Barrel", 0.034, 1.0, 32, STEEL), 1.0)))
for y in (0.575, 1.43):
    keep(along_y(bc.bevel(bc.cylinder(f"Band{y}", 0.088, 0.036, 48, BRASS), 0.006, 2), y))
crown = along_y(bc.cylinder("Crown", 0.052, 0.09, 40, STEEL), 1.495)
notches = [bc.place(bc.box(f"Notch{k}", (0.03, 0.05, 0.08)), location=(0, 1.54, BORE_Z), rotation=(0, 45 + k * 90, 0)) for k in range(4)]
keep(bc.smooth_by_angle(bc.subtract(crown, notches + [along_y(bc.cylinder("Muzzle", 0.024, 0.4, 24), 1.5)])))
keep(bc.bevel(bc.place(bc.box("FrontSight", (0.014, 0.05, 0.05), STEEL), location=(0, 1.36, BORE_Z + 0.10)), 0.004, 2))

# --- magazine, trigger, hammer, sight ----------------------------------------------------------------------------
MAG_PIVOT = (0, 0.205, 0.045)
magazine = bc.place(bc.box("Magazine", (0.085, 0.21, 0.36)), location=(0, 0, -0.17))
magazine.data.materials.append(STEEL)
flutes = [bc.place(bc.box(f"Flute{s}{y}", (0.012, 0.026, 0.25)), location=(s * 0.0425, y, -0.19)) for s in (-1, 1) for y in (-0.04, 0.04)]
magazine = bc.bevel(bc.subtract(magazine, flutes), 0.010, 2, 30)
keep(bc.place(magazine, location=MAG_PIVOT, rotation=(-6, 0, 0)))
plate = bc.bevel(bc.place(bc.box("MagazinePlate", (0.10, 0.235, 0.035), BRASS), location=(0, 0, -0.36)), 0.009, 2)
keep(bc.place(plate, location=MAG_PIVOT, rotation=(-6, 0, 0)))
guard_path = bc.smooth_path([(-0.31, 0.06), (-0.335, -0.02), (-0.30, -0.105), (-0.19, -0.13), (-0.07, -0.118), (0.0, -0.06), (0.015, 0.06)], 28)
keep(bc.smooth_by_angle(bc.bevel(bc.band_along("TriggerGuard", guard_path, 0.026, 0.05, BRASS), 0.008, 3, 30), 40))
keep(bc.tube_along("Trigger", [Vector((0, -0.11, 0.06)), Vector((0, -0.12, 0.0)), Vector((0, -0.10, -0.055))], [0.013, 0.012, 0.009], 10, STEEL))
keep(bc.place(bc.torus("Hammer", 0.032, 0.009, 32, 10, STEEL), location=(0, -0.475, 0.325), rotation=(0, 90, 0)))
keep(bc.bevel(bc.place(bc.box("HammerStem", (0.022, 0.04, 0.07), STEEL), location=(0, -0.452, 0.29)), 0.005, 2))
rear_sight = bc.place(bc.box("RearSight", (0.05, 0.07, 0.03), STEEL), location=(0, -0.31, 0.35))
keep(bc.bevel(bc.subtract(rear_sight, [bc.place(bc.box("SightNotch", (0.014, 0.2, 0.03)), location=(0, -0.31, 0.365))]), 0.004, 2))

# --- the light crystal in its setting ------------------------------------------------------------------------------
CY, CZ = 0.24, 0.425  # the crystal's centre
LENGTH, RADIUS, MIDDLE = 0.38, 0.052, 0.14
keep(bc.bevel(bc.place(bc.cylinder("SettingBase", 0.055, 0.022, 48, BRASS), location=(0, CY, 0.321), scale=(1.0, 2.8, 1.0)), 0.006, 2))


def crystal(name):
    """A long eight-sided crystal along Y: a prism of length MIDDLE between two eight-sided points."""
    bm = bmesh.new()
    rings = [[bm.verts.new((math.cos(k * math.pi / 4 + math.pi / 8) * RADIUS, y, math.sin(k * math.pi / 4 + math.pi / 8) * RADIUS))
              for k in range(8)] for y in (-MIDDLE / 2, MIDDLE / 2)]
    tips = [bm.verts.new((0, -LENGTH / 2, 0)), bm.verts.new((0, LENGTH / 2, 0))]
    for k in range(8):
        a, b = rings[0][k], rings[0][(k + 1) % 8]
        c, d = rings[1][k], rings[1][(k + 1) % 8]
        bm.faces.new((a, b, d, c))
        bm.faces.new((b, a, tips[0]))
        bm.faces.new((c, d, tips[1]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bc.object_from_bmesh(name, bm, AMBER)


light_crystal = bc.place(crystal("Crystal"), location=(0, CY, CZ))
for end in (-1, 1):  # at each shoulder a ring, four prongs up the point, and a finial past the tip
    shoulder, tip = CY + end * MIDDLE / 2, CY + end * LENGTH / 2
    keep(bc.place(bc.torus(f"Collet{end}", RADIUS + 0.006, 0.0075, 40, 10, BRASS), location=(0, shoulder, CZ), rotation=(90, 0, 0)))
    keep(bc.bevel(bc.place(bc.box(f"Post{end}", (0.012, 0.012, 0.05)), location=(0, shoulder, 0.355)), 0.003, 2))
    body[-1].data.materials.append(BRASS)
    for k in range(4):
        a = math.radians(45 + 90 * k)
        start = Vector((math.cos(a) * (RADIUS + 0.004), shoulder, CZ + math.sin(a) * (RADIUS + 0.004)))
        end_point = Vector((math.cos(a) * 0.012, tip - end * 0.035, CZ + math.sin(a) * 0.012))
        keep(bc.tube_along(f"Prong{end}{k}", [start, start.lerp(end_point, 0.5) + Vector((math.cos(a), 0, math.sin(a))) * 0.008, end_point], [0.0065, 0.006, 0.005], 8, BRASS))
    keep(bc.place(bc.sphere(f"Finial{end}", 0.013, 16, 8, BRASS), location=(0, tip + end * 0.008, CZ)))
    keep(bc.place(bc.cylinder(f"Spike{end}", 0.008, 0.035, 12, BRASS, radius_top=0.0), location=(0, tip + end * 0.03, CZ), rotation=(-90 * end, 0, 0)))

# --- assemble: the hand at the origin; bake the body into one texture set ----------------------------------------
gun = bc.smooth_by_angle(bc.join(body, "SMG_Body"), 40)
for obj in (gun, light_crystal):
    bc.place(obj, location=tuple(-HAND))
light_crystal.name = "SMG_Crystal"
tris = sum(len(p.vertices) - 2 for obj in (gun, light_crystal) for p in obj.data.polygons)
print(f"BL_SMG triangles: {tris}")

bc.unwrap(gun)
maps = bc.bake_pbr(gun, 1024, OUT, "smg", samples=64, emissive={GARNET.name})  # the garnets smoulder
print("BL_SMG baked", ", ".join(str(p) for p in maps.values()))
bc.assign_only(gun, bc.baked_material("SMG_Baked", maps))
bc.save_blend(OUT / "smg.blend")
for obj, name in ((gun, "smg_body"), (light_crystal, "smg_crystal")):
    print("BL_SMG exported", name, bc.export_mesh_json(obj, OUT / f"{name}.json", uv=obj is gun), "triangles")

bc.studio(scene)
centre = Vector((0, 0.5, 0.0)) - HAND
views = [("three_quarter", 35, 14, 50), ("side", 90, 4, 50), ("rear_quarter", 215, 18, 50), ("panel", 75, 10, 135)]
for name, azimuth, elevation, lens in views:
    target = centre if name != "panel" else Vector((0, 0.1, 0.19)) - HAND
    radius = 1.35 if name != "panel" else 0.42
    for path in bc.render_views(scene, target, radius, OUT, "smg", [(name, azimuth, elevation, lens)]):
        print("BL_SMG render", path)
