"""R6 animation in Blender, for clip scripts such as tools/blender/bite_anim.py (run headless:
blender.exe -b --factory-startup --python <clip script> -- <out_dir>).

An exact R6 rig, built from Roblox's own Motor6D joints (C0/C1 measured on a live character), animated with Blender's
curves, reviewed in renders from the game's player camera, and baked to one pose per frame for Studio: the JSON goes to
build/import/Anim_<Name>.txt, and tools/studio/Animations/Author.SaveBaked turns it into a KeyframeSequence.

Frames: Roblox X = Blender X, Roblox Y = Blender Z, Roblox Z = -Blender Y (blcommon); a character faces Roblox -Z, which
is Blender +Y. Each rig is a tree of objects: an Empty for the HumanoidRootPart (moved for review only: in the game
physics moves it), and per joint an Empty at its C0 (child of Part0), an animated Empty under it whose local transform
is the Motor6D's Transform, and the part's box under that at C1's inverse. What's exported is what Roblox plays.

Poses use the body-space angles of tools/studio/Animations/Author: degrees, X = pitch (forward for arms, legs, torso and
head), Y = turn (left), Z = swing (an arm or leg out: Right +, Left -), then an optional move in studs (-Z is forward).
Keyed with plant=True (the default), a pose gives the legs' pitch against the ground: R6 legs hang from the torso, so
the torso's lean is added to them and the torso shifts to keep the hips over the feet.
"""

import json
import math
import re
from pathlib import Path

import bpy
from mathutils import Matrix, Quaternion, Vector

import blcommon as bl

REPO = Path(__file__).resolve().parents[2]

# Roblox to Blender: (x, y, z) -> (x, -z, y), a rotation (blcommon's frames).
M = Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))
M_INV = M.inverted()

PARTS = ("Torso", "Head", "Right Arm", "Left Arm", "Right Leg", "Left Leg")
LEANS = {"Torso", "Head"}  # pitch flips on these: their joint bases face the other way from a limb's
LEGS = {"Right Leg", "Left Leg"}
ROOT_HEIGHT = 3.0  # studs from the floor to the HumanoidRootPart's centre

# Part1: (Part0, C0, C1), Roblox CFrame components, measured on a live R6 character (2026-10-31).
_BASE = (-1, 0, 0, 0, 0, 1, 0, 1, 0)
_RIGHT = (0, 0, 1, 0, 1, 0, -1, 0, 0)
_LEFT = (0, 0, -1, 0, 1, 0, 1, 0, 0)
JOINTS = {
    "Torso": ("HumanoidRootPart", (0, 0, 0) + _BASE, (0, 0, 0) + _BASE),
    "Head": ("Torso", (0, 1, 0) + _BASE, (0, -0.5, 0) + _BASE),
    "Right Arm": ("Torso", (1, 0.5, 0) + _RIGHT, (-0.5, 0.5, 0) + _RIGHT),
    "Left Arm": ("Torso", (-1, 0.5, 0) + _LEFT, (0.5, 0.5, 0) + _LEFT),
    "Right Leg": ("Torso", (1, -1, 0) + _RIGHT, (0.5, 1, 0) + _RIGHT),
    "Left Leg": ("Torso", (-1, -1, 0) + _LEFT, (-0.5, 1, 0) + _LEFT),
}
SIZES = {"Torso": (2, 2, 1), "Head": (2, 1, 1), "Right Arm": (1, 2, 1), "Left Arm": (1, 2, 1),
         "Right Leg": (1, 2, 1), "Left Leg": (1, 2, 1)}

# Gustave's weapons as review boxes: (part, weld C0, weld C1, size), from the live welds (Equipment.AttachLoadout).
_GRIP = (0, -1, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0)
WEAPONS = {
    "SabreHilt": ("Right Arm", _GRIP, (0, 0.0091, 0.1707, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.39, 1.42, 0.64)),
    "SabreBlade": ("SabreHilt", (0, 2.1374, 0.2578, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.05, 3.35, 0.43)),
    "Pistol": ("Left Arm", _GRIP, (0, -0.2009, 0.9275, 1, 0, 0, 0, 1, 0, 0, 0, 1), (0.19, 0.98, 2.09)),
}


# --- frames ------------------------------------------------------------------------------------------------------

