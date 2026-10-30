# Victorian map: design brief

Claudius (lead designer), 2026-10-30. The owner: "we still don't have the Victorian map I want." This brief is how we get it. Claude does the work (team mode: Claude only), Claudius reviews it against the vision, and the owner chooses.

## What we have

- **The first zone, the Cathedral Quarter:** ChatGPT's spec ([cathedral-quarter-spec.md](CathedralQuarter/cathedral-quarter-spec.md): a 480 × 500-stud envelope, four regions per D8) and Claude's W1 blockout ([w1-blockout.md](CathedralQuarter/w1-blockout.md), built by the `CathedralQuarter` generator).
- **ChatGPT's art rebuild,** started on 10-30 and stopped mid-way. Backup: `ServerStorage.WorldBackups.PreArtRebuild_20261030`; its handoff file is uncommitted on the owner's PC.
- **D10:** the first loop is built on the Cathedral Quarter alone, and more districts join through its sockets after M5. Changing that is the owner's call.
- **The reference evidence:** the written study in `docs/duskbloods-*` and the images in ChatGPT's study folder (`/bl-reference-study`).

## The goal

A Victorian match map with the reference's quality and feel, and entirely our own city: monumental gothic silhouettes over human-scale streets, a city you can climb, and regions that each have their own mood.

## Step 1: reference study

Use `/bl-reference-study` and write `worlds/Victorian/reference-study.md`, answering:

1. **The whole map.** How many regions the match map shows, how big they are against the player and each other, and how they connect. The region-select map appears around 54:15–54:59, 1:00:36–1:01:46, 1:25:00, 1:39:00, 1:46:00, 1:52:30, 2:05:30 and 2:12:00, and the map tutorial around 14:00–17:30.
2. **Region identities.** The kinds of places (cathedral and nave, bridges, underground, forest edge, clock tower, sunken court, the flower garden of the final), and what makes each read as its own place: materials, light, density, height.
3. **Verticality.** How many walking layers, how players move between them, and how tall landmarks are against the jump kit (`src/shared/Config/Movement.luau`).
4. **Flow.** How long a region takes to cross, where fights happen, how routes rejoin.
5. **Phases.** How light and atmosphere change from phase I to the final.
6. **From above.** How the map reads on the map screen, which drives our intermission map.

## Step 2: three original concepts

Close the images. From the study and our city's own story, draw three different concepts: a top-down sketch each (SVG, like the Cathedral Quarter set) plus one player-view sketch.

- **A.** The Cathedral Quarter is the heart and gets finished first; the city grows from its sockets later (keeps D10).
- **B.** The whole city now: the Quarter plus new districts at the reference's scale (changes D10).
- **C.** A bold alternative of your own.

For each: scale in studs; regions with our own names and identities; walking layers and key routes; where ritual sites, pact circles, spawns, enemy groups and the final arena go; the movement envelope (`worlds/world-contract.md`); a part and light budget; how it passes the fan test; what it keeps or retires from the W1 blockout and ChatGPT's rebuild. Critique each one harshly against the vision and the IP list, then show the owner, who picks or mixes.

## Step 3: spec, then build

The chosen concept becomes the spec (update or replace the Cathedral Quarter spec; archive the old one, never lose it). Then the blockout through the generator, gameplay first (routes, heights, markers, probe), then the art through `/bl-asset-pipeline` and `/bloodlocks-environment-art`, one hero bay before anything is replicated.

## Done when

- The owner says it's the map he wants, from the player's camera in Studio.
- The world report is clean, the route probe passes, and 8 players plus enemies stay inside the frame budget.
- It passes the fan test, and every name is ours.
