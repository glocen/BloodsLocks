---
name: bl-reference-study
description: Study reference footage and screenshots (the network-test study in docs/reference/network-test, the owner's recordings and screenshots) to answer one design question, cheaply and inside the IP rules, and write the findings as an OBSERVED/DESIGN study. Use before designing a map, region, enemy, boss, screen or effect from reference.
---

# Reference study (shared by Claude and ChatGPT)

## Where the evidence is

- **The network-test study (read it first):** `docs/reference/network-test/` (2026-10-30). The full recording at 1080p60 surveyed every second for 0:00–52:23 (one full playthrough), with measured bursts, in topic files (match flow, scenery, combat, movement, VFX, animation, UI, enemies, takeaways). Its frames are local, in `build/reference/network-test/`; make more with `tools/reference/frames.py` from the owner's `C:\Users\gloce\Videos\duskbloodsfullreference.mp4`.
- **The older written index:** `docs/duskbloods-gameplay-breakdown.md`, `docs/duskbloods-reference.md`, `docs/duskbloods-manual-summary.md`, `docs/ui-research.md` (the owner's screenshots). ChatGPT's 30-second survey (`docs/duskbloods-evidence-appendix.md`, `docs/duskbloods-evidence-second-half.md`) is superseded by the study for 0:00–52:23 (owner, 2026-10-30) and stays useful only beyond it.
- **ChatGPT's older images**, on the owner's PC: `C:/Users/gloce/.codex/visualizations/2026/10/29/01a1894d-1ea3-7272-a667-17d74cd6c8e1/reference` (a 1280×720 copy of the recording, 341 frames at 30-second intervals, 2-second sequences, and the ffmpeg build the study tool uses).
- **Study evidence only:** never copy frames, crops or traced shapes into the game or the repo. Git keeps our notes and our own drawings.

## Study without wasting tokens

1. Write the question down first, for example: "how is the match map structured: how many regions, how big, how they connect, how vertical?"
2. Search the written docs for the timestamps that answer it. Open only the images the docs point to, or the ones needed for what the docs can't answer.
3. Contact sheets before single frames: one sheet shows many moments. Then open only the frames that matter, as downscaled copies in the scratchpad (about 1280 px wide is plenty), never the video itself. Extract a new frame only for a gap the sheets can't fill, with the existing scripts.
4. Stop when the question is answered, and list the images you looked at, so nobody repeats the work.

## What to record

- Write the study where the task says (for example `worlds/<World>/reference-study.md`): each finding with its timestamp and a label: OBSERVED (seen in an image), MANUAL (the official guide) or DESIGN (our adaptation). Unknowns stay unknown; never present a guess as a measurement.
- Capture structure, not appearance: scale against the player and the jump kit, the number and size of regions, how regions connect, the walking layers, landmark rhythm and sightlines, route types (street, roof, interior, underground), where fights happen, light and atmosphere per phase, and how the map reads from above on the map screen.

## The IP line (AGENTS.md, supreme rule 3)

- Learn how it plays and feels; never copy their layout, region shapes, landmarks, names, or a specific shot 1:1. Our design must pass the fan test: nobody could point at a part of it and name the place it came from.
- Close the images before designing. Design from your written findings and our own world (its own history, our names), then compare: if anything echoes theirs, change it.