def cframe(c) -> Matrix:
    """A Roblox CFrame from its 12 components (x, y, z, R00 ... R22)."""
    x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = c
    return Matrix(((r00, r01, r02, x), (r10, r11, r12, y), (r20, r21, r22, z), (0, 0, 0, 1)))


def components(m: Matrix) -> list:
    return [m[0][3], m[1][3], m[2][3], m[0][0], m[0][1], m[0][2], m[1][0], m[1][1], m[1][2], m[2][0], m[2][1], m[2][2]]


def to_blender(m: Matrix) -> Matrix:
    return M @ m @ M_INV


def to_roblox(m: Matrix) -> Matrix:
    return M_INV @ m @ M


def point_to_blender(p) -> Vector:
    return Vector((p[0], -p[2], p[1]))


def point_to_roblox(p) -> Vector:
    return Vector((p[0], p[2], -p[1]))


def look_at(position, target) -> Matrix:
    """A Roblox CFrame at `position` looking at `target` (both Roblox points), like CFrame.lookAt."""
    position, target = Vector(position), Vector(target)
    look = (target - position).normalized()
    right = look.cross(Vector((0, 1, 0))).normalized()
    up = right.cross(look)
    back = -look
    return Matrix(((right.x, up.x, back.x, position.x), (right.y, up.y, back.y, position.y),
                   (right.z, up.z, back.z, position.z), (0, 0, 0, 1)))


# --- the rig ---------------------------------------------------------------------------------------------------------

class Rig:
    def __init__(self, name: str):
        self.name = name
        self.root: bpy.types.Object | None = None  # the HumanoidRootPart
        self.parts: dict[str, bpy.types.Object] = {}  # part name -> its box
        self.joints: dict[str, bpy.types.Object] = {}  # part name -> the animated Empty (Motor6D Transform)
        self.bases: dict[str, Matrix] = {}  # part name -> its C0 rotation (Roblox), for body-space poses
        self.last: dict[str, Quaternion] = {}  # the last keyed rotation per joint, to keep quaternions continuous


def _empty(name, parent, local: Matrix, size=0.15):
    obj = bpy.data.objects.new(name, None)
    obj.empty_display_size = size
    bpy.context.scene.collection.objects.link(obj)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.rotation_mode = "QUATERNION"
    obj.matrix_basis = to_blender(local)
    return obj


def _block(name, parent, local: Matrix, size, material):
    """A box of Roblox `size` under `parent` at Roblox `local`."""
    obj = bl.box(name, (size[0], size[2], size[1]), material)
    obj.parent = parent
    obj.matrix_parent_inverse = Matrix.Identity(4)
    obj.matrix_basis = to_blender(local)
    return obj


def flat_material(name, colour, roughness=0.6, emission=None):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*colour, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = 2.0
    material.diffuse_color = (*colour, 1)  # what Workbench shows
    return material


def build_rig(name: str, palette: dict, weapons: bool = False) -> Rig:
    """An R6 body: palette maps part names (and "Face", "Blade", "Steel") to RGB. Weapons adds Gustave's sabre and pistol."""
    rig = Rig(name)
    materials = {key: flat_material(f"{name}_{key}", rgb) for key, rgb in palette.items()}
    rig.root = _empty(f"{name}.Root", None, Matrix.Identity(4), 0.4)
    rig.parts["HumanoidRootPart"] = rig.root
    for part in PARTS:  # in order: every Part0 exists before its children
        part0, c0, c1 = JOINTS[part]
        base = _empty(f"{name}.C0.{part}", rig.parts[part0], cframe(c0))
        joint = _empty(f"{name}.J.{part}", base, Matrix.Identity(4))
        rig.joints[part] = joint
        rig.bases[part] = cframe(c0).to_3x3().to_4x4()
        rig.parts[part] = _block(f"{name}.{part}", joint, cframe(c1).inverted(), SIZES[part], materials.get(part))
    # the face's side: a dark band across the front of the head, so its facing reads in any render
    _block(f"{name}.Face", rig.parts["Head"], cframe((0, 0.08, -0.47, 1, 0, 0, 0, 1, 0, 0, 0, 1)), (1.3, 0.22, 0.1),
           materials.get("Face"))
    if weapons:
        for weapon, (part0, c0, c1, size) in WEAPONS.items():
            key = "Blade" if weapon == "SabreBlade" else "Steel"
            rig.parts[weapon] = _block(f"{name}.{weapon}", rig.parts[part0], cframe(c0) @ cframe(c1).inverted(), size,
                                       materials.get(key))
    return rig


