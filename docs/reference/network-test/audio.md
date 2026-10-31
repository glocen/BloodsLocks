# Sound: the reference's music and effects, measured

What the recording's audio does, so our library picks (`tools/studio/Audio`) and, later, our music aim at the same qualities. **Inspiration only** (owner, 2026-10-31: "it js inspiration NO 1:1 copy"): we take qualities (weight, dynamics, how hits sit over the music, where silence falls), never their recordings, melodies, motifs or sounds (AGENTS.md rule 3). The extracted audio stays local (`build/reference/`, gitignored): never in the game or the repo, never uploaded.

## Method

- **Spans:** 23 minutes of the recording (0:00–1:23, 2:00–3:41, 4:00–6:23, 9:00–10:35, 10:36–13:00, 13:48–15:11, 16:00–16:47, 18:24–20:47, 27:36–28:47, 33:36–34:47, 36:00–37:59, 44:00–45:11, 48:48–52:23), plus the owner's whole Albert clip (2:16, the final).
- **Measured, never heard** (Claude can't listen): `tools/reference/audio.py` (run with Blender's Python for numpy).
  - It measures loudness (RMS dBFS; 3 s windows for the range), stereo width, brightness (spectral centroid; band shares through the same filters as `Waveform.luau`), and a rough key and tempo.
  - It also lists transients: onset, attack, decay, and bands above the music bed.
  - The spectrogram sheets were read by eye. "Tonal, sustained" means harmonic stacks (orchestra, choir, organ or pads); instruments aren't named.
- **Limits:**
  - Tempo is never clear (confidence z under 4 in every span): no steady beat was found.
  - Key estimates are rough, so none is quoted.
  - Decays end where a hit sinks into the music, so they're lower bounds.
  - The Albert clip is near mono (side 43 dB under mid) and dull above a few kHz, so its brightness isn't comparable.

## The mix (OBSERVED)

- **Fights play loud and squeezed:** −16 to −22 dBFS RMS, with a loudness range of only 2–6 dB (the boss fight at 16:00 is the loudest and flattest: −16.7, 2.4 dB). Films and transitions open up to 10–34 dB of range.
- **Dark and heavy:** the spectral centroid sits at 180–700 Hz in every span, and the low band holds most of the energy. The sound world is weight and body, not sparkle.
- **Hits cut through the music** by 10–19 dB. The big skill is the loudest thing in its span: 18–22 dB over the bed (Blood Blade, 28:29–28:36).
- **Stereo:** moderate width (the side channel 3–12 dB under the mid).
- **Silence frames the big moments:** the black loading screen (0:27–0:37), before the hub reveal (11:11–11:14), between the phase end and the final (50:05–50:17).

## Music by moment (OBSERVED)

| Moment | Time | What the measures and spectrogram show |
|---|---|---|
| Title screen | 0:00–0:27 | Warm, tonal, sustained harmony with a strong low register; stops dead at the loading screen. |
| Opening film | 0:37–1:23 | A soft broadband bed (room or weather), then low tonal chords punctuated by a few sharp stingers. |
| The rite and the arrival | 2:04–2:46 | A sharp swell at 2:04, then a 40-second crescendo as the circle grows, peaking 2:20–2:30 (bright, dense, loudest), then a slow decay. Cut to silence at the first control (2:47). |
| Tutorial play | 2:47–3:41 | A steady tonal bed under play; hits on top. |
| Cathedral film, the rival | 4:37–5:51 | Sparse: low drones, gaps of silence, single sharp foley hits. |
| A duel | 5:52–6:23 | The music kicks in at once as a dense, loud wall (−19.5 dBFS, 2.9 dB range); hits stack on it. |
| The hub reveal | 11:14–11:36 | A huge slow orchestral swell over ~16 s, then a long fade into a quiet ambient bed. |
| The hub | 12:21–13:00 | Quiet (−32 dBFS), calm sustained chords, a slow pulse of footsteps. |
| Phase I | 13:48–14:33 | A continuous bed with a clear melodic line in the mids; denser once the great foe engages. |
| Phase end and the tally | 37:00–37:24 | A short fade, then sustained low chords under the Renown tally: deep ticks one second apart, closing on a long chime (2.9 s). |
| Phase III at night | 44:00–45:11 | A slower, calmer bed (the only span with a ~60 BPM pulse, weak). |
| The phase III end to the final | 49:52–50:17 | A decaying tonal stinger (~13 s), silence, a falling sweep, silence, then the final's wall. |
| The final | 50:17–51:45 | The densest, loudest music of the match, without a break (also the Albert clip: −16 dBFS, 3.8 dB range). |
| Victory and the outcome | 51:48–52:23 | Drops to a low drone with a faint high line, then calm tonal music under the outcome screen. |

## Effects (OBSERVED)

| Effect | Time | Shape |
|---|---|---|
| Blade hits and clashes | 5:59–6:19 | Instant attack (≤ 0.02 s), gone within 0.02–0.12 s; mid-heavy (low 15–45 %, mid 45–70 %, high 5–27 %). Crisp and short, so a flurry stays readable. |
| Heavy impacts (axe, fire wave) | 6:01–6:20 | Attack ≤ 0.05 s; tails 0.4–1.6 s; low-heavy (low 50–76 %). |
| Gunshots | 6:10, 10:10 | +14–19 dB over the bed; low-mid body (low ~55 %) with a bright crack after (high ~24 %). |
| Blood Blade | 28:29–28:36 | The loudest events: +14–22 dB, tails 1.1–2.5 s, low 48–74 %. |
| The bite | 28:41–28:46 | Three low thumps (low 67–83 %), +10–12 dB, gone within 0.16–0.32 s: weight, never a bright or wet sound. |
| The Renown tally | 37:12–37:15 | Deep ticks one second apart (low 62 %), then a long chime. |

## What we take (DESIGN)

- **Weight first.** Every combat sound gets low-mid body: blade hits are crisp and short but not thin; gunshots boom; big skills roar with long low tails. The `Briefs` band targets follow this.
- **Short where it repeats.** Blade hits and swings end fast, so combos never smear.
- **Loudness by importance.** Big skills and the parry sit on top (cue `Volume`); everything plays at a measured, equal base level (`Level`).
- **Silence before big moments**, when we build the match music: the loading passage, before the hub reveal, before the final.
- **Music, later** (from the library's licensed tracks, the same audition route):
  - slow, tonal, sustained gothic harmony with no driving beat;
  - a calm hub, and a steady bed under exploration;
  - an instant wall for duels and the final;
  - a stinger and then silence at phase ends, deep ticks under the tally.

  Never their melodies, motifs or recordings.
