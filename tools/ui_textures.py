"""Draws the BloodsLocks menu images as PNGs (pure standard library; shares helpers with vfx_textures.py).

Run:  py tools/ui_textures.py [out_dir] [--preview]

  hunt_card.png       880x472  the Hunt tab's mode card: a Victorian skyline at blood dusk (shown at 440x236)
  ritual_circle.png   768x768  the blood circle the character stands on in the Blood Table menu (a Decal)

Everything is drawn from math, so it can be retuned and redrawn. Upload the PNGs and put the ids in Theme.Images.
"""

import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from vfx_textures import write_png, clamp, smoothstep, lerp, mix, gauss  # noqa: E402

OUT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "ui"))


# --- hunt card: a Victorian skyline at blood dusk --------------------------------------------------------------

CARD_W, CARD_H = 880, 472

SKY_TOP = (0.05, 0.025, 0.06)
SKY_MID = (0.36, 0.06, 0.09)
SKY_LOW = (0.80, 0.36, 0.15)
MOON = (0.70, 0.10, 0.10)


def skyline(seed, base, rise, spire_chance, width):
    """Per-column silhouette heights (fraction of the card height, measured from the top) for one depth layer."""
    rng = random.Random(seed)
    heights = [1.0] * width
    x = -20
    while x < width:
        w = rng.randint(28, 90)
        top = base - rng.random() * rise
        kind = rng.random()
        for i in range(max(0, x), min(width, x + w)):
            t = (i - x) / w
            h = top
            if kind < 0.45:  # gable roof
                h = top - (0.5 - abs(t - 0.5)) * 0.10
            heights[i] = min(heights[i], h)
        # chimneys
        for _ in range(rng.randint(0, 3)):
            cx = x + rng.randint(4, max(5, w - 8))
            for i in range(max(0, cx), min(width, cx + rng.randint(4, 7))):
                heights[i] = min(heights[i], top - 0.035 - rng.random() * 0.02)
        # a spire on some buildings
        if rng.random() < spire_chance:
            cx = x + w // 2
            tall = 0.12 + rng.random() * 0.20
            half = rng.randint(6, 12)
            for i in range(max(0, cx - half), min(width, cx + half)):
                t = 1 - abs(i - cx) / half
                heights[i] = min(heights[i], top - tall * t ** 1.4)
        x += w + rng.randint(-6, 4)
    return heights


def cathedral(width):
    """The near layer's landmark: a twin-towered cathedral with a rose-window gable, left of centre."""
    heights = [1.0] * width
    cx = CATHEDRAL_X
    for i in range(width):
        d = i - cx
        h = 1.0
        if abs(d) < 120:
            h = 0.66  # nave roofline
            if abs(d) < 46:
                h = 0.60 - (1 - abs(d) / 46) * 0.10  # central gable
            if abs(d) > 50 and (abs(d) - 50) % 18 < 3:
                h = min(h, 0.60)  # pinnacles along the nave
        for tower in (-78, 78):
            td = abs(d - tower)
            if td < 20:
                h = min(h, 0.34)  # tower body
            if td < 23 and td >= 19:
                h = min(h, 0.31)  # corner pinnacles
            if td < 16:
                h = min(h, 0.34 - (1 - td / 16) ** 1.4 * 0.27)  # spire
            if td < 1.5:
                h = min(h, 0.04)  # finial
        heights[i] = h
    return heights


CATHEDRAL_X = int(CARD_W * 0.34)


def cathedral_window(x, y):
    """Warm light in the cathedral: a rose window in the gable, lancet slits and belfry openings in the towers."""
    u, v = x - CATHEDRAL_X, y / CARD_H
    if math.hypot(u, (v - 0.66) * CARD_H) < 13:
        ring = math.hypot(u, (v - 0.66) * CARD_H)
        spokes = abs(math.sin(math.atan2((v - 0.66) * CARD_H, u) * 6)) > 0.25 or ring < 4
        return 0.9 if spokes and ring > 2 else 0.35
    for tower in (-78, 78):
        tx = u - tower
        if abs(tx) < 2.5 and 0.42 < v < 0.52:
            return 0.8  # lancet slit
        if abs(abs(tx) - 7) < 2.5 and 0.36 < v < 0.40:
            return 0.55  # belfry openings
    if abs(u) < 118 and abs(u) > 52 and (abs(u) - 52) % 18 < 5 and 0.72 < v < 0.79:
        return 0.5  # nave windows
    return 0.0