# Each hand's real weapon: the .blend its script writes (saber.py, smg.py) and the objects in it. Their origins are
# the grips (the models' Grip attachments, at the model's origin with no turn), seated in the hand like the game's welds.
WEAPON_MESHES = {"Right Arm": ("saber.blend", ("Saber_Hilt", "Saber_Blade")),
                 "Left Arm": ("smg.blend", ("SMG_Body", "SMG_Crystal"))}
# Workbench colours for their materials (review only), by a word in the material's name.
WEAPON_COLOURS = (("Inlaid", (0.075, 0.07, 0.08)), ("Steel", (0.075, 0.07, 0.08)), ("Brass", (0.62, 0.45, 0.17)),
                  ("Walnut", (0.27, 0.12, 0.05)), ("Shagreen", (0.22, 0.04, 0.05)), ("Crystal", (1.0, 0.6, 0.2)),
                  ("Garnet", (0.5, 0.03, 0.06)))


def weapon_meshes(rig: Rig, folder: Path) -> bool:
    """Gustave's real sabre and machine pistol in the rig's hands, for reviews that need their silhouettes: loaded from
    the .blend files tools/blender/saber.py and smg.py wrote to `folder`. False (nothing added) if one is missing."""
    paths = {arm: Path(folder) / blend for arm, (blend, _) in WEAPON_MESHES.items()}
    if not all(path.exists() for path in paths.values()):
        return False
    for arm, (_, names) in WEAPON_MESHES.items():
        with bpy.data.libraries.load(str(paths[arm])) as (_, data_to):
            data_to.objects = list(names)
        for obj in data_to.objects:
            bpy.context.scene.collection.objects.link(obj)
            obj.parent = rig.parts[arm]
            obj.matrix_parent_inverse = Matrix.Identity(4)
            obj.matrix_basis = to_blender(cframe(_GRIP))
            rig.parts[obj.name] = obj
            for slot in obj.material_slots:
                for word, colour in WEAPON_COLOURS:
                    if slot.material and word in slot.material.name:
                        slot.material.diffuse_color = (*colour, 1)
                        break
    return True


def place_root(rig: Rig, frame: int, position, facing, interpolation="LINEAR"):
    """Keys the HumanoidRootPart at a Roblox `position` (feet on the floor + ROOT_HEIGHT), facing a Roblox direction.
    Review only: in the game physics moves the root (the pull and the throw are Knock pushes)."""
    position = Vector(position)
    rig.root.matrix_basis = to_blender(look_at(position, position + Vector(facing)))
    rig.root.keyframe_insert("location", frame=frame)
    rig.root.keyframe_insert("rotation_quaternion", frame=frame)
    _set_interpolation(rig.root, frame, interpolation, "AUTO")


# --- poses -----------------------------------------------------------------------------------------------------------

def transform(rig: Rig, part: str, data) -> Matrix:
    """The Motor6D Transform (Roblox) for a body-space pose `data` = (x, y, z, dx?, dy?, dz?)."""
    x, y, z = data[0], data[1], data[2]
    move = Matrix.Translation(Vector((data[3] if len(data) > 3 else 0, data[4] if len(data) > 4 else 0,
                                      data[5] if len(data) > 5 else 0)))
    pitch = -x if part in LEANS else x
    turn = (Matrix.Rotation(math.radians(pitch), 4, "X") @ Matrix.Rotation(math.radians(y), 4, "Y")
            @ Matrix.Rotation(math.radians(z), 4, "Z"))
    b = rig.bases[part]
    return b.inverted() @ (move @ turn) @ b


def planted(body: dict) -> dict:
    """Legs given against the ground: the torso's lean goes into their pitch, and the torso shifts so the hips stay
    over the feet."""
    out = dict(body)
    torso = list(body.get("Torso", (0, 0, 0)))
    torso += [0] * (6 - len(torso))
    lean = math.radians(torso[0])
    out["Torso"] = (torso[0], torso[1], torso[2], torso[3], torso[4] - (1 - math.cos(lean)), torso[5] - math.sin(lean))
    for leg in LEGS:
        data = list(body.get(leg, (0, 0, 0)))
        data += [0] * (6 - len(data))
        data[0] += torso[0]
        out[leg] = tuple(data)
    return out


