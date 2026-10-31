"""The bite's animations (owner, 2026-10-31: "it gotta be a bit long, both characters can't move ... make it perfect";
"do the animation in Blender"; "the character who got caught should be down on his knee, then grabbed, and the bite
starts"): any body's stagger (Staggered), Gustave's lunge (Bite) and hold (BiteHold), and the victim's (Bitten).

The body language follows the network-test study: the staggered foe slumps down, head bowed (the manual, 9:34); the bite
seizes it, it arches back, is drained, then thrown off and falls (docs/reference/network-test/vfx.md). Our own poses,
and no blood, ever. Roblox's rules ban romantic gestures, so this is staged as a hostile attack, never an embrace: the
gun hand seizes it by the side, the sabre arm stays out to the side, the victim claws at the gripping arm, each drain pulse
is a convulsion, the release is a throw.

Timed to the game: the hold's definition (src/shared/Definitions/Common.luau), the knockdown and the stagger (Config/
Combat). The bodies are staged as in the game: the victim pulled to the hold's distance and thrown back at the release,
turned to the biter's left (physics pushes in the game; here they only stage the review).

Run: blender.exe -b --factory-startup --python tools/blender/bite_anim.py -- <out_dir> [review|export|all]
Writes contact sheets (review) and Anim_Staggered.txt, Anim_Bite.txt, Anim_BiteHold.txt and Anim_Bitten.txt (export);
the .txt files go to build/import for Author.SaveBaked.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from mathutils import Vector

import blcommon as bl
import r6anim as r6

FPS = 30
COMMON, COMBAT = "src/shared/Definitions/Common.luau", "src/shared/Config/Combat.luau"
HOLD = r6.luau_table(COMMON, '["Common.BiteHold"] = {')
LUNGE = r6.luau_table(COMMON, "Lunge = {")  # the bite's (the first lunge in the file)
LUNGE["Duration"] = r6.luau_table(COMMON, '["Common.Bite"] = {')["Duration"]
BITE_HIT = r6.luau_table(COMMON, "Hit = {")  # the bite's hit window (the first hit in the file)
KNOCKDOWN = r6.luau_table(COMBAT, "Hitstun = {")["Knockdown"]
STAGGER = r6.luau_number(COMBAT, "StaggerDuration")
SOURCE = "tools/blender/bite_anim.py"

BITER = {"Torso": (0.07, 0.06, 0.08), "Right Arm": (0.07, 0.06, 0.08), "Left Arm": (0.07, 0.06, 0.08),
         "Right Leg": (0.035, 0.03, 0.04), "Left Leg": (0.035, 0.03, 0.04), "Head": (0.80, 0.68, 0.62),
         "Face": (0.12, 0.05, 0.06), "Steel": (0.42, 0.38, 0.34), "Blade": (0.05, 0.05, 0.06)}
VICTIM = {"Torso": (0.62, 0.60, 0.68), "Right Arm": (0.55, 0.53, 0.62), "Left Arm": (0.55, 0.53, 0.62),
          "Right Leg": (0.24, 0.24, 0.32), "Left Leg": (0.24, 0.24, 0.32), "Head": (0.82, 0.74, 0.70),
          "Face": (0.12, 0.05, 0.06)}

IDLE = {"Torso": (4, 0, 0), "Head": (-3, 0, 0), "Right Arm": (16, -5, 9), "Left Arm": (10, 5, -9),
        "Right Leg": (-4, 0, 3), "Left Leg": (4, 0, -3)}  # Gustave's stance (Animations/Gustave)
NEUTRAL = {"Torso": (0, 0, 0), "Head": (0, 0, 0), "Right Arm": (0, 0, 4), "Left Arm": (0, 0, -4),
           "Right Leg": (0, 0, 2), "Left Leg": (0, 0, -2)}  # any body's own stance
# Down on one knee, slumped, head bowed, arms hanging: the stagger's hold, where a bite finds its victim.
KNEEL = {"Torso": (28, 0, 0, 0, -1.0, 0), "Head": (22, 0, 0), "Right Arm": (18, 0, 10), "Left Arm": (26, 0, -12),
         "Right Leg": (-58, 0, 4), "Left Leg": (58, 0, -4)}
# The lunge's far point, where a bite that takes hold hands over to the hold (both clips share it): the gun hand
# leads to seize, the sabre arm swings out of the way.
REACH = {"Torso": (18, -6, 0, 0, 0, -0.1), "Head": (8, 4, 0), "Left Arm": (84, 0, -6), "Right Arm": (30, -10, 34),
         "Right Leg": (-12, 0, 5), "Left Leg": (16, 0, -4)}
STANCE = {"Right Leg": (-12, 0, 5), "Left Leg": (14, 0, -4)}  # the biter's feet through the hold

# Contact points, in each part's own frame (Roblox studs).
MOUTH = (0, -0.2, -0.5)  # the biter's head
NECK = (-0.45, -0.6, -0.1)  # the victim's head: the left side of its neck (the side the player's camera sees)
HAND = (0, -1, 0)  # an arm's end
GRIP = (0.95, 0.35, -0.3)  # the victim's torso: its right side below the shoulder, where the gun hand seizes it
# (the pistol is mounted along the forearm, so the arm points where its barrel goes: forward-down past the flank)
UPPER_ARM = (0, 0.4, 0)  # the biter's gun arm near the shoulder, which the victim claws at
CHIN = (0, 1.3, -0.5)  # the biter's torso: where its mouth sits with the head straight


def frame(seconds: float, start: int = 0) -> int:
    return start + round(seconds * FPS)


def heave(pose: dict, amount: float) -> dict:
    """A breath or a pulse through a pose: the torso and head rise a little."""
    out = dict(pose)
    t = list(out["Torso"]) + [0] * (6 - len(out["Torso"]))
    out["Torso"] = (t[0] + 3 * amount, t[1], t[2], t[3], t[4] + 0.05 * amount, t[5])
    h = out["Head"]
    out["Head"] = (h[0] + 3 * amount, h[1], h[2])
    return out


def animate_stagger(body: r6.Rig, start: int):
    """Staggered: the blow rocks it back, it buckles onto one knee and slumps there, heaving for breath. Long enough for
    the longest stagger; the game stops it when the stagger ends (or a bite takes it)."""
    k = lambda t, pose, i="BEZIER", e="AUTO": r6.key(body, frame(t, start), pose, True, i, e)
    k(0, NEUTRAL, "EXPO", "EASE_OUT")
    k(0.06, {"Torso": (-10, 0, 0), "Head": (-16, 0, 0), "Right Arm": (-14, 0, 22), "Left Arm": (-14, 0, -22),
             "Right Leg": (-4, 0, 4), "Left Leg": (6, 0, -4)})
    k(0.18, {"Torso": (14, 0, 0, 0, -0.45, 0), "Head": (10, 0, 0), "Right Arm": (8, 0, 18), "Left Arm": (8, 0, -18),
             "Right Leg": (-30, 0, 4), "Left Leg": (26, 0, -4)}, "BACK", "EASE_OUT")
    k(0.32, {**KNEEL, "Torso": (32, 0, 0, 0, -1.1, 0), "Head": (26, 0, 0)})
    k(0.45, KNEEL, "SINE", "EASE_IN_OUT")
    t = 0.45
    while t < STAGGER + 0.6:
        k(t + 0.3, heave(KNEEL, 1), "SINE", "EASE_IN_OUT")
        k(t + 0.6, KNEEL, "SINE", "EASE_IN_OUT")
        t += 0.6


def drink(draw: float, deepen: float) -> dict:
    """The biter at the neck: leaning in from the victim's left, the gun hand gripping its side, the sabre held low and
    back, out of the way. `draw` (0..1) is a drain pulse (the shoulders heave, the sabre arm tenses); `deepen` (0..1) how far in."""
    return {"Torso": (21 + 1.5 * draw + 1.5 * deepen, 9, 7, 0.32, 0.04 * draw, -0.3), "Head": (20, 18, 8),
            "Left Arm": (80, 0, -2), "Right Arm": (-15, -20, 25 + 4 * draw), **STANCE}


def held(sag: float, twitch: float) -> dict:
    """The victim in the bite: arched back, head thrown back and turned from the bite, the right hand clawing at the gun
    arm, the left arm flung out. `sag` (0..1): the drain draws it down; `twitch` (0..1): a pulse convulses it."""
    return {"Torso": (-15 + 4 * sag - 3 * twitch, -9, 4, 0, 0, 0.04), "Head": (-32 - 8 * sag - 4 * twitch, -22, 12),
            "Right Arm": (70 - 20 * sag, 0, 10), "Left Arm": (-10 + 16 * sag, 0, -86 + 30 * sag - 8 * twitch),
            "Right Leg": (0, 0, 4), "Left Leg": (4, 0, -6)}


def animate_hold(biter: r6.Rig, victim: r6.Rig, start: int):
    """BiteHold on the biter and Bitten on the victim, from the seize at `start`. At each beat the victim is keyed
    first, then the biter reaches for it (its gun hand on the victim's side, its mouth on the neck), then the victim's right
    hand claws at the biter's arm."""
    fangs, release = HOLD["Fangs"], HOLD["Release"]
    first, every, pulses = HOLD["FirstPulse"], HOLD["PulseEvery"], int(HOLD["Pulses"])

    def beat(t, victim_pose, biter_pose, i="BEZIER", e="AUTO", seize=True, bite=False, claw=False):
        f = frame(t, start)
        victim_pose = dict(victim_pose)
        claw_hint = victim_pose.pop("Right Arm") if claw else None
        r6.key(victim, f, victim_pose, True, i, e)
        contacts = {}
        if seize:
            contacts["Left Arm"] = (HAND, r6.world_point(victim, "Torso", GRIP))
        if bite:
            neck = r6.world_point(victim, "Head", NECK)
            contacts["Torso"] = (CHIN, neck)
            contacts["Head"] = (MOUTH, neck)
        r6.key(biter, f, biter_pose, True, i, e, contacts)
        if claw:
            r6.key(victim, f, {"Right Arm": claw_hint}, False, i, e,
                   {"Right Arm": (HAND, r6.world_point(biter, "Left Arm", UPPER_ARM))})

    beat(0, KNEEL, REACH, seize=False)
    beat(0.10, {"Torso": (20, 6, 0, 0, -0.55, 0), "Head": (-10, 0, 0), "Right Arm": (40, 0, 20), "Left Arm": (30, 0, -30),
                "Right Leg": (-30, 0, 4), "Left Leg": (30, 0, -4)},
         {"Torso": (22, -8, 0, 0, 0, -0.15), "Head": (14, 6, 0), "Left Arm": (70, 0, -4), "Right Arm": (-10, -16, 22), **STANCE},
         "QUART", "EASE_OUT")
    beat(0.28, {"Torso": (-12, -8, 3, 0, 0, 0.04), "Head": (-28, -18, 10), "Right Arm": (70, 0, 10), "Left Arm": (-8, 0, -78),
                "Right Leg": (0, 0, 4), "Left Leg": (4, 0, -6)},
         {"Torso": (6, -4, 0, 0.1, 0, 0), "Head": (-12, 10, 4), "Left Arm": (85, 0, 0), "Right Arm": (-14, -20, 24), **STANCE},
         "QUART", "EASE_IN", claw=True)
    beat(fangs - 0.1, held(0, 0), {**drink(0, 0), "Torso": (20, 8, 6, 0.3, 0, -0.25)}, "BACK", "EASE_OUT",
         bite=True, claw=True)
    beat(fangs, held(0, 1), {**drink(1, 0), "Torso": (23, 9, 7, 0.32, 0, -0.3), "Right Arm": (-22, -20, 34)},
         bite=True, claw=True)
    beat(fangs + 0.15, held(0, 0), drink(0, 0), bite=True, claw=True)
    for pulse in range(pulses):
        at = first + pulse * every
        deepen = (pulse + 1) / pulses
        beat(at, held(deepen, 1), drink(1, deepen), "SINE", "EASE_IN_OUT", bite=True, claw=True)
        beat(at + 0.13, held(deepen, 0), drink(0, deepen), "SINE", "EASE_IN_OUT", bite=True, claw=True)
    beat(release - 0.2, {"Torso": (-10, -6, 3), "Head": (-20, -12, 6), "Right Arm": (40, 0, 14), "Left Arm": (6, 0, -50),
                         "Right Leg": (0, 0, 4), "Left Leg": (4, 0, -6)},
         {"Torso": (12, 4, 3, 0.15, 0, -0.15), "Head": (2, 10, 2), "Left Arm": (80, 0, -2), "Right Arm": (-12, -20, 24), **STANCE},
         "QUART", "EASE_IN")
    beat(release, {"Torso": (-28, 10, -2), "Head": (18, 8, 0), "Right Arm": (48, 0, 36), "Left Arm": (44, 0, -40),
                   "Right Leg": (24, 0, 4), "Left Leg": (-8, 0, -4)},
         {"Torso": (8, -25, -2, 0, 0, -0.1), "Head": (-10, 12, 0), "Left Arm": (100, 0, -35), "Right Arm": (-30, -10, 30),
          "Right Leg": (-22, 0, 5), "Left Leg": (16, 0, -4)}, "BACK", "EASE_OUT", seize=False)
    beat(release + 0.13, {"Torso": (-18, 12, -4), "Head": (-6, 6, 0), "Right Arm": (24, 0, 56), "Left Arm": (30, 0, -48),
                          "Right Leg": (-24, 0, 6), "Left Leg": (18, 0, -4)},
         {"Torso": (2, -32, 0), "Head": (-6, 28, 0), "Left Arm": (80, 0, -45), "Right Arm": (-18, -8, 26),
          "Right Leg": (-16, 0, 5), "Left Leg": (12, 0, -4)}, seize=False)
    beat(release + 0.27, {"Torso": (8, 4, 0, 0, -0.4, 0), "Head": (4, 0, 0), "Right Arm": (20, 0, 30), "Left Arm": (14, 0, -30),
                          "Right Leg": (-30, 0, 4), "Left Leg": (30, 0, -4)},
         {"Torso": (2, -10, 0), "Head": (-4, 8, 0), "Left Arm": (22, 4, -16), "Right Arm": (20, -4, 16),
          "Right Leg": (-6, 0, 3), "Left Leg": (6, 0, -3)}, seize=False)
    r6.key(biter, frame(HOLD["Duration"], start), IDLE)
    r6.key(victim, frame(release + 0.45, start), {**KNEEL, "Torso": (32, 0, 0, 0, -1.1, 0)}, True, "BACK", "EASE_OUT")
    r6.key(victim, frame(release + 0.65, start), KNEEL)
    r6.key(victim, frame(release + KNOCKDOWN, start), NEUTRAL)


def stage_hold(biter: r6.Rig, victim: r6.Rig, start: int):
    """Where the two roots are (review only): the victim pulled from the lunge's reach to the hold's distance, then thrown
    back, turned to the biter's left."""
    reach = LUNGE["Speed"] * (LUNGE["To"] - LUNGE["From"]) + 0.6  # where a bite at the lunge's far edge finds it
    r6.place_root(biter, start, (0, r6.ROOT_HEIGHT, 0), (0, 0, -1))
    r6.place_root(victim, start, (0, r6.ROOT_HEIGHT, -reach), (0, 0, 1))
    r6.place_root(victim, frame(HOLD["Pull"], start), (0, r6.ROOT_HEIGHT, -HOLD["Distance"]), (0, 0, 1))
    r6.place_root(victim, frame(HOLD["Release"], start), (0, r6.ROOT_HEIGHT, -HOLD["Distance"]), (0, 0, 1))
    turn = math.radians(HOLD["ThrowTurn"])
    away = Vector((-math.sin(turn), 0, -math.cos(turn)))
    thrown = Vector((0, r6.ROOT_HEIGHT, -HOLD["Distance"])) + away * HOLD["Throw"]
    r6.place_root(victim, frame(HOLD["Release"] + 0.15, start), thrown, (0, 0, 1))
    r6.place_root(victim, frame(HOLD["Release"] + KNOCKDOWN, start), thrown, (0, 0, 1))  # down where it landed


def animate_lunge(biter: r6.Rig, start: int):
    """Bite: a coil, a spring forward with the gun hand reaching to seize, a snap of the jaws at the far point, the
    recovery."""
    k = lambda t, pose, i="BEZIER", e="AUTO": r6.key(biter, frame(t, start), pose, True, i, e)
    k(0, {"Torso": (-4, 6, 0, 0, 0, 0.05), "Head": (-10, -4, 0), "Right Arm": (20, -4, 24), "Left Arm": (24, 4, -24),
          "Right Leg": (-8, 0, 4), "Left Leg": (10, 0, -4)}, "EXPO", "EASE_OUT")
    k(0.05, {"Torso": (14, -2, 0), "Head": (4, 2, 0), "Left Arm": (60, 4, -10), "Right Arm": (26, -8, 30),
             "Right Leg": (-16, 0, 4), "Left Leg": (18, 0, -4)})
    k(0.10, REACH)
    k(0.17, {"Torso": (26, -4, 0, 0, 0, -0.15), "Head": (24, 4, 0), "Left Arm": (88, 0, -2), "Right Arm": (32, -12, 36),
             "Right Leg": (-14, 0, 5), "Left Leg": (16, 0, -4)}, "BACK", "EASE_OUT")
    k(0.23, {"Torso": (22, -4, 0, 0, 0, -0.1), "Head": (12, 2, 0), "Left Arm": (78, 4, -6), "Right Arm": (30, -10, 32),
             "Right Leg": (-12, 0, 5), "Left Leg": (14, 0, -4)})
    k(0.40, {"Torso": (10, -2, 0), "Head": (-4, 2, 0), "Left Arm": (34, 4, -14), "Right Arm": (26, -4, 20),
             "Right Leg": (-6, 0, 3), "Left Leg": (6, 0, -3)})
    k(0.56, {"Torso": (6, -2, 0), "Head": (-3, 2, 0), "Left Arm": (16, 4, -11), "Right Arm": (20, -4, 12)})
    k(LUNGE["Duration"], IDLE)


def stage_still(rig: r6.Rig, start: int, position, facing):
    r6.place_root(rig, start, position, facing)


def stage_lunge(biter: r6.Rig, start: int):
    r6.place_root(biter, start, (0, r6.ROOT_HEIGHT, 0), (0, 0, -1))
    r6.place_root(biter, frame(LUNGE["From"], start), (0, r6.ROOT_HEIGHT, 0), (0, 0, -1))
    travel = LUNGE["Speed"] * (LUNGE["To"] - LUNGE["From"])
    r6.place_root(biter, frame(LUNGE["To"], start), (0, r6.ROOT_HEIGHT, -travel), (0, 0, -1))


def contacts(biter: r6.Rig, victim: r6.Rig, scene, start: int):
    """How well the hold's contacts land, between keys too: mouth on neck, gun hand on its side, the victim's hand on the
    gun arm, feet on the floor."""
    for t in (0.1, 0.28, 0.45, 0.55, 0.7, 1.0, 1.3, 1.6, 2.15):
        scene.frame_set(frame(t, start))
        mouth = (r6.world_point(biter, "Head", MOUTH) - r6.world_point(victim, "Head", NECK)).length
        grip = (r6.world_point(biter, "Left Arm", HAND) - r6.world_point(victim, "Torso", GRIP)).length
        claw = (r6.world_point(victim, "Right Arm", HAND) - r6.world_point(biter, "Left Arm", UPPER_ARM)).length
        floor = [r6._lowest_foot(rig) - r6._floor(rig) for rig in (biter, victim)]
        gap = (r6.world_point(biter, "Torso", (0, 0, -0.5)) - r6.world_point(victim, "Torso", (0, 0, -0.5))).length
        print(f"[contacts] t={t:.2f}  mouth-neck {mouth:.2f}  hand-grip {grip:.2f}  claw {claw:.2f}"
              f"  chest gap {gap:.2f}  feet {floor[0]:+.2f} {floor[1]:+.2f}")


def main():
    out = bl.out_dir()
    args = sys.argv[sys.argv.index("--") + 1:]
    mode = args[1] if len(args) > 1 else "all"
    scene = bl.reset_scene()
    r6.stage(scene, FPS)
    biter = r6.build_rig("Gustave", BITER, weapons=True)
    victim = r6.build_rig("Victim", VICTIM)

    hold_start, hold_end = 0, frame(HOLD["Release"] + KNOCKDOWN)
    lunge_start = hold_end + 30  # each clip has its own stretch of the timeline
    stagger_start = lunge_start + frame(LUNGE["Duration"]) + 30
    stagger_end = stagger_start + frame(STAGGER + 0.6)
    stage_hold(biter, victim, hold_start)
    animate_hold(biter, victim, hold_start)
    stage_lunge(biter, lunge_start)
    animate_lunge(biter, lunge_start)
    stage_still(victim, stagger_start, (0, r6.ROOT_HEIGHT, -14), (0, 0, 1))  # clear of the biter
    animate_stagger(victim, stagger_start)
    contacts(biter, victim, scene, hold_start)

    if mode in ("review", "all"):
        scene.frame_start = hold_start
        beats = [0, 0.1, 0.28, 0.45, 0.55, 0.7, 1.3, 2.15, 2.35, 2.48, 2.8, 3.1]
        frames = [frame(t, hold_start) for t in beats]
        side = r6.fixed_camera(scene, (7.5, 4.6, -1.0), (0.3, 3.9, -1.0), 38, "Side")
        player = r6.player_camera(scene, biter, hold_start, fov=62, yaw=40, distance=9, name="Player")
        r6.render_sheet(scene, side, frames, out / "bite_hold_side.png", columns=4)
        r6.render_sheet(scene, player, frames, out / "bite_hold_player.png", columns=4)
        gun = r6.fixed_camera(scene, (-3.5, 8.5, 2.5), (-0.4, 4.2, -0.9), 45, "GunCheck")
        r6.render_sheet(scene, gun, [frame(t, hold_start) for t in (0.1, 0.7, 1.3, 2.15)], out / "bite_gun_check.png", columns=4)
        scene.frame_start = stagger_start
        stagger = [frame(t, stagger_start) for t in (0, 0.06, 0.18, 0.32, 0.45, 0.75, 1.05, 1.6)]
        r6.render_sheet(scene, r6.fixed_camera(scene, (6.0, 4.2, -11.0), (0, 2.4, -14), 40, "StaggerSide"), stagger,
                        out / "stagger_side.png", columns=4)
        scene.frame_start = lunge_start
        lunge = [frame(t, lunge_start) for t in (0, 0.05, 0.1, 0.17, 0.23, 0.4, 0.56, 0.75)]
        r6.render_sheet(scene, r6.fixed_camera(scene, (8, 4.2, 0.5), (0, 3.4, -1.5), 40, "LungeSide"), lunge,
                        out / "bite_lunge_side.png", columns=4)

    if mode in ("export", "all"):
        markers = [(HOLD["Fangs"], "Fangs"), (HOLD["Release"], "Release")]
        r6.export(biter, out / "Anim_BiteHold.txt", "Gustave", "BiteHold", hold_start,
                  frame(HOLD["Duration"], hold_start), markers, source=SOURCE)
        r6.export(victim, out / "Anim_Bitten.txt", "Common", "Bitten", hold_start, hold_end, markers, source=SOURCE)
        r6.export(biter, out / "Anim_Bite.txt", "Gustave", "Bite", lunge_start, frame(LUNGE["Duration"], lunge_start),
                  [(BITE_HIT["From"], "BiteImpact"), (BITE_HIT["To"], "BiteWindowClose")], source=SOURCE)
        r6.export(victim, out / "Anim_Staggered.txt", "Common", "Staggered", stagger_start, stagger_end, source=SOURCE)
    bl.save_blend(out / "bite_anim.blend")


main()
