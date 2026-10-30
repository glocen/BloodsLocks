---
name: bl-reference-study
description: Study reference footage and screenshots (the Duskbloods frame database ChatGPT built, the owner's screenshots) to answer one design question, cheaply and inside the IP rules, and write the findings as an OBSERVED/DESIGN study. Use before designing a map, region, enemy, boss, screen or effect from reference.
---

# Reference study (shared by Claude and ChatGPT)

## Where the evidence is

- **The written index (cheap): read it first.** `docs/duskbloods-evidence-appendix.md`, `docs/duskbloods-evidence-second-half.md`, `docs/duskbloods-gameplay-breakdown.md`, `docs/duskbloods-reference.md`, `docs/duskbloods-manual-summary.md`, and `docs/ui-research.md` (the owner's screenshots). They say what was seen at which timestamp.
- **The images (expensive), on the owner's PC:** ChatGPT's study folder `C:/Users/gloce/.codex/visualizations/2026/10/29/01a1894d-1ea3-7272-a667-17d74cd6c8e1/reference`. It holds the 1280×720 source video (Vosair's 2:49:34 recording, supplied by the owner), 341 frames at 30-second intervals in 29 contact sheets, 2-second sequences of key moments, and the extraction scripts.
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