def _set_interpolation(obj, frame, interpolation, easing):
    action = obj.animation_data.action if obj.animation_data else None
    if not action:
        return
    for curve in _curves(action):
        for point in curve.keyframe_points:
            if abs(point.co.x - frame) < 1e-3:
                point.interpolation = interpolation
                point.easing = easing
                point.handle_left_type = point.handle_right_type = "AUTO_CLAMPED"


def _curves(action):
    """Every F-curve of an action (Blender 5 keeps them in layered channelbags)."""
    if hasattr(action, "fcurves") and len(getattr(action, "fcurves", [])) > 0:
        return list(action.fcurves)
    curves = []
    for layer in getattr(action, "layers", []):
        for strip in layer.strips:
            for bag in getattr(strip, "channelbags", []):
                curves.extend(bag.fcurves)
    return curves


def _key_parts(rig: Rig, frame: int, body: dict, interpolation: str, easing: str):
    for part, data in body.items():
        if part not in rig.joints:
            continue
        joint = rig.joints[part]
        joint.matrix_basis = to_blender(transform(rig, part, data))
        rotation = joint.rotation_quaternion.copy()
        last = rig.last.get(part)
        if last is not None and last.dot(rotation) < 0:
            rotation.negate()  # the same rotation, the short way round
            joint.rotation_quaternion = rotation
        rig.last[part] = rotation
        joint.keyframe_insert("location", frame=frame)
        joint.keyframe_insert("rotation_quaternion", frame=frame)
        _set_interpolation(joint, frame, interpolation, easing)


def key(rig: Rig, frame: int, body: dict, plant=True, interpolation="BEZIER", easing="AUTO", contacts=None) -> dict:
    """Keys a pose at `frame` and returns what was keyed. `body` holds body-space poses for the parts it names.
    Interpolation and easing shape the segment that starts here ("BEZIER" smooth, "BACK" overshoots, "EXPO"/"QUART"
    snap, "SINE" breathes, "CONSTANT" holds).
    - plant: the legs stand against the ground (see planted), and the torso is raised or lowered so the lowest foot
      corner rests exactly on the floor.
    - contacts: {part: (local point, target)} puts a part's point on a Roblox world point, the part's pose in `body`
      being the hint: the torso leans and shifts toward it (lean_to, solved first), then an arm reaches (reach) or the
      head turns (gaze) from the torso as keyed, keeping the hint's roll or tilt."""
    bpy.context.scene.frame_set(frame)
    contacts = dict(contacts or {})
    if "Torso" in contacts:
        local, target = contacts.pop("Torso")
        body = {**body, "Torso": lean_to(rig, local, target, body.get("Torso", (0, 0, 0)))}
    body = planted(body) if plant else dict(body)
    trunk = {part: data for part, data in body.items() if part == "Torso" or part in LEGS}
    _key_parts(rig, frame, trunk, interpolation, easing)
    if plant and "Torso" in body:
        _refresh()
        drop = _lowest_foot(rig) - _floor(rig)
        torso = list(body["Torso"]) + [0] * (6 - len(body["Torso"]))
        torso[4] -= drop
        body["Torso"] = tuple(torso)
        _key_parts(rig, frame, {"Torso": body["Torso"]}, interpolation, easing)
    _refresh()
    for part, (local, target) in contacts.items():
        hint = body.get(part, (0, 0, 0))
        body[part] = gaze(rig, local, target, hint) if part == "Head" else reach(rig, part, local, target, hint)
    rest = {part: data for part, data in body.items() if part != "Torso" and part not in LEGS}
    _key_parts(rig, frame, rest, interpolation, easing)
    return body


def world_point(rig: Rig, part: str, local) -> Vector:
    """Where a point in a part's Roblox local frame is, in Roblox world space (at the current frame)."""
    obj = rig.parts[part]
    return point_to_roblox(obj.matrix_world @ point_to_blender(local))


def _refresh():
    bpy.context.view_layer.update()


def _floor(rig: Rig) -> float:
    root = to_roblox(rig.root.matrix_world)
    return root[1][3] - ROOT_HEIGHT


