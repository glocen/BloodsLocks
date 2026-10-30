"""Synthesizes BloodsLocks' combat sounds (our own, no samples) and packs them into one sound sheet, so a whole batch
costs one audio upload: the game plays each cue as a region of the sheet (Sound.PlaybackRegion).

Run: py tools/audio/sound_sheet.py <out_dir>
Writes <out_dir>/bl_combat_sounds.wav (44.1 kHz mono 16-bit) and src/shared/Definitions/SoundSheet.luau (each cue's
region). The sheet's upload id is kept in SoundSheet.luau while the audio is unchanged (same hash); a changed sheet
needs a new upload (the owner: Studio, View > Asset Manager > Bulk Import), and its id goes back into that file.

Pure standard library: biquad filters (RBJ cookbook), modal synthesis for struck metal, a Freeverb-style room, all
deterministic (seeded), so every sound can be retuned and rebuilt.
"""

import hashlib
import json
import math
import os
import random
import re
import struct
import sys
import wave

SR = 44100
REPO = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
LUAU = os.path.join(REPO, "src", "shared", "Definitions", "SoundSheet.luau")
GAP = 0.35  # silence between cues, seconds
LEAD = 0.2  # silence before the first cue
CLEAN_LOW = 40  # Hz: every cue is high-passed here (two passes, 24 dB/octave)


# --- building blocks -------------------------------------------------------------------------------------------------

def samples(seconds):
    return int(round(seconds * SR))


def silence(seconds):
    return [0.0] * samples(seconds)


def white(seconds, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(samples(seconds))]


class Biquad:
    """One RBJ-cookbook biquad (lowpass, highpass, bandpass with 0 dB peak, peak EQ)."""

    def __init__(self, kind, freq, q=0.7071, gain_db=0.0):
        self.x1 = self.x2 = self.y1 = self.y2 = 0.0
        self.set(kind, freq, q, gain_db)

    def set(self, kind, freq, q=0.7071, gain_db=0.0):
        freq = min(max(freq, 20.0), SR * 0.45)
        w0 = 2 * math.pi * freq / SR
        cw, sw = math.cos(w0), math.sin(w0)
        alpha = sw / (2 * q)
        if kind == "peak":
            a = 10 ** (gain_db / 40)
            b0, b1, b2 = 1 + alpha * a, -2 * cw, 1 - alpha * a
            a0, a1, a2 = 1 + alpha / a, -2 * cw, 1 - alpha / a
        else:
            if kind == "lowpass":
                b0, b1, b2 = (1 - cw) / 2, 1 - cw, (1 - cw) / 2
            elif kind == "highpass":
                b0, b1, b2 = (1 + cw) / 2, -(1 + cw), (1 + cw) / 2
            elif kind == "bandpass":
                b0, b1, b2 = alpha, 0.0, -alpha
            else:
                raise ValueError(kind)
            a0, a1, a2 = 1 + alpha, -2 * cw, 1 - alpha
        self.b0, self.b1, self.b2, self.a1, self.a2 = b0 / a0, b1 / a0, b2 / a0, a1 / a0, a2 / a0

    def run(self, signal):
        b0, b1, b2, a1, a2 = self.b0, self.b1, self.b2, self.a1, self.a2
        x1, x2, y1, y2 = self.x1, self.x2, self.y1, self.y2
        out = []
        for x in signal:
            y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
            x2, x1, y2, y1 = x1, x, y1, y
            out.append(y)
        self.x1, self.x2, self.y1, self.y2 = x1, x2, y1, y2
        return out


def filt(signal, kind, freq, q=0.7071, gain_db=0.0, passes=1):
    for _ in range(passes):
        signal = Biquad(kind, freq, q, gain_db).run(signal)
    return signal


def sweep(signal, kind, freq_at, q=0.7071, step=32):
    """A filter whose cutoff follows freq_at(t) (seconds), updated every `step` samples."""
    biquad = Biquad(kind, freq_at(0.0), q)
    out = []
    for start in range(0, len(signal), step):
        biquad.set(kind, freq_at(start / SR), q)
        out.extend(biquad.run(signal[start:start + step]))
    return out


def env(seconds, attack, decay, delay=0.0):
    """Silent for `delay`, a linear rise over `attack`, then an exponential fall with time constant `decay`."""
    out = []
    for i in range(samples(seconds)):
        t = i / SR - delay
        if t < 0:
            out.append(0.0)
        elif t < attack:
            out.append(t / attack)
        else:
            out.append(math.exp(-(t - attack) / decay))
    return out


