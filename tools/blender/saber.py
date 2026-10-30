"""Gustave's sabre: a Victorian cavalry sabre for the right hand. Our own design after the jewelled sabre of the hunter
Gustave is modelled on (docs/duskbloods-reference.md, "Albert"): a black blade, gold and a jewel, never a copy.

A blackened, curved blade with a fuller, damascened in gold: a gothic panel at its root framing a blood garnet in a
gold quatrefoil, gold rules along the fuller's shoulders ending in a finial, a gold vine in the fuller, a polished
edge. A gold three-bar basket hilt with a pierced guard plate; an oxblood shagreen grip bound with gold wire laid in a
spiral groove; a gold pommel set with garnets that answer the machine pistol's.

Run: blender.exe -b --factory-startup --python tools/blender/saber.py -- <out_dir>
Writes <out_dir>/saber.blend, the inlay mask (saber_inlay.png), two baked texture sets (saber_hilt_*, saber_blade_*),
saber_hilt.json and saber_blade.json (centred, for ModelAssembly) and preview renders.

Studs. X across the flat, Y toward the edge (the spine is -Y), Z along the blade; the middle of the grip, where the
hand closes, is the origin. In Roblox (x, z, -y) the blade runs along +Y: the weapon's up, out of the fist and along
the arm's front (Simulation/Equipment), with the edge leading down. The hilt is drawn at a hand's scale, then scaled by
HILT_SCALE to fill an R6 fist: a 1-stud block, which the grip spans, its guard at the block's front face.

Two meshes. The hilt carries the jewel settings on the blade's root. The blade's UVs are laid out here, not projected:
its surface unrolled around each cross-section and cut into PIECES columns (~700 texels a stud). A second UV map,
(across, along) on each face, reads the inlay mask this script draws (anti-aliased strokes measured in studs on the
face), which the bake turns into the blade's texture set.
"""

import math
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
import bmesh  # noqa: E402
import blcommon as bc  # noqa: E402
from mathutils import Vector  # noqa: E402

OUT = bc.out_dir()
scene = bc.reset_scene()

BRASS = bc.brass_material()
GRIP = bc.shagreen_material("Shagreen_Oxblood", shades=((0.080, 0.022, 0.024), (0.024, 0.007, 0.009)), beads=120.0)
GARNET = bc.garnet_material()

# --- dimensions ------------------------------------------------------------------------------------------------------
HILT_SCALE = 1.85  # the hilt is drawn at a hand's size, then scaled to fill an R6 fist
GRIP_FROM, GRIP_TO = -0.27, 0.232  # the grip's ends along Z (hand scale): from inside the pommel up to the guard plate
PLATE_Z = 0.245  # the guard plate's middle (hand scale); the blade's root sits in it
TURNS, GROOVE = 13, 0.08  # the wire's turns down the grip; its groove's depth, as a share of the grip's radius

BLADE_FROM = PLATE_Z * HILT_SCALE
BLADE_LENGTH = 3.35
BLADE_WIDTH = (0.21, 0.165)  # spine to edge, at the root and at the point
BLADE_THICKNESS = (0.05, 0.022)  # the spine's, at the root and at the point
SPINE = -0.08  # the spine's Y at the root
CURVE = 0.30  # how far the blade sweeps back toward the spine by the point
RICASSO = (0.15, 0.18)  # s (0 the root .. 1 the point) where the flat root gives way to the fuller
FULLER_END = (0.80, 0.86)  # s where the fuller fades out before the point
# Across a cross-section, from the spine (u = 0) to the edge (u = 1): the half-thickness as a share of the spine's.
SECTION_U = (0.0, 0.14, 0.18, 0.34, 0.50, 0.54, 0.76, 1.0)
FLAT = (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.9, 0.5)  # the root: flat faces, a blunt chamfer to the edge
FULLER = (1.0, 1.0, 0.62, 0.52, 0.62, 0.95, 0.58, 0.06)  # a flat spine, the fuller, a swell, the bevel to the edge
LENS = (1.0, 0.98, 0.95, 0.9, 0.85, 0.8, 0.55, 0.06)  # near the point: no fuller
RINGS, PIECES, GAP = 72, 3, 0.012  # cross-sections (the point is extra); the blade's UV columns, and their gap

