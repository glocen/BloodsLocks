# The network-test reference: our study of the full recording

The monolith (owner, 2026-10-30): what we learned from the full Duskbloods network-test recording, organized by topic, so every system, screen, world and effect we build can be measured against it. It replaces ChatGPT's 30-second survey (`docs/duskbloods-evidence-appendix.md`, `docs/duskbloods-evidence-second-half.md`) for the part it covers, at the owner's request.

## Source

- **The recording:** Vosair's network-test session (tutorials, the hub, several matches). 2:49:34 long, 1920×1080 at 60 fps, 5.3 GB, with stereo audio.
- **Where:** the owner's file `C:\Users\gloce\Videos\duskbloodsfullreference.mp4`; the original upload is <https://www.youtube.com/watch?v=8Dyw5O2zyiY>.
- **Covered so far: 0:00–52:23, one full playthrough** (the opening, four tutorial matches, the last one a complete four-phase match with its final, victory and outcome, and the class screen). The owner stopped the study there (2026-10-30): the rest is more matches, to study when a slice needs it ([takeaways.md](takeaways.md) §8).

## Method

- **Survey:** one frame every second, stamped with the source time, tiled 4×3 into sheets of 12 s (848 sheets for the whole recording; sheet *n* covers (n−1)·12 s to n·12 s). The tiles are 480 px wide, big enough to read poses and effects (owner: "make sure it's very readable").
- **Bursts:** every frame of a short span (5–30 fps), cropped on the action, where motion, timing or an effect's layers matter.
- **Full frames:** 1080p stills for scenery, UI and detail.
- **The tool:** `tools/reference/frames.py` (survey, frames, burst). Frames live in `build/reference/network-test/`, local and gitignored: the repo is public, and frames are study evidence only.
- **Ignore the VOSAIR mark** in the lower right (the uploader's watermark, not game UI) and the scrolling network-test notice (test-only).
- **Limits:**
  - Stills can't show motion between samples; timings come from bursts and are stated with their frame rate.
  - Audio wasn't listened to; nothing here describes sound.
  - Dialogue and item texts are paraphrased, never transcribed; short UI labels are quoted as seen.

**Labels:** **OBSERVED** (seen in a frame; with its timestamp), **MANUAL** (the game's own tutorial cards, paraphrased), **WIKI** (Fextralife), **DESIGN** (our adaptation for BloodsLocks). Unknowns stay unknown: no guess is written as a measurement.

## The IP line (AGENTS.md, supreme rule 3)

- We study how it plays, feels and is laid out. Never their names, art, characters, icons, fonts, sounds or a 1:1 shot.
- The owner's aim for our UI and world: as close in quality and structure as the guardrail allows ("95% or 99% is fine but not 100%"). Our look is our own, and our own identity comes later.
- Rendering follows our own art direction ([production plan](../../production-plan.md), "The owner's direction"): stylized like Type Soul but more detailed and deeper, not their realistic graphics.
- Frames, crops and tracings never enter the game or the repo.

## Files

| File | What it holds |
|---|---|
| [timeline.md](timeline.md) | The playthrough second by second, in short sections: what's on screen, where, and when |
| [match-flow.md](match-flow.md) | The hub, starting a match, the intermission, phases, the clock, phase ends, the cull, the final, Virtue, growth, death, co-op, travel; timings |
| [scenery.md](scenery.md) | Time of day by phase; every region and space; light, props, verticality |
| [combat.md](combat.md) | The controls, Albert's kit, defence, posture and drinking blood, damage feedback, growth, the kin, the rivals, items |
| [movement.md](movement.md) | Jumps, air jumps, dodges, climbing, falls, travel, the camera |
| [vfx.md](vfx.md) | Every effect broken into its layers; the measured ones in detail; against ours |
| [animation.md](animation.md) | Poses and measured timings; what reads well |
| [ui.md](ui.md) | The style, the match HUD element by element, banners, every screen |
| [enemies.md](enemies.md) | Enemies, great foes, trespassers, companions, thralls, where encounters sit |
| [takeaways.md](takeaways.md) | DESIGN: what we build from all of it, slice by slice, and the owner's open decisions |