def _lowest_foot(rig: Rig) -> float:
    return min(world_point(rig, leg, (x, -1, z)).y for leg in LEGS for x in (-0.5, 0.5) for z in (-0.5, 0.5))


def _solve(fk, hint, ranges, steps=((5.0, 1.0, 0.2), (5.0, 1.0, 0.2)), pull=(0.002, 0.002)):
    """A coarse grid, then finer grids around the best, over two values: the pair whose point `fk(a, b)` lands nearest
    its target (fk returns the distance), nudged toward `hint` (by `pull` per unit) so the answer stays close to the
    pose asked for. `steps` gives each value's grid steps, coarse to fine."""
    best = None
    for level in range(3):
        values = []
        for axis in range(2):
            step = steps[axis][level]
            if level == 0:
                low, high = ranges[axis]
                values.append([low + i * step for i in range(int((high - low) / step) + 1)])
            else:
                centre, reach = best[1 + axis], steps[axis][level - 1]
                values.append([centre + i * step for i in range(-int(reach / step), int(reach / step) + 1)])
        for a in values[0]:
            for b in values[1]:
                cost = fk(a, b) + pull[0] * abs(a - hint[0]) + pull[1] * abs(b - hint[1])
                if best is None or cost < best[0]:
                    best = (cost, a, b)
    return best[1], best[2]


def lean_to(rig: Rig, local, target: Vector, hint) -> tuple:
    """The torso's lean (pitch) and sideways shift that bring a torso point (e.g. where the chin sits) to `target`,
    the rest of the pose kept as `hint` and the legs planted."""
    root = to_roblox(rig.root.matrix_world)
    _, c0, c1 = JOINTS["Torso"]
    c0m, c1_inv, point = cframe(c0), cframe(c1).inverted(), Vector((*local, 1))
    base = list(hint) + [0] * (6 - len(hint))

    def distance(pitch, shift):
        pose = planted({"Torso": (pitch, base[1], base[2], shift, base[4], base[5])})["Torso"]
        p = root @ c0m @ transform(rig, "Torso", pose) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, shift = _solve(distance, (base[0], base[3]), ((-10, 60), (-1.0, 1.0)),
                          ((5.0, 1.0, 0.2), (0.1, 0.02, 0.005)), (0.002, 0.05))
    return (round(pitch, 1), base[1], base[2], round(shift, 3), base[4], base[5])


def _joint_frame(rig: Rig, part: str) -> Matrix:
    """The joint's frame (Part0 at the current pose, times C0), Roblox world space."""
    part0, c0, _ = JOINTS[part]
    return to_roblox(rig.parts[part0].matrix_world) @ cframe(c0)


def reach(rig: Rig, part: str, local, target: Vector, hint) -> tuple:
    """Arm angles (pitch, roll, swing) that put the arm's `local` point (Roblox, e.g. the hand: (0, -1, 0)) on the Roblox
    world `target`, with the torso as it stands at the current frame. `hint` (pitch, roll, swing) is the pose asked
    for: its roll is kept and the answer stays near it."""
    frame0, c1_inv, point = _joint_frame(rig, part), cframe(JOINTS[part][2]).inverted(), Vector((*local, 1))
    roll = hint[1]

    def distance(pitch, swing):
        p = frame0 @ transform(rig, part, (pitch, roll, swing)) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, swing = _solve(distance, (hint[0], hint[2]), ((-90, 200), (-150, 150)))
    return (round(pitch, 1), roll, round(swing, 1))


def gaze(rig: Rig, local, target: Vector, hint) -> tuple:
    """Head angles (pitch, turn, tilt) that put the head's `local` point (e.g. the mouth) on `target`, the tilt kept."""
    frame0, c1_inv, point = _joint_frame(rig, "Head"), cframe(JOINTS["Head"][2]).inverted(), Vector((*local, 1))
    tilt = hint[2]

    def distance(pitch, turn):
        p = frame0 @ transform(rig, "Head", (pitch, turn, tilt)) @ c1_inv @ point
        return (Vector((p.x, p.y, p.z)) - target).length

    pitch, turn = _solve(distance, (hint[0], hint[1]), ((-70, 80), (-85, 85)))
    return (round(pitch, 1), round(turn, 1), tilt)


