"""Renders BloodsLocks' gunfire and hit sprites (our own art) with Blender, headless:
  smoke_puff    4x4 flipbook of 256 px cells: a lit volumetric puff that billows out and thins (white: tint it)
  fire_burst    4x4 flipbook of 256 px cells: an emissive flame that kindles, licks upward and thins (white: tint it)
  muzzle_flash  2x2 sheet of 256 px variants: a star flash, white-hot core to orange rim (one variant a shot)
  muzzle_cone   128x512: the side flash, for a Beam (a Beam runs its texture's vertical axis along its length)
  spark         256x64: a thin hot streak tapered at both ends, for velocity-aligned particles (white: tint it)
  tracer        64x512: a pale thin core in a faint glow, tapered at both ends, for a Beam (white: tint it)
  slash_edge    64x512: the hot hairline the point leaves, for a Trail (same layout; white, additive)
  blade_smear   256x256: a blade's pale motion smear for a Trail (base left, point right, newest at the top; white)
  smoke_ribbon  256x512: a wisp of smoke for a Trail, frayed band across, torn toward the tail (white: tint it)
  wind_line     64x512: a thin speed line of wind for a Trail, breaking into dashes toward the tail (white)
  wind_ring     512x512: a gust ring seen from above, streaked around, for a flat expanding particle (white)
  wind_streak   256x64: a gust's soft bent streak, velocity-aligned (white)
  crescent_arc  512x192: an energy crescent, convex edge up: a hard bright edge, a streaked body fading inward (white)
  crescent_halo 512x192: the soft glow around that crescent (white, additive)
  energy_wisp   128x256: a soft wavering column of energy, tapered at both ends (white)
  ward_tracery  512x512: the ward's rose-window tracery, face on, every line with a soft glow (white, for a Decal)
  ward_cracks   512x512: cracks spreading through the ward's glass from three strikes (white, for a Decal)
  glass_shard   2x2 sheet of 128 px cells: four crimson-glass shards, a bright edge and a glint each (white: tint it)
No gore, ever (AGENTS.md rule 4: Roblox ToS): nothing here draws blood (no drops, sprays, splatter or stains), and
nothing that could read as gore is ever uploaded (it went to the owner's account and drew a moderation warning).
Velocity-aligned art is drawn moving toward the top, then turned (lead_left) so it moves toward the LEFT: a particle
with Orientation VelocityParallel leads with its texture's left edge (tested in Studio, 2026-10-31).
The flipbooks run left to right, top to bottom (Roblox's Grid4x4). Volumes render in Cycles; the flat emissive
shapes are drawn with numpy, so every sprite can be retuned and redrawn at any time.

Run: blender.exe -b --factory-startup --python tools/blender/vfx_sprites.py -- <out_dir> [name ...]
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import blcommon as bc  # noqa: E402
import bpy  # noqa: E402
import numpy as np  # noqa: E402

OUT = bc.out_dir()
WANTED = set(sys.argv[sys.argv.index("--") + 2:]) if "--" in sys.argv else set()


def wanted(name):
    return not WANTED or name in WANTED


# --- images ------------------------------------------------------------------------------------------------------

def save_rgba(name, rgba):
    """Saves an (h, w, 4) float array (row 0 = the top of the image, straight alpha, display values) as PNG."""
    height, width, _ = rgba.shape
    image = bpy.data.images.new(name, width, height, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(np.clip(rgba[::-1], 0, 1), dtype=np.float32).ravel())
    path = OUT / f"{name}.png"
    image.filepath_raw = str(path)
    image.file_format = "PNG"
    image.save()
    print("BL_VFX wrote", path)


def load_rgba(path):
    image = bpy.data.images.load(str(path))
    width, height = image.size
    data = np.empty(width * height * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(height, width, 4)[::-1]


def lead_left(cell):
    """Turns art drawn moving toward the top so it moves toward the left (a quarter turn counter-clockwise): velocity-
    aligned particles lead with their texture's left edge."""
    return np.ascontiguousarray(np.rot90(cell, 1))


def sheet(cells, columns):
    """Tiles equal (h, w, 4) cells left to right, top to bottom."""
    rows = [np.concatenate(cells[i:i + columns], axis=1) for i in range(0, len(cells), columns)]
    return np.concatenate(rows, axis=0)


def grid(size):
    """Cell coordinates in -1..1 (y up), for a size x size cell."""
    axis = (np.arange(size) + 0.5) / size * 2 - 1
    x, y = np.meshgrid(axis, -axis)
    return x, y


def smoothstep(a, b, v):
    t = np.clip((v - a) / (b - a), 0, 1)
    return t * t * (3 - 2 * t)


def value_noise(shape, scale, rng):
    """Smooth 2D value noise in 0..1: a coarse random grid, bicubically upsampled."""
    h, w = shape
    gh, gw = max(2, int(h / scale) + 3), max(2, int(w / scale) + 3)
    coarse = rng.random((gh, gw))
    ys = np.linspace(1, gh - 2.001, h)
    xs = np.linspace(1, gw - 2.001, w)
    y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
    fy, fx = (ys - y0)[:, None], (xs - x0)[None, :]
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    a = coarse[np.ix_(y0, x0)]
    b = coarse[np.ix_(y0, x0 + 1)]
    c = coarse[np.ix_(y0 + 1, x0)]
    d = coarse[np.ix_(y0 + 1, x0 + 1)]
    return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy


def fire_ramp(intensity):
    """Emissive colour by intensity: white-hot, then yellow, then orange; alpha follows the light."""
    stops = [(0.0, (1.0, 0.36, 0.06)), (0.35, (1.0, 0.62, 0.20)), (0.65, (1.0, 0.86, 0.52)), (1.0, (1.0, 0.98, 0.92))]
    rgb = np.zeros(intensity.shape + (3,))
    for (t0, c0), (t1, c1) in zip(stops, stops[1:]):
        inside = (intensity >= t0) & (intensity <= t1)
        f = ((intensity - t0) / (t1 - t0))[..., None]
        rgb = np.where(inside[..., None], np.array(c0) * (1 - f) + np.array(c1) * f, rgb)
    rgb = np.where((intensity > 1)[..., None], np.array(stops[-1][1]), rgb)
    return np.concatenate([rgb, np.clip(intensity * 1.5, 0, 1)[..., None]], axis=-1)


# --- flat emissive sprites (numpy) ----------------------------------------------------------------------------

def muzzle_flash(size=256, variants=4, seed=7):
    """Flame tongues around a white-hot core: each direction's reach comes from periodic noise around the circle
    (a few long tongues among short ones), streaked with fine striations and broken by ragged noise."""
    rng = np.random.default_rng(seed)
    x, y = grid(size)
    r, theta = np.hypot(x, y), np.arctan2(y, x)
    cells = []
    for _ in range(variants):
        lobes = sum(rng.uniform(0.3, 1.0) / k ** 0.5 * np.cos(k * theta + rng.uniform(0, 2 * math.pi)) for k in range(2, 12))
        lobes = (lobes - lobes.min()) / (lobes.max() - lobes.min())
        reach = 0.18 + 0.72 * lobes ** 2.4
        striae = 0.7 + 0.3 * np.cos(37 * theta + rng.uniform(0, 6)) * np.cos(23 * theta + rng.uniform(0, 6))
        ragged = 0.55 + 0.9 * value_noise((size, size), size / 18, rng)
        tongues = np.exp(-2.5 * (r / reach) ** 2) * striae * ragged
        core = 1.3 * np.exp(-(r / 0.12) ** 2)
        glow = 0.3 * np.exp(-(r / 0.5) ** 2)
        intensity = (core + 1.05 * tongues + glow) * (1 - smoothstep(0.85, 1.0, r))
        cells.append(fire_ramp(intensity))
    return sheet(cells, 2)


def muzzle_cone(width=128, height=512, seed=11):
    rng = np.random.default_rng(seed)
    v = np.linspace(1, 0, height)[:, None]  # 0 at the bottom row: the muzzle end
    u = np.linspace(-1, 1, width)[None, :]
    half = 0.55 * (1 - v) ** 0.8 + 0.04  # widest at the muzzle, a point at the far end
    wobble = (value_noise((height, width), 24, rng) - 0.5) * 0.35
    body = np.exp(-((u + wobble * v) / half) ** 2)
    intensity = body * (1 - smoothstep(0.55, 1.0, v)) * 1.3
    intensity *= smoothstep(0.0, 0.05, v)  # a soft start, so the beam's base never shows an edge
    return fire_ramp(intensity)


def streak_noise(height, width, along, across, rng):
    """Value noise stretched into streaks running down the image: cells `along` px tall and `across` px wide."""
    small = value_noise((max(4, int(height * across / along)), width), across, rng)
    ys = np.linspace(0, small.shape[0] - 1, height)
    y0 = np.floor(ys).astype(int)
    y1 = np.minimum(y0 + 1, small.shape[0] - 1)
    f = (ys - y0)[:, None]
    return small[y0] * (1 - f) + small[y1] * f


def slash_edge(width=64, height=512):
    """For a Trail along a blade's last stretch, its point at the right, the newest edge at the top: a hot hairline on
    the point's path in a soft glow, dying toward the tail (white: tint it; additive)."""
    v = np.linspace(0, 1, height)[:, None]
    u = np.linspace(0, 1, width)[None, :]
    line = np.exp(-((u - 0.88) / 0.05) ** 2) + 0.3 * np.exp(-((u - 0.8) / 0.2) ** 2)
    intensity = line * (1 - v) ** 2.2 * smoothstep(0.0, 0.02, v)
    return np.concatenate([np.ones((height, width, 3)), np.clip(intensity, 0, 1)[..., None]], axis=-1)