# The inlay, in studs on the face: across from the spine, along from the blade's root.
PANEL = (0.06, 0.76, 0.105, 0.31)  # the gothic panel at the root: its sides (u), its foot and springing (along)
JEWEL = 0.20  # the garnet's height up the panel; it sits midway across
QUATREFOIL, CUSHION = 0.05, 0.008  # the setting's radius, and how high its gold cushion domes off the flat
STONE = (0.024, 0.032, 0.016)  # the stone's radii (across, along) and height
FULLER_LINES = (0.125, 0.565, 0.34)  # u of the gold rules on the fuller's shoulders, and of the fuller's middle
INLAY_SIZE = (384, 4096)  # mask texels across and along
AA = 0.001  # the soft edge of a stroke (studs)


def smoothstep(a, b, x):
    t = np.clip((x - a) / (b - a), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def taper(count, start, end):
    return [lerp(start, end, i / max(count - 1, 1)) for i in range(count)]


# --- the blade's shape -----------------------------------------------------------------------------------------------
def blade_width(s):
    return lerp(*BLADE_WIDTH, s)


def blade_section(s):
    """At s (0 the root, 1 the point): the spine's and the edge's Y, the spine's thickness, and the half-thickness
    shares across the section (SECTION_U)."""
    spine = SPINE - CURVE * s ** 1.8  # a cavalry sabre's sweep, the edge convex
    width = blade_width(s)
    edge = spine + width
    point = spine + width * 0.62
    spine += (point - spine) * smoothstep(0.84, 1.0, s)  # the clipped point: the spine falls to it
    edge += (point - edge) * smoothstep(0.9, 1.0, s) ** 2
    fuller, lens = smoothstep(*RICASSO, s), smoothstep(*FULLER_END, s)
    shares = [lerp(lerp(f, g, fuller), n, lens) for f, g, n in zip(FLAT, FULLER, LENS)]
    return spine, edge, lerp(*BLADE_THICKNESS, s), shares


# --- the inlay -------------------------------------------------------------------------------------------------------
class Inlay:
    """The blade's inlay mask. Rows run along the blade (0 the root .. 1 the point), columns across a face (0 the
    spine .. 1 the edge). Strokes are given in studs on the face, (across from the spine, along from the root), so
    shapes keep their proportions as the blade narrows."""

    def __init__(self, size):
        cols, rows = size
        self.gold = np.zeros((rows, cols), np.float32)
        self.across = (np.arange(cols) + 0.5) / cols
        self.along = (np.arange(rows) + 0.5) / rows
        self.width = blade_width(self.along)

    def stroke(self, points, radius):
        """A polyline through `points` ((across, along) studs), `radius` studs to each side: one number, or one per
        point (tapered: leaves, scroll ends)."""
        rows, cols = self.gold.shape
        radii = list(radius) if isinstance(radius, (list, tuple)) else [radius] * len(points)
        for (a0, z0), (a1, z1), r0, r1 in zip(points, points[1:], radii, radii[1:]):
            reach = max(r0, r1) + 2 * AA
            row0 = max(int((min(z0, z1) - reach) / BLADE_LENGTH * rows), 0)
            row1 = min(int((max(z0, z1) + reach) / BLADE_LENGTH * rows) + 2, rows)
            if row0 >= row1:
                continue
            width = self.width[row0:row1, None]
            col0 = max(int((min(a0, a1) - reach) / width.max() * cols), 0)
            col1 = min(int((max(a0, a1) + reach) / width.min() * cols) + 2, cols)
            if col0 >= col1:
                continue
            x = self.across[None, col0:col1] * width
            z = self.along[row0:row1, None] * BLADE_LENGTH
            dx, dz = a1 - a0, z1 - z0
            t = np.clip(((x - a0) * dx + (z - z0) * dz) / max(dx * dx + dz * dz, 1e-12), 0.0, 1.0)
            distance = np.hypot(x - a0 - t * dx, z - z0 - t * dz) - (r0 + (r1 - r0) * t)
            block = self.gold[row0:row1, col0:col1]
            np.maximum(block, np.clip(0.5 - distance / AA, 0.0, 1.0), out=block)

    def dot(self, centre, radius):
        self.stroke([centre, centre], radius)

    def finish(self):
        """The mask as RGB: the gold; the satin of the fuller; the polish of the sharpened edge and of the false edge
        at the point (which the bright steel shows from the collar up)."""
        w, s = self.across[None, :], self.along[:, None]
        satin = smoothstep(0.165, 0.185, w) * (1 - smoothstep(0.495, 0.515, w))
        satin = satin * smoothstep(*RICASSO, s) * (1 - smoothstep(*FULLER_END, s))
        polish = np.maximum(smoothstep(0.775, 0.80, w) * smoothstep(0.03, 0.045, s),
                            (1 - smoothstep(0.08, 0.11, w)) * smoothstep(0.86, 0.90, s))
        return np.dstack([self.gold, satin, polish])


def arc(centre, radius, start, end, steps=24):
    """Points on a circle, from `start` to `end` degrees (0 = toward the edge, 90 = toward the point)."""
    return [(centre[0] + radius * math.cos(math.radians(a)), centre[1] + radius * math.sin(math.radians(a)))
            for a in np.linspace(start, end, steps)]


def arch(left, right, foot, spring, steps=24):
    """A gothic (equilateral) arch's outline, closed: up the left side, over the apex, down the right, along the foot."""
    span = right - left
    return ([(left, foot), (left, spring)] + arc((right, spring), span, 180, 120, steps)
            + arc((left, spring), span, 60, 0, steps) + [(right, foot), (left, foot)])


def volute(start, heading, length, turn, curl=(15.0, 380.0), steps=48):
    """A scroll: from `start` heading `heading` degrees (0 = toward the point, 90 = toward the edge), its curvature
    growing from curl[0] to curl[1] (per stud) so it winds into a tight spiral; `turn` +1 winds clockwise, -1 counter."""
    x, z = start
    angle = math.radians(heading)
    step = length / steps
    points = [start]
    for i in range(steps):
        angle += turn * lerp(curl[0], curl[1], (i / steps) ** 2) * step
        x, z = x + math.sin(angle) * step, z + math.cos(angle) * step
        points.append((x, z))
    return points


def leaf(base, heading, length, width):
    """A leaf: points from its base along `heading`, and radii swelling to `width` and closing to a point."""
    angle = math.radians(heading)
    points = [(base[0] + math.sin(angle) * length * t, base[1] + math.cos(angle) * length * t) for t in (0, 0.35, 0.7, 1)]
    return points, [width * 0.35, width, width * 0.6, 0.0]


def on_face(u, along):
    """The point `u` of the way across the face (spine to edge), `along` studs up the blade."""
    return (u * blade_width(along / BLADE_LENGTH), along)


def draw_inlay():
    ink = Inlay(INLAY_SIZE)
    width = blade_width(JEWEL / BLADE_LENGTH)
    left, right, foot, spring = PANEL[0] * width, PANEL[1] * width, PANEL[2], PANEL[3]
    middle = (left + right) / 2
    apex = spring + (right - left) * math.sin(math.radians(60))
    inner_apex = spring + (right - left - 0.02) * math.sin(math.radians(60))

    # the collar where the blade leaves the guard: a broad band, a fine rule above it
    ink.stroke([(0.0, 0.05), (width, 0.05)], 0.02)
    ink.stroke([(0.0, 0.088), (right, 0.088)], 0.0026)
    # the panel: a double rule in a gothic arch
    ink.stroke(arch(left, right, foot, spring), 0.0036)
    ink.stroke(arch(left + 0.01, right - 0.01, foot + 0.01, spring), 0.0016)
    # under the stone: a drop of three leaves hanging toward the collar
    low = JEWEL - QUATREFOIL
    ink.stroke([(middle, low), (middle, low - 0.008)], 0.0018)
    for heading, length in ((180, 0.016), (140, 0.012), (-140, 0.012)):
        ink.stroke(*leaf((middle, low - 0.008), heading, length, 0.004))
    # over the stone: a stem to a trefoil under the apex, two pairs of acanthus scrolls sweeping out and down
    high, crown = JEWEL + QUATREFOIL, inner_apex - 0.026
    ink.stroke([(middle, high), (middle, crown)], 0.0016)
    for heading, length in ((0, 0.022), (-48, 0.016), (48, 0.016)):
        ink.stroke(*leaf((middle, crown), heading, length, 0.0045))
    for along, heading, length, curl in ((high + 0.03, 62, 0.07, (6, 240)), (high + 0.085, 40, 0.045, (10, 300))):
        for side in (-1, 1):
            ink.stroke(volute((middle, along), side * heading, length, side, curl), taper(49, 0.0019, 0.0007))

    # the rules on the fuller's shoulders: they spring from the arch's apex like a spire's ribs, run up the blade and
    # close into a finial
    lo, hi, mid = FULLER_LINES
    top = 2.12
    for u in (lo, hi):
        side = -1 if u < mid else 1
        rise = bc.smooth_path([(middle + side * 0.002, apex + 0.003), (middle + side * 0.012, apex + 0.05),
                               on_face(u, 0.60), on_face(u, 0.70)], 28)
        run = [on_face(u, along) for along in np.linspace(0.70, 1.92, 60)]
        close = bc.smooth_path([on_face(u, 1.92), on_face(u, 2.0), on_face(lerp(u, mid, 0.7), 2.07), on_face(mid, top)], 24)
        ink.stroke([(p.x, p.y) for p in rise] + run[1:] + [(p.x, p.y) for p in close][1:], 0.0045)  # bold enough to read in play
    finial = on_face(mid, top)
    for dx, dz, r in ((0.0, 0.016, 0.0045), (-0.0085, 0.006, 0.0038), (0.0085, 0.006, 0.0038)):
        ink.dot((finial[0] + dx, finial[1] + dz), r)

    # the vine in the fuller: a wavy stem; at each crest a tendril curling into the hollow of the wave, a leaf outside
    start, end, wave, amp = 0.70, 1.72, 0.22, 0.012

    def stem(along):
        return on_face(mid, along)[0] + amp * math.sin(2 * math.pi * (along - start) / wave), along

    alongs = np.linspace(start, end, 280)
    ink.stroke([stem(a) for a in alongs], taper(len(alongs), 0.0022, 0.0012))
    along, side = start + wave / 4, 1
    while along < end - wave / 4:
        ink.stroke(volute(stem(along - 0.006), -side * 35, 0.058, -side, (10, 330)), taper(49, 0.0017, 0.0006))
        ink.stroke(*leaf(stem(along + 0.004), side * 120, 0.018, 0.0042))
        along += wave / 2
        side = -side
    ink.stroke(volute(stem(end), 0, 0.03, 1, (25, 420)), taper(49, 0.0012, 0.0006))
    return ink


# --- the blade's mesh ------------------------------------------------------------------------------------------------
def blade(material):
    """The blade: RINGS cross-sections and the point. UV maps: "Bake" (the atlas: each section unrolled around its
    perimeter, centred on the edge, the blade cut into PIECES columns) and "Pattern" (across, 0 the spine .. 1 the
    edge, on each face; along, 0 the root .. 1 the point), which reads the inlay mask."""
    bm = bmesh.new()
    bake = bm.loops.layers.uv.new("Bake")
    pattern = bm.loops.layers.uv.new("Pattern")
    rings = []
    for k in range(RINGS):
        s = k / RINGS
        spine, edge, thickness, shares = blade_section(s)
        z = BLADE_FROM + s * BLADE_LENGTH
        front = [Vector((thickness / 2 * h, spine + (edge - spine) * u, z)) for u, h in zip(SECTION_U, shares)]
        points = front + [Vector((-p.x, p.y, p.z)) for p in reversed(front)]
        arcs = [0.0]
        for a, b in zip(points, points[1:]):
            arcs.append(arcs[-1] + (b - a).length)
        rings.append({"verts": [bm.verts.new(p) for p in points], "across": SECTION_U + SECTION_U[::-1], "arc": arcs,
                      "perimeter": arcs[-1] + (points[0] - points[-1]).length, "s": s,
                      "centre": (arcs[len(front) - 1] + arcs[len(front)]) / 2})  # the middle of the edge

    per = RINGS // PIECES
    pieces = [rings[p * per:min((p + 1) * per + 1, RINGS)] for p in range(PIECES)]
    left = [max(r["centre"] for r in piece) for piece in pieces]
    right = [max(r["perimeter"] - r["centre"] for r in piece) for piece in pieces]
    scale = min((1 - (PIECES + 1) * GAP) / sum(left + right), (1 - 2 * GAP) / (BLADE_LENGTH / PIECES))
    columns, x = [], GAP
    for l, r in zip(left, right):
        columns.append(x + l * scale)
        x += (l + r) * scale + GAP

    def atlas(ring, index, piece, wrap=False):
        arc_length = ring["perimeter"] if wrap else ring["arc"][index]
        return (columns[piece] + (arc_length - ring["centre"]) * scale,
                GAP + (ring["s"] - piece / PIECES) * BLADE_LENGTH * scale)

    count = len(rings[0]["verts"])
    for k in range(RINGS - 1):
        piece = min(k // per, PIECES - 1)
        a, b = rings[k], rings[k + 1]
        for i in range(count):
            j = (i + 1) % count
            corners = ((a, i, False), (a, j, j == 0), (b, j, j == 0), (b, i, False))
            face = bm.faces.new([ring["verts"][index] for ring, index, _ in corners])
            for loop, (ring, index, wrap) in zip(face.loops, corners):
                loop[bake].uv = atlas(ring, index, piece, wrap)
                loop[pattern].uv = (ring["across"][index], ring["s"])
    last = rings[-1]
    point = bm.verts.new((0.0, blade_section(1.0)[0], BLADE_FROM + BLADE_LENGTH))
    tip_v = GAP + (1 - (PIECES - 1) / PIECES) * BLADE_LENGTH * scale
    for i in range(count):
        j = (i + 1) % count
        face = bm.faces.new((last["verts"][i], last["verts"][j], point))
        near, far = atlas(last, i, PIECES - 1), atlas(last, j, PIECES - 1, j == 0)
        corners = ((near, (last["across"][i], last["s"])), (far, (last["across"][j], last["s"])),
                   (((near[0] + far[0]) / 2, tip_v), ((last["across"][i] + last["across"][j]) / 2, 1.0)))
        for loop, (atlas_uv, pattern_uv) in zip(face.loops, corners):
            loop[bake].uv, loop[pattern].uv = atlas_uv, pattern_uv
    print(f"BL_SABER blade UVs: {scale * 1024:.0f} texels a stud")
    return bc.object_from_bmesh("Saber_Blade", bm, material)


# --- the hilt (drawn at a hand's scale) -----------------------------------------------------------------------------
hilt = []


def keep(obj):
    hilt.append(obj)
    return obj


def grip_point(t, angle, depth):
    """A point on the grip's oval at t (0 the pommel's end .. 1 the guard's) and `angle`, sunk `depth` (a share of the
    radius) below the surface. The grip swells where the palm closes."""
    f = (1 + 0.12 * math.sin(math.pi * t)) * (1 - depth)
    return Vector((0.052 * f * math.cos(angle), 0.012 + 0.066 * f * math.sin(angle), lerp(GRIP_FROM, GRIP_TO, t)))


def grip():
    """The grip: an oval barrel of shagreen with a spiral groove cut for the wire."""
    bm = bmesh.new()
    sides, steps = 28, TURNS * 7
    rings = []
    for k in range(steps + 1):
        t = k / steps
        ring = []
        for i in range(sides):
            angle = 2 * math.pi * i / sides
            phase = (TURNS * t - angle / (2 * math.pi)) % 1.0
            ring.append(bm.verts.new(grip_point(t, angle, GROOVE * math.exp(-((phase - 0.5) / 0.14) ** 2))))
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for i in range(sides):
            bm.faces.new((a[i], a[(i + 1) % sides], b[(i + 1) % sides], b[i]))
    bm.faces.new(list(reversed(rings[0])))
    bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bc.object_from_bmesh("Grip", bm, GRIP)


keep(grip())
wire = [grip_point(t, 2 * math.pi * (TURNS * t - 0.5), GROOVE * 0.5) for t in np.linspace(0.03, 0.97, TURNS * 12)]
keep(bc.tube_along("Wire", wire, [0.0068] * len(wire), 6, BRASS))  # seated in the groove, standing proud of the ridges

# ferrules at both ends of the grip, and the backstrap down the spine side
for z in (GRIP_TO - 0.008, GRIP_FROM + 0.02):
    keep(bc.place(bc.torus(f"Ferrule{z}", 0.062, 0.012, 32, 8, BRASS), location=(0, 0.012, z), scale=(1.0, 1.27, 1.0)))
keep(bc.bevel(bc.place(bc.box("Backstrap", (0.056, 0.02, GRIP_TO - GRIP_FROM), BRASS),
                       location=(0, -0.062, (GRIP_TO + GRIP_FROM) / 2)), 0.008, 3))

# the guard: a domed plate pierced with a quatrefoil (the stone's setting, answered), and a three-bar basket
plate = bc.place(bc.cylinder("GuardPlate", 0.13, 0.022, 48, BRASS), location=(0, 0.06, PLATE_Z), scale=(0.62, 1.0, 1.0))
holes = [(dx, 0.135 + dy, 0.0125) for dx, dy in ((0.0165, 0), (-0.0165, 0), (0, 0.0165), (0, -0.0165))]
holes += [(side * 0.045, 0.118, 0.008) for side in (-1, 1)]
cutters = [bc.place(bc.cylinder(f"Pierce{i}", r, 0.2, 20), location=(x, y, PLATE_Z)) for i, (x, y, r) in enumerate(holes)]
keep(bc.bevel(bc.subtract(plate, cutters), 0.006, 2))
keep(bc.place(bc.torus("PlateRim", 0.128, 0.009, 56, 6, BRASS), location=(0, 0.06, PLATE_Z + 0.007), scale=(0.62, 1.0, 1.0)))

bow = bc.smooth_path([(0, 0.175, PLATE_Z), (0, 0.245, 0.12), (0, 0.235, -0.08), (0, 0.17, -0.24), (0, 0.07, -0.305)], 36)
keep(bc.tube_along("KnuckleBow", bow, [0.019 - 0.006 * i / 35 for i in range(36)], 12, BRASS))
for side in (-1, 1):  # the side bars swell out and merge into the bow (their ends buried in it)
    bar = bc.smooth_path([(side * 0.05, 0.12, PLATE_Z), (side * 0.095, 0.2, 0.15), (side * 0.07, 0.25, 0.04),
                          (0.0, 0.243, -0.035)], 28)
    keep(bc.tube_along(f"Bar{side}", bar, [0.011 - 0.003 * max(0, i - 20) / 7 for i in range(28)], 10, BRASS))

# the pommel: a gold cap, a setting on each face for its stones (set below, at full scale)
POMMEL = (0, 0.02, -0.315)
keep(bc.place(bc.sphere("Pommel", 0.07, 32, 16, BRASS), location=POMMEL, scale=(0.95, 1.3, 0.85)))
keep(bc.place(bc.cylinder("PommelButton", 0.022, 0.03, 20, BRASS), location=(0, 0.02, -0.375)))
for side in (-1, 1):
    keep(bc.place(bc.torus(f"Setting{side}", 0.026, 0.006, 32, 8, BRASS), location=(side * 0.064, POMMEL[1], POMMEL[2]),
                  rotation=(0, 90, 0)))


# --- stones and settings (full scale) --------------------------------------------------------------------------------
def gem(name, centre, radii, height, facing, segments=12):
    """A cut stone on an oval girdle of `radii` (across Y, along Z), rising `height` along X toward `facing` (+1 or
    -1): a girdle, a ring of crown facets turned half a step, a table. Flat-shaded, so each facet flashes alone."""
    bm = bmesh.new()

    def ring(scale, lift, turn):
        return [bm.verts.new((centre[0] + facing * lift, centre[1] + radii[0] * scale * math.cos(a),
                              centre[2] + radii[1] * scale * math.sin(a)))
                for a in (2 * math.pi * (i + turn) / segments for i in range(segments))]

    girdle, crown, table = ring(1.0, 0.0, 0.0), ring(0.78, height * 0.62, 0.5), ring(0.42, height, 0.0)
    for i in range(segments):
        j = (i + 1) % segments
        bm.faces.new((girdle[i], girdle[j], crown[i]))
        bm.faces.new((crown[i], girdle[j], crown[j]))
        bm.faces.new((crown[i], crown[j], table[j]))
        bm.faces.new((table[i], crown[i], table[j]))
    bm.faces.new(table)
    bm.faces.new(list(reversed(girdle)))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    for face in bm.faces:
        face.smooth = False
    return bc.object_from_bmesh(name, bm, GARNET)


def quatrefoil(angle):
    """A quatrefoil's radius at `angle` (a share of its full radius): four round lobes, along and across, with cusps
    between them."""
    return 0.74 + 0.26 * abs(math.cos(2 * angle)) ** 0.7


def cushion(name, centre, face, side, steps=48, rings=6):
    """The setting's gold cushion on the blade's flat at x = side * face: a quatrefoil outline domed CUSHION high (it
    rises steeply at the rim, then flattens), so its curve catches light the way a flat plate can't."""
    bm = bmesh.new()
    y, z = centre
    angles = [2 * math.pi * i / steps for i in range(steps)]
    rows = []
    for k in range(rings):
        f = 1 - k / rings  # the share of the outline's size: 1 at the rim
        lift = CUSHION * (1 - f ** 3) ** 0.5
        rows.append([bm.verts.new((side * (face + lift), y + QUATREFOIL * quatrefoil(a) * f * math.cos(a),
                                   z + QUATREFOIL * quatrefoil(a) * f * math.sin(a))) for a in angles])
    top = bm.verts.new((side * (face + CUSHION), y, z))
    for a, b in zip(rows, rows[1:]):
        for i in range(steps):
            bm.faces.new((a[i], a[(i + 1) % steps], b[(i + 1) % steps], b[i]))
    for i in range(steps):
        bm.faces.new((rows[-1][i], rows[-1][(i + 1) % steps], top))
    bm.faces.new(list(reversed(rows[0])))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return bc.object_from_bmesh(name, bm, BRASS)


def jewel_centre():
    s = JEWEL / BLADE_LENGTH
    return blade_section(s)[0] + (PANEL[0] + PANEL[1]) / 2 * blade_width(s), BLADE_FROM + JEWEL


def jewel_mount(side):
    """The blade's garnet on one face (side +1 or -1): a gold quatrefoil cushion on the flat of the root, a gold pearl
    in each cusp, a bezel and the stone. Returns (gold parts, stone)."""
    y, z = jewel_centre()
    face = blade_section(JEWEL / BLADE_LENGTH)[2] / 2
    parts = [cushion(f"Quatrefoil{side}", (y, z), face, side)]
    top = side * (face + CUSHION)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        r = QUATREFOIL * quatrefoil(a)
        parts.append(bc.place(bc.sphere(f"Pearl{side}{k}", 0.0048, 8, 6, BRASS),
                              location=(side * (face + 0.002), y + r * math.cos(a), z + r * math.sin(a))))
    across, along, height = STONE
    parts.append(bc.place(bc.torus(f"Bezel{side}", 0.03, 0.0045, 40, 6, BRASS), location=(top + side * 0.002, y, z),
                          rotation=(0, 90, 0), scale=((along + 0.002) / 0.03, (across + 0.002) / 0.03, 1)))
    return parts, gem(f"Stone{side}", (top, y, z), (across, along), height, side)


# --- assemble ----------------------------------------------------------------------------------------------------------
body = bc.join(hilt, "Saber_Hilt")
bc.place(body, scale=(HILT_SCALE,) * 3)
bc.smooth_by_angle(body, 50)
gold, stones = [], []
for side in (-1, 1):
    parts, stone = jewel_mount(side)
    gold += [bc.smooth_by_angle(p, 50) for p in parts]
    stones.append(stone)
    pommel = Vector(POMMEL) * HILT_SCALE
    stones.append(gem(f"PommelStone{side}", (side * 0.064 * HILT_SCALE, pommel.y, pommel.z), (0.036, 0.036), 0.024, side))
body = bc.join([body] + gold + stones, "Saber_Hilt")

mask = bc.mask_image("Saber_Inlay", draw_inlay().finish(), OUT / "saber_inlay.png")
steel = bc.inlaid_steel_material("Steel_Inlaid", mask, "Pattern")
sword = bc.smooth_by_angle(blade(steel), 50)
uv_maps = sword.data.uv_layers
uv_maps.active = uv_maps["Bake"]
uv_maps["Bake"].active_render = True
for obj in (body, sword):
    print(f"BL_SABER {obj.name} triangles: {sum(len(p.vertices) - 2 for p in obj.data.polygons)}")

# --- bake, export, preview -------------------------------------------------------------------------------------------
bc.unwrap(body)
for obj, prefix, emissive in ((body, "saber_hilt", {GARNET.name}), (sword, "saber_blade", set())):
    maps = bc.bake_pbr(obj, 1024, OUT, prefix, samples=64, emissive=emissive)
    print("BL_SABER baked", ", ".join(str(p) for p in maps.values()))
    bc.assign_only(obj, bc.baked_material(f"{prefix}_Baked", maps))
    print("BL_SABER exported", bc.export_mesh_json(obj, OUT / f"{prefix}.json", uv=True), "triangles to", f"{prefix}.json")
bc.save_blend(OUT / "saber.blend")

base_s = 0.14
spine, edge, _, _ = blade_section(base_s)
jewel_y, jewel_z = jewel_centre()
points = {"Grip": Vector(), "BladeBase": Vector((0, (spine + edge) / 2, BLADE_FROM + base_s * BLADE_LENGTH)),
          "BladeTip": Vector((0, blade_section(1.0)[0], BLADE_FROM + BLADE_LENGTH)), "Jewel": Vector((0, jewel_y, jewel_z))}
print("BL_SABER points (Roblox x, y, z):", "; ".join(f"{name} ({p.x:.4f}, {p.z:.4f}, {-p.y:.4f})" for name, p in points.items()))

bc.studio(scene)
render = scene.render
for size, target, radius, views in (
        ((900, 1500), Vector((0, 0.1, 1.55)), 2.6, [("side", 90, 4, 35), ("three_quarter", 35, 14, 35)]),
        ((1600, 1000), Vector((0, jewel_y, jewel_z + 0.09)), 0.26, [("root", 78, 8, 135)]),
        ((1600, 1000), Vector((0, -0.02, BLADE_FROM + 1.2)), 0.42, [("fuller", 84, 4, 135)]),
        ((1600, 1000), Vector((0, 0.15, -0.1)), 0.95, [("hilt", 60, 12, 135), ("hilt_back", 235, 18, 135)])):
    render.resolution_x, render.resolution_y = size
    for path in bc.render_views(scene, target, radius, OUT, "saber", views):
        print("BL_SABER render", path)
