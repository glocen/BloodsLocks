"""Gustave's weapon holds (WeaponHolds, docs/asset-requests.md; owner, 2026-10-31: "the way we hold the SMG while being
idle, walking and running is stupid, same for the sabre"): three R6 loops, GustaveIdle, GustaveWalk and GustaveSprint,
with the sabre in the right hand and the machine pistol in the left.

The reference is how the network-test study's hunter carries both weapons (docs/reference/network-test/animation.md §2):
never put away, low at the sides when standing and walking, trailing back and out when sprinting. Our poses are our own
(see each loop's notes below).

Both weapons stay in hand, welded as today (Simulation/Equipment). The sabre's blade runs along the right arm's front,
square to the arm, so the arm's roll chooses where the blade points; the pistol's barrel runs out of the left fist along
the forearm, so the arm points where the gun does. Holds give those directions and r6anim.aim solves the arm from them.

Speeds are Config.Movement's (WalkSpeed, SprintSpeed). A gait loop covers speed × its length in studs, and its feet stay
planted: a sole on the floor keeps its spot in the world while the body passes over it (r6anim.stand), the torso rides
on the stance leg (r6anim.sole) and rises and falls in the flight between steps. R6 legs have no knees, so a planted foot
can stay down only while its leg sweeps ±35°: ~0.13 s at WalkSpeed. The walk is therefore a light run, the sprint a dash.

Run: blender.exe -b --factory-startup --python tools/blender/holds_anim.py -- <out_dir> [poses|review|export|all]
         [weapons <folder>]
`weapons` names a folder holding saber.blend and smg.blend (as tools/blender/saber.py and smg.py write them), to review
with the real weapons; otherwise the rig's boxes stand in. Every run prints each loop's checks (contacts, floor
clearances); poses writes the pose sheet (holds_pose_sheet.png), review the cycles frame by frame
(holds_cycle_*.png), export Anim_GustaveIdle.txt, Anim_GustaveWalk.txt and Anim_GustaveSprint.txt for build/import.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from mathutils import Vector

import blcommon as bl
import r6anim as r6

MOVEMENT = "src/shared/Config/Movement.luau"
WALK_SPEED = r6.luau_number(MOVEMENT, "WalkSpeed")
SPRINT_SPEED = r6.luau_number(MOVEMENT, "SprintSpeed")
SOURCE = "tools/blender/holds_anim.py"

GUSTAVE = {"Torso": (0.07, 0.06, 0.08), "Right Arm": (0.07, 0.06, 0.08), "Left Arm": (0.07, 0.06, 0.08),
           "Right Leg": (0.035, 0.03, 0.04), "Left Leg": (0.035, 0.03, 0.04), "Head": (0.80, 0.68, 0.62),
           "Face": (0.12, 0.05, 0.06), "Steel": (0.42, 0.38, 0.34), "Blade": (0.05, 0.05, 0.06)}

# Weapon points in their grip frames (Roblox studs): the sabre's tip (saber.py's BladeTip) and the pistol's muzzle
# (tools/studio/Models/SMG.luau), for the floor checks.
SABRE_TIP = (0, 3.80, 0.28)
MUZZLE = (0, 0.42, -2.03)
LEGS = ("Right Leg", "Left Leg")


def D(right, up, forward) -> tuple:
    """A direction in the body's frame (right, up, forward), as a Roblox vector (forward is -Z). Every loop is staged
    facing -Z, so the body's frame is the world's."""
    v = Vector((right, up, -forward)).normalized()
    return (v.x, v.y, v.z)


# --- curves ----------------------------------------------------------------------------------------------------------

def periodic(keys):
    """A looping curve through (phase, value) keys, phase in 0..1, values numbers or tuples: a cardinal spline, so it
    passes through every key with no corner, and phase 1 meets phase 0."""
    keys = sorted(keys, key=lambda k: k[0])
    n = len(keys)
    phases = [k[0] for k in keys]
    values = [k[1] if isinstance(k[1], tuple) else (k[1],) for k in keys]
    scalar = not isinstance(keys[0][1], tuple)

    def key(i):  # key i, unwrapped past either end
        cycles, j = divmod(i, n)
        return phases[j] + cycles, values[j]

    def at(phase):
        phase %= 1.0
        i = max(j for j in range(-1, n) if key(j)[0] <= phase)
        (t0, p0), (t1, p1) = key(i), key(i + 1)
        (tm, pm), (t2, p2) = key(i - 1), key(i + 2)
        u = (phase - t0) / (t1 - t0)
        h00, h10, h01, h11 = 2 * u ** 3 - 3 * u ** 2 + 1, u ** 3 - 2 * u ** 2 + u, -2 * u ** 3 + 3 * u ** 2, u ** 3 - u ** 2
        out = []
        for c in range(len(p0)):
            m0 = (p1[c] - pm[c]) / (t1 - tm) * (t1 - t0)
            m1 = (p2[c] - p0[c]) / (t2 - t0) * (t1 - t0)
            out.append(h00 * p0[c] + h10 * m0 + h01 * p1[c] + h11 * m1)
        return out[0] if scalar else tuple(out)

    return at


def lerp(a, b, u):
    return a + (b - a) * u


# --- a loop ----------------------------------------------------------------------------------------------------------

class Loop:
    """One loop's timing: `seconds` long at `fps`, moving at `speed` studs/s, keyed from frame `start`. Its design is
    curves over the phase (0..1), passed to animate:
    - torso: (lean, twist, roll, shift right, shift forward, lift): degrees, then studs; lift rides on the height the
      feet give the body;
    - head: (pitch, turn, tilt) on the torso;
    - holds: per arm, a hold (axis, front, keep): world directions for r6anim.aim;
    - feet: per leg, its steps (the phases it lands and lifts, and where it lands: right of the middle and ahead of
      the root, studs) and, between steps, its swing (world pitch, swing out)."""

    def __init__(self, name, seconds, fps, speed, start):
        self.name, self.seconds, self.fps, self.speed, self.start = name, seconds, fps, speed, start
        self.count = round(seconds * fps)  # frames in the loop; frame `count` is frame 0 again

    def frame(self, phase):
        return self.start + round(phase * self.count)


def animate(rig: r6.Rig, loop: Loop, torso, head, holds, feet, rise=0.0):
    """Keys every frame of a loop (frame start .. start + count). Two passes: the first plants the feet and finds the
    height each stance asks of the torso, the second keys the torso at that height (and through each flight on an arc
    `rise` studs over the line between its take-off and landing), then the arms and head."""
    scene = bpy_scene()
    root_at = lambda f: Vector((0, r6.ROOT_HEIGHT, -loop.speed * (f - loop.start) / loop.fps))
    r6.place_root(rig, loop.start, root_at(loop.start), (0, 0, -1))
    r6.place_root(rig, loop.start + loop.count, root_at(loop.start + loop.count), (0, 0, -1))

    rolls = {}  # with both feet down, the roll that stands both soles at one height (solved below)

    def torso_pose(phase, height, f=None):
        """The torso's pose; leaning, it swings about the hips, which stay over the root (as r6anim.planted)."""
        lean, twist, roll, right, forward, lift = torso(phase)
        tilt = math.radians(lean)
        return (lean, twist, rolls.get(f, roll), right, height + lift - (1 - math.cos(tilt)),
                -forward - math.sin(tilt))

    # each leg's stance: where its sole is planted, in the world, for every frame it is down
    plants = {leg: {} for leg in LEGS}
    for leg in LEGS:
        for down, up, (right, ahead) in feet[leg]["steps"]:
            for cycle in (-1, 0, 1):  # a stance may wrap round the loop's ends
                f0 = loop.start + round((down + cycle) * loop.count)
                spot = root_at(f0) + Vector((right, -r6.ROOT_HEIGHT, -ahead))
                for f in range(f0, loop.start + round((up + cycle) * loop.count) + 1):
                    if loop.start <= f <= loop.start + loop.count:
                        plants[leg][f] = spot

    # pass 1: trunk and legs at height 0; the height each planted sole asks for (the floor is at y = 0)
    frames = list(range(loop.start, loop.start + loop.count + 1))
    need = {}
    legs_at = {}
    def trunk(f, phase, height):
        """Keys the torso and legs at frame f; returns the legs' poses."""
        lean, twist = torso(phase)[0], torso(phase)[1]
        r6.key(rig, f, {"Torso": torso_pose(phase, height, f)}, plant=False, interpolation="LINEAR")
        r6._refresh()
        poses = {}
        for leg in LEGS:
            if f in plants[leg]:
                poses[leg] = r6.stand(rig, leg, plants[leg][f], (lean, -twist, 0.0))
            else:
                pitch, out = feet[leg]["swing"](phase)
                poses[leg] = (pitch + lean, -twist, out)
        r6.key(rig, f, poses, plant=False, interpolation="LINEAR")
        r6._refresh()
        return poses

    for f in frames:
        phase = (f - loop.start) / loop.count
        if all(f in plants[leg] for leg in LEGS):
            # secant steps on the roll until both soles stand at one height
            roll = torso(phase)[2]
            gaps = []
            for r in (roll, roll + 0.5):
                rolls[f] = r
                trunk(f, phase, 0.0)
                gaps.append((r, r6.sole(rig, "Right Leg") - r6.sole(rig, "Left Leg")))
            for _ in range(6):
                (r0, g0), (r1, g1) = gaps[-2], gaps[-1]
                if abs(g1) < 1e-4 or abs(g1 - g0) < 1e-9:
                    break
                rolls[f] = r1 - g1 * (r1 - r0) / (g1 - g0)
                trunk(f, phase, 0.0)
                gaps.append((rolls[f], r6.sole(rig, "Right Leg") - r6.sole(rig, "Left Leg")))
            rolls[f] = gaps[-1][0] if abs(gaps[-1][1]) <= abs(gaps[-2][1]) else gaps[-2][0]
        legs_at[f] = trunk(f, phase, 0.0)
        down = [leg for leg in LEGS if f in plants[leg]]
        if down:
            need[f] = -min(r6.sole(rig, leg) for leg in down)

    # the height through each flight: an arc `rise` over the line between the heights at take-off and landing
    stances = sorted(need)

    def base(f):
        if f in need:
            return need[f]
        before = max((g for g in stances if g < f), default=stances[-1] - loop.count)  # the loop repeats
        after = min((g for g in stances if g > f), default=stances[0] + loop.count)
        h0 = need[before] if before in need else need[before + loop.count]
        h1 = need[after] if after in need else need[after - loop.count]
        u = (f - before) / (after - before)
        return lerp(h0, h1, u) + 4 * rise * u * (1 - u)

    height = {f: base(f) for f in frames}

    # pass 2: the torso at its height, the legs again (the shift and lift move the hips), then the arms and the head
    for f in frames:
        phase = (f - loop.start) / loop.count
        body = {"Torso": torso_pose(phase, height[f], f)}
        r6.key(rig, f, body, plant=False, interpolation="LINEAR")
        r6._refresh()
        lean, twist = torso(phase)[0], torso(phase)[1]
        poses = {}
        for leg in LEGS:
            if f in plants[leg]:
                poses[leg] = r6.stand(rig, leg, plants[leg][f], legs_at[f][leg])
            else:
                poses[leg] = legs_at[f][leg]
        r6.key(rig, f, poses, plant=False, interpolation="LINEAR")
        r6._refresh()
        arms = {}
        for arm, hold in holds.items():
            axis, front, keep = hold(phase)
            arms[arm] = r6.aim(rig, arm, front, axis=axis, keep=keep)
        arms["Head"] = head(phase)
        r6.key(rig, f, arms, plant=False, interpolation="LINEAR")
    return plants