def blade_smear(width=256, height=256, seed=41):
    """A blade's motion smear for a Trail: the blade's base at the left, its point at the right, the newest edge at the
    top. A pale, translucent wedge: denser toward the point (it moves fastest), streaked along the motion, crisp at
    its leading edge, gone at its tail; a brighter line on the point's path. White: the trail's colour tints it."""
    rng = np.random.default_rng(seed)
    v = (np.arange(height) + 0.5)[:, None] / height  # 0 the newest edge .. 1 the tail
    u = (np.arange(width) + 0.5)[None, :] / width  # 0 the base .. 1 the point
    streaks = streak_noise(height, width, 400, 5, rng)
    body = smoothstep(0.02, 0.75, u) ** 1.3 * (1 - smoothstep(0.96, 1.0, u))
    life = (1 - v) ** 1.8 * smoothstep(0.0, 0.012, v)
    edge = np.exp(-((u - 0.93) / 0.025) ** 2) * (1 - v) ** 3
    alpha = np.clip((0.55 * body * (0.7 + 0.3 * streaks) + 0.6 * edge) * life, 0, 1)
    return np.concatenate([np.ones((height, width, 3)), alpha[..., None]], axis=-1)


# --- wind (the bite's gust: dark smoke and pale wind; numpy) ---------------------------------------------------------

def smoke_ribbon(width=256, height=512, seed=53):
    """For a Trail: a wisp of smoke the trail drags through the air, the newest edge at the top. Across (Attachment0 at
    the left, Attachment1 at the right) a soft band with frayed edges; along, streaked like smoke pulled by wind,
    dense at the head and tearing into wisps toward the tail (white: the trail's colour tints it)."""
    rng = np.random.default_rng(seed)
    v = (np.arange(height) + 0.5)[:, None] / height  # 0 the newest edge .. 1 the tail
    u = (np.arange(width) + 0.5)[None, :] / width
    fibres = streak_noise(height, width, 260, 7, rng)
    billows = value_noise((height, width), 40, rng)
    fray = (value_noise((height, width), 22, rng) - 0.5) * 0.35  # the band's edges wander
    band = np.exp(-((u - 0.5 + fray * v) / (0.3 + 0.12 * v)) ** 2 * 2.2)
    torn = smoothstep(0.7 * v, 0.7 * v + 0.35, 0.6 * fibres + 0.4 * billows)  # toward the tail only wisps survive
    life = (1 - v) ** 1.2 * smoothstep(0.0, 0.04, v)
    alpha = np.clip(band * (0.45 + 0.55 * fibres) * torn * life * 1.25, 0, 1)
    return np.concatenate([np.ones((height, width, 3)), alpha[..., None]], axis=-1)


def wind_line(width=64, height=512, seed=59):
    """For a Trail: a thin speed line of wind, the newest edge at the top: a crisp core in a soft halo, whole at the
    head, breaking into dashes toward the tail (white: tint it)."""
    rng = np.random.default_rng(seed)
    v = (np.arange(height) + 0.5)[:, None] / height
    u = (np.arange(width) + 0.5)[None, :] / width
    line = np.exp(-((u - 0.5) / 0.07) ** 2) + 0.35 * np.exp(-((u - 0.5) / 0.25) ** 2)
    gaps = value_noise((height, 1), 18, rng)  # one value per row: the dashes
    dashes = smoothstep(0.85 * v, 0.85 * v + 0.12, gaps)
    life = (1 - v) ** 1.5 * smoothstep(0.0, 0.03, v)
    alpha = np.clip(line * dashes * life, 0, 1)
    return np.concatenate([np.ones((height, width, 3)), alpha[..., None]], axis=-1)


def wind_ring(size=512, seed=61):
    """A gust ring seen from above, for a flat expanding particle: a band of wind at 70 % of the radius made of fine
    lines running around the circle, broken into long arcs (the air sweeping round), its outer edge crisp, its inner
    edge fading into a faint haze (white)."""
    rng = np.random.default_rng(seed)
    x, y = grid(size)
    r, theta = np.hypot(x, y), np.arctan2(y, x)
    wobble = (value_noise((size, size), size / 10, rng) - 0.5) * 0.05
    lines = 0.5 + 0.5 * np.cos(2 * math.pi * 26 * (r + wobble) + 0.6 * np.sin(3 * theta + rng.uniform(0, 6)))
    arcs = sum(np.sin(k * theta + rng.uniform(0, 6.283)) / k for k in (2, 3, 5, 7))  # where each line breaks
    breaks = smoothstep(-0.2, 0.5, arcs + 1.2 * (r - 0.7))
    band = np.exp(-((r - 0.7 + wobble) / 0.08) ** 2)
    outer = 1 - smoothstep(0.75, 0.81, r + wobble)
    haze = 0.07 * smoothstep(0.2, 0.62, r) * (1 - smoothstep(0.62, 0.72, r))
    alpha = np.clip((band * (0.35 + 0.65 * lines * breaks) + haze) * outer, 0, 1)
    return np.concatenate([np.ones((size, size, 3)), alpha[..., None]], axis=-1)