def card_pixels():
    far = skyline(11, 0.66, 0.10, 0.25, CARD_W)
    mid = skyline(23, 0.74, 0.12, 0.35, CARD_W)
    near = skyline(37, 0.84, 0.10, 0.30, CARD_W)
    church = cathedral(CARD_W)
    near = [min(a, b) for a, b in zip(near, church)]
    rng = random.Random(5)
    windows = set()
    for _ in range(140):
        wx, wy = rng.randint(0, CARD_W - 1), rng.uniform(0.70, 0.95)
        if wy > mid[wx] + 0.02 and wy < near[wx] - 0.005:
            windows.add((wx // 3, int(wy * CARD_H) // 4))
    grain = random.Random(9)

    def pixel(x, y):
        u, v = x / CARD_W, y / CARD_H
        # sky: violet top → crimson → ember at the horizon, with soft cloud bands
        sky = mix(SKY_TOP, SKY_MID, smoothstep(0.0, 0.55, v))
        sky = mix(sky, SKY_LOW, smoothstep(0.45, 0.78, v))
        band = 0.5 + 0.5 * math.sin(v * 38 + math.sin(u * 7) * 1.8)
        sky = mix(sky, (sky[0] * 0.55, sky[1] * 0.5, sky[2] * 0.6), band * smoothstep(0.08, 0.5, v) * 0.35)
        # blood moon with a halo
        md = math.hypot((u - 0.73) * CARD_W / CARD_H, v - 0.22)
        sky = mix(sky, (0.55, 0.10, 0.08), gauss(md, 0.16) * 0.35)
        if md < 0.075:
            shade = 0.75 + 0.25 * (1 - md / 0.075)
            sky = mix(sky, (MOON[0] * shade, MOON[1] * shade, MOON[2] * shade), smoothstep(0.075, 0.068, md))
        color = sky
        # far layer: hazy, warm; mist above it
        if v > far[x]:
            color = mix(color, (0.30, 0.10, 0.10), 0.85)
        color = mix(color, (0.55, 0.22, 0.15), gauss(v - far[x] + 0.02, 0.03) * 0.25)
        # mid layer: darker, with a few lit windows
        if v > mid[x]:
            color = (0.10, 0.03, 0.05)
            if (x // 3, y // 4) in windows:
                color = (0.95, 0.62, 0.28)
        # near layer: near-black, with the cathedral's windows lit from inside
        if v > near[x]:
            color = (0.025, 0.012, 0.02)
            glow = cathedral_window(x, y)
            if glow > 0:
                color = mix(color, (0.95, 0.55, 0.22), glow)
        # ground fog in front of the mid layer
        color = mix(color, (0.32, 0.12, 0.12), smoothstep(0.80, 0.98, v) * 0.25 * (1 if v < near[x] else 0.3))
        # vignette + grain
        vig = 1 - 0.55 * smoothstep(0.35, 0.85, math.hypot(u - 0.5, (v - 0.5) * 0.9))
        g = 1 + (grain.random() - 0.5) * 0.06
        return (color[0] * vig * g, color[1] * vig * g, color[2] * vig * g, 1.0)

    return pixel


# --- ritual circle ---------------------------------------------------------------------------------------------

CIRCLE_N = 768
INK = (0.50, 0.03, 0.07)


def seg_distance(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    t = clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy))
    return math.hypot(px - (ax + dx * t), py - (ay + dy * t))


def circle_pixels():
    points = [(0.74 * math.cos(math.pi / 2 + k * 2 * math.pi / 7), 0.74 * math.sin(math.pi / 2 + k * 2 * math.pi / 7)) for k in range(7)]
    star = [(points[k], points[(k + 3) % 7]) for k in range(7)]  # heptagram {7/3}
    rng = random.Random(3)
    wear = [rng.random() for _ in range(360)]

    def pixel(x, y):
        u, v = (x + 0.5) / CIRCLE_N * 2 - 1, (y + 0.5) / CIRCLE_N * 2 - 1
        r = math.hypot(u, v)
        if r > 1:
            return (0, 0, 0, 0)
        angle = math.degrees(math.atan2(v, u)) % 360
        w = 0.004  # line half-width
        a = 0.0
        for radius, width in ((0.97, w * 1.6), (0.93, w), (0.80, w * 1.3), (0.76, w), (0.30, w), (0.26, w * 1.4)):
            a = max(a, smoothstep(width, width * 0.4, abs(r - radius)))
        if 0.93 < r < 0.97 and int(angle * 2) % 6 == 0:  # tick marks
            a = max(a, 0.9)
        if 0.82 < r < 0.91:  # glyph bars every 15 degrees
            k = int(angle // 15)
            local = angle - k * 15
            if 3 < local < 4.4 + (k % 3) * 1.2 and r < 0.84 + (k % 4) * 0.018:
                a = max(a, 0.85)
            if abs(local - 9) < 0.5 and 0.84 < r < 0.89:
                a = max(a, 0.85)
        for (ax, ay), (bx, by) in star:
            a = max(a, smoothstep(w * 1.2, w * 0.4, seg_distance(u, v, ax, ay, bx, by)) * (1 if r < 0.76 else 0))
        # worn ink: uneven strength around the circle, blotches toward the centre
        a *= 0.65 + 0.35 * wear[int(angle)]
        a = max(a, 0.18 * smoothstep(0.3, 0.0, r) * (0.6 + 0.4 * math.sin(u * 23) * math.sin(v * 19)))
        a *= smoothstep(1.0, 0.97, r)
        return (INK[0], INK[1], INK[2], a)

    return pixel


# --- tab ribbon: painted wine texture + the active tab's filigree --------------------------------------------

RIBBON_W, RIBBON_H = 512, 64
GOLD = (0.86, 0.70, 0.44)


def value_noise(seed, cells_x, cells_y):
    """Smooth tileable value noise on a cells_x by cells_y lattice; returns f(u, v) for u, v in 0..1."""
    rng = random.Random(seed)
    grid = [[rng.random() for _ in range(cells_x)] for _ in range(cells_y)]

    def f(u, v):
        x, y = (u % 1) * cells_x, (v % 1) * cells_y
        x0, y0 = int(x), int(y)
        tx, ty = x - x0, y - y0
        tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
        a = grid[y0 % cells_y][x0 % cells_x]
        b = grid[y0 % cells_y][(x0 + 1) % cells_x]
        c = grid[(y0 + 1) % cells_y][x0 % cells_x]
        d = grid[(y0 + 1) % cells_y][(x0 + 1) % cells_x]
        return lerp(lerp(a, b, tx), lerp(c, d, tx), ty)

    return f


def ribbon_pixels():
    """A tileable, horizontally brushed paint texture in neutral greys (tinted wine by the UI)."""
    broad = value_noise(1, 6, 3)
    brush = value_noise(2, 48, 6)
    fine = value_noise(3, 160, 40)

    def pixel(x, y):
        u, v = x / RIBBON_W, y / RIBBON_H
        n = 0.55 * broad(u, v) + 0.30 * brush(u, v) + 0.15 * fine(u, v)
        g = 0.78 + 0.22 * n
        return (g, g, g, 1.0)

    return pixel


FLOURISH_W, FLOURISH_H = 512, 48


def flourish_pixels():
    """The active tab's filigree: a fine gold line with sword-guard crosses near both ends and small lozenge
    terminals. Drawn for a 9-slice: the outer 72 px on each side are the ornaments, the middle stretches."""
    mid = FLOURISH_H / 2

    def ornament(dx, dy):
        """Coverage of one end ornament; dx is distance from the outer edge, dy from the line."""
        a = 0.0
        a = max(a, smoothstep(1.4, 0.6, abs(dy)) * smoothstep(8, 12, dx))  # the line itself
        # the cross: a vertical bar with flared tips
        bar = abs(dx - 34)
        a = max(a, smoothstep(1.6, 0.7, bar) * smoothstep(13, 11, abs(dy)))
        a = max(a, smoothstep(3.0, 1.5, math.hypot(bar, abs(dy) - 12)))  # tip pearls
        # small cross-guard quillons, angled
        for side in (-1, 1):
            qx, qy = dx - 34 - 7 * side, dy
            a = max(a, smoothstep(1.3, 0.5, abs(qy - side * 0 + (abs(qx) - 0) * 0.0)) * smoothstep(9, 7, abs(qx) + abs(qy) * 3))
        # lozenge terminal at the very end
        a = max(a, smoothstep(1.0, 0.0, abs(dx - 10) / 6 + abs(dy) / 4 - 0.8))
        # a second, smaller lozenge between cross and terminal
        a = max(a, smoothstep(1.0, 0.0, abs(dx - 22) / 3 + abs(dy) / 2.2 - 0.8))
        return clamp(a)

    def pixel(x, y):
        dy = y + 0.5 - mid
        dx = min(x + 0.5, FLOURISH_W - x - 0.5)
        a = ornament(dx, dy) if dx < 72 else smoothstep(1.4, 0.6, abs(dy))
        return (GOLD[0], GOLD[1], GOLD[2], a)

    return pixel


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out = args[0] if args else OUT
    os.makedirs(out, exist_ok=True)
    write_png(os.path.join(out, "hunt_card.png"), CARD_W, CARD_H, card_pixels())
    write_png(os.path.join(out, "ritual_circle.png"), CIRCLE_N, CIRCLE_N, circle_pixels())
    write_png(os.path.join(out, "ribbon.png"), RIBBON_W, RIBBON_H, ribbon_pixels())
    write_png(os.path.join(out, "tab_flourish.png"), FLOURISH_W, FLOURISH_H, flourish_pixels())


if __name__ == "__main__":
    main()