def bell(seconds, peak, rise_power=2.0, fall=0.08):
    """Rises as (t/peak)^rise_power to 1 at `peak`, then falls exponentially: a swing's whoosh."""
    out = []
    for i in range(samples(seconds)):
        t = i / SR
        out.append((t / peak) ** rise_power if t < peak else math.exp(-(t - peak) / fall))
    return out


def tone(seconds, freq_at, amp=1.0, phase=0.0):
    """A sine whose frequency follows freq_at(t)."""
    out = []
    for i in range(samples(seconds)):
        out.append(amp * math.sin(phase))
        phase += 2 * math.pi * freq_at(i / SR) / SR
    return out


def glide(f0, f1, time):
    """Exponential glide from f0 to f1 over `time` seconds, then holding f1."""
    return lambda t: f0 * (f1 / f0) ** min(t / time, 1.0)


def modal(seconds, partials, rng, delay=0.0):
    """Struck metal: decaying sines [(freq, amp, decay)], random phases."""
    n = samples(seconds)
    out = [0.0] * n
    start = samples(delay)
    for freq, amp, decay in partials:
        phase = rng.uniform(0, 2 * math.pi)
        w = 2 * math.pi * freq / SR
        for i in range(start, n):
            t = (i - start) / SR
            out[i] += amp * math.exp(-t / decay) * math.sin(phase + w * (i - start))
    return out


def grains(seconds, count, start, end, rng, band=(1200, 4500), length=(0.004, 0.011), q=3.0, amp=(0.35, 0.05)):
    """Scattered short noise ticks between `start` and `end` (debris, droplets), fading from amp[0] to amp[1]."""
    out = [0.0] * samples(seconds)
    for k in range(count):
        at = rng.uniform(start, end)
        dur = rng.uniform(*length)
        tick = mul(filt(white(dur, rng), "bandpass", rng.uniform(*band), q), env(dur, 0.0005, dur / 3))
        gain = amp[0] + (amp[1] - amp[0]) * (at - start) / max(1e-6, end - start)
        mix(out, tick, at, gain * rng.uniform(0.6, 1.0))
    return out


def mul(a, b):
    return [x * y for x, y in zip(a, b)]


def scale(signal, gain):
    return [x * gain for x in signal]


def mix(dest, src, at=0.0, gain=1.0):
    offset = samples(at)
    for i, x in enumerate(src):
        j = offset + i
        if j >= len(dest):
            break
        dest[j] += x * gain
    return dest


def total(seconds, *layers):
    out = silence(seconds)
    for layer in layers:
        mix(out, layer)
    return out


def softclip(signal, drive=2.0):
    norm = math.tanh(drive)
    return [math.tanh(drive * x) / norm for x in signal]


def reverb(signal, size=0.5, damp=0.4, wet=0.25):
    """A Freeverb-style room (8 damped combs, 4 allpasses) mixed under the dry signal."""
    combs = [1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617]
    allpasses = [556, 441, 341, 225]
    feedback = 0.28 * size + 0.7
    out = [0.0] * len(signal)
    for delay in combs:
        buf = [0.0] * delay
        store, idx = 0.0, 0
        for i, x in enumerate(signal):
            y = buf[idx]
            store = y * (1 - damp) + store * damp
            buf[idx] = x * 0.015 + store * feedback
            idx = (idx + 1) % delay
            out[i] += y
    for delay in allpasses:
        buf = [0.0] * delay
        idx = 0
        for i, x in enumerate(out):
            b = buf[idx]
            buf[idx] = x + b * 0.5
            out[i] = b - x
            idx = (idx + 1) % delay
    return [d + w * wet for d, w in zip(signal, out)]


def finish(signal, peak=0.9, fade=0.04):
    """Cuts the sub-bass speakers can't play (it only eats headroom), normalizes to `peak` and fades the last `fade`
    seconds, so a region ends in silence."""
    signal = filt(signal, "highpass", CLEAN_LOW, passes=2)
    top = max(1e-9, max(abs(x) for x in signal))
    signal = [x * peak / top for x in signal]
    n = samples(fade)
    for i in range(n):
        signal[-1 - i] *= i / n
    return signal