def wind_streak(width=64, height=256):
    """A gust's streak for velocity-aligned particles: a thin soft line bending a little, tapered at both ends,
    turned to lead with its left edge (white: tint it)."""
    v = np.linspace(-1, 1, height)[:, None]
    u = np.linspace(-1, 1, width)[None, :]
    bend = 0.25 * (1 - v ** 2)  # a gentle arc
    along = np.sin(np.clip((v + 1) / 2, 0, 1) * math.pi) ** 0.8
    intensity = (np.exp(-((u - bend) / 0.12) ** 2) + 0.3 * np.exp(-((u - bend) / 0.35) ** 2)) * along
    return lead_left(np.concatenate([np.ones((height, width, 3)), np.clip(intensity, 0, 1)[..., None]], axis=-1))


def streak(width, height, core, glow, glow_strength):
    v = np.linspace(-1, 1, height)[:, None]
    u = np.linspace(-1, 1, width)[None, :]
    along = np.sin(np.clip((v + 1) / 2, 0, 1) * math.pi) ** 0.6  # tapers to nothing at both ends
    intensity = (np.exp(-(u / core) ** 2) + glow_strength * np.exp(-(u / glow) ** 2)) * along
    white = np.ones((height, width, 3)) * np.clip(0.75 + 0.25 * np.exp(-(u / core) ** 2), 0, 1)[..., None]
    return np.concatenate([white, np.clip(intensity, 0, 1)[..., None]], axis=-1)



def line_alpha(distance, width, glow_width, glow_strength, pixel):
    """An anti-aliased line of half-width `width` from a distance field, with a soft glow round it."""
    core = smoothstep(width + pixel, width - pixel, distance)
    glow = glow_strength * np.exp(-(distance / glow_width) ** 2)
    return np.maximum(core, glow)


def ward_tracery(size=512):
    """The ward's rose window, face on: a double ring at the rim; twelve mullions from a foiled centre; pointed arches
    springing between their tips; a roundel holding a quatrefoil in each light; a small oculus at the heart. Every
    line glows softly, and a faint wash brightens the glass toward the rim (the ward is darker at its centre). White
    on transparent: a Decal tints it in the game (gold-red leading on crimson glass)."""
    x, y = grid(size)
    r, theta = np.hypot(x, y), np.arctan2(y, x)
    pixel = 2 / size
    lights = 12
    sector = 2 * math.pi / lights
    to_spoke = (theta + sector / 2) % sector - sector / 2  # angle to the nearest mullion (mullions at 0, 30, 60 ...)
    to_middle = theta % sector - sector / 2  # angle to the middle of the nearest light
    frame = np.minimum(np.abs(r - 0.955), np.abs(r - 0.905))
    mullion = np.where((r > 0.30) & (r < 0.905), np.abs(r * np.sin(to_spoke)), 9.0)
    # pointed arches: each side bulges outward (a sine profile, steep at the springing) and the two meet at a point
    # mid-light, where the slope is still steep
    rise = 1 - np.abs(to_middle) / (sector / 2)  # 0 at a mullion, 1 mid-light
    arch = np.abs(r - (0.755 + 0.13 * np.sin(0.28 * math.pi * rise) / math.sin(0.28 * math.pi)))
    du, dv = r * np.cos(to_middle) - 0.6, r * np.sin(to_middle)
    from_roundel = np.hypot(du, dv)
    roundel = np.abs(from_roundel - 0.1)
    foil_angle = np.arctan2(dv, du)
    quatrefoil = np.abs(from_roundel - 0.068 * (0.7 + 0.3 * np.abs(np.cos(2 * foil_angle))))
    hexafoil = np.abs(r - 0.205 * (0.76 + 0.24 * np.abs(np.cos(3 * theta))))
    inner_ring = np.abs(r - 0.30)
    oculus = np.abs(r - 0.06)
    alpha = np.maximum.reduce([
        line_alpha(frame, 0.012, 0.05, 0.3, pixel),
        line_alpha(mullion, 0.011, 0.045, 0.3, pixel),
        line_alpha(arch, 0.009, 0.04, 0.26, pixel),
        line_alpha(np.minimum(roundel, inner_ring), 0.008, 0.035, 0.24, pixel),
        line_alpha(np.minimum(quatrefoil, np.minimum(hexafoil, oculus)), 0.006, 0.03, 0.22, pixel),
        0.14 * smoothstep(0.5, 0.95, r),  # the wash toward the rim
    ])
    alpha *= 1 - smoothstep(0.965, 0.985, r)
    return np.concatenate([np.ones((size, size, 3)), np.clip(alpha, 0, 1)[..., None]], axis=-1)


def crack_path(rng, start, heading, length, step, wander):
    """A crack as a polyline: short steps that wander a little from the heading."""
    points = [np.array(start, dtype=float)]
    angle = heading
    travelled = 0.0
    while travelled < length:
        angle += rng.normal(0, wander)
        points.append(points[-1] + step * np.array([math.cos(angle), math.sin(angle)]))
        travelled += step
    return points


def segment_distance(x, y, a, b):
    """The distance from every pixel to the segment a-b."""
    ab = b - a
    t = np.clip(((x - a[0]) * ab[0] + (y - a[1]) * ab[1]) / max(float(ab @ ab), 1e-9), 0, 1)
    return np.hypot(x - (a[0] + t * ab[0]), y - (a[1] + t * ab[1]))


