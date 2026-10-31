"""Tiles PNGs into one numbered contact sheet over a dark checker, so white-on-alpha art can be judged by eye (each tile
keeps its aspect, the checker shows its transparency, the number in its corner is its place in the list).

Run: blender.exe -b --factory-startup --python tools/blender/sheet.py -- <out.png> <tile size> <image.png> [...]
"""

import math
import sys

import bpy
import numpy as np

# 3x5 digits, row by row (1 = ink).
DIGITS = {
    "0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
    "4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010",
    "8": "111101111101111", "9": "111101111001111",
}


def load(path):
    image = bpy.data.images.load(path)
    width, height = image.size
    data = np.empty(width * height * 4, dtype=np.float32)
    image.pixels.foreach_get(data)
    bpy.data.images.remove(image)
    return data.reshape(height, width, 4)[::-1]  # row 0 = the top


def fit(rgba, size):
    """Nearest-neighbour scale into a size x size box, keeping the aspect (letterboxed, transparent)."""
    h, w = rgba.shape[:2]
    scale = size / max(h, w)
    nh, nw = max(1, int(h * scale)), max(1, int(w * scale))
    ys = np.minimum((np.arange(nh) / scale).astype(int), h - 1)
    xs = np.minimum((np.arange(nw) / scale).astype(int), w - 1)
    out = np.zeros((size, size, 4), dtype=np.float32)
    y0, x0 = (size - nh) // 2, (size - nw) // 2
    out[y0:y0 + nh, x0:x0 + nw] = rgba[ys][:, xs]
    return out


def label(tile, number, scale=4):
    text = str(number)
    for i, ch in enumerate(text):
        bits = DIGITS[ch]
        for r in range(5):
            for c in range(3):
                if bits[r * 3 + c] == "1":
                    y, x = 6 + r * scale, 6 + (i * 4 + c) * scale
                    tile[y:y + scale, x:x + scale, :3] = (1.0, 0.85, 0.3)


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    out, size, paths = args[0], int(args[1]), args[2:]
    columns = min(6, len(paths))
    rows = math.ceil(len(paths) / columns)
    sheet = np.zeros((rows * size, columns * size, 4), dtype=np.float32)
    yy, xx = np.mgrid[0:size, 0:size]
    checker = np.where(((yy // 16) + (xx // 16)) % 2 == 0, 0.07, 0.11)[..., None] * np.array([1.0, 0.9, 1.1])
    for i, path in enumerate(paths):
        art = fit(load(path), size)
        alpha = art[..., 3:4]
        tile = np.concatenate([checker * (1 - alpha) + art[..., :3] * alpha, np.ones((size, size, 1))], axis=-1)
        label(tile, i + 1)
        r, c = divmod(i, columns)
        sheet[r * size:(r + 1) * size, c * size:(c + 1) * size] = tile
    image = bpy.data.images.new("sheet", columns * size, rows * size, alpha=True)
    image.pixels.foreach_set(np.ascontiguousarray(sheet[::-1]).ravel())
    image.filepath_raw = out
    image.file_format = "PNG"
    image.save()
    print("BL_SHEET wrote", out)


main()
