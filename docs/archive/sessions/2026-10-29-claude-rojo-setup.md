# 2026-10-29 · Claude · Rojo setup, framework in the Victorian place, Manor rename

**Owner asked:** use Rojo, set it up well, connect it to the GitHub repo so any old version can be restored. The hub is now called the **Manor**, not the castle.

**Done and verified:**
- **New home:** the project lives in `C:\Users\gloce\BloodsLocks`, a git clone of the repo. Windows Controlled Folder Access blocks git, Rojo and Python in Documents. The old Documents folder is a retired backup.
- **Tools:** Rokit + Rojo 7.7.1 (pinned in `rokit.toml`), the Luau LSP VS Code extension, `.vscode/` settings, `.gitattributes` (LF everywhere).
- **Export:** `default.project.json` maps the framework folders to `src/`. A `rojo syncback` from the hub gave 125 files, with script counts verified against Studio. Tag `framework-v0` (pushed).
- **Rename:** Castle → Manor in code. `Shared.Util.PlaceRole` replaces four hard-coded role checks.
- **Both places connected through Rojo:**
  - Manor boots 10 + 7 modules with 0 errors.
  - Victorian (`PlaceRole = "Match"`, gravity 145) boots 8 + 7 with 0 errors, the profile loads, and the jump is 8.50 studs.

**Open:**
1. The owner's framework issue list → fix pass → tag `framework-v1`.
2. Owner sign-off on match flow v1 (engineering-plan section 3) → MatchService.
3. ChatGPT: shorten the `ArtStatus` / `ExteriorArtStatus` attributes on `workspace.Vigil` (over 50 characters, so Roblox drops them).
4. Victorian `Workspace.AuthorityMode` = Server: the owner was asked to set it; not confirmable from MCP.
