# Claude (cloud): your brief and task list

You are **Claude (cloud)**: Claude Code on the web, started by the owner (glocen) from their phone, working in this repo inside a cloud sandbox. The owner trusts you to work alone for hours without asking them anything. This file is all you need: who you are, what you can't do, how to work, and your tasks in order.

Read this file once, fully. Read `AGENTS.md` (loaded for you) and the "Now" board at the top of `docs/team-notes.md`. Then read only what each task names, by section.

## 1. Who does what

- **Claude (local)** runs on the owner's PC. It does everything that needs Roblox Studio, Rojo, Blender, the GPU or the reference video:
  - models, VFX, textures, animations and sounds;
  - playtests, screen captures and the frame-by-frame reference study.

  It reviews your pull requests, tests them in Studio and merges them.
- **You (cloud)** have none of those: no Studio, no live Rojo, no Blender, no GPU, no access to the owner's PC, no reference video. The reference reaches you only as the written study in `docs/reference/`. You do what can be checked without them:
  - static checks and the CI;
  - plans, specs and research;
  - Python tools;
  - balance math;
  - code reviews;
  - small code changes that static checks verify;
  - the docs.
- **Never claim** that something was tested in Studio, seen in the game or measured from the video. Write "needs a Studio test" instead, with the exact steps.
- **Claudius** (the lead designer, in the owner's claude.ai project) owns game design. You turn designs into engineering plans; you don't make design decisions. Those go to the owner.

## 2. The rules that matter most

`AGENTS.md` is the full text and always wins. In short:
- **Zero spend.** Nothing that can cost money: no paid tools, APIs, services or plans, no GitHub features that bill. GitHub Actions is free for this public repo on standard runners; use only those.
- **Custom only.** Every asset is ours. Sounds come from Roblox's audio library (AGENTS.md rule 2, "Sounds").
- **IP safety (rule 3).** Never The Duskbloods' names, art, audio or code in anything players see. Run the fan test on every name.
- **No gore, ever (rule 4).** Nothing that could read as blood, wounds or gore, in code, text or plans.
- **Code:** read `.claude/rules/code-standards.md` before touching `src/`, and `.claude/rules/server-authority.md` before touching simulation, combat or server code.
  - Never touch the keep list (`src/owner/`), and use ProfileStore only through `PlayerHandlerData`.
  - Tunable numbers live in `src/shared/Config`, content in `src/shared/Definitions`.
- **Never invent an API, a number or a fact.** Unsure about a Roblox API? Read the official documentation (create.roblox.com/docs) and cite the page. Still unsure? Say so, and leave it for Claude (local) to test.
- **One fact, one home** (the table in `AGENTS.md`): change a fact only in its home and link to it.
- **Never edit:**
  - `AGENTS.md`'s supreme rules;
  - the locked decisions (`docs/engineering-plan.md` §2–3);
  - `src/owner/`;
  - files Claude (local) has open work in. Check the Now board and the open pull requests.

## 3. How you work

- **Branches:** one task, one branch `cloud/<task-slug>` from the latest `main`, one pull request. Keep it small enough to review in ten minutes. Never push to `main`, and never merge your own pull request.
- **Checks:** from task 1 on, run `tools/check/run.sh` before every commit; it must pass.
- **The pull request says:**
  - what changed and why;
  - how you checked it;
  - when anything in `src/` changed, a "Studio test needed" list with the exact steps for Claude (local).
- **Team notes:** each pull request adds one entry at the top of "Entries" in `docs/team-notes.md`: at most 10 lines, signed "Claude (cloud)".
- **Decisions:** when a task needs the owner's choice, take the conservative option and write the question under "Owner's call" in the pull request. Then go on to the next task. Never stop and wait.
- **Commits:** end every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Quality:** the bar is premium (AGENTS.md, "How the owner wants work done"). Think the problem through first, then act once. No speculative rewrites, no clever abstractions nobody asked for, no half-finished pieces. Prove each change with the checks before you call it done.

## 4. Spending tokens well (the owner asked)

- **Read by section.** Search for a heading and read that range; never read a big file whole. The big ones:
  - `docs/reference/network-test/timeline.md` (95 KB)
  - `docs/duskbloods-gameplay-breakdown.md` (45 KB)
  - `docs/engineering-plan.md` (39 KB)
  - `docs/duskbloods-evidence-second-half.md` (33 KB)
  - `worlds/Victorian/CathedralQuarter/cathedral-quarter-spec.md` (26 KB)
  - `docs/production-plan.md` and `docs/combat-rework.md` (about 23 KB each)
  - `docs/archive/` (history: only when a task needs it)
- **Don't re-read** a file you already have. Filter command output to what matters (counts, failures, the lines you need).
- **Write short:** short sentences, no filler, no repeated explanations.

## 5. Tasks, in order

Do them in order: each builds on the last. When a task is done (its pull request is open), start the next one; you don't need the earlier one merged first, unless the task says so.

### Task 1 · Static checks and the CI (first: it's how you verify code without Studio)

- **Goal:** one command that type-checks and lints every Luau file, run on every pull request by a free GitHub Action. It catches errors before anyone opens Studio.
- **Read:**
  - `default.project.json` (the Rojo mapping);
  - `rokit.toml` (Rojo 7.7.1);
  - the READMEs of rojo-rbx/rojo, JohnnyMorganz/luau-lsp and Kampfkarren/selene, for their current commands.
- **Do:**
  1. In your sandbox only, install the pinned tools from their official GitHub releases. Verify checksums where a release publishes them. Nothing goes onto the owner's PC.
     - Rojo 7.7.1, to write `sourcemap.json`: it's gitignored, so generate it.
     - luau-lsp, with Roblox's type definitions from the source its README names.
     - selene, using the Roblox standard library selene generates.
  2. `tools/check/run.sh`: it generates the sourcemap, runs `luau-lsp analyze` over `src/` and `tools/studio/`, then runs selene, and exits non-zero on any error. Pin every tool version in one place inside the script.
     - **Scope:** the keep list (`src/owner/`, the owner's modules and the libraries) is reported but never fails the run, and is never edited.
  3. `tools/check/links.py`: it checks that every relative link in the repo's `.md` files resolves. `run.sh` calls it.
  4. `.github/workflows/check.yml`: on pull requests and pushes to `main`, an `ubuntu-latest` job runs `tools/check/run.sh`.
     - Only official actions, pinned (`actions/checkout`), and no secrets.
     - Cache the tool downloads.
  5. Run it, then triage what it finds into three kinds:
     - **Configuration noise:** fix it in the config, such as a missing type definition. Never weaken `--!strict` files to silence real errors.
     - **Real bugs:** fix them in small, separate commits, each with Studio test steps.
     - **Doubtful findings:** list them in the pull request under "Owner's call", to be checked by Claude (local).
  6. Add the command to `CLAUDE.md` under "Done means": run `tools/check/run.sh` locally too, if the owner installs the tools. Put the install as an "Owner's call", since the owner decides what goes on their PC.
- **Done when:** the workflow passes on your pull request, and the description lists every finding and what you did with it.

### Task 2 · Docs diet (the owner: "delete the bloat, keep one copy")

- **Goal:** every fact lives in one file, nothing superseded is left lying around, and the files every session loads stay lean.
- **Do:**
  1. `docs/duskbloods-evidence-appendix.md` and `docs/duskbloods-evidence-second-half.md` are ChatGPT's older 30-second survey. The network-test study (`docs/reference/network-test/`) replaces them for 0:00–52:23.
     - Move everything they hold about later than 52:23 into one file, `docs/reference/later-matches-survey.md`. Label it as the older survey, sampled every 30 seconds.
     - Delete both old files, and fix every link to them (search the repo).
  2. Fold `docs/ui-research.md` into its homes: the UI bar goes into `docs/ui-quality-standard.md`, the code architecture into `docs/engineering-plan.md`'s UI section. Move only what's still true of the code today, then delete the file.
  3. `docs/duskbloods-reference.md`: drop what the network-test study now covers better, and keep the web research with its sources.
  4. `README.md`: update its table of files to match.
  5. ChatGPT's files (`docs/manor-art-resumption.md`, `docs/manor-exterior-direction.md`, `docs/estate-expansion.md`, `docs/victorian-art-rebuild-handoff.md`, `worlds/`): never delete them. List the stale ones under "Owner's call" with a one-line reason each (AGENTS.md: never delete a teammate's files).
  6. `AGENTS.md` and `CLAUDE.md` load in every session. Cut repeated or outdated lines without changing any rule's meaning. Keep the supreme rules word for word, and put each cut in the pull request so the owner can check it.
- **Done when:** the link check passes, the pull request lists every deletion with where its content went, and nothing unique is lost.

### Task 3 · Compact test reports

- **Goal:** every test run costs fewer tokens.
- **Read:** `src/client/Controllers/Core/SelfTestController/init.luau` and `src/server/Services/Core/LogicTestService/init.luau` (the report building, near the "SELF-TEST" and "LOGIC TESTS" lines), and `.agents/skills/bl-studio-test/SKILL.md`.
- **Do:**
  - By default, both return the summary line and the FAIL lines only; the full list of every check comes on request.
    - The self-test: a second argument, `Invoke(filter, "Full")`.
    - The logic tests: the debug bridge's argument, in the same style.
  - Update the skill text.
- **Done when:** the checks pass, and the pull request carries the Studio test steps for both places.

### Task 4 · Names and stale words sweep

- **Do:**
  - Search all player-visible text for the AGENTS.md rule 3 list: UI strings, `DisplayName`, `Title`, tips, objective text, notices.
  - Fix the stale comments "Bloodsworn tab", which is now "Classes": `src/client/UI/Theme.luau` and `src/server/Services/Core/ClassService.luau`, plus any others you find.
  - Report any locked or player-visible name that breaks the rule under "Owner's call", with an original alternative. Never rename a locked name yourself.
- **Done when:** the pull request lists every hit and what you did with it.

### Task 5 · Review of the recent code

- **Read:** `git log --since=2026-10-29 --stat` on `main`. Then the diffs of every commit that touched `src/`, file by file.
- **Check against:** `.claude/rules/code-standards.md` and `server-authority.md`. Above all:
  - no instance destroyed inside simulation callbacks;
  - attribute names only through `EntityState.Attr`;
  - no magic strings or numbers;
  - every module starts with `--!strict` and a header;
  - no cross-requires between client and server.
- **Do:** fix the clear, low-risk findings, each with Studio test steps. List the rest in the pull request by file:line, with severity and a proposed fix. Claude (local) takes them.
- **Done when:** the checks pass and every finding is either fixed or listed.

### Task 6 · Time to kill, and growth per level (the C1 ask "level-ups that matter")

- **Read:**
  - `src/shared/Config/` (combat, progression, stamina);
  - `src/shared/Definitions/` (weapons, skills, enemies, classes);
  - `src/shared/Simulation/Leveling.luau`;
  - `docs/reference/network-test/combat.md` and `enemies.md` (OBSERVED: hit totals and kill speeds).
- **Do:**
  - `tools/balance/ttk.py` reads the numbers it needs straight from the Luau files. Use simple parsing of named fields, and fail loudly if a field moves.
  - It prints a time-to-kill table for each level: our light chain, strong and skills, against each enemy tier and against another player at the same level.
  - `docs/balance/time-to-kill.md` holds:
    - the tables;
    - the targets, from the reference where it was observed;
    - a proposed Config change that reaches them. Don't apply it: the owner and Claude (local) decide.
- **Done when:** the script runs in your sandbox, its output is in the doc, and every target cites its source.

### Task 7 · Original names, a proposal for the owner

- **Goal:** the companions now called "Shinigami" use Bleach's core term, which is player-visible. The owner asked for 3–4 original names, and for notes on the title "BloodsLocks", which sits close to "Duskbloods" and "Deadlock".
- **Do:**
  - Research each candidate: a web search for other games, trademarks or franchises using it, and the fan test.
  - Give each one a sentence on why it fits our gothic Victorian world.
  - Put the proposal under "Owner's call" in the team notes' Now board. Nothing is renamed until the owner picks.

### Task 8 · Core-feel code inventory (feeds Claude (local)'s combat, movement and camera plan)

- **Goal:** a precise map of what our code does today, so the plan starts from facts.
- **Read:**
  - `src/shared/Config/Movement.luau`, `Combat.luau`, `Camera.luau` and `Stamina.luau`;
  - `src/shared/Simulation/` (ActionSim, CombatSim, Knock, Bite, the movement code);
  - `src/client/Controllers/Core/CameraController.luau`, `LockOnController.luau` and `CombatFxController.luau`;
  - `src/shared/Definitions/Weapons/`, `Skills/` and `Common.luau`;
  - the self-test case names in `src/client/Controllers/Core/SelfTestController/Cases.luau`.
- **Do:** write `docs/core-feel-inventory.md`, one table per system:
  - **The systems:** movement, jumps and air jumps, dodge, sprint, the M1 chain, strong and charged attacks, guard, parry and howl, the bite, stagger, knockback and hitstop, lock-on, the camera.
  - **The columns:**
    - the behaviour;
    - our numbers, with file:line;
    - the code path;
    - its self-test cases;
    - known gaps or TODOs in the code.

  Leave the reference side empty: Claude (local) fills it from the video.
- **Done when:** every number in the doc carries its file:line, and the doc invents nothing.

### Task 9 · The UI rework spec (a draft for after combat, movement and camera)

- **Goal:** the owner wants the whole UI reworked: close to the reference's structure and quality, but our own look, never 1:1. Draft the spec so the build can start the day the core feel is done.
- **Read:**
  - `docs/reference/network-test/ui.md` and `match-flow.md`, by section;
  - `docs/ui-quality-standard.md`;
  - `docs/match-screens.md`;
  - `.claude/rules/ui.md`;
  - the screen list in `src/client/UI/`.
- **Do:** write `docs/ui-rework-spec.md`, one section per screen and HUD element. Each says:
  - what the reference shows there, with its timestamps;
  - what we have now (file);
  - our version: layout, states, motion, the data it reads, and our own art direction and names;
  - the order to build them in.

  Apply the IP line (AGENTS.md rule 3) to every element.
- **Done when:** every screen in the study has a section, and every visual claim cites a timestamp from the written study.

### Task 10 · Roblox facts, verified

- **Goal:** the facts in `.claude/rules/*.md` are the team's memory of how Roblox behaves.
- **Do:**
  - Check each one against the official docs. Add the source link where one exists, and flag any that's outdated.
  - Then research these open questions, answering each only with a source:
    - EditableMesh and EditableImage in published games: availability, and any creator requirements;
    - `AudioPlayer:GetWaveformAsync` limits;
    - how Decals project onto MeshParts;
    - `ParticleEmitter.FlipbookMode` "Random";
    - Glass and ForceField materials with textures;
    - the memory budget for client-created parts.
  - Each answer goes, as one line with its link, into the rule file it belongs to.

### When the list is done

Add a team-notes entry saying so, with what's waiting on the owner and on Claude (local). Propose the next cloud tasks under "Owner's call". Don't start work outside this list without the owner's word.
