"""Study frames from reference footage (docs/reference/): contact sheets, single frames and bursts, each stamped with its
source timestamp. Study evidence only (AGENTS.md, IP safety): frames go to a local folder under build/reference/,
which git ignores; never into the game or the repo.

  py tools/reference/frames.py survey VIDEO OUT [--every 1] [--cols 4] [--rows 3] [--width 480] [--jobs 6]
      One frame every N seconds over the whole video, tiled into sheets (4x3 at 1 s: 12 s of footage a sheet, sheet n
      starting at (n-1)*12 s; tiles big enough to read poses and effects). Every frame is decoded (keyframes can be
      seconds apart), split across parallel jobs.
  py tools/reference/frames.py frames VIDEO OUT T [T ...] [--width 1280]
      Single frames at timestamps (seconds or h:mm:ss[.s]), scaled to --width (0 keeps the source size).
  py tools/reference/frames.py burst VIDEO OUT T [--duration 3] [--fps 10] [--cols 6] [--width 320] [--crop W:H:X:Y]
      Every frame of a short span (at --fps), tiled into one sheet: motion, timing, effect layers.

ffmpeg: set BL_FFMPEG, or the imageio build ChatGPT's study folder installed is used.
"""

import argparse
import math
import os
import re
import subprocess
import sys
from pathlib import Path

FFMPEG = os.environ.get("BL_FFMPEG") or (
    "C:/Users/gloce/.codex/visualizations/2026/10/29/01a1894d-1ea3-7272-a667-17d74cd6c8e1/media-runtime/"
    "imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe")
FONTS = "C:/Windows/Fonts"  # ffmpeg runs from here, so the font needs no drive colon (the filter graph's separator)


def stamp(size):
    """A drawtext filter printing each frame's source time (h:mm:ss.mmm) in its top-left corner."""
    return (f"drawtext=fontfile=arial.ttf:text='%{{pts\\:hms}}':x=6:y=6:fontsize={size}:fontcolor=white:"
            "box=1:boxcolor=black@0.65:boxborderw=4")


def seconds(text):
    parts = [float(p) for p in str(text).split(":")]
    total = 0.0
    for part in parts:
        total = total * 60 + part
    return total


def label(t):
    h, rest = divmod(t, 3600)
    m, s = divmod(rest, 60)
    return f"{int(h)}h{int(m):02d}m{s:04.1f}s".replace(".", "_")


def run(args):
    result = subprocess.run([FFMPEG, "-v", "error", "-y", *args], capture_output=True, text=True, cwd=FONTS)
    if result.returncode:
        sys.exit(result.stderr.strip()[:2000])


def duration(video):
    probe = subprocess.run([FFMPEG, "-hide_banner", "-i", str(video)], capture_output=True, text=True, cwd=FONTS)
    found = re.search(r"Duration: (\d+):(\d+):([\d.]+)", probe.stderr)
    if not found:
        sys.exit(f"no duration in: {probe.stderr[-500:]}")
    return seconds(":".join(found.groups()))


def survey(video, out, every, cols, rows, width, jobs):
    out.mkdir(parents=True, exist_ok=True)
    span = every * cols * rows  # seconds of footage a sheet covers
    sheets = math.ceil(duration(video) / span)
    per_job = math.ceil(sheets / jobs)
    chain = f"scale={width}:-2,{stamp(max(12, width // 20))},tile={cols}x{rows}"
    running = []
    for first in range(0, sheets, per_job):
        count = min(per_job, sheets - first)
        start = first * span
        running.append(subprocess.Popen(
            [FFMPEG, "-v", "error", "-y", "-ss", f"{start:.3f}", "-t", f"{count * span:.3f}", "-copyts", "-i", str(video),
             "-an", "-vf", f"fps=1/{every},{chain}", "-fps_mode", "vfr", "-start_number", str(first + 1), "-q:v", "3",
             str(out / "sheet_%03d.jpg")], cwd=FONTS, stderr=subprocess.PIPE, text=True))
    for job in running:
        _, errors = job.communicate()
        if job.returncode:
            sys.exit(errors.strip()[:2000])
    print(f"{len(list(out.glob('sheet_*.jpg')))} sheets in {out}, {span:g} s each (sheet n starts at (n-1)*{span:g} s)")


def frames(video, out, times, width):
    out.mkdir(parents=True, exist_ok=True)
    scale = f"scale={width}:-2," if width else ""
    for text in times:
        t = seconds(text)
        path = out / f"f_{label(t)}.jpg"
        run(["-ss", f"{t:.3f}", "-copyts", "-i", str(video), "-an", "-frames:v", "1",
             "-vf", f"{scale}{stamp(24)}", "-q:v", "2", str(path)])
        print(path)


def burst(video, out, start, duration, fps, cols, width, crop):
    out.mkdir(parents=True, exist_ok=True)
    t = seconds(start)
    count = max(1, round(duration * fps))
    rows = math.ceil(count / cols)
    chain = (f"crop={crop}," if crop else "") + f"fps={fps},scale={width}:-2,{stamp(max(11, width // 22))},tile={cols}x{rows}"
    path = out / f"burst_{label(t)}_{duration:g}s_{fps:g}fps.jpg"
    run(["-ss", f"{t:.3f}", "-t", f"{duration:.3f}", "-copyts", "-i", str(video), "-an", "-vf", chain,
         "-frames:v", "1", "-q:v", "2", str(path)])
    print(path)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="mode", required=True)
    s = sub.add_parser("survey")
    s.add_argument("video", type=Path)
    s.add_argument("out", type=Path)
    s.add_argument("--every", type=float, default=1)
    s.add_argument("--cols", type=int, default=4)
    s.add_argument("--rows", type=int, default=3)
    s.add_argument("--width", type=int, default=480)
    s.add_argument("--jobs", type=int, default=6)
    f = sub.add_parser("frames")
    f.add_argument("video", type=Path)
    f.add_argument("out", type=Path)
    f.add_argument("times", nargs="+")
    f.add_argument("--width", type=int, default=1280)
    b = sub.add_parser("burst")
    b.add_argument("video", type=Path)
    b.add_argument("out", type=Path)
    b.add_argument("start")
    b.add_argument("--duration", type=float, default=3)
    b.add_argument("--fps", type=float, default=10)
    b.add_argument("--cols", type=int, default=6)
    b.add_argument("--width", type=int, default=320)
    b.add_argument("--crop", default="")
    a = parser.parse_args()
    a.video, a.out = a.video.resolve(), a.out.resolve()  # ffmpeg runs from the fonts folder
    if a.mode == "survey":
        survey(a.video, a.out, a.every, a.cols, a.rows, a.width, a.jobs)
    elif a.mode == "frames":
        frames(a.video, a.out, a.times, a.width)
    else:
        burst(a.video, a.out, a.start, a.duration, a.fps, a.cols, a.width, a.crop)


if __name__ == "__main__":
    main()
