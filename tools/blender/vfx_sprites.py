"""Renders BloodsLocks' gunfire and hit sprites (our own art) with Blender, headless:
  smoke_puff    4x4 flipbook of 256 px cells: a lit volumetric puff that billows out and thins (white: tint it)
  mist_burst    4x4 flipbook of 256 px cells: a fibrous burst thrown toward the left of the cell, for velocity-aligned
                particles (white: tint it)
  muzzle_flash  2x2 sheet of 256 px variants: a star flash, white-hot core to orange rim (one variant a shot)
  muzzle_cone   128x512: the side flash, for a Beam (a Beam runs its texture's vertical axis along its length)
  spark         256x64: a thin hot streak tapered at both ends, for velocity-aligned particles (white: tint it)
  tracer        64x512: a pale thin core in a faint glow, tapered at both ends, for a Beam (white: tint it)
  slash_edge    64x512: the hot hairline the point leaves, for a Trail (same layout; white, additive)
  blade_smear   256x256: a blade's pale motion smear for a Trail (base left, point right, newest at the top; white)
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


def streak(width, height, core, glow, glow_strength):
    v = np.linspace(-1, 1, height)[:, None]
    u = np.linspace(-1, 1, width)[None, :]
    along = np.sin(np.clip((v + 1) / 2, 0, 1) * math.pi) ** 0.6  # tapers to nothing at both ends
    intensity = (np.exp(-(u / core) ** 2) + glow_strength * np.exp(-(u / glow) ** 2)) * along
    white = np.ones((height, width, 3)) * np.clip(0.75 + 0.25 * np.exp(-(u / core) ** 2), 0, 1)[..., None]
    return np.concatenate([white, np.clip(intensity, 0, 1)[..., None]], axis=-1)


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


def mist_burst(cell=256, frames=16):
    """Fibres thrown from the bottom of the cell upward. Noise sampled on the direction from the origin is constant
    along each ray, so it streaks; a second direction noise gives each fibre its own reach (so the front is ragged)
    and frays the cone's edge; a misty knot billows at the origin. The front rushes out, then everything thins."""
    scene, tree, volume = volume_stage(cell)
    links = tree.links
    coords = node(tree, "ShaderNodeTexCoord")
    offset = node(tree, "ShaderNodeVectorMath", operation="SUBTRACT")
    offset.inputs[1].default_value = (0, 0, -0.6)  # high enough that the knot never touches the cell's edge
    links.new(coords.outputs["Object"], offset.inputs[0])
    distance = node(tree, "ShaderNodeVectorMath", operation="LENGTH")
    links.new(offset.outputs["Vector"], distance.inputs[0])
    direction = node(tree, "ShaderNodeVectorMath", operation="NORMALIZE")
    links.new(offset.outputs["Vector"], direction.inputs[0])

    def direction_noise(scale, detail):
        n = node(tree, "ShaderNodeTexNoise", Scale=scale, Detail=detail, Roughness=0.55)
        n.noise_dimensions = "4D"
        links.new(direction.outputs["Vector"], n.inputs["Vector"])
        return n

    fibres = direction_noise(13.0, 4.0)
    reach_noise = direction_noise(4.0, 2.0)
    fray = direction_noise(3.0, 2.0)
    wisps = node(tree, "ShaderNodeTexNoise", Scale=5.0, Detail=8.0, Roughness=0.65)
    wisps.noise_dimensions = "4D"
    links.new(coords.outputs["Object"], wisps.inputs["Vector"])

    up = node(tree, "ShaderNodeSeparateXYZ")
    links.new(direction.outputs["Vector"], up.inputs[0])
    frayed = math_node(tree, "ADD", up.outputs["Z"], math_node(tree, "MULTIPLY", math_node(tree, "SUBTRACT", fray.outputs["Fac"], 0.5), 0.5))
    cone = node(tree, "ShaderNodeMapRange", interpolation_type="SMOOTHSTEP")
    links.new(frayed, cone.inputs["Value"])
    cone.inputs["From Min"].default_value = math.cos(math.radians(42))
    cone.inputs["From Max"].default_value = math.cos(math.radians(14))

    # each fibre's reach: the front's distance times about 0.45..1.45 (noise mostly spans 0.25..0.75)
    own_reach = math_node(tree, "MULTIPLY", math_node(tree, "ADD", math_node(tree, "MULTIPLY", reach_noise.outputs["Fac"], 2.0), -0.05), 1.0)
    reach = own_reach.node
    ratio = math_node(tree, "DIVIDE", distance.outputs["Value"], math_node(tree, "MAXIMUM", own_reach, 0.05))
    front = node(tree, "ShaderNodeMapRange", interpolation_type="SMOOTHSTEP")
    links.new(ratio, front.inputs["Value"])
    front.inputs["From Min"].default_value, front.inputs["From Max"].default_value = 1.05, 0.7

    strands = math_node(tree, "POWER", fibres.outputs["Fac"], 3.0)
    body = math_node(tree, "MULTIPLY", math_node(tree, "MULTIPLY", strands, cone.outputs["Result"]), front.outputs["Result"])
    body = math_node(tree, "MULTIPLY", body, math_node(tree, "ADD", wisps.outputs["Fac"], 0.25))
    knot = node(tree, "ShaderNodeMapRange", interpolation_type="SMOOTHSTEP")  # the mist at the origin
    links.new(distance.outputs["Value"], knot.inputs["Value"])
    mist = math_node(tree, "MULTIPLY", knot.outputs["Result"], math_node(tree, "MAXIMUM", math_node(tree, "SUBTRACT", wisps.outputs["Fac"], 0.35), 0.0))
    density = math_node(tree, "MULTIPLY", math_node(tree, "ADD", body, math_node(tree, "MULTIPLY", mist, 1.6)), 70.0)
    links.new(density, volume.inputs["Density"])

    def update(t):
        reach.inputs[1].default_value = 0.3 + 0.85 * t ** 0.6
        knot.inputs["From Min"].default_value = 0.18 + 0.17 * t  # the knot spreads ...
        knot.inputs["From Max"].default_value = 0.0
        fibres.inputs["W"].default_value = t * 0.5
        reach_noise.inputs["W"].default_value = t * 0.3
        wisps.inputs["W"].default_value = t * 1.2
        density.node.inputs[1].default_value = 95 * (1 - t) ** 1.8 + 2.0  # ... and everything thins

    return render_frames(scene, frames, update, "mist", lead_left)


# --- main ------------------------------------------------------------------------------------------------------------

DRAWN = {
    "muzzle_flash": muzzle_flash,
    "muzzle_cone": muzzle_cone,
    "spark": lambda: lead_left(streak(64, 256, core=0.10, glow=0.35, glow_strength=0.35)),
    "tracer": lambda: streak(64, 512, core=0.07, glow=0.30, glow_strength=0.25),
    "slash_edge": slash_edge,
    "blade_smear": blade_smear,
}
RENDERED = {"smoke_puff": smoke_puff, "mist_burst": mist_burst}

for name, make in {**DRAWN, **RENDERED}.items():
    if wanted(name):
        save_rgba(name, make())
