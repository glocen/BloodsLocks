# Cathedral Quarter: W1 blockout (Claude)

> **Ownership (owner, 2026-10-29): ChatGPT now owns the Cathedral Quarter's 3D world** (art, materials, models, further layout). Claude stays on code. This blockout is the handoff: a working, tested test world for the match code. Keep its tagged markers and route levels working (or move them knowingly and re-run `Probe.Run()` and the world report).

2026-10-29. How ChatGPT's [spec](cathedral-quarter-spec.md) becomes geometry for the neutral blockout. Studs; north is −Z; heights are finished walking surfaces. The generator is `worlds/Victorian/WorldTools/CathedralQuarter` (`Build()`, idempotent, into `workspace.CathedralQuarter`).

**Blockout only:** neutral grey values that separate walkable surfaces from walls, no texture, no fog. Art starts in W2, and only after the circulation passes.

## Levels

| Y | Surface |
|---|---|
| −18 | Crypt floor (ceiling underside −2 = the street slab) |
| 0 | Street, courts, plaza |
| +8 | Nave floor, west vestibule (tower base), east vestibule (chapel) |
| +24 | Interior gallery (U-shape), cloister roof ring, tower door G1, chapel roof G2, U1/U2 landings |
| +36 | Tower top, west range roof walk, crossing bridge, east range roof court, S7 and S8 roof spawns |

The spec's +48 far landing and Z −132 far bridge are left out until sightline tests justify them (the spec allows this).

## Massing (from the plan drawing, scaled 1.70 px/stud)

| Block | X | Z | Notes |
|---|---|---|---|
| Cathedral | −68..68 | −176..−32 | plinth to +8; walls to +56; gable roof, ridge +104 |
| Bell tower (west) | −94..−68 | −58..−32 | base = west vestibule (+8); floors +24, +36; walls to +100; spire to +148 |
| West range | −94..−70 | −136..−58 | flat roof walk +36 |
| East chapel | 68..96 | −76..−32 | east vestibule (+8); flat roof +24 (G2) |
| East range | 68..118 | −140..−90 | flat roof court +36 (S8) |
| Cloister | −128..−68 | 18..88 | 12-wide arcade ranges, roofs +24 as a walk; centre 36×46 |
| Chapter houses | −226..−142 | −244..−160 | court with S3 |
| Bell works | 142..226 | −244..−150 | court with S4 |
| North pair | −110..−30 / 30..110 | −244..−204 | north socket between them |
| West terrace | −226..−170 | −80..50 | court with S5 |
| SW terraces | −226..−170 | 112..210 | court with S1 |
| S7 house | −150..−110 | 112..136 | flat roof +36 |
| South terraces | −132..−14 / 14..140 | 154..214 / 158..222 | 28-wide Lamplighters' Reach between them |
| Service row | 150..226 | 112..210 | court with S2 |
| East terrace | 172..226 | −100..40 | court with S6 |

A perimeter wall 100 high closes the envelope. That's above the best jump from any roof (36 + 46). The W, E and N sockets are closed with iron gates in 28-wide openings.

## Circulation

- **Ground ring:** the plaza → west court → west lane (X −170..−128) → north lane behind the apse (Z −204..−176) → east lane (X 144..172) → bell yard → processional court. Every lane is at least 22 wide; service gaps at least 14.
- **Interior:** front stair (X −56..56, Z −32..−16; 16 risers of 0.5) → nave → west vestibule (tower base) → ramp down to the west lane; → east vestibule (chapel) → ramp down to the east lane. Ramps drop 8 over 24, 18 wide.
- **U1 (west):** along the cloister's south side, eastward. Flight 0→12 (X −144..−120), landing, flight 12→24 (X −102..−78), landing (X −78..−60) onto the cloister roof ring (+24) → Y24 bridge north (X −94..−82) → tower door (+24) → G1 into the gallery. Inside the tower, a flight 24→36 to the tower top → the west range roof walk (north) and the Y36 bridge (X −80..−68) south to the crossing.
- **Crossing (+36):** X −80..60, Z 8..20, on piers. East end: a flight 36→24 down onto the chapel roof (+24, G2).
- **U2 (east):** a stacked switchback against the east range (X 120..144): 0→12 north, 12→24 south, 24→36 north directly above the first (24 clear). The +24 landing links west to the chapel roof by a walkway, and an east stair runs 24→0 down to the bell yard.
- **Crypt (−18):** L1 house (X −146..−128, Z −2..56; two 9-rise flights and a landing, straight) → west corridor → north corridor under the nave (Z −95..−81) → east corridor → L2 house (X 104..122, Z −40..14). Two chambers of 36×40: the lower chamber (F, under the west) and the crypt chamber (O3). Corridors are 14 wide with 16 clear.

## Regions (D8) and spawns

| Region | Volume (X, Z) | Spawns |
|---|---|---|
| Lamplighters' Reach | −240..240, 94..240; centre −50..50, 14..94 | S1, S2, S7 (+36), S9 (64, 231), S10 (−64, 227) |
| Cloister | −240..−50, −150..94 (west of the court) | S5, S11 (−198, −120), S12 (−150, −60), S13 (−98, 64) |
| Bell Works | 50..240, −260..94 | S4, S6, S8 (+36), S14 (196, 80) |
| Chapter Close | −240..50, −260..−150; centre −50..50, −150..14 | S3, S16 (0, −190), S17 (−126, −224), S18 (−40, −4) |