def bpy_scene():
    import bpy
    return bpy.context.scene


def hold(keys, keep, lag=0.0):
    """A hold through (phase, axis, front) keys: directions eased round the loop. `lag` (phase) delays the front behind
    the axis: a blade that follows its arm's swing a beat late (follow-through)."""
    axis = periodic([(p, tuple(a)) for p, a, _ in keys])
    front = periodic([(p, tuple(f)) for p, _, f in keys])
    return lambda phase: (Vector(axis(phase)).normalized(), Vector(front(phase - lag)).normalized(), keep)


def run_feet(loop, down_frames, width, back, front):
    """Both legs of a run: the right lands at phase 0, the left at 0.5, each down for `down_frames` frames, landing
    `width` studs out from the middle and as far ahead of the hips as it lifts behind them, so at the loop's speed its
    leg sweeps ±theta while down.
    An R6 leg has no knee: swinging under the body it would scrape the floor while the other foot is down. So after
    its lift a leg kicks on `back` degrees (the push's follow-through) and stays back through the other foot's step,
    then whips through in the flight before its own landing, passing under the body at the top of the flight, reaches
    to `front` degrees and paws back down to land: a scissor at every landing."""
    reach = loop.speed * down_frames / loop.fps / 2
    theta = math.degrees(math.asin(reach / 2))
    s = down_frames / loop.count
    feet = {}
    for leg, c, side in (("Right Leg", 0.0, 1), ("Left Leg", 0.5, -1)):
        keys = [(c, theta), (c + s, -theta), (c + 0.25 + s / 2, -theta - back), (c + 0.5 + s, -theta - back * 0.6),
                (c + 0.75 + s / 2, 0.0), (c + 0.5 + s + 0.8 * (0.5 - s), front)]
        swing = periodic([(p % 1, (angle, 0.0)) for p, angle in keys])
        feet[leg] = {"steps": [(c, c + s, (side * width, reach))], "swing": swing}
    print(f"[gait] {loop.name}: {loop.speed:.0f} studs/s, {2 / loop.seconds:.2f} steps/s, "
          f"{loop.speed * loop.seconds / 2:.2f} studs a step, each foot down {down_frames / loop.fps:.3f} s, "
          f"legs ±{theta:.1f}° while down")
    return feet