# --- the cues --------------------------------------------------------------------------------------------------------

def gun_shot(rng):
    """One round of the machine pistol: a hard click, a bright crack, a mid bark, a saturated low thump, the bolt's
    small metallic tick, then a short dark room tail."""
    d = 0.55
    click = mul(filt(white(0.002, rng), "highpass", 2000), env(0.002, 0.0002, 0.0006))
    crack = mul(filt(white(d, rng), "highpass", 2600), env(d, 0.0004, 0.014))
    bark = mul(filt(white(d, rng), "bandpass", 950, 1.1), env(d, 0.001, 0.05))
    body = softclip(mul(tone(d, glide(170, 68, 0.06)), env(d, 0.002, 0.04)), 2.2)  # short: a machine pistol snaps
    bolt = modal(d, [(2400, 0.16, 0.03), (3650, 0.1, 0.02), (5100, 0.05, 0.015)], rng, delay=0.022)
    dry = softclip(total(d, scale(click, 1.0), scale(crack, 1.0), scale(bark, 0.9), scale(body, 0.75), bolt), 1.8)
    room = filt(reverb(dry, size=0.55, damp=0.55, wet=0.35), "lowpass", 6500)
    return finish(room, 0.95)


def gun_reload(rng):
    """The magazine out (a click and a slide), the magazine in (a heavier clack), then the bolt racked back and home."""
    d = 1.35
    out = silence(d)
    mix(out, modal(0.08, [(3200, 0.5, 0.012), (4600, 0.3, 0.009)], rng), 0.05)
    mix(out, mul(filt(white(0.12, rng), "bandpass", 1500, 1.0), env(0.12, 0.01, 0.03)), 0.07, 0.5)
    mix(out, modal(0.12, [(1100, 0.6, 0.035), (1700, 0.4, 0.025), (2600, 0.25, 0.02)], rng), 0.6)
    mix(out, mul(tone(0.06, glide(170, 90, 0.03)), env(0.06, 0.001, 0.025)), 0.6, 0.6)
    mix(out, mul(filt(white(0.03, rng), "highpass", 1200), env(0.03, 0.0005, 0.006)), 0.6, 0.5)
    mix(out, mul(filt(white(0.09, rng), "bandpass", 2000, 1.2), env(0.09, 0.008, 0.025)), 0.95, 0.45)
    mix(out, modal(0.08, [(1800, 0.5, 0.03), (2900, 0.35, 0.02)], rng), 1.03)
    mix(out, mul(filt(white(0.07, rng), "bandpass", 2400, 1.2), env(0.07, 0.006, 0.02)), 1.07, 0.4)
    mix(out, modal(0.1, [(2100, 0.6, 0.035), (3300, 0.4, 0.025), (4700, 0.2, 0.015)], rng), 1.12)
    return finish(reverb(out, size=0.3, damp=0.5, wet=0.15), 0.8)


def surface_hit(rng):
    """A round striking stone: a sharp tick, a gritty chip, scattered debris and a faint fading whine."""
    d = 0.4
    tick = mul(filt(white(d, rng), "bandpass", 3200, 2.0), env(d, 0.0004, 0.006))
    chip = mul(filt(white(d, rng), "highpass", 1800), env(d, 0.001, 0.03))
    thump = mul(tone(d, glide(220, 120, 0.03)), env(d, 0.001, 0.025))
    debris = grains(d, 14, 0.012, 0.22, rng, band=(1500, 5200), amp=(0.35, 0.06))
    whine = mul(tone(d, glide(3400, 1800, 0.12)), env(d, 0.004, 0.05))
    dry = total(d, tick, scale(chip, 0.6), scale(thump, 0.4), debris, scale(whine, 0.06))
    return finish(reverb(dry, size=0.3, damp=0.5, wet=0.2), 0.85)


def body_hit(rng):
    """A round striking a body: a dull low thump and a muted slap with a little wet flutter (a hit, not gore)."""
    d = 0.35
    thump = softclip(mul(tone(d, glide(125, 66, 0.05)), env(d, 0.002, 0.06)), 2.5)
    slap = mul(filt(white(d, rng), "lowpass", 2200), env(d, 0.0008, 0.03))
    flutter = [0.6 + 0.4 * math.sin(2 * math.pi * 42 * i / SR) for i in range(samples(d))]
    wet = mul(mul(filt(white(d, rng), "bandpass", 620, 1.5), env(d, 0.003, 0.06)), flutter)
    dry = total(d, scale(thump, 0.8), scale(slap, 0.95), scale(wet, 0.35))
    return finish(filt(reverb(dry, size=0.2, damp=0.6, wet=0.12), "lowpass", 6000), 0.9)


