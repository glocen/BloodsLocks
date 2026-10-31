"""Study the sound of reference footage (docs/reference/): extract spans of its audio and measure them, so its music and
effects can be described by their qualities (loudness, dynamics, brightness, tempo, key, stereo width, how hits are
shaped). Study evidence only (AGENTS.md, IP safety): the audio stays in a local folder under build/reference/, which git
ignores; never into the game or the repo, never uploaded, never imitated.

Needs numpy, so run it with Blender's bundled Python (nothing to install):
  BLPY="C:/Program Files (x86)/Steam/steamapps/common/Blender/5.2/python/bin/python.exe"
  "$BLPY" tools/reference/audio.py extract VIDEO OUT SPAN [SPAN ...]
      Each SPAN (start-end, seconds or h:mm:ss) to OUT/<start>.wav: 48 kHz stereo.
  "$BLPY" tools/reference/audio.py study OUT
      Every WAV in OUT: a spectrogram sheet (<name>.png: 60 s a row, log frequency 50 Hz-16 kHz, ticks every 5 s and
      tall ones every 30 s, faint lines at 100 Hz, 1 kHz and 10 kHz; under it the loudness and the chroma, C at the
      top) and OUT/report.md (measures per span and minute, and the strongest transients).
  "$BLPY" tools/reference/audio.py events WAV [--start T] [--end T] [--count 40]
      The transients of one span (source times): onset, attack, decay to -20 dB, band shares above the bed. The same
      measures as tools/studio/Audio/Waveform.luau, so a reference hit and a library sound compare directly.
"""

import argparse
import sys
import wave
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from frames import run, seconds  # noqa: E402  (tools/reference: the shared ffmpeg runner)
from vfx_textures import write_png  # noqa: E402  (tools: the shared PNG writer)

RATE = 48000
FRAME, HOP = 2048, 512  # STFT: 43 ms frames every 10.7 ms
CHROMA_FRAME, CHROMA_HOP = 16384, 4096  # harmony: 341 ms frames (3 Hz bins) every 85 ms
LOW_HZ, HIGH_HZ = 250, 2500  # band edges, as in Waveform.luau
ROW_SECONDS, PX_PER_SECOND = 60, 10
SPEC_ROWS, LOUD_ROWS, CHROMA_ROWS, GAP_ROWS = 180, 30, 36, 10
NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
# Krumhansl-Kessler key profiles
MAJOR = np.array([6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88])
MINOR = np.array([6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17])
MAGMA = [(0.0, (0, 0, 4)), (0.25, (59, 15, 112)), (0.5, (140, 41, 129)), (0.75, (229, 80, 100)), (1.0, (252, 253, 191))]


def clock(t):
    m, s = divmod(t, 60)
    return f"{int(m)}:{s:04.1f}"


# --- extracting -------------------------------------------------------------------------------------------------

def extract(video, out, spans):
    out.mkdir(parents=True, exist_ok=True)
    for span in spans:
        start, end = (seconds(part) for part in span.split("-"))
        name = f"{int(start // 60):02d}m{int(start % 60):02d}s"
        run(["-ss", f"{start:.3f}", "-t", f"{end - start:.3f}", "-i", str(video), "-vn", "-ac", "2", "-ar", str(RATE),
             "-c:a", "pcm_s16le", str(out / f"{name}.wav")])
        print(f"{name}.wav  {clock(start)}-{clock(end)}")


# --- reading and measuring --------------------------------------------------------------------------------------

def load(path):
    """The span's start (source seconds, from its name) and its left and right channels in -1..1."""
    with wave.open(str(path)) as f:
        assert f.getframerate() == RATE and f.getnchannels() == 2 and f.getsampwidth() == 2, path
        data = np.frombuffer(f.readframes(f.getnframes()), dtype=np.int16).reshape(-1, 2) / 32768.0
    name = path.stem
    start = int(name[:2]) * 60 + int(name[3:5])
    return start, data[:, 0].astype(np.float32), data[:, 1].astype(np.float32)


