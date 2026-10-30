---
paths:
  - "src/**"
  - "tools/studio/**"
  - "worlds/**/WorldTools/**"
---

# Code standards (owner, 2026-10-29: pro-quality, modular)

- One job per module. When a module grows a second job, split it. Helpers only one service uses are child ModuleScripts of that service (the Loader ignores modules nested in modules), e.g. `CombatService.Melee`.
- No duplicated helpers: direction math in `Util.Vector`, model lookups in `Util.Parts`, raycast and overlap params in `Util.Raycast`. Attribute reads use `EntityState.Number` / `EntityState.Set` / `EntityState.CurrentAction`.
- No magic strings: attribute names from `EntityState.Attr`, the entity tag from `EntityState.Tag`, input names from `Input`, world tags from `Shared.World.Tags`, rule ids through `Registry`. Tunable numbers live in `Config`, content in `Definitions`.
- Defaults are data: spawn state is the `EntityState.Defaults` tables applied with `EntityState.Apply`, not lists of `SetAttribute` calls.
- Names never depend on child order (dummies take their number from their spot's name).
- Every module starts with `--!strict` and a header comment saying what it does and where it runs.
- Boot: the Loader requires every module in Services (or Controllers), validates its shape, calls `Init()` on each (own state only, no cross-calls), then `Start()` on each. Module names must be unique.
- Dependencies: Definitions require nothing. Simulation requires only Config and Definitions. Server and Client code require Shared, never each other.
- Hit detection uses the owner's MuchachoHitbox (the `--!strict` copy in `Modules.SharedModules`) behind a small wrapper, as long as it runs cleanly under Server Authority; ask the owner before swapping it. Camera effects use CameraShaker.
- After any refactor, re-run the self-test and logic tests.
