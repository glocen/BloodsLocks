# Framework audit (2026-10-29, Claude)

The `framework-v0` code (tag), read before the fix pass. The simulation, networking, combat and server services were read fully; the client UI and VFX got a lighter pass. **Nothing has been changed yet.** The owner picks what gets fixed. After the fixes and regression checks, the result is tagged `framework-v1`.

**Overall:** the core is solid. One simulation pipeline, data-driven actions, a rate-limited network layer, the damage pipeline in the right order, and clean boot. The problems are a few real bugs, missing pieces the match will need, and some rule breaks (magic strings, colors outside Theme).

## High: fix before building the match

| # | Problem | What goes wrong | Fix | Size |
|---|---|---|---|---|
| H1 | **Your class choice never reaches the game.** `Simulation/Spawn` always gives the default class, and `ClassService` (which knows your pick) only runs in the Manor. | Invisible today because Gustave is the only class. With class 2, you pick it, enter a match, and spawn as Gustave. | A Core service mirrors `SelectedClass` from the profile onto the Player in every place; Spawn reads it. | Small |
| H2 | **No automated regression tests.** Every check (jump 8.5, dodge i-frames, chain damage, parry, skill charges) is run by hand through MCP. | Each refactor needs a long manual retest, and a regression can slip through unnoticed. "Perfect framework" can't be proven. | One debug command, `SelfTest`, runs every movement and combat check in a playtest and prints PASS/FAIL. Run it after every change, in any place. | Medium |
| H3 | **No lag compensation.** Melee hitboxes and bullets test where the *server* sees the target. The plan (section 5) asks for 1 s of position history; it was never built. | With 100+ ms ping, a swing that clearly connects on your screen misses (or a dodge you made gets hit). PvP feels unfair. | Record each entity's position for the last second; check hits against where the attacker saw the target (capped at 200 ms). | Medium |

## Medium: your keep list (needs your OK to touch)

| # | Problem | What goes wrong | Fix |
|---|---|---|---|
| M1 | `ProductManager`: `IsPurchaseSaved` searches for the whole cache table instead of the purchase id. | It's always false, so a purchase is **never confirmed to Roblox**, and the loop force-saves the profile **every 10 s until the player leaves** (heavy DataStore use, can hit limits). | One word: `purchaseID` instead of `purchaseIdCache`. |
| M2 | `Products.luau` holds template leftovers ("100 bananas" etc.) and a revive product that does nothing. | Selling one would award bananas, which don't exist in BloodsLocks. | Empty the table until we add real products (Bloodgem packs?). |
| M3 | Two health numbers: `DataInit` sets the Humanoid's MaxHealth to the profile's `Health` (2000), while combat HP is 1000 from the class. | Confusing: anything that reads the Humanoid shows the wrong HP. Combat itself is fine (it uses its own HP). | Stop writing MaxHealth from the profile in combat places, or drop the old `Health` stat. |
| M4 | `PlayerHandlerData.AddWeapon` looks for `ServerStorage.WeaponsFLD`, which doesn't exist. | Errors if ever called. | Remove it or point it at our weapon definitions. |

## Medium: our code

| # | Problem | Fix |
|---|---|---|
| M5 | Player attributes are typed as raw strings in several files: `"class"` (3 files), `"shId"`, `"shLv"`, `"shHp"`, `"shOut"`, `"shCd"` (service + HUD), `"ClientReady"`. A typo silently breaks the HUD. | One `PlayerState` schema (like `EntityState.Attr`) that everything uses. |
| M6 | A hit that was detected but not applied yet still lands after the attacker died or was staggered. | Skip queued hits whose attacker is dead. Keep trades when both swing at the same moment. |

## Low: polish and rule breaks

| # | Problem | Fix |
|---|---|---|
| L1 | About 12 colors hard-coded outside Theme (heal number, class portrait lighting, Dusk Battle card gradient, panel shade, the Gōka fire colors). Rule 5 breaks: a restyle misses them. | Move them into `Theme`. |
| L2 | The boot log says "0 errors" even when a module's `Start()` crashes (Start runs after the count). | Count Start errors and report them in a second line. |
| L3 | Shinigami borrow the player class's saber by pretending to be Gustave (`ClassId = DefaultClass`). | Give a Shinigami its own weapon in its definition. |
| L4 | Training dummy numbers (2000 HP, 3 s regen, 1.5 s revive) live in the service, not in Config. | Move them to `Config`. |
| L5 | `DataService.Wait` checks every frame until the profile loads. | Wait on the `ProfileReady` signal instead. |

## Not problems (checked)

- Projectiles can't multi-hit: a hit stops them.
- Rate limiting and pcall wrap every client → server remote.
- Hit order (allegiance → i-frames → howl → bite → guard/parry → damage) matches the design.
- Simulation code writes state only inside the simulation, and only when values change.

## Suggested order

H1 → M5 (same files, both small) → H2 (the self-test, so everything after is checked automatically) → M1–M4 (with your OK) → M6, L1–L5 → H3 (lag compensation, best tested with two players). Then tag `framework-v1`.
