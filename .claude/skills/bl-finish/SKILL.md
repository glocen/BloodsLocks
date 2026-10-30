---
name: bl-finish
description: Close a finished BloodsLocks slice - run the checks, review what players see, update the one status home and the team notes, log assets, commit only our paths. Use when a piece of work is done or the owner says to wrap up.
---

# Finish a slice

1. **Checks, all passing.** `BL_SelfTest` (Client context) and `LogicTests` (Server); `WorldReport` if markers or world code changed; `Probe.Run()` if the Cathedral Quarter changed; `MatchSmoke` if the match lifecycle changed. Add a self-test or logic case for every new mechanic or rule.
2. **Visual review** for anything players see: player-camera captures at 1920×1080 and 1366×768, over a bright and a dark backdrop, then a harsh self-critique against the bar before showing the owner. World pieces: also at the player's distance, in the place's real lighting, with the backup of what they replaced still in `ServerStorage.WorldBackups`.
3. **Status, once.** Update the status line and the milestone table in `docs/production-plan.md` (the only status home). Update a spec only if behaviour changed: its section in `docs/engineering-plan.md`, or the slice's design doc.
4. **Team notes.** Update the "Now" board. Add one entry at the top, at most about 10 lines: what changed, where it lives, what's open, who it's for. If the file passes about 250 lines, move the oldest entries to `docs/archive/team-notes-YYYY-MM.md`.
5. **Assets.** Add a row to `docs/asset-log.md` for each new or replaced asset.
6. **Tidy.** Delete the temp files, unused parts and dead code you created; empty `build/import`.
7. **Commit.** `git add` only the paths you changed (never `-A`), with a clear message. Push only when the owner says go.
8. **Report** to the owner, each stated separately: implemented, tested, visually reviewed, owner-accepted. Then suggest `/clear` before an unrelated slice.