def swing(rng, d, peak, low, high, fall, whomp):
    """A blade cutting the air: noise through a band-pass that sweeps up to `high` at the peak and back toward `low`,
    shaped like the swing's speed, with the faint ring of the blade on top."""
    span = high - low

    def centre(t):
        if t < peak:
            return low + span * (t / peak) ** 1.5
        return low + span * math.exp(-(t - peak) / (fall * 1.3))

    shape = bell(d, peak, 2.0, fall)
    air = mul(sweep(white(d, rng), "bandpass", centre, 2.2), shape)
    body = mul(filt(white(d, rng), "lowpass", 650), shape)
    ring = mul(tone(d, lambda t: high * 0.75 + 40 * math.sin(2 * math.pi * 9 * t)), mul(shape, shape))
    layers = [air, scale(body, 0.3), scale(ring, 0.07)]
    if whomp:
        layers.append(mul(tone(d, glide(95, 65, peak * 2)), shape))
    return finish(total(d, *layers), 0.8, 0.05)


def saber_swing(rng):
    return swing(rng, 0.42, 0.12, 500, 2700, 0.08, False)


def saber_swing_heavy(rng):
    return swing(rng, 0.62, 0.22, 350, 1700, 0.12, True)


def saber_hit(rng):
    """The edge biting: a bright slice and a short metallic shing over a body's thump and slap."""
    d = 0.45
    slice_ = mul(filt(white(d, rng), "highpass", 3000), env(d, 0.0005, 0.02))
    shing = modal(d, [(2150, 0.4, 0.12), (3380, 0.3, 0.09), (4870, 0.2, 0.07), (6900, 0.1, 0.05)], rng)
    thump = softclip(mul(tone(d, glide(95, 50, 0.05)), env(d, 0.002, 0.065)), 2.2)
    slap = mul(filt(white(d, rng), "lowpass", 1200), env(d, 0.001, 0.03))
    dry = total(d, scale(slice_, 0.8), shing, scale(thump, 0.8), scale(slap, 0.5))
    return finish(reverb(dry, size=0.4, damp=0.5, wet=0.22), 0.92)


def guard_block(rng):
    """Steel caught on steel: a hard strike and a dull, quickly damped clang."""
    d = 0.6
    strike = mul(filt(white(d, rng), "bandpass", 1800, 0.9), env(d, 0.0005, 0.01))
    f0 = 520
    clang = modal(d, [(f0, 1.0, 0.18), (f0 * 1.52, 0.7, 0.14), (f0 * 2.33, 0.5, 0.1), (f0 * 3.17, 0.35, 0.08),
                      (f0 * 4.1, 0.2, 0.06)], rng)
    thud = mul(tone(d, glide(140, 80, 0.04)), env(d, 0.002, 0.05))
    dry = total(d, strike, scale(clang, 0.55), scale(thud, 0.5))
    return finish(reverb(dry, size=0.45, damp=0.45, wet=0.25), 0.9)


def parry(rng):
    """A perfect parry: a bright clash ringing like a struck bell, its partials beating slightly, with a spark of air."""
    d = 1.1
    strike = mul(filt(white(d, rng), "highpass", 2000), env(d, 0.0003, 0.008))
    f0 = 880
    ring = modal(d, [(f0, 1.0, 0.9), (f0 + 3.5, 0.5, 0.8), (f0 * 2.76, 0.6, 0.6), (f0 * 5.4, 0.4, 0.4),
                     (f0 * 8.93, 0.25, 0.3), (f0 * 1.5, 0.3, 0.5), (f0 * 3.9, 0.2, 0.35)], rng)
    sparkle = mul(filt(white(d, rng), "highpass", 6000), env(d, 0.001, 0.05))
    dry = total(d, strike, scale(ring, 0.5), scale(sparkle, 0.2))
    return finish(reverb(dry, size=0.6, damp=0.35, wet=0.3), 0.9)