def ward_cracks(size=512, seed=83):
    """Cracks through the ward's glass, for its strength: three strikes, each breaking the glass the way a blow does,
    a star of nearly straight cracks running out and thinning, a few forking, tied near the strike by straight rings
    from crack to crack (a spider's web). White on transparent: a Decal fades it in as the guard's stamina runs low."""
    rng = np.random.default_rng(seed)
    x, y = grid(size)
    pixel = 2 / size
    alpha = np.zeros((size, size))

    def stroke(points, width_start, width_end):
        nonlocal alpha
        for index, (a, b) in enumerate(zip(points, points[1:])):
            width = width_start + (width_end - width_start) * index / max(1, len(points) - 2)
            alpha = np.maximum(alpha, line_alpha(segment_distance(x, y, a, b), width, 0.018, 0.16, pixel))

    for centre, arms, reach in (((-0.18, 0.22), 8, 0.8), ((0.34, -0.2), 7, 0.6), ((-0.05, -0.45), 6, 0.45)):
        centre = np.array(centre)
        spokes = []
        for arm in range(arms):
            heading = arm / arms * 2 * math.pi + rng.uniform(-0.25, 0.25)
            path = crack_path(rng, centre, heading, reach * rng.uniform(0.55, 1.0), 0.05, 0.07)
            spokes.append(path)
            stroke(path, 0.006, 0.0015)
            if rng.random() < 0.45:  # a fork from part way along
                fork = path[len(path) // 2]
                stroke(crack_path(rng, fork, heading + rng.choice([-1, 1]) * rng.uniform(0.35, 0.7), reach * 0.3, 0.04,
                                  0.08), 0.003, 0.001)
        for ring in (1, 3):  # straight links between neighbouring cracks, a step or three out from the strike
            for left, right in zip(spokes, spokes[1:] + spokes[:1]):
                if ring < len(left) and ring < len(right) and rng.random() < 0.8:
                    stroke([left[ring], right[ring]], 0.0028, 0.0028)
    alpha *= 1 - smoothstep(0.93, 0.96, np.hypot(x, y))
    return np.concatenate([np.ones((size, size, 3)), np.clip(alpha, 0, 1)[..., None]], axis=-1)


def convex_hull(points):
    """The convex hull of a few points, counter-clockwise (Andrew's monotone chain)."""
    ordered = sorted(points, key=lambda q: (q[0], q[1]))

    def half(sequence):
        chain = []
        for q in sequence:
            while len(chain) >= 2 and ((chain[-1][0] - chain[-2][0]) * (q[1] - chain[-2][1])
                                       - (chain[-1][1] - chain[-2][1]) * (q[0] - chain[-2][0])) <= 0:
                chain.pop()
            chain.append(q)
        return chain

    lower, upper = half(ordered), half(list(reversed(ordered)))
    return lower[:-1] + upper[:-1]


def glass_shard(cell=128, seed=89):
    """Four shards of the ward's glass in a 2x2 sheet: sharp, uneven slivers, each with a bright edge, a clearer body
    and one glint along it. Glass, never anything else (AGENTS.md rule 4). White: tinted crimson in the game."""
    rng = np.random.default_rng(seed)
    x, y = grid(cell)
    pixel = 2 / cell
    cells = []
    for _ in range(4):
        # a long point and two or three base corners, closed into a convex outline (a hull fills completely)
        turn = rng.uniform(0, math.pi)
        corners = [(0.95, 0.0)] + [(rng.uniform(0.3, 0.65), rng.uniform(1.9, 4.4)) for _ in range(int(rng.integers(2, 4)))]
        stretch = rng.uniform(0.5, 0.75)  # slivers, longer than wide
        raw = [np.array([rr * math.cos(a), rr * math.sin(a) * stretch]) for rr, a in corners]
        raw = [np.array([q[0] * math.cos(turn) - q[1] * math.sin(turn), q[0] * math.sin(turn) + q[1] * math.cos(turn)]) for q in raw]
        points = convex_hull(raw)
        edges = [segment_distance(x, y, a, b) for a, b in zip(points, points[1:] + points[:1])]
        edge = np.minimum.reduce(edges)
        inside = np.ones_like(x, dtype=bool)  # convex polygon: inside every edge
        for a, b in zip(points, points[1:] + points[:1]):
            inside &= ((b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0])) >= 0
        body = np.where(inside, 0.55, 0.0) * smoothstep(0.0, 2 * pixel, edge)
        rim = line_alpha(edge, 0.012, 0.03, 0.25, pixel) * (inside | (edge < 0.02))
        glint_a, glint_b = points[0] * 0.6, points[len(points) // 2] * 0.6
        glint = line_alpha(segment_distance(x, y, glint_a, glint_b), 0.006, 0.02, 0.2, pixel) * inside
        alpha = np.clip(np.maximum.reduce([body, rim, glint]), 0, 1)
        cells.append(np.concatenate([np.ones((cell, cell, 3)), alpha[..., None]], axis=-1))
    return sheet(cells, 2)

# --- volumetric flipbooks (Cycles) ------------------------------------------------------------------------------

def volume_stage(cell):
    """A transparent Cycles scene: an orthographic camera looking down +Y (X right, Z up), a key light from the
    upper left, a faint cool fill, and a 2x2x2 cube to carry the volume."""
    scene = bc.reset_scene()
    bc.use_gpu(scene)
    scene.cycles.samples = 96
    scene.cycles.use_denoising = True
    scene.cycles.volume_step_rate = 0.5
    scene.cycles.volume_max_steps = 512
    scene.render.film_transparent = True
    scene.render.resolution_x = scene.render.resolution_y = cell
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Fill")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.20, 0.21, 0.25, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.32  # low fill: the volume shadows itself
    scene.world = world
    camera = bpy.data.objects.new("Camera", bpy.data.cameras.new("Camera"))
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 2.0
    camera.location = (0, -6, 0)
    camera.rotation_euler = (math.radians(90), 0, 0)
    scene.collection.objects.link(camera)
    scene.camera = camera
    sun = bpy.data.objects.new("Key", bpy.data.lights.new("Key", "SUN"))
    sun.data.energy = 6.0
    sun.data.angle = math.radians(8)
    sun.rotation_euler = (math.radians(50), math.radians(-35), math.radians(-30))
    scene.collection.objects.link(sun)
    bpy.ops.mesh.primitive_cube_add(size=2)
    cube = bpy.context.active_object
    material = bpy.data.materials.new("Volume")
    material.use_nodes = True
    tree = material.node_tree
    tree.nodes.remove(tree.nodes["Principled BSDF"])
    volume = tree.nodes.new("ShaderNodeVolumePrincipled")
    volume.inputs["Color"].default_value = (0.86, 0.86, 0.88, 1)
    volume.inputs["Anisotropy"].default_value = 0.25
    tree.links.new(volume.outputs["Volume"], tree.nodes["Material Output"].inputs["Volume"])
    cube.data.materials.append(material)
    return scene, tree, volume


def node(tree, kind, **inputs):
    n = tree.nodes.new(kind)
    for key, value in inputs.items():
        if key in ("operation", "noise_dimensions", "data_type", "interpolation_type", "clamp"):
            setattr(n, key, value)
        else:
            n.inputs[key].default_value = value
    return n


def math_node(tree, operation, a, b=None):
    n = tree.nodes.new("ShaderNodeMath")
    n.operation = operation
    for index, value in enumerate((a, b)):
        if value is None:
            continue
        if isinstance(value, (int, float)):
            n.inputs[index].default_value = value
        else:
            tree.links.new(value, n.inputs[index])
    return n.outputs[0]


def render_frames(scene, frames, update, name, turn=None):
    """Renders `frames` cells as a 4x4 sheet, each cell passed through `turn` if given (lead_left)."""
    cells = []
    for i in range(frames):
        update(i / (frames - 1))
        path = OUT / f"_{name}_{i:02d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        cell = load_rgba(path)
        cells.append(turn(cell) if turn else cell)
        path.unlink()
    return sheet(cells, 4)


def smoke_puff(cell=256, frames=16):
    """Billows: swirling noise inside a sphere whose surface is pushed in and out by coarser noise (a lumpy,
    cauliflower silhouette), lit from one side so it shadows itself. It grows, then thins and breaks up."""
    scene, tree, volume = volume_stage(cell)
    volume.inputs["Anisotropy"].default_value = 0.35
    links = tree.links
    coords = node(tree, "ShaderNodeTexCoord")
    noise = node(tree, "ShaderNodeTexNoise", Scale=2.2, Detail=8.0, Roughness=0.62, Distortion=0.6)
    noise.noise_dimensions = "4D"
    links.new(coords.outputs["Object"], noise.inputs["Vector"])
    lumps = node(tree, "ShaderNodeTexNoise", Scale=1.6, Detail=2.0, Roughness=0.5)
    lumps.noise_dimensions = "4D"
    links.new(coords.outputs["Object"], lumps.inputs["Vector"])
    radius = node(tree, "ShaderNodeVectorMath", operation="LENGTH")
    links.new(coords.outputs["Object"], radius.inputs[0])
    lumpy_radius = math_node(tree, "ADD", radius.outputs["Value"], math_node(tree, "MULTIPLY", math_node(tree, "SUBTRACT", lumps.outputs["Fac"], 0.5), -0.7))
    falloff = node(tree, "ShaderNodeMapRange", interpolation_type="SMOOTHSTEP")
    links.new(lumpy_radius, falloff.inputs["Value"])
    detail = math_node(tree, "SUBTRACT", noise.outputs["Fac"], 0.3)
    threshold = detail.node
    shaped = math_node(tree, "MULTIPLY", math_node(tree, "MAXIMUM", detail, 0.0), falloff.outputs["Result"])
    density = math_node(tree, "MULTIPLY", shaped, 60.0)
    links.new(density, volume.inputs["Density"])

    def update(t):
        size = 0.36 + 0.5 * t ** 0.55
        falloff.inputs["From Min"].default_value = size  # 0 at the edge ...
        falloff.inputs["From Max"].default_value = size * 0.45  # ... 1 inside
        noise.inputs["W"].default_value = t * 1.2
        lumps.inputs["W"].default_value = t * 0.5
        threshold.inputs[1].default_value = 0.28 + 0.2 * t  # breaks up as it ages
        density.node.inputs[1].default_value = 45 * (1 - t) ** 1.7 + 2.0

    return render_frames(scene, frames, update, "smoke")


def crescent_masks(width, height):
    """The crescent's geometry on a (height, width) grid, convex edge up: how deep inside the outer edge (d_out) and
    how far beyond the inner edge (d_in) each pixel is, in the grid's units (x across -1..1), and its angle round the
    outer arc's centre."""
    aspect = height / width
    x = np.linspace(-1, 1, width)[None, :]
    y = np.linspace(aspect * 1.6, -aspect * 0.4, height)[:, None]  # row 0 is the top
    # both arcs pass through the tips at (+-0.95, 0): the outer one peaks at 0.55, the inner (larger, lower) at 0.37, so
    # the band is thickest in the middle and comes to a point at each tip
    outer_c, outer_r = -0.545, 1.095
    inner_c, inner_r = -1.035, 1.405
    d_out = outer_r - np.hypot(x, y - outer_c)
    d_in = np.hypot(x, y - inner_c) - inner_r
    angle = np.arctan2(x, y - outer_c)
    return d_out, d_in, angle


def crescent_arc(width=512, height=192, seed=71):
    """An energy crescent like a sword wave (the Crimson Crescent): a hard bright edge along the convex side, a body of
    streaks running along the arc that fades toward the inner edge. Clean energy, never liquid: no drips, no
    droplets (AGENTS.md rule 4). White; the game tints it."""
    rng = np.random.default_rng(seed)
    d_out, d_in, angle = crescent_masks(width, height)
    inside = smoothstep(0.0, 0.012, d_out) * smoothstep(0.0, 0.02, d_in)
    edge = np.exp(-(d_out / 0.014) ** 2)
    body = np.exp(-np.clip(d_out, 0, None) / 0.16)
    inner_glow = np.exp(-(np.clip(d_in, 0, None) / 0.03) ** 2) * 0.35  # a faint second line along the inner edge
    streaks = 0.5 + 0.5 * streak_noise(width, height, 110, 5, rng).T  # long along the arc
    along = np.clip(np.abs(angle) / 1.05, 0, 1)
    taper = 1 - smoothstep(0.6, 1.0, along)  # the tips thin out
    alpha = np.clip((edge * 1.2 + body * 0.85 * streaks + inner_glow) * inside * (0.3 + 0.7 * taper), 0, 1)
    white = np.ones((height, width, 3)) * np.clip(0.8 + 0.2 * edge, 0, 1)[..., None]
    return np.concatenate([white, alpha[..., None]], axis=-1)


def crescent_halo(width=512, height=192):
    """The soft glow round the crescent: brightest along its outer edge, spreading a little past both edges."""
    d_out, d_in, angle = crescent_masks(width, height)
    outside = np.clip(-d_out, 0, None) + np.clip(-d_in, 0, None)
    near = np.exp(-(outside / 0.07) ** 2)
    rim = np.exp(-(d_out / 0.08) ** 2)
    along = np.clip(np.abs(angle) / 1.1, 0, 1)
    taper = 1 - smoothstep(0.55, 1.0, along)
    alpha = np.clip((0.5 * near + 0.55 * rim) * taper, 0, 1)
    return np.concatenate([np.ones((height, width, 3)), alpha[..., None]], axis=-1)


def energy_wisp(width=128, height=256, seed=79):
    """A soft column of energy wavering as it rises, streaked along its length, tapered at both ends (white)."""
    rng = np.random.default_rng(seed)
    v = np.linspace(1, 0, height)[:, None]  # 1 at the top
    u = np.linspace(-1, 1, width)[None, :]
    centre = 0.32 * np.sin(math.tau * (0.9 * v + 0.1)) * (0.3 + 0.7 * v)  # sways more as it rises
    width_at = 0.22 + 0.38 * np.sin(np.clip(v, 0, 1) * math.pi) ** 0.9
    core = np.exp(-((u - centre) / (width_at * 0.3)) ** 2)
    glow = np.exp(-((u - centre) / width_at) ** 2)
    streaks = streak_noise(height, width, 60, 6, rng)
    breakup = smoothstep(0.25, 0.75, value_noise((height, width), 24, rng))  # holes torn through it
    ends = np.sin(np.clip(v, 0, 1) * math.pi) ** 0.6
    alpha = np.clip((core * 0.8 + glow * 0.55 * (0.35 + 0.65 * streaks)) * (0.45 + 0.55 * breakup) * ends, 0, 1)
    return np.concatenate([np.ones((height, width, 3)), alpha[..., None]], axis=-1)


def fire_burst(cell=256, frames=16):
    """Flame, the smoke puff's method made to burn: swirling noise inside a lumpy body stretched upward, emissive, its
    noise drifting down through it so tongues lick up. It kindles small and bright, swells and rises, then breaks up and
    dims. White emission (the game tints it), so the texture never carries a colour of its own."""
    scene, tree, volume = volume_stage(cell)
    links = tree.links
    volume.inputs["Color"].default_value = (1, 1, 1, 1)
    volume.inputs["Emission Color"].default_value = (1, 1, 1, 1)
    volume.inputs["Anisotropy"].default_value = 0.0
    coords = node(tree, "ShaderNodeTexCoord")
    tall = node(tree, "ShaderNodeVectorMath", operation="MULTIPLY")  # squashed vertically: the body reads tall
    links.new(coords.outputs["Object"], tall.inputs[0])
    tall.inputs[1].default_value = (1.0, 1.0, 0.62)
    lift = node(tree, "ShaderNodeVectorMath", operation="SUBTRACT")  # the body's centre rises over time
    links.new(tall.outputs["Vector"], lift.inputs[0])
    drift = node(tree, "ShaderNodeVectorMath", operation="SUBTRACT")  # the noise falls through it: tongues lick up
    links.new(coords.outputs["Object"], drift.inputs[0])
    noise = node(tree, "ShaderNodeTexNoise", Scale=1.6, Detail=2.5, Roughness=0.45, Distortion=1.4)  # broad tongues, no grain
    noise.noise_dimensions = "4D"
    links.new(drift.outputs["Vector"], noise.inputs["Vector"])
    lumps = node(tree, "ShaderNodeTexNoise", Scale=1.5, Detail=2.0, Roughness=0.5)
    lumps.noise_dimensions = "4D"
    links.new(drift.outputs["Vector"], lumps.inputs["Vector"])
    radius = node(tree, "ShaderNodeVectorMath", operation="LENGTH")
    links.new(lift.outputs["Vector"], radius.inputs[0])
    lumpy = math_node(tree, "ADD", radius.outputs["Value"], math_node(tree, "MULTIPLY", math_node(tree, "SUBTRACT", lumps.outputs["Fac"], 0.5), -0.9))
    falloff = node(tree, "ShaderNodeMapRange", interpolation_type="SMOOTHSTEP")
    links.new(lumpy, falloff.inputs["Value"])
    detail = math_node(tree, "SUBTRACT", noise.outputs["Fac"], 0.3)
    threshold = detail.node
    core = math_node(tree, "MULTIPLY", falloff.outputs["Result"], falloff.outputs["Result"])  # brightest deep inside
    flame = math_node(tree, "MULTIPLY", math_node(tree, "ADD", math_node(tree, "MAXIMUM", detail, 0.0), math_node(tree, "MULTIPLY", core, 0.25)), falloff.outputs["Result"])
    density = math_node(tree, "MULTIPLY", flame, 6.0)
    links.new(density, volume.inputs["Density"])
    glow = math_node(tree, "MULTIPLY", flame, 40.0)
    links.new(glow, volume.inputs["Emission Strength"])

    def update(t):
        lift.inputs[1].default_value = (0, 0, -0.35 + 0.55 * t)  # the centre starts low and rises
        drift.inputs[1].default_value = (0, 0, -1.1 * t)
        noise.inputs["W"].default_value = t * 1.4
        lumps.inputs["W"].default_value = t * 0.7
        size = 0.32 + 0.48 * t ** 0.5
        falloff.inputs["From Min"].default_value = size
        falloff.inputs["From Max"].default_value = size * 0.4
        threshold.inputs[1].default_value = 0.26 + 0.24 * t ** 1.2  # tongues break apart as it ages
        glow.node.inputs[1].default_value = 55 * (1 - t) ** 1.3 + 4
        density.node.inputs[1].default_value = 7 * (1 - t) + 1.0

    return render_frames(scene, frames, update, "fire")


# --- main ------------------------------------------------------------------------------------------------------------

DRAWN = {
    "muzzle_flash": muzzle_flash,
    "muzzle_cone": muzzle_cone,
    "spark": lambda: lead_left(streak(64, 256, core=0.10, glow=0.35, glow_strength=0.35)),
    "tracer": lambda: streak(64, 512, core=0.07, glow=0.30, glow_strength=0.25),
    "slash_edge": slash_edge,
    "blade_smear": blade_smear,
    "smoke_ribbon": smoke_ribbon,
    "wind_line": wind_line,
    "wind_ring": wind_ring,
    "wind_streak": wind_streak,
    "crescent_arc": crescent_arc,
    "crescent_halo": crescent_halo,
    "energy_wisp": energy_wisp,
    "ward_tracery": ward_tracery,
    "ward_cracks": ward_cracks,
    "glass_shard": glass_shard,
}
RENDERED = {"smoke_puff": smoke_puff, "fire_burst": fire_burst}

for name, make in {**DRAWN, **RENDERED}.items():
    if wanted(name):
        save_rgba(name, make())