Spawn markers are 1-stud parts on the floor. The spawn service (L1) adds the root offset.

## Departures from the spec (and why)

1. **Ring and blocks follow the drawing,** shrunk where a lane came under its stated width: the west terrace and the SW terraces end at X −170, and the east terrace starts at X 172.
2. **The north lane runs Z −204..−176**, behind the apse, instead of at Z −220. The drawing's north blocks would otherwise sit on it.
3. **U1 runs along the cloister's south side**, not up its west side. The west side holds the west lane and the L1 house, and a straight flight there would block the lane. It still never crosses the cloister's centre.
4. **U2 is a stacked switchback at (126, 0, −92)**, not starting at (148, 0, −118). The three flights stack with 24 studs of clearance, which leaves the east lane open.
5. **The crossing's east end steps down to the chapel roof (+24).** A +36 link over the chapel would leave 12 studs of headroom on a walkable roof.
6. **The bell tower is also the west vestibule and the G1 house.** That gives the tower a job, and every upper route on the west meets there.
7. **L2 moves to (113, 0, 14)** so the east lane stays clear; group C moves to (156, 0, −20) because the L2 house stands on (112, 0, −38). Group F moves into the lower chamber at (−112, −18, −24) and (−100, −18, −14), and stays untagged until N1.
8. **The service stairs from the nave down to the crypt are deferred.** L1 and L2 are the obvious returns; the spec calls the service stairs extra loops.
9. **R1 is tagged now** as `BL_RitualSite` (Site `ProcessionalCourt`, a 64×64 box), so the data is ready for R1. R2, O2, O3 and O4 are reserved parts with no tag, and O1 carries the live `BL_PactCircle` (Kurogane).

## Built and checked (2026-10-29)

Generator: `worlds/Victorian/WorldTools/CathedralQuarter` (`init`, `Kit`, `Layout`, `Lighting`, `Probe`), installed in the Victorian place's `ServerStorage.WorldTools`. Rebuild there with `require(game.ServerStorage.WorldTools.CathedralQuarter).Build()`. Result: 913 parts, 64 lights, 3 of them casting shadows.

| Check | Result |
|---|---|
| Route probe (`Probe.Run()`): floor at the expected height and at least 14 studs of headroom every 2 studs on 11 routes | **1,970 points, 0 problems** (ground ring, both interiors, U1 → gallery → G2 → U2 top, crossing, west range, U2, east vestibule → bell yard, S7, crypt, chambers) |
| A real R6 character walks the front stair, U1, U2's hung flight, the crossing flight, both crypt stairs and the west ramp | Every stop lands on its exact floor (8, 12, 36, 36, −18, 0, 0) |
| World report | 0 problems, 0 missing: 6 region volumes, 17 spawns, 10 enemy markers, R1, the pact circle, the Antechamber, the final arena and 4 final spawns |
| Enemies | 10 spawn exactly at their authored spots, on their floors (nave groups at +8). F stays untagged until N1 |
| Self-test | 49/49 |

**Changed while checking:**
- The east stair down to the bell yard was removed: it blocked the east vestibule's way out. U2 is the east return.
- The crypt house doors went from 14 to 16 tall.
- Four missing door thresholds were added.
- U2's top flight became a "hung" flight, so it keeps 24 studs clear above the flight below it all the way up.

**Lighting (spec section 9), tuned at views A and B, in the nave and in the crypt:**
- The place's skybox has a warm horizon. Its image-based light (`EnvironmentDiffuseScale` 0.45) tinted every wall orange, so it runs at 0.12, and the low sun's colour is pulled cool.
- Lamps went from a range of 24 (washing whole façades) to 16, so they make pools.
- The nave got cool clerestory light on its fighting floor; without it the D/E encounter sat in black.
- The crypt got a pool every ~30 studs and warm sconces at its two junctions; it was pitch black.
- The result reads in four values: violet sky > warm entrance and lamp pools > cool stone > street.
- Future lighting takes a few seconds to settle after a playtest starts; capture after that.

**Not done in W1, by design:** materials, detail and fog (W2); the service stairs from the nave to the crypt; the +48 far landing; group F; the boss arena R2 and objects O2–O4 (their reserved parts only).

## Critique before building

- **Roof dominance:** the crossing (+36) overlooks R1 and the plaza. That's intended: it's the "bridge overlooks the front court" sector. The tower and the cathedral mass block it from seeing the cloister and the bell yard. Test it from the crossing with ranged aim.
- **Tower congestion:** the tower holds a door at +24, an internal flight and a deck at +36. At 26×26 it's tight; the flight runs along its west wall, and the landings must keep 18.
- **The crypt is long and plain:** about 260 studs of corridor under the nave. The chambers break it, but the art pass needs light pools at the mouths and junctions.
- **The south arrival** must read the cathedral front from camera A without the crossing hiding the portal. The bridge sits at +36 with its underside at +34, and the portal is 32 tall (+8..+40). Check view A, and lower the bridge's visual mass in art if needed.
- **Perimeter wall at 100:** honest for a blockout but ugly. In art it becomes the backs of distant buildings and the skyline.