def blood_blade_cast(rng):
    """The blood crescent leaving the blade: a wet, rising whoosh, a gurgling body, a low pulse and a thin sizzle."""
    d = 0.65
    shape = bell(d, 0.15, 1.5, 0.12)
    whoosh = mul(sweep(white(d, rng), "bandpass", lambda t: 300 + 1100 * math.exp(-((t - 0.15) / 0.12) ** 2), 1.6), shape)
    wobble = [0.55 + 0.45 * math.sin(2 * math.pi * 28 * i / SR + 2 * math.sin(2 * math.pi * 3 * i / SR))
              for i in range(samples(d))]
    gurgle = mul(mul(filt(white(d, rng), "lowpass", 500), env(d, 0.02, 0.2)), wobble)
    pulse = mul(tone(d, lambda t: 72), env(d, 0.03, 0.25))
    gate = [1.0 if rng.random() < 0.08 else 0.15 for _ in range(samples(d))]
    sizzle = mul(mul(filt(white(d, rng), "highpass", 5000), env(d, 0.01, 0.15)), gate)
    dry = total(d, scale(whoosh, 0.8), scale(gurgle, 0.35), scale(pulse, 0.5), scale(sizzle, 0.12))
    return finish(reverb(dry, size=0.45, damp=0.5, wet=0.2), 0.85)


def blood_blade_impact(rng):
    """The crescent bursting: a heavy thump, a wet splash, scattered droplets and a settling mist (stylized)."""
    d = 0.7
    thump = softclip(mul(tone(d, glide(120, 58, 0.07)), env(d, 0.002, 0.08)), 2.5)
    splash = mul(filt(white(d, rng), "lowpass", 3500), env(d, 0.002, 0.12))
    drops = grains(d, 18, 0.02, 0.45, rng, band=(1200, 4000), length=(0.005, 0.012), q=4.0, amp=(0.3, 0.05))
    mist = mul(filt(white(d, rng), "bandpass", 800, 0.7), env(d, 0.03, 0.3))
    dry = total(d, thump, scale(splash, 0.7), drops, scale(mist, 0.15))
    return finish(reverb(dry, size=0.55, damp=0.45, wet=0.3), 0.92)


def chord(d, freq_at, amp_at, partials=((1, 1.0), (2, 0.5), (3, 0.3), (5, 0.15)), detune=1.004):
    """A shimmering tone: harmonic partials, each doubled slightly sharp so it beats."""
    out = silence(d)
    for k, a in partials:
        for ratio, gain in ((1.0, 1.0), (detune, 0.6)):
            mix(out, tone(d, lambda t, k=k, r=ratio: freq_at(t) * k * r), 0.0, a * gain)
    return mul(out, [amp_at(i / SR) for i in range(samples(d))])


def light_beam_charge(rng):
    """Light gathering in the crystal: a shimmering chord rising an octave, air swelling, a bright tick as it arms."""
    d = 0.45
    rise = chord(d, lambda t: 220 * 2 ** (t / d), lambda t: (t / d) ** 1.5)
    air = mul(filt(white(d, rng), "highpass", 4000), [(i / samples(d)) ** 2 for i in range(samples(d))])
    tick = modal(d, [(3520, 0.6, 0.03), (5280, 0.3, 0.02)], rng, delay=0.42)
    return finish(total(d, rise, scale(air, 0.15), tick), 0.75, 0.01)


def light_beam_loop(rng):
    """The beam held: a bright drone that loops seamlessly (every partial and every wobble repeats exactly each
    LOOP seconds) with a breath of air; the noise is crossfaded across the seam."""
    loop = 1.2
    n = samples(loop)
    base = 440.0  # 528 cycles a loop: every partial and its beating partner close on themselves
    drone = silence(loop)
    for k, a in ((1, 1.0), (2, 0.45), (3, 0.3), (4, 0.15)):
        for f, gain in ((base * k, 1.0), (base * k + 2.5 * k, 0.55)):
            cycles = round(f * loop)
            mix(drone, tone(loop, lambda t, c=cycles: c / loop), 0.0, a * gain)
    wobble = [0.8 + 0.2 * math.sin(2 * math.pi * 5 * i / n) for i in range(n)]
    drone = mul(drone, wobble)
    extra = samples(0.1)
    air = filt(white(loop + 0.1, rng), "bandpass", 2600, 3.0)
    seam = [air[i] if i >= extra else air[i] * (i / extra) + air[n + i] * (1 - i / extra) for i in range(n)]
    return finish(total(loop, drone, scale(seam, 0.25)), 0.7, 0.0)