# --- the loops' designs --------------------------------------------------------------------------------------------
# Filled in by the design pass below.


# The idle: "the gun leads, the sabre waits". A duelist at ease but never off guard: the left foot a half step ahead
# and the body turned a little onto it, chest up; the machine pistol angled down and out ahead of the left hip, its
# profile to the camera; the sabre held back by the right hip, its blade out and down behind, the point a hand over the
# floor. A slow breath lifts the chest and the point; the weight settles on the back foot.
def build_idle(start):
    loop = Loop("GustaveIdle", 3.2, 30, 0.0, start)
    # exhale at 0, inhale at 0.45 (the chest lifts, the weight eases forward), the slow glance at 0.7
    torso = periodic([(0.0, (-1.2, -6.0, 0.6, 0.05, -0.04, 0.0)), (0.45, (-3.0, -5.0, 0.9, 0.03, -0.02, 0.0)),
                      (0.7, (-2.2, -6.5, 0.7, 0.04, -0.03, 0.0))])
    head = periodic([(0.0, (1.5, 6.0, -1.0)), (0.45, (-0.5, 5.0, -0.5)), (0.7, (0.5, 9.5, -1.5))])
    # the sabre's point drifts in a slow small loop, a beat behind the breath; the gun hand settles with it
    sabre = hold([(0.0, D(-0.12, -1, 0.30), D(0.62, -0.42, -0.66)), (0.3, D(-0.12, -1, 0.28), D(0.66, -0.38, -0.64)),
                  (0.55, D(-0.12, -1, 0.27), D(0.62, -0.36, -0.70)), (0.8, D(-0.12, -1, 0.29), D(0.58, -0.40, -0.70))],
                 "front", lag=0.06)
    gun = hold([(0.0, D(-0.55, -1, 0.30), D(-0.75, 0.2, 0.6)), (0.45, D(-0.53, -1, 0.34), D(-0.72, 0.25, 0.6)),
                (0.7, D(-0.56, -1, 0.31), D(-0.75, 0.2, 0.6))], "axis", lag=0.04)
    feet = {"Right Leg": {"steps": [(0.0, 1.0, (0.72, -0.2))]}, "Left Leg": {"steps": [(0.0, 1.0, (-0.72, 0.25))]}}
    return loop, torso, head, {"Right Arm": sabre, "Left Arm": gun}, feet, 0.0