def stft(x):
    """Magnitudes (frames x bins), computed in chunks to keep memory low."""
    window = np.hanning(FRAME).astype(np.float32)
    count = max(0, (len(x) - FRAME) // HOP + 1)
    out = np.empty((count, FRAME // 2 + 1), dtype=np.float32)
    for first in range(0, count, 2000):
        last = min(count, first + 2000)
        index = np.arange(first, last)[:, None] * HOP + np.arange(FRAME)[None, :]
        out[first:last] = np.abs(np.fft.rfft(x[index] * window, axis=1)).astype(np.float32)
    return out


def freqs():
    return np.fft.rfftfreq(FRAME, 1 / RATE)


def db(v):
    return 20 * np.log10(np.maximum(v, 1e-9))


def one_pole_power(f, cutoff):
    """|H|^2 of the one-pole low-pass Waveform.luau runs (at its 32 kHz read rate), so band shares compare."""
    a = 1 - np.exp(-2 * np.pi * cutoff / 32000)
    w = 2 * np.pi * np.minimum(f, 16000) / 32000
    h = a / (1 - (1 - a) * np.exp(-1j * w))
    return h


def band_shares(power_spectrum, f):
    """Low, mid and high shares of a power spectrum, through the same filters as Waveform.luau."""
    low_h = one_pole_power(f, LOW_HZ)
    high_lp = one_pole_power(f, HIGH_HZ)
    parts = [np.abs(low_h) ** 2, np.abs(high_lp - low_h) ** 2, np.abs(1 - high_lp) ** 2]
    energy = np.array([float(np.sum(power_spectrum * p)) for p in parts])
    total = energy.sum()
    return energy / total if total > 0 else energy


def chroma(x):
    """Pitch-class energy per CHROMA_HOP (A2-C8), normalised per frame. A long FFT, and each semitone's band takes the
    mean power of its bins: with short frames the bins (23.4 Hz apart, about F#0) form a harmonic series of their own,
    and summing them biases every span toward F#, C#, A# and E."""
    window = np.hanning(CHROMA_FRAME).astype(np.float32)
    f = np.fft.rfftfreq(CHROMA_FRAME, 1 / RATE)
    bands = []
    for note in range(45, 109):  # MIDI A2 (110 Hz) to C8
        centre = 440.0 * 2 ** ((note - 69) / 12)
        use = np.nonzero((f >= centre * 2 ** (-1 / 24)) & (f < centre * 2 ** (1 / 24)))[0]
        bands.append((note % 12, use))
    count = max(0, (len(x) - CHROMA_FRAME) // CHROMA_HOP + 1)
    out = np.zeros((count, 12), dtype=np.float32)
    for first in range(0, count, 400):
        last = min(count, first + 400)
        index = np.arange(first, last)[:, None] * CHROMA_HOP + np.arange(CHROMA_FRAME)[None, :]
        power = np.abs(np.fft.rfft(x[index] * window, axis=1)) ** 2
        for pitch_class, use in bands:
            out[first:last, pitch_class] += power[:, use].mean(axis=1)
    return out / np.maximum(out.sum(axis=1, keepdims=True), 1e-12)


def key_of(profile):
    best = None
    for tonic in range(12):
        for mode, template in (("major", MAJOR), ("minor", MINOR)):
            r = np.corrcoef(profile, np.roll(template, tonic))[0, 1]
            if best is None or r > best[0]:
                best = (r, f"{NOTES[tonic]} {mode}")
    return best


def tempo_of(mags):
    """BPM from the spectral flux's autocorrelation (40-200 BPM), and how clearly it stands out (z-score)."""
    logm = np.log1p(mags[:, 4:600] * 10)
    flux = np.maximum(0, np.diff(logm, axis=0)).sum(axis=1)
    flux = flux - flux.mean()
    if len(flux) < 800:
        return None, 0.0
    ac = np.correlate(flux, flux, mode="full")[len(flux) - 1:]
    hop_s = HOP / RATE
    lags = np.arange(int(60 / 200 / hop_s), int(60 / 40 / hop_s))
    values = ac[lags]
    best = int(np.argmax(values))
    z = (values[best] - values.mean()) / (values.std() + 1e-9)
    return 60 / (lags[best] * hop_s), float(z)


def measures(left, right, mags, f):
    mid = (left + right) / 2
    side = (left - right) / 2
    power = mags.astype(np.float64) ** 2
    total = power.sum(axis=1) + 1e-12
    centroid = (power * f[None, :]).sum(axis=1) / total
    use = (f >= 100) & (f <= 10000)
    p = power[:, use] + 1e-12
    flatness = np.exp(np.mean(np.log(p), axis=1)) / np.mean(p, axis=1)
    loud = frame_loudness(mags)
    voiced = loud > loud.max() - 40
    short = [float(np.sqrt(np.mean(mid[i:i + 3 * RATE] ** 2))) for i in range(0, max(1, len(mid) - 3 * RATE), RATE)]
    short_db = db(np.array(short)) if short else np.array([-120.0])
    profile = key_profile(mid)
    key = key_of(profile) if profile.sum() > 0 else (0, "?")
    bpm, z = tempo_of(mags)
    shares = band_shares(power.sum(axis=0), f)
    return {
        "rms": float(db(np.sqrt(np.mean(mid ** 2)))),
        "peak": float(db(np.max(np.abs(np.concatenate([left, right]))))),
        "range": float(np.percentile(short_db, 95) - np.percentile(short_db, 10)),
        "quiet": float(np.percentile(short_db, 10)),
        "loud": float(np.percentile(short_db, 95)),
        "width": float(db(np.sqrt(np.mean(side ** 2))) - db(np.sqrt(np.mean(mid ** 2)))),
        "centroid": float(np.median(centroid[voiced])) if voiced.any() else 0.0,
        "flatness": float(np.median(flatness[voiced])) if voiced.any() else 0.0,
        "bands": shares,
        "key": key,
        "tones": [NOTES[i] for i in np.argsort(profile)[::-1][:4]],
        "bpm": bpm,
        "bpm_z": z,
    }


def key_profile(mid):
    """The pitch-class profile of the louder stretches (within 40 dB of the loudest), for the key estimate."""
    ch = chroma(mid)
    if not len(ch):
        return np.zeros(12)
    energy = np.array([np.mean(mid[j * CHROMA_HOP:j * CHROMA_HOP + CHROMA_FRAME] ** 2) for j in range(len(ch))])
    voiced = energy > energy.max() * 1e-4
    return ch[voiced].sum(axis=0)


def frame_loudness(mags):
    return db(np.sqrt((mags.astype(np.float64) ** 2).sum(axis=1)) / FRAME)


# --- transients -------------------------------------------------------------------------------------------------

def transients(mid, mags, f, start, count, window=(None, None)):
    """The strongest onsets: where the 10 ms peak envelope jumps 9 dB over the last half second's median."""
    per = RATE // 100
    env = np.abs(mid[: len(mid) // per * per]).reshape(-1, per).max(axis=1)
    top = env.max()
    found = []
    i = 50
    while i < len(env) - 2:
        background = np.median(env[i - 50:i]) + 1e-6
        if env[i] > background * 10 ** (9 / 20) and env[i] > top * 10 ** (-30 / 20) and env[i] > env[i - 1] * 1.4:
            peak = i + int(np.argmax(env[i:i + 15]))
            limit = max(env[peak] * 0.1, background * 1.4)  # 20 dB down, or back near the bed
            end = peak
            while end < len(env) - 1 and env[end] > limit and end - peak < 300:
                end += 1
            t = start + i / 100
            if (window[0] is None or t >= window[0]) and (window[1] is None or t <= window[1]):
                frame = int(i * per / HOP)
                before = mags[max(0, frame - 28):max(1, frame - 2)].astype(np.float64) ** 2
                during = mags[frame:frame + 14].astype(np.float64) ** 2
                lifted = np.maximum(during.mean(axis=0) - before.mean(axis=0), 0) if len(before) else during.mean(axis=0)
                shares = band_shares(lifted, f)
                found.append({
                    "t": t, "attack": (peak - i) / 100, "decay20": (end - peak) / 100,
                    "level": float(db(env[peak]) - db(top)), "over": float(db(env[peak]) - db(background)),
                    "bands": shares,
                })
            i = max(i + 6, peak + 3)
        else:
            i += 1
    found.sort(key=lambda e: -e["over"])
    return sorted(found[:count], key=lambda e: e["t"])


def describe_transient(e):
    low, mid, high = (round(v * 100) for v in e["bands"])
    return (f"{clock(e['t'])}  +{e['over']:.0f} dB over the bed ({e['level']:+.0f} dB)  attack {e['attack']:.2f}  "
            f"-20 dB {e['decay20']:.2f}  low {low}% mid {mid}% high {high}%")


# --- pictures ---------------------------------------------------------------------------------------------------

def magma(v):
    v = np.clip(v, 0, 1)
    out = np.zeros(v.shape + (3,))
    for (a, ca), (b, cb) in zip(MAGMA, MAGMA[1:]):
        m = (v >= a) & (v <= b)
        t = ((v - a) / (b - a))[..., None]
        out[m] = (np.array(ca) * (1 - t) + np.array(cb) * t)[m] / 255
    return out


def sheet(path, mags, f, mid):
    """60 s per row: spectrogram (log frequency), loudness, chroma; source ticks every 5 s and 30 s."""
    frames_per_px = RATE / HOP / PX_PER_SECOND
    width = ROW_SECONDS * PX_PER_SECOND
    columns = int(mags.shape[0] / frames_per_px)
    rows = max(1, int(np.ceil(columns / width)))
    edges = np.geomspace(50, 16000, SPEC_ROWS + 1)
    band_index = np.searchsorted(f, edges)
    spec = np.zeros((SPEC_ROWS, columns))
    chroma_img = np.zeros((12, columns))
    ch = chroma(mid)
    loud = np.zeros(columns)
    for c in range(columns):
        a, b = int(c * frames_per_px), max(int(c * frames_per_px) + 1, int((c + 1) * frames_per_px))
        block = mags[a:b].astype(np.float64) ** 2
        mean = block.mean(axis=0)
        for r in range(SPEC_ROWS):
            lo, hi = band_index[r], max(band_index[r] + 1, band_index[r + 1])
            spec[SPEC_ROWS - 1 - r, c] = mean[lo:hi].mean()
        j = int(np.clip(round((c / PX_PER_SECOND * RATE - CHROMA_FRAME / 2) / CHROMA_HOP), 0, len(ch) - 1))
        chroma_img[:, c] = ch[j]
        loud[c] = 10 * np.log10(block.sum(axis=1).mean() + 1e-12)
    spec_db = 10 * np.log10(spec + 1e-12)
    hi_db = np.percentile(spec_db, 99.5)
    spec_v = (spec_db - (hi_db - 70)) / 70
    loud_v = (loud - (loud.max() - 45)) / 45
    chroma_v = chroma_img / max(chroma_img.max(), 1e-9)
    grid_rows = [SPEC_ROWS - 1 - int(np.searchsorted(edges, hz)) for hz in (100, 1000, 10000)]
    row_h = SPEC_ROWS + LOUD_ROWS + CHROMA_ROWS + GAP_ROWS
    img = np.zeros((rows * row_h, width, 3))
    for row in range(rows):
        c0 = row * width
        n = min(width, columns - c0)
        y0 = row * row_h
        block = magma(spec_v[:, c0:c0 + n])
        for g in grid_rows:
            block[g, ::4] = block[g, ::4] * 0.5 + 0.3
        img[y0:y0 + SPEC_ROWS, :n] = block
        for x in range(n):
            h = int(np.clip(loud_v[c0 + x], 0, 1) * (LOUD_ROWS - 2))
            img[y0 + SPEC_ROWS + LOUD_ROWS - 1 - h:y0 + SPEC_ROWS + LOUD_ROWS, x] = (0.45, 0.75, 0.95)
        cy = y0 + SPEC_ROWS + LOUD_ROWS
        for k in range(12):
            img[cy + k * 3:cy + k * 3 + 3, :n] = magma(chroma_v[k, c0:c0 + n] ** 1.5)[None, :, :]
        for s in range(0, ROW_SECONDS + 1, 5):
            x = min(width - 1, s * PX_PER_SECOND)
            tall = 12 if s % 30 == 0 else 5
            img[y0:y0 + tall, x] = 1.0
    h, w = img.shape[:2]
    write_png(str(path), w, h, lambda x, y: (img[y, x, 0], img[y, x, 1], img[y, x, 2], 1.0))


# --- study ------------------------------------------------------------------------------------------------------

def study(out):
    lines = ["# Reference audio: measures (local study file)", "",
             "rms/peak dBFS; range = loudness range (P95-P10 of 3 s windows); width = side vs mid, dB; centroid Hz; "
             "flatness 0 = tonal, 1 = noise; bands low/mid/high through Waveform.luau's filters; tempo z > 4 is clear.", ""]
    f = freqs()
    for path in sorted(out.glob("*.wav")):
        start, left, right = load(path)
        mid = (left + right) / 2
        mags = stft(mid)
        m = measures(left, right, mags, f)
        end = start + len(mid) / RATE
        low, midb, high = (round(v * 100) for v in m["bands"])
        lines += [f"## {clock(start)}-{clock(end)} ({path.stem})", "",
                  f"- rms {m['rms']:.1f}, peak {m['peak']:.1f}, range {m['range']:.1f} dB ({m['quiet']:.0f} to "
                  f"{m['loud']:.0f}), width {m['width']:.1f} dB",
                  f"- centroid {m['centroid']:.0f} Hz, flatness {m['flatness']:.2f}, bands low {low}% mid {midb}% "
                  f"high {high}%",
                  f"- key {m['key'][1]} (r {m['key'][0]:.2f}), strongest tones {', '.join(m['tones'])}; tempo "
                  f"{m['bpm']:.0f} BPM (z {m['bpm_z']:.1f})" if m["bpm"] else f"- key {m['key'][1]}", ""]
        for minute in range(0, int(np.ceil(len(mid) / RATE / 60))):
            a, b = minute * 60 * RATE, min(len(mid), (minute + 1) * 60 * RATE)
            if b - a < 20 * RATE:
                continue
            fa, fb = a // HOP, b // HOP
            mm = measures(left[a:b], right[a:b], mags[fa:fb], f)
            lines.append(f"  - {clock(start + minute * 60)}: rms {mm['rms']:.1f}, range {mm['range']:.1f}, centroid "
                         f"{mm['centroid']:.0f}, flatness {mm['flatness']:.2f}, key {mm['key'][1]} "
                         f"(r {mm['key'][0]:.2f}), tempo {mm['bpm']:.0f} (z {mm['bpm_z']:.1f})")
        lines += ["", "Strongest transients:", ""]
        lines += [f"- {describe_transient(e)}" for e in transients(mid, mags, f, start, 25)]
        lines.append("")
        sheet(out / f"{path.stem}.png", mags, f, mid)
        print("studied", path.name)
    (out / "report.md").write_text("\n".join(lines), encoding="utf-8")
    print("wrote", out / "report.md")


def events(path, start_t, end_t, count):
    start, left, right = load(path)
    mid = (left + right) / 2
    mags = stft(mid)
    for e in transients(mid, mags, freqs(), start, count, (start_t, end_t)):
        print(describe_transient(e))


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="command", required=True)
    e = sub.add_parser("extract")
    e.add_argument("video", type=Path)
    e.add_argument("out", type=Path)
    e.add_argument("spans", nargs="+")
    s = sub.add_parser("study")
    s.add_argument("out", type=Path)
    t = sub.add_parser("events")
    t.add_argument("wav", type=Path)
    t.add_argument("--start", type=seconds)
    t.add_argument("--end", type=seconds)
    t.add_argument("--count", type=int, default=40)
    a = parser.parse_args()
    if a.command == "extract":
        extract(a.video.resolve(), a.out.resolve(), a.spans)
    elif a.command == "study":
        study(a.out.resolve())
    else:
        events(a.wav.resolve(), a.start, a.end, a.count)


if __name__ == "__main__":
    main()
