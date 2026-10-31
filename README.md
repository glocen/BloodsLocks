# BloodsLocks

A PvPvE Roblox action game inspired by FromSoftware's *The Duskbloods* (inspiration only: names, art and lore are our own). Director: **glocen**. Budget: **0 €** until the game earns revenue, so everything is custom and free.

The game lives in Roblox Studio (the Manor hub, place "ROLOCK", and the Victorian match place). This repo is the team's shared brain: the rules, plan, research, decisions, tools and handoff notes for everyone working on it (the owner, Claude, ChatGPT), plus the framework code in `src/`, synced into every place with [Rojo](https://rojo.space).

## Start here

| File | What it is |
|---|---|
| [AGENTS.md](AGENTS.md) | The rules every AI teammate follows. Codex loads it automatically; Claude loads it through [CLAUDE.md](CLAUDE.md), which adds the Claude-only Studio essentials |
| [docs/team-notes.md](docs/team-notes.md) | The "Now" board (current state, open asks) and the handoff log, newest first |
| [docs/production-plan.md](docs/production-plan.md) | What's next, and the status of each milestone |
| [docs/engineering-plan.md](docs/engineering-plan.md) | Source of truth: locked decisions, systems, code architecture |
| [docs/duskbloods-manual-summary.md](docs/duskbloods-manual-summary.md) | **The official Duskbloods manual, summarized**: our main inspiration, mapped to BloodsLocks |
| [docs/duskbloods-reference.md](docs/duskbloods-reference.md) | Research on how Duskbloods works, with sources |
| [docs/ui-research.md](docs/ui-research.md) | UI research, the "Vigil gothic" style, the UI architecture |
| [worlds/world-contract.md](worlds/world-contract.md) | What the game code reads from a world (markers, map, Antechamber, checks) |
| [docs/asset-log.md](docs/asset-log.md) | Receipts: who made each asset, and how |
| [docs/github-sync-lesson.md](docs/github-sync-lesson.md) | **How we sync**: git routine, Rojo, restoring old versions |
| [src/](src/) | The framework code (Rojo; mapping in `default.project.json`) |
| [tools/](tools/) | Our own asset tools (e.g. `vfx_textures.py` draws the VFX textures) |
| [assets/](assets/) | Notes on generated assets |
| `docs/archive/` | History: old team notes, session logs, finished audits |

## Team

- **glocen**: director, owner, final say. The vision and every decision; the data system and the original modules in `src/owner/`.
- **Claudius**: lead designer (Claude, in the owner's claude.ai project). The team's foundation (`AGENTS.md`, the rules and the skills) and the Victorian map brief.
- **Claude**: builds the game (Claude Code). The framework and the systems in `src/`, the match, the UI and VFX, the asset pipeline, Gustave's machine pistol, the Cathedral Quarter blockout.
- **Claude (cloud)**: Claude Code on the web, from the owner's phone. Static checks, plans and specs, research, tools and reviews, through pull requests (`docs/cloud-tasks.md`).
- **ChatGPT**: world artist (Codex), when the owner switches it on. The whole-game brief, the UI quality standard, the Duskbloods evidence study, the Cathedral Quarter spec, the Manor art studies, Gustave's animation sources.

Who works on what, and the current team mode: [AGENTS.md](AGENTS.md).

## Rules of the road

All of them live in [AGENTS.md](AGENTS.md).