# The walk: a light, composed run at WalkSpeed. Upright with a small lean, the sabre trailing low out behind the right
# hip, rocking with the stride; the pistol angled out at the left side, swinging with its arm; the head steady.
def build_walk(start):
    loop = Loop("GustaveWalk", 32 / 60, 60, WALK_SPEED, start)
    torso = periodic([(0.0, (9.0, -3.0, -1.2, 0.04, 0.0, 0.0)), (0.25, (10.5, 0.0, 0.0, 0.0, 0.0, 0.0)),
                      (0.5, (9.0, 3.0, 1.2, -0.04, 0.0, 0.0)), (0.75, (10.5, 0.0, 0.0, 0.0, 0.0, 0.0))])
    head = periodic([(0.0, (-7.0, 3.0, 1.2)), (0.5, (-7.0, -3.0, -1.2))])
    sabre = hold([(0.04, D(0.20, -1, -0.10), D(0.62, -0.10, -0.80)),  # the blade swings out as the arm goes back...
                  (0.54, D(0.20, -1, 0.32), D(0.46, -0.33, -0.82))], "axis", lag=0.07)  # ...and in as it comes on
    gun = hold([(0.04, D(-0.42, -1, 0.50), D(-0.75, 0.2, 0.6)),
                (0.54, D(-0.50, -1, -0.15), D(-0.75, 0.2, 0.6))], "axis")
    feet = run_feet(loop, 7, 0.55, 8.0, 38.0)
    return loop, torso, head, {"Right Arm": sabre, "Left Arm": gun}, feet, 0.18