def light_beam_end(rng):
    """The beam collapsing: the chord falling an octave and fading, a soft low whoomp, air draining away."""
    d = 0.55
    fall = chord(d, glide(440, 220, 0.3), lambda t: math.exp(-t / 0.12))
    whoomp = mul(tone(d, glide(90, 50, 0.1)), env(d, 0.005, 0.15))
    air = mul(filt(white(d, rng), "highpass", 3000), env(d, 0.0, 0.2))
    dry = total(d, fall, scale(whoomp, 0.6), scale(air, 0.1))
    return finish(reverb(dry, size=0.5, damp=0.4, wet=0.3), 0.75)


# Cue name -> (maker, extra region data). Peak: when a swing's whoosh peaks, so the game can line it up with the hit.
CUES = [
    ("GunShot", gun_shot, {}),
    ("GunReload", gun_reload, {}),
    ("SurfaceHit", surface_hit, {}),
    ("BodyHit", body_hit, {}),
    ("SaberSwing", saber_swing, {"Peak": 0.12}),
    ("SaberSwingHeavy", saber_swing_heavy, {"Peak": 0.22}),
    ("SaberHit", saber_hit, {}),
    ("GuardBlock", guard_block, {}),
    ("Parry", parry, {}),
    ("BloodBladeCast", blood_blade_cast, {}),
    ("BloodBladeImpact", blood_blade_impact, {}),
    ("LightBeamCharge", light_beam_charge, {}),
    ("LightBeamLoop", light_beam_loop, {"Loop": True}),
    ("LightBeamEnd", light_beam_end, {}),
]


def existing_id(sheet_hash):
    """The uploaded id in the current SoundSheet.luau, kept only if it was recorded for this exact audio."""
    if not os.path.exists(LUAU):
        return ""
    text = open(LUAU, encoding="utf-8").read()
    found_hash = re.search(r'Hash = "([0-9a-f]+)"', text)
    found_id = re.search(r'Id = "([^"]*)"', text)
    if found_hash and found_id and found_hash.group(1) == sheet_hash:
        return found_id.group(1)
    return ""


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else os.path.join(REPO, "build", "audio")
    os.makedirs(out_dir, exist_ok=True)
    sheet = silence(LEAD)
    regions = []
    for index, (name, maker, extra) in enumerate(CUES):
        sound = maker(random.Random(1000 + index))
        start = len(sheet) / SR
        sheet.extend(sound)
        regions.append((name, round(start, 4), round(len(sheet) / SR, 4), extra))
        sheet.extend(silence(GAP))
        print(f"  {name:<17} {start:6.3f} - {len(sheet) / SR - GAP:6.3f} s")
    pcm = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in sheet)
    sheet_hash = hashlib.sha1(pcm).hexdigest()[:16]
    wav_path = os.path.join(out_dir, "bl_combat_sounds.wav")
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm)
    upload_id = existing_id(sheet_hash)
    lines = [
        "--!strict",
        "-- SoundSheet: GENERATED by tools/audio/sound_sheet.py; don't edit the regions by hand. The combat cues are regions",
        "-- of one uploaded audio file, so a whole batch costs one upload. Id is that upload, as \"rbxassetid://<id>\" (the owner bulk-imports",
        "-- build/audio/bl_combat_sounds.wav); the tool keeps it while the audio's Hash is unchanged. Volumes and the rest",
        "-- of each cue's tuning live in Definitions/Sounds.",
        "",
        "return {",
        f'\tId = "{upload_id}",',
        f'\tHash = "{sheet_hash}",',
        "\tRegions = {",
    ]
    for name, start, end, extra in regions:
        fields = [f"From = {start}", f"To = {end}"] + [f"{k} = {str(v).lower() if isinstance(v, bool) else v}" for k, v in extra.items()]
        lines.append(f"\t\t{name} = {{ {', '.join(fields)} }},")
    lines += ["\t},", "}", ""]
    with open(LUAU, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))
    print(f"wrote {wav_path} ({len(sheet) / SR:.2f} s, hash {sheet_hash}); {LUAU} (id {'kept' if upload_id else 'empty: upload needed'})")


if __name__ == "__main__":
    main()
