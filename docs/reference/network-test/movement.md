# Movement: getting around

How the hero moves, from the first full playthrough (0:00–52:23). **OBSERVED** unless labelled; **MANUAL** marks tutorial prompts and cards (paraphrased). The trails and afterimages are broken down in [vfx.md](vfx.md).

## 1. The moves

| Move | How it works | Seen |
|---|---|---|
| **Walk, sprint** | Hold to sprint (MANUAL) | 4:00 |
| **Jump** | A tap | 3:12 |
| **High jump** | Hold, then release: reaches roof level from the street | 3:12, 8:51, 37:36–37:51 |
| **Air jumps** | Up to three in the air (MANUAL 3:24), each with a burst of white streaks from the feet | 3:24, 21:24–21:35, 23:41 |
| **Dodge** | On the ground and in the air (MANUAL), leaving an afterimage | 4:00, 10:07, 24:02 |
| **Climb** | Grab ivy or other grips, then climb up and down with the stick (MANUAL 3:42); towers climbed hand over hand (43:17–43:27) | 3:42, 43:17 |
| **Ledge grab** | Hang from an edge, "Climb up" | 25:05, 41:19, 43:31 |
| **Wall jump** | A jump off a wall onto a ledge | 8:16–8:17 |
| **Falls** | Long drops do no harm (off the Greatbridge into the city) | 26:30–26:31 |
| **Walk on anything** | Roof ridges, balustrade tops, chandeliers | 25:03, 25:54–26:06 |
| **Instant travel** | From the map, between travel points (rules in [match-flow.md](match-flow.md)) | 17:51–18:05 |
| **Co-op transport** | Accepting a co-op request moves you to the fight and back | 15:46–17:23 |

## 2. What the moves are for

- **Roofs are the fast lane.** In City Streets the hero spends most of his travel jumping from roof to roof with air jumps, dropping into streets to fight (21:06–21:35, 38:49–39:08).
- **Height is a route inside buildings too.** Galleries, a walkable chandelier, ledge grabs on balustrades and drops through floor openings link the cathedral's levels (24:12–25:11).
- **Climbing reaches what jumps can't:** ivy on rock faces and towers.
- **Long falls are free,** so jumping off bridges and roofs is a normal shortcut.

## 3. The camera

- Third person behind the hero, slightly above; it pulls back during fast travel.
- **Lock-on** puts a circular reticle on the target and keeps both in frame (6:18); a flick switches targets.
- Authored shots for big moments: the phase arrival from behind the hero; the hub's reveal pulling back through the hall (12:00–12:20); the victory tilting up to the moon (51:38–51:45).

## 4. Against ours (DESIGN)

- **Jumps match:** our `Config.Movement.MaxJumps = 4` (a ground jump and three air jumps), with a held high jump.
- **Sprint:** ours is a toggle; the reference teaches holding. Keep ours unless the owner asks.
- **We lack** ivy and grip climbing, ledge grabs, wall jumps and instant travel. These belong to the combat framework rework (owner, 2026-10-30), not C1.
- **Trails:** our movement has no trails yet; the reference's air-jump streaks, high-jump ribbons and dodge afterimages are part of how the movement reads, and belong to the VFX pass.