# The sprint: a dash at SprintSpeed. A deep lean; the sabre arm hangs from the leaning body with the blade streaming
# out behind, rocking up as the arm swings back; the pistol arm pumps hard like a runner's, the gun riding along it.
def build_sprint(start):
    loop = Loop("GustaveSprint", 0.4, 60, SPRINT_SPEED, start)
    torso = periodic([(0.0, (19.0, -4.0, -1.5, 0.05, 0.0, 0.0)), (0.25, (21.0, 0.0, 0.0, 0.0, 0.0, 0.0)),
                      (0.5, (19.0, 4.0, 1.5, -0.05, 0.0, 0.0)), (0.75, (21.0, 0.0, 0.0, 0.0, 0.0, 0.0))])
    head = periodic([(0.0, (-15.0, 4.0, 1.5)), (0.5, (-15.0, -4.0, -1.5))])
    sabre = hold([(0.04, D(0.36, -1, -0.22), D(0.58, 0.18, -0.80)),
                  (0.54, D(0.34, -1, 0.10), D(0.44, -0.05, -0.90))], "axis", lag=0.07)
    gun = hold([(0.04, D(-0.28, -1, 0.75), D(-0.75, 0.25, 0.6)),
                (0.54, D(-0.38, -1, -0.62), D(-0.75, 0.25, 0.6))], "axis")
    feet = run_feet(loop, 5, 0.55, 12.0, 46.0)
    return loop, torso, head, {"Right Arm": sabre, "Left Arm": gun}, feet, 0.28


def player_view(scene, rig: r6.Rig, frame: int, fov=40.0):
    """The game's camera (Config.Camera: 11 studs back, 1.4 right, FocusHeight 2.4, looking 10° down) closed in on
    the body: the same eye, turned onto the body's middle with a narrow lens, so the body is seen exactly as the player
    sees it, larger."""
    eye = r6.point_to_roblox(r6.player_camera(scene, rig, frame, name=f"Eye{frame}").location)
    root = r6.to_roblox(rig.root.matrix_world).to_translation()
    return r6.fixed_camera(scene, eye, root + Vector((0, -0.6, 0)), fov, f"Player{frame}")


# --- checks ----------------------------------------------------------------------------------------------------------

def grip_point(rig: r6.Rig, arm: str, local) -> Vector:
    frame = r6.to_roblox(rig.parts[arm].matrix_world) @ r6.cframe(r6._GRIP)
    return (frame @ Vector((*local, 1))).to_3d()


def checks(rig: r6.Rig, loop: Loop, plants):
    """Prints a loop's contacts: how far a planted sole's middle strays from its spot (studs), how far the planted
    soles sit above or sink below the floor, how low a swinging sole comes, how high the body flies (both feet up),
    and the sabre tip's and muzzle's lowest heights."""
    scene = bpy_scene()
    stray, high, sink, scuff, fly, tip, muzzle = 0.0, -9.0, 9.0, (9.0, ""), 0.0, 9.0, 9.0
    for f in range(loop.start, loop.start + loop.count + 1):
        scene.frame_set(f)
        soles = {leg: r6.sole(rig, leg) for leg in LEGS}
        for leg in LEGS:
            if f in plants[leg]:
                centre = r6.world_point(rig, leg, (0, -1, 0))
                stray = max(stray, Vector((centre.x - plants[leg][f].x, 0, centre.z - plants[leg][f].z)).length)
                high, sink = max(high, soles[leg]), min(sink, soles[leg])
            elif soles[leg] < scuff[0]:
                scuff = (soles[leg], f"{leg} at phase {(f - loop.start) / loop.count:.3f}")
        if not any(f in plants[leg] for leg in LEGS):
            fly = max(fly, min(soles.values()))
        tip = min(tip, grip_point(rig, "Right Arm", SABRE_TIP).y)
        muzzle = min(muzzle, grip_point(rig, "Left Arm", MUZZLE).y)
    print(f"[checks] {loop.name}: planted sole strays {stray:.4f}, sits {sink:+.3f}..{high:+.3f}; swinging sole "
          f">= {scuff[0]:+.3f} ({scuff[1]}); flies {fly:.2f}; sabre tip >= {tip:.2f}, muzzle >= {muzzle:.2f}")


# --- main ------------------------------------------------------------------------------------------------------------

