"""Draws the BloodsLocks VFX textures as PNGs (pure standard library, no dependencies).

Run:  py tools/vfx_textures.py [out_dir]   ->  writes assets/vfx/*.png (or into out_dir)

Every texture is drawn from math so it can be retuned and redrawn at any time. Upload the PNGs to Roblox and put
the asset ids in Client.Vfx.Kit.Textures.
"""

import math
import os
import random
import struct
import sys
import zlib

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "vfx"))


# --- helpers -------------------------------------------------------------------------------------------------

def write_png(path, width, height, pixels):
    """pixels: function (x, y) -> (r, g, b, a) floats in 0..1."""
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            r, g, b, a = pixels(x, y)
            rows.extend(int(max(0.0, min(1.0, c)) * 255 + 0.5) for c in (r, g, b, a))

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(rows), 9))
    png += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)
    print("wrote", os.path.relpath(path))


def clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def smoothstep(a, b, v):
    t = clamp((v - a) / (b - a))
    return t * t * (3 - 2 * t)


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(lerp(a, b, t) for a, b in zip(c1, c2))


def gauss(v, sigma):
    return math.exp(-(v / sigma) ** 2)


def rgb(r, g, b):
    return (r / 255, g / 255, b / 255)


# --- blood crescent ------------------------------------------------------------------------------------------
# A moon-slash of liquid blood, convex edge up, needle tips at the left and right. The region inside the outer
# circle and outside a much larger inner circle, so the band is thickest at the apex and tapers to points. The
# inner edge ripples like liquid. Shading runs from a hot crimson rim with a wet highlight, through a dark wet
# body, to near-black at the inner edge, with flow streaks along the arc.

CRESCENT_W, CRESCENT_H = 512, 192
OUTER_C, OUTER_R = (256.0, 312.0), 290.0  # apex at y=22
INNER_C, INNER_R = (256.0, 703.0), 603.0  # apex at y=100, meets the outer arc near the image edges

HOT = rgb(255, 92, 92)
RIM = rgb(222, 24, 44)
WET = rgb(118, 0, 16)
DARK = rgb(32, 0, 5)
GLOSS = rgb(255, 190, 190)

random.seed(7)
STREAKS = [(random.uniform(0, math.tau), random.uniform(5, 11)) for _ in range(4)]
RIPPLES = [(random.uniform(0, math.tau), random.uniform(22, 48), random.uniform(0.4, 1.1)) for _ in range(3)]


def crescent_shape(x, y):
    """Returns (alpha, t across the band 0=outer 1=inner, thickness px, arc angle)."""
    dx1, dy1 = x - OUTER_C[0], y - OUTER_C[1]
    dx2, dy2 = x - INNER_C[0], y - INNER_C[1]
    angle = math.atan2(dx1, -dy1)  # 0 at the apex
    ripple = sum(amp * math.sin(angle * freq + phase) for phase, freq, amp in RIPPLES)
    d_outer = OUTER_R - math.hypot(dx1, dy1)  # >0 inside the outer circle
    d_inner = math.hypot(dx2, dy2) - INNER_R + ripple  # >0 outside the (rippled) inner circle
    thickness = max(d_outer + d_inner, 1e-3)
    t = clamp(d_outer / thickness)
    edge = min(d_outer, d_inner)
    alpha = smoothstep(-0.8, 1.2, edge) * smoothstep(1.0, 14.0, thickness)
    return alpha, t, thickness, angle


def blood_crescent(x, y):
    alpha, t, thickness, angle = crescent_shape(x, y)
    if alpha <= 0:
        return (0, 0, 0, 0)
    # rim → body → dark
    if t < 0.07:
        color = mix(HOT, RIM, t / 0.07)
    elif t < 0.3:
        color = mix(RIM, WET, (t - 0.07) / 0.23)
    else:
        color = mix(WET, DARK, smoothstep(0.3, 0.85, t))
    # flow streaks running along the arc
    flow = 0.0
    for phase, freq in STREAKS:
        flow += math.sin((t + 0.06 * math.sin(angle * freq + phase)) * 34 + phase)
    shade = 1 + 0.07 * flow / len(STREAKS)
    color = tuple(c * shade for c in color)
    # wet highlight just inside the rim, broken up along the arc
    gloss = gauss(t - 0.12, 0.03) * (0.55 + 0.45 * math.sin(angle * 9 + 1.3)) * 0.75
    color = mix(color, GLOSS, clamp(gloss))
    # the tips burn hotter as they thin out
    tip = 1 - smoothstep(4, 30, thickness)
    color = mix(color, RIM, tip * 0.7)
    return (*color, alpha)


