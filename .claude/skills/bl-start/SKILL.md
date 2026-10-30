---
name: bl-start
description: Start a BloodsLocks working session - sync git safely, get Rojo and the Studios ready, read only the current state, confirm the slice. Use once at the start of a session or when the owner says to start.
---

# Start a session

1. **Git.** `git status`, then `git fetch`. If `origin/main` is ahead, pull with `git pull --rebase` only after comparing any blocking local file with `origin/main` (remove only identical copies). Never touch ChatGPT's uncommitted files.
2. **Rojo.** Make sure it's serving through `tools/rojo-serve.ps1` in a visible terminal. If you pulled, ask the owner to reconnect each Studio (Plugins → Rojo → Connect), then check Studio has the pulled code.
3. **Studios.** `list_roblox_studios` (ids change on restart). Note which places are open and, if ChatGPT is on, whether it's editing one: a playtest there would lock its Edit DataModel.
4. **State, not history.** Read the "Now" board (team mode included) and the newest 3 entries of `docs/team-notes.md`, then the status line and the milestone table in `docs/production-plan.md`. Read the spec section the slice touches, nothing more.
5. **Baseline.** If the slice changes code, run the self-test once before editing (`/bl-studio-test`), so you know what was already failing.
6. **Tell the owner in 3–5 lines:** the slice for this session, its acceptance checks, and anything you need from them (approvals, Studio clicks, publishing).