def main():
    import bpy
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 1:]
    mode = args[1] if len(args) > 1 else "all"
    weapons = Path(args[args.index("weapons") + 1]) if "weapons" in args else None
    meshes = weapons is not None and all((weapons / blend).exists() for blend, _ in r6.WEAPON_MESHES.values())
    scene = bl.reset_scene()
    r6.stage(scene, 30)
    rig = r6.build_rig("Gustave", GUSTAVE, weapons=not meshes)
    if meshes:
        r6.weapon_meshes(rig, weapons)

    idle = build_idle(0)
    walk = build_walk(idle[0].start + idle[0].count + 30)
    sprint = build_sprint(walk[0].start + walk[0].count + 30)
    for loop, torso, head, holds, feet, rise in (idle, walk, sprint):
        scene.render.fps = loop.fps
        checks(rig, loop, animate(rig, loop, torso, head, holds, feet, rise))

    if mode in ("poses", "all"):
        # the pose sheet: a column per key moment, rows alternating the player's camera and a side view
        scene.render.resolution_x, scene.render.resolution_y = 520, 600
        i = idle[0]
        idle_views = [(player_view(scene, rig, i.frame(0), 42), "Idle | player cam"),
                      (r6.body_camera(scene, rig, i.frame(0), 35, name="IdleFront"), "Idle | front"),
                      (r6.body_camera(scene, rig, i.frame(0), 90, name="IdleSide"), "Idle | side"),
                      (r6.body_camera(scene, rig, i.frame(0), 140, name="IdleBack"), "Idle | back right")]
        shots = []
        for row, (loop, gait) in enumerate(((walk[0], walk[4]), (sprint[0], sprint[4]))):
            lift = gait["Right Leg"]["steps"][0][1]
            moments = ((0.0, "R foot lands"), (lift, "push-off"), (0.25 + lift / 2, "flight"), (0.5, "L foot lands"))
            for view in ("player", "side"):
                camera, label = idle_views[2 * row + (view == "side")]
                shots.append((camera, i.frame(0), label))
                for phase, moment in moments:
                    f = loop.frame(phase)
                    camera = (player_view(scene, rig, f, 42) if view == "player"
                              else r6.body_camera(scene, rig, f, 90, name=f"S{f}"))
                    shots.append((camera, f, f"{loop.name[7:]}: {moment} | {view}"))
        r6.render_shots(scene, shots, out / "holds_pose_sheet.png", columns=5)

    if mode in ("review", "all"):
        # the cycles frame by frame (every other frame), from the side and from the player's camera
        scene.render.resolution_x, scene.render.resolution_y = 360, 420
        for loop, step in ((walk[0], 2), (sprint[0], 2)):
            frames = range(loop.start, loop.start + loop.count, step)
            shots = [(r6.body_camera(scene, rig, f, 90, name=f"RS{f}"), f, f"{(f - loop.start) / loop.count:.3f}")
                     for f in frames]
            r6.render_shots(scene, shots, out / f"holds_cycle_{loop.name[7:].lower()}_side.png", columns=8)
            shots = [(player_view(scene, rig, f, 44), f, f"{(f - loop.start) / loop.count:.3f}") for f in frames]
            r6.render_shots(scene, shots, out / f"holds_cycle_{loop.name[7:].lower()}_player.png", columns=8)
        loop = idle[0]
        frames = range(loop.start, loop.start + loop.count, loop.count // 8)
        shots = [(r6.body_camera(scene, rig, f, 35, name=f"RI{f}"), f, f"{(f - loop.start) / loop.fps:.2f} s")
                 for f in frames]
        r6.render_shots(scene, shots, out / "holds_cycle_idle_front.png", columns=8)

    if mode in ("export", "all"):
        # loops for Author.SaveBaked: Loop and Priority to set on the KeyframeSequence, the speed each was planted for
        # (play a gait at actual speed / Speed), and the footfalls for steps and dust
        for loop, *_ in (idle, walk, sprint):
            scene.render.fps = loop.fps
            markers = [(0.0, "FootR"), (loop.seconds / 2, "FootL")] if loop.speed else []
            extra = {"Loop": True, "Priority": "Movement" if loop.speed else "Idle", "Speed": loop.speed,
                     "StudsPerLoop": round(loop.speed * loop.seconds, 3)}
            path = r6.export(rig, out / f"Anim_{loop.name}.txt", "Gustave", loop.name, loop.start,
                             loop.start + loop.count, markers, source=SOURCE, extra=extra)
            print(f"[export] {path.name}: {loop.count + 1} poses over {loop.seconds:.3f} s at {loop.fps} fps")
    bl.save_blend(out / "holds_anim.blend")


main()