def _rest_offset(part: str, local) -> Vector:
    """A point of a limb (its own frame) from its joint, in Part0's frame with the limb at rest."""
    _, c0, c1 = JOINTS[part]
    c0m = cframe(c0)
    return (c0m @ cframe(c1).inverted() @ Vector((*local, 1))).to_3d() - c0m.to_translation()


def aim(rig: Rig, part: str, front, axis=None, point=None, local=(0, -1, 0), keep="front") -> tuple:
    """Limb angles (pitch, turn, swing) from world directions (Roblox), with Part0 as it stands at the current frame: the
    limb's front face toward `front` (an arm's: where the sabre's blade points, or the pistol's top), and its length
    toward `axis` (an arm's: where the pistol's barrel points, out of the fist) or, instead, its `local` point (the hand)
    onto the world `point`. A limb's front and length are square: `keep` says which of the two is kept exactly
    ("front" or "axis"); the other is squared to it."""
    part0, c0, _ = JOINTS[part]
    frame0 = to_roblox(rig.parts[part0].matrix_world)
    inverse = frame0.to_3x3().transposed()  # world to Part0's frame (a rotation)
    f = (inverse @ Vector(front)).normalized()

    def square(a, f):
        if keep == "front":
            return (a - a.dot(f) * f).normalized(), f
        return a, (f - f.dot(a) * a).normalized()

    if point is not None:
        # the limb turns about its joint, so the point lands at pivot + Q·o, Q taking the rest frame (length down,
        # front forward) to (length a, front f): Q·o = o.x (a × f) - o.y a - o.z f, solved for a by fixed point
        o = _rest_offset(part, local)
        d = inverse @ (Vector(point) - (frame0 @ cframe(c0)).to_translation())
        a = d.normalized()
        for _ in range(12):
            a = ((d - o.x * a.cross(f) + o.z * f) / -o.y).normalized()
            a, f = square(a, f)
    else:
        a, f = square((inverse @ Vector(axis)).normalized(), f)
    q = Matrix((a.cross(f), -a, -f)).transposed()  # columns: where the rest right, length and front go
    x, y, z = q.to_euler("ZYX")  # Rx·Ry·Rz, the order of transform's body-space angles
    return (round(math.degrees(x), 2), round(math.degrees(y), 2), round(math.degrees(z), 2))


def stand(rig: Rig, part: str, target, hint, local=(0, -1, 0)) -> tuple:
    """Leg angles (pitch, turn, swing) that put the leg's `local` point (the sole's middle) over the world `target`'s
    x and z, with Part0 as it stands at the current frame; the height is left to the torso (see sole). `hint` gives the
    turn, kept, and the start. Newton steps on the two angles."""
    part0, c0, c1 = JOINTS[part]
    frame0 = to_roblox(rig.parts[part0].matrix_world) @ cframe(c0)
    c1_inv, point, target = cframe(c1).inverted(), Vector((*local, 1)), Vector(target)
    pitch, turn, swing = hint[0], hint[1], hint[2]

    def miss(p, s):
        q = frame0 @ transform(rig, part, (p, turn, s)) @ c1_inv @ point
        return Vector((q.x - target.x, q.z - target.z))

    for _ in range(12):
        m = miss(pitch, swing)
        if m.length < 1e-5:
            break
        h = 0.01
        dp, ds = (miss(pitch + h, swing) - m) / h, (miss(pitch, swing + h) - m) / h
        det = dp.x * ds.y - ds.x * dp.y
        if abs(det) < 1e-9:
            break
        pitch -= (m.x * ds.y - ds.x * m.y) / det
        swing -= (dp.x * m.y - m.x * dp.y) / det
    return (round(pitch, 3), turn, round(swing, 3))


def sole(rig: Rig, part: str) -> float:
    """The height (Roblox world y) of a leg's lowest sole corner, at the current frame."""
    return min(world_point(rig, part, (x, -1, z)).y for x in (-0.5, 0.5) for z in (-0.5, 0.5))


# --- staging and review --------------------------------------------------------------------------------------------