def blood_glow(x, y):
    """Soft halo hugging the outer rim, fading toward the tips. White (tinted in Roblox)."""
    dx1, dy1 = x - OUTER_C[0], y - OUTER_C[1]
    d = math.hypot(dx1, dy1) - OUTER_R  # 0 on the rim, >0 outside
    angle = abs(math.atan2(dx1, -dy1))
    span = 1 - smoothstep(0.45, 1.0, angle)
    a = (gauss(d, 9) * 0.9 + gauss(d, 26) * 0.4) * span
    return (1, 1, 1, clamp(a))


def preview(path, width, height, pixels, background=(0.12, 0.08, 0.12)):
    """The texture composited over a dark background, for judging white/alpha art by eye."""
    def over(x, y):
        r, g, b, a = pixels(x, y)
        return (lerp(background[0], r, a), lerp(background[1], g, a), lerp(background[2], b, a), 1)
    write_png(path, width, height, over)


# --- beams ---------------------------------------------------------------------------------------------------
# Drawn with u along x and v across y, then written transposed: Roblox runs a beam texture's vertical axis along
# the beam's length, so the saved PNGs are tall (length = height, tileable top to bottom). White; Roblox tints them.

def beam_core(x, y, w=256, h=128):
    v = (y + 0.5) / h - 0.5
    u = (x + 0.5) / w
    core = gauss(v, 0.07)
    body = gauss(v, 0.2) * 0.55
    haze = gauss(v, 0.42) * 0.18
    ripple = 0.9 + 0.1 * math.sin(math.tau * 3 * u) * math.sin(math.tau * 5 * u + 1.1)
    a = clamp((core + body) * ripple + haze)
    return (1, 1, 1, a)


ENERGY = [(random.uniform(0.04, 0.16), random.randint(1, 3), random.uniform(0, math.tau),
           random.randint(2, 6), random.uniform(0, math.tau), random.uniform(0.012, 0.03)) for _ in range(7)]


def beam_energy(x, y, w=512, h=128):
    v = (y + 0.5) / h
    u = (x + 0.5) / w
    total = 0.0
    for amp, freq, phase, pulse, pphase, width in ENERGY:
        center = 0.5 + amp * math.sin(math.tau * (freq * u) + phase)
        strand = gauss(v - center, width)
        flicker = (0.5 + 0.5 * math.sin(math.tau * pulse * u + pphase)) ** 2
        total += strand * flicker
    edge = smoothstep(0.0, 0.18, v) * smoothstep(1.0, 0.82, v)
    return (1, 1, 1, clamp(total * 1.2 * edge))


# --- sparks --------------------------------------------------------------------------------------------------

def glint(x, y, n=256):
    """A four-point star with a hot core, for the 'armed' glint and muzzle flares."""
    u = (x + 0.5) / n * 2 - 1
    v = (y + 0.5) / n * 2 - 1
    r = math.hypot(u, v)
    rays = 0.0
    for a, b in ((u, v), (v, u)):
        rays += gauss(b, 0.018 + 0.05 * abs(a)) * (1 - smoothstep(0.0, 1.0, abs(a)))
    diag = 0.0
    for a, b in (((u + v) / math.sqrt(2), (u - v) / math.sqrt(2)), ((u - v) / math.sqrt(2), (u + v) / math.sqrt(2))):
        diag += gauss(b, 0.012 + 0.03 * abs(a)) * (1 - smoothstep(0.0, 0.55, abs(a))) * 0.45
    core = gauss(r, 0.09) + gauss(r, 0.3) * 0.35
    return (1, 1, 1, clamp(rays + diag + core))


def soft_glow(x, y, n=128):
    u = (x + 0.5) / n * 2 - 1
    v = (y + 0.5) / n * 2 - 1
    r = math.hypot(u, v)
    a = gauss(r, 0.35) * 0.8 + gauss(r, 0.7) * 0.3
    return (1, 1, 1, clamp(a * (1 - smoothstep(0.85, 1.0, r))))


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else OUT
    previews = "--preview" in sys.argv
    os.makedirs(out, exist_ok=True)
    textures = [
        ("blood_crescent", CRESCENT_W, CRESCENT_H, blood_crescent),
        ("blood_glow", CRESCENT_W, CRESCENT_H, blood_glow),
        ("beam_core", 128, 256, lambda x, y: beam_core(y, x)),
        ("beam_energy", 128, 512, lambda x, y: beam_energy(y, x)),
        ("glint", 256, 256, glint),
        ("soft_glow", 128, 128, soft_glow),
    ]
    for name, w, h, pixels in textures:
        write_png(os.path.join(out, name + ".png"), w, h, pixels)
        if previews:
            preview(os.path.join(out, name + "_preview.png"), w, h, pixels)


if __name__ == "__main__":
    main()
