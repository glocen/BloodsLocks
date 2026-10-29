# BloodsLocks

A PvPvE Roblox action game inspired by FromSoftware's *The Duskbloods* (inspiration only: names, art and lore are our own). Director: **glocen**. Budget: **0 €** until the game earns revenue, so everything is custom and free.

The game itself lives in Roblox Studio (castle hub place "ROLOCK"). This repo is the team's shared brain: the plan, research, decisions, tools and handoff notes for everyone working on it (the owner, Claude, ChatGPT).

## Start here

| File | What it is |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Working rules from the owner + Studio gotchas. **Every AI teammate reads this first.** |
| [docs/engineering-plan.md](docs/engineering-plan.md) | Source of truth: locked decisions, systems, code architecture, build-step table |
| [docs/team-notes.md](docs/team-notes.md) | Handoff log between teammates, newest first. Add an entry after every piece of work. |
| [docs/duskbloods-manual-summary.md](docs/duskbloods-manual-summary.md) | **The official Duskbloods manual, summarized**: our main inspiration, mapped to BloodsLocks |
| [docs/duskbloods-reference.md](docs/duskbloods-reference.md) | Research on how Duskbloods works, with sources |
| [docs/ui-research.md](docs/ui-research.md) | UI research, the "Vigil gothic" style, the UI architecture |
| [tools/](tools/) | Our own asset tools (e.g. `vfx_textures.py` draws the VFX textures) |
| [assets/](assets/) | Notes on generated assets |

## Team

- **glocen**: director, owner, final say.
- **Claude**: engineering (systems, infrastructure, UI code, quality).
- **ChatGPT**: 3D world building in Blender (via the Blender MCP).

## Rules of the road

1. Read `CLAUDE.md` and the latest entries in `docs/team-notes.md` before starting.
2. Locked decisions in the plan change only with the owner's OK.
3. Nothing that costs money: ask the owner first.
4. Leave a team-notes entry when you finish something: what changed, where it lives, what's open.