def stage(scene, fps=30, size=(960, 540)):
    """Dusk on a stone floor: a cold moon key, a warm rim and a violet fill (the game's mood), Workbench-fast."""
    scene.render.fps = fps
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.engine = "BLENDER_WORKBENCH"
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "MATERIAL"
    shading.show_shadows = True
    shading.show_cavity = True
    shading.cavity_type = "BOTH"
    shading.show_object_outline = True
    shading.object_outline_color = (0.02, 0.01, 0.03)
    shading.background_type = "VIEWPORT"
    shading.background_color = (0.10, 0.07, 0.14)
    scene.display.shadow_focus = 0.6
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("Dusk")
    world.color = (0.10, 0.07, 0.14)
    scene.world = world
    floor = bl.box("Floor", (60, 60, 0.2), flat_material("Floor", (0.16, 0.14, 0.17)))
    floor.location = (0, 0, -0.1)


def player_camera(scene, rig: Rig, frame: int, fov=70.0, yaw=0.0, pitch=-10.0, distance=11.0, shoulder=1.4, name="PlayerCamera"):
    """The game's camera (CameraController): behind the rig's root at `frame`, turned `yaw` degrees from where it faces,
    `pitch` degrees, `distance` studs back, `shoulder` studs right of the focus (FocusHeight 2.4). Vertical FOV."""
    scene.frame_set(frame)
    root = to_roblox(rig.root.matrix_world)
    position = Vector((root[0][3], root[1][3], root[2][3]))
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    heading = math.atan2(-look.x, -look.z) + math.radians(yaw)
    rotation = (Matrix.Rotation(heading, 4, "Y") @ Matrix.Rotation(math.radians(pitch), 4, "X"))
    focus = position + Vector((0, 2.4, 0))
    offset = rotation @ Vector((shoulder, 0, distance, 0))
    eye = focus + Vector((offset.x, offset.y, offset.z))
    target = eye + (rotation @ Vector((0, 0, -1, 0))).to_3d()
    return fixed_camera(scene, eye, target, fov, name)


def fixed_camera(scene, eye, target, fov=50.0, name="Camera"):
    """A camera at Roblox point `eye` looking at Roblox point `target`, with a vertical FOV."""
    data = bpy.data.cameras.new(name)
    data.sensor_fit = "VERTICAL"
    data.angle_y = math.radians(fov)
    camera = bpy.data.objects.new(name, data)
    scene.collection.objects.link(camera)
    eye_b, target_b = point_to_blender(eye), point_to_blender(target)
    camera.location = eye_b
    camera.rotation_euler = (target_b - eye_b).to_track_quat("-Z", "Y").to_euler()
    return camera


