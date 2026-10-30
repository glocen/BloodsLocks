# Lesson: sharing our work through GitHub and Rojo

Goal: one folder, `C:\Users\gloce\BloodsLocks`, is a copy of the GitHub repo [glocen/BloodsLocks](https://github.com/glocen/BloodsLocks). Claude and ChatGPT both read and write there, Rojo sends its code into every Studio place, and git keeps every old version so nothing can be lost. Everything here is free.

## The idea in 30 seconds

- **The repo is the shared brain.** Plans, research, handoff notes, session logs, tools, and the framework code (`src/`).
- **pull** = download what the others pushed. **commit** = save a snapshot. **push** = upload your snapshots. **tag** = a name on a snapshot (`framework-v1`) so we can always return to it.
- Always **pull before you start** and **push when you stop**.

## Part 1: setup (done 2026-10-29)

- Git 2.56, Rokit and Rojo 7.7.1 are installed. VS Code has the Rojo and Luau LSP extensions.
- The repo lives in `C:\Users\gloce\BloodsLocks`, **not in Documents**. Windows' ransomware protection (Controlled Folder Access) blocks git and Rojo from writing in Documents, and this way we don't have to weaken it.
- The old `Documents\BloodsLocks - Project` folder is only a backup now. Don't work in it.
- **Open the project:** VS Code → File → Open Folder → `C:\Users\gloce\BloodsLocks`.
- If git ever asks who you are, run the next two commands (with your GitHub noreply email from GitHub → Settings → Emails):

```bash
git config --global user.name "glocen"
```

```bash
git config --global user.email "92930182+glocen@users.noreply.github.com"
```

## Part 2: every work session

In VS Code's terminal (Terminal → New Terminal), inside `C:\Users\gloce\BloodsLocks`:

| When | Command | Why |
|---|---|---|
| Before you start | `git pull` | Get what Claude / ChatGPT pushed |
| After a piece of work | `git add -A` then `git commit -m "what changed"` | Save a snapshot |
| When you stop | `git push` | Share it |

VS Code's Source Control tab (the branch icon on the left) does the same with buttons: ⟳ to pull/push, ✓ to commit.

If `git pull` reports a **conflict**, ask Claude "resolve the git conflict". Nothing is lost.

## Part 3: our conversations in the repo

**Don't push raw chat transcripts.** The repo is **public**. Raw transcripts are huge, full of tool noise, and contain personal details (email, PC paths). `.gitignore` blocks `*.jsonl` so they can't slip in.

**Do push short summaries** of what each session did. That's what the other AI actually needs.

- Since 2026-10-30 the summary is a short entry in `docs/team-notes.md` plus its "Now" board (the rules are in `AGENTS.md`). The old session logs are in `docs/archive/sessions/`.
- Claude writes it as part of `/bl-finish`; ChatGPT as part of its `bl-world-session` skill.
- Then commit and push (Part 2).
- **Starting a session:** Claude runs `/bl-start`; ChatGPT runs `bl-world-session`. Both read the "Now" board, not the history.

## Part 4: folder layout

| Folder | What goes there | Who writes |
|---|---|---|
| `docs/` | plan, research, team notes | everyone |
| `docs/archive/` | history: old notes, session logs, finished audits | everyone |
| `src/` | the framework code, synced into Studio by Rojo | Claude |
| `src/owner/` | your keep list (Data, Libraries, Modules, Events) | ask before replacing |
| `worlds/<World>/` | world-only tools and notes (Manor, Victorian, ...) | ChatGPT + Claude |
| `tools/` | our own asset scripts | everyone |
| `.claude/`, `.agents/skills/` | the AI rules and skills (Claude's and the shared ones) | everyone |
| `assets/` | notes and ids for uploaded assets | everyone |

## Part 5: Rojo (the code ↔ Studio bridge)

**The rule: code is edited in the files, never in Studio's script editor.** Rojo copies the files into Studio live. A change typed into Studio's editor gets overwritten on the next sync.

**Connect a place (Manor or Victorian):**
1. In VS Code: open the command palette (Ctrl+Shift+P) → **Rojo: Open menu** → **Start** on `default.project.json` (or run `rojo serve` in the terminal).
2. In Studio: Plugins tab → **Rojo** → **Connect**. The code in `src/` now appears in the place and stays in sync.
3. Only the framework folders are managed. Your world builds, lighting, `ServerStorage.WorldTools` and the like are never touched.

**Go back to an old version when something breaks:**

| You want | Command |
|---|---|
| See the history | `git log --oneline` |
| See the named versions | `git tag` |
| Bring all the code back to a version (Rojo pushes it into Studio right away) | `git checkout framework-v0 -- src` |
| Undo that and return to the newest | `git checkout HEAD -- src` |
| Throw away code changes you haven't committed | `git restore src` |

Restoring makes a normal change you can commit, so the history is never rewritten and nothing is deleted.

**Named versions:**
- `framework-v0`: the hub's code exactly as exported on 2026-10-29, before the fix pass.
- `framework-v1`: will be the fixed, "perfect" framework that each world copies.

**Upgrading a world:** connect that place with Rojo and it gets the current `src/`. To pin a world to a named version, check out that tag first.

**If someone edited code inside Studio anyway:** save the place to a file (File → Save to File As) and ask Claude to run `rojo syncback` to pull those edits into `src/`.

## Golden rules

1. Pull before you start, push when you stop.
2. Code changes go in `src/` files, not Studio's editor.
3. Never commit passwords, API keys, cookies or `.ROBLOSECURITY`. The repo is public.
4. One topic per commit, with a message that says what changed.
5. Before a risky change, tag the current version. Git keeps everything, so ask before deleting anything.
