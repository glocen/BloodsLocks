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


def gauss(v, sigma):
    return math.exp(-(v / sigma) ** 2)


def ring(x, y, n=256, inner=0.80, outer=0.96):
    """A clean white ring (anti-aliased), for HUD gauges: swept in code into a radial meter."""
    u = (x + 0.5) / n * 2 - 1
    v = (y + 0.5) / n * 2 - 1
    r = math.hypot(u, v)
    edge = 1.5 / (n / 2)
    a = smoothstep(inner - edge, inner + edge, r) * (1 - smoothstep(outer - edge, outer + edge, r))
    return (1, 1, 1, a)


def medallion(x, y, n=512):
    """An engraved metal bezel for HUD skill medallions: bevelled outer band with tick marks, an inner lip, and a
    lit top-left / shadowed bottom-right. Light grey on transparent so code tints it (bronze, gold, blood)."""
    u = (x + 0.5) / n * 2 - 1
    v = (y + 0.5) / n * 2 - 1
    r = math.hypot(u, v)
    ang = math.atan2(v, u)
    aa = 2.0 / n
    band = smoothstep(0.78 - aa, 0.78 + aa, r) * (1 - smoothstep(0.985 - aa, 0.985 + aa, r))
    if band <= 0:
        return (0, 0, 0, 0)
    t = clamp((r - 0.78) / 0.205)  # 0 inner edge .. 1 outer edge
    # bevel profile: bright ridge near the outer third, darker groove in the middle, bright inner lip
    profile = 0.55 + 0.35 * gauss(t - 0.72, 0.12) + 0.3 * gauss(t - 0.06, 0.05) - 0.25 * gauss(t - 0.38, 0.09)
    # light from the top-left
    light = 0.78 + 0.22 * (-(u + v) / max(r, 1e-3) / math.sqrt(2))
    # engraved ticks in the groove, every 10 degrees, longer every 30
    deg = (math.degrees(ang) + 360) % 360
    k = deg % 10
    tick_w = 0.6
    tick = (1 - smoothstep(tick_w * 0.5, tick_w, min(k, 10 - k)))
    long_tick = (deg % 30 < 1.2 or deg % 30 > 28.8)
    tick_mask = tick * gauss(t - 0.38, 0.06 if not long_tick else 0.11)
    shade = clamp(profile * light - 0.35 * tick_mask)
    s = shade
    return (s, s, s, band)


def bullet(x, y, n=64):
    """A pistol cartridge icon (white), pointing up."""
    u = (x + 0.5) / n
    v = (y + 0.5) / n
    cx, w = 0.5, 0.17
    aa = 1.5 / n
    body = (1 - smoothstep(w - aa, w + aa, abs(u - cx))) * smoothstep(0.30 - aa, 0.30 + aa, v) * (1 - smoothstep(0.92 - aa, 0.92 + aa, v))
    # ogive tip
    tip_v = 0.08
    tw = w * math.sqrt(clamp((v - tip_v) / (0.34 - tip_v))) if v > tip_v else 0
    tip = (1 - smoothstep(tw - aa, tw + aa, abs(u - cx))) * (1 if v <= 0.34 else 0)
    groove = 1 - 0.75 * gauss(v - 0.80, 0.012)
    a = clamp(max(body * groove, tip))
    return (1, 1, 1, a)


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


# The strands' random draws, seeded so every build matches the uploaded texture (after the 17 draws a deleted texture
# used to make first).
_rng = random.Random(7)
for _ in range(17):
    _rng.random()
ENERGY = [(_rng.uniform(0.04, 0.16), _rng.randint(1, 3), _rng.uniform(0, math.tau),
           _rng.randint(2, 6), _rng.uniform(0, math.tau), _rng.uniform(0.012, 0.03)) for _ in range(7)]


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
        ("beam_core", 128, 256, lambda x, y: beam_core(y, x)),
        ("beam_energy", 128, 512, lambda x, y: beam_energy(y, x)),
        ("glint", 256, 256, glint),
        ("soft_glow", 128, 128, soft_glow),
        ("ring", 256, 256, ring),
        ("medallion", 512, 512, medallion),
        ("bullet", 64, 64, bullet),
    ]
    for name, w, h, pixels in textures:
        write_png(os.path.join(out, name + ".png"), w, h, pixels)
        if previews:
            preview(os.path.join(out, name + "_preview.png"), w, h, pixels)


if __name__ == "__main__":
    main()