def render_sheet(scene, camera, frames, path: Path, columns=6):
    """Renders `frames` from `camera` and tiles them into one contact sheet (left to right, top to bottom), each stamped
    with its time."""
    import numpy as np
    scene.camera = camera
    scene.render.use_stamp = True
    scene.render.use_stamp_date = scene.render.use_stamp_render_time = scene.render.use_stamp_camera = False
    scene.render.use_stamp_lens = scene.render.use_stamp_scene = scene.render.use_stamp_filename = False
    scene.render.use_stamp_frame = scene.render.use_stamp_time = False
    scene.render.use_stamp_note = True
    scene.render.stamp_font_size = 22
    tiles = []
    for frame in frames:
        scene.frame_set(frame)
        scene.render.stamp_note_text = f"{(frame - scene.frame_start) / scene.render.fps:.2f} s"
        tile = path.with_name(f"{path.stem}_{frame:04d}.png")
        scene.render.filepath = str(tile)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(tile))
        w, h = image.size
        tiles.append(np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(image)
        tile.unlink()
    h, w = tiles[0].shape[:2]
    rows = math.ceil(len(tiles) / columns)
    sheet = np.zeros((rows * h, columns * w, 4), dtype=np.float32)
    for i, tile in enumerate(tiles):
        r, c = divmod(i, columns)
        y0 = (rows - 1 - r) * h  # Blender images start at the bottom row
        sheet[y0:y0 + h, c * w:(c + 1) * w] = tile
    out = bpy.data.images.new(path.stem, columns * w, rows * h, alpha=True)
    out.pixels = sheet.ravel()
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    return path


def body_camera(scene, rig: Rig, frame: int, azimuth: float, elevation=8.0, distance=13.0, fov=38.0, height=2.6,
                name="BodyCamera"):
    """A camera around the rig's root as it stands at `frame`: `azimuth` degrees from its front (90 = its right side,
    180 = behind), `elevation` degrees up, `distance` studs from a point `height` studs over the floor."""
    scene.frame_set(frame)
    root = to_roblox(rig.root.matrix_world)
    position = Vector((root[0][3], root[1][3], root[2][3]))
    look = Vector((-root[0][2], -root[1][2], -root[2][2]))
    side = look.cross(Vector((0, 1, 0))).normalized()  # the body's right
    a, e = math.radians(azimuth), math.radians(elevation)
    focus = position + Vector((0, height - ROOT_HEIGHT, 0))
    eye = focus + (look * math.cos(a) + side * math.sin(a)) * distance * math.cos(e) + Vector((0, distance * math.sin(e), 0))
    return fixed_camera(scene, eye, focus, fov, name)


def render_shots(scene, shots, path: Path, columns=4):
    """Like render_sheet, for shots from different cameras: (camera, frame, label) each, the label stamped on its tile."""
    import numpy as np
    scene.render.use_stamp = True
    scene.render.use_stamp_date = scene.render.use_stamp_render_time = scene.render.use_stamp_camera = False
    scene.render.use_stamp_lens = scene.render.use_stamp_scene = scene.render.use_stamp_filename = False
    scene.render.use_stamp_frame = scene.render.use_stamp_time = False
    scene.render.use_stamp_note = True
    scene.render.stamp_font_size = 22
    tiles = []
    for camera, frame, label in shots:
        scene.camera = camera
        scene.frame_set(frame)
        scene.render.stamp_note_text = label
        tile = path.with_name(f"{path.stem}_{len(tiles):03d}.png")
        scene.render.filepath = str(tile)
        bpy.ops.render.render(write_still=True)
        image = bpy.data.images.load(str(tile))
        w, h = image.size
        tiles.append(np.array(image.pixels[:], dtype=np.float32).reshape(h, w, 4))
        bpy.data.images.remove(image)
        tile.unlink()
    h, w = tiles[0].shape[:2]
    rows = math.ceil(len(tiles) / columns)
    sheet = np.zeros((rows * h, columns * w, 4), dtype=np.float32)
    for i, tile in enumerate(tiles):
        r, c = divmod(i, columns)
        y0 = (rows - 1 - r) * h
        sheet[y0:y0 + h, c * w:(c + 1) * w] = tile
    out = bpy.data.images.new(path.stem, columns * w, rows * h, alpha=True)
    out.pixels = sheet.ravel()
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    return path


# --- bake for Studio -------------------------------------------------------------------------------------------------

def export(rig: Rig, path: Path, character: str, name: str, start: int, end: int, markers=(), legs=1.0, source="",
           extra=None):
    """Bakes the rig's joints frame by frame (start to end) to JSON for Author.SaveBaked: each pose is the Motor6D
    Transform's 12 CFrame components. Markers: (seconds, name). `extra` adds fields (a loop's Loop, Priority, ...)."""
    scene = bpy.context.scene
    fps = scene.render.fps
    frames = []
    for frame in range(start, end + 1):
        scene.frame_set(frame)
        poses = {part: [round(v, 5) for v in components(to_roblox(rig.joints[part].matrix_basis))] for part in PARTS}
        frames.append({"T": round((frame - start) / fps, 4), "Poses": poses})
    clip = {"Name": name, "Character": character, "Source": source, "Legs": legs, "Fps": fps, "Frames": frames,
            "Markers": [{"T": t, "Name": n} for t, n in markers], **(extra or {})}
    path.write_text(json.dumps(clip, separators=(",", ":")))
    return path


# --- the game's numbers ----------------------------------------------------------------------------------------------

def luau_number(relative: str, name: str) -> float:
    """The first `name = number` in a repo file."""
    text = (REPO / relative).read_text(encoding="utf-8")
    return float(re.search(rf"\b{re.escape(name)}\s*=\s*(-?[\d.]+)", text).group(1))


def luau_table(relative: str, anchor: str) -> dict:
    """The `name = number` fields of the Luau table that starts at the first line containing `anchor` in a repo file
    (one level of braces), so clips stay timed to the game's own definitions."""
    text = (REPO / relative).read_text(encoding="utf-8")
    start = text.index(anchor)
    depth, end = 0, start
    for i in range(text.index("{", start), len(text)):
        depth += {"{": 1, "}": -1}.get(text[i], 0)
        if depth == 0:
            end = i
            break
    return {k: float(v) for k, v in re.findall(r"(\w+)\s*=\s*(-?[\d.]+)", text[start:end])}
