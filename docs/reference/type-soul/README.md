# Type Soul 2: the quality check

The owner's three clips of Type Soul 2 (2026-10-31), studied as a **quality check only**: how finished, readable and well-timed a top Roblox action game's visuals are. Duskbloods stays the inspiration and its study (`docs/reference/network-test/`) sets our shapes, scale and colours.
- Owner, 2026-10-31: "we aren't making Type Soul 2 VFX, remember, just a quality control check"; "don't overdo the giant VFX Type Soul has, we stick to Duskbloods inspiration"; "a mix: Type Soul-ish Roblox quality, aiming for Duskbloods". More clips will come.
- IP (AGENTS.md rule 3): its name stays out of everything players see; nothing of theirs is traced or copied. Frames are study evidence only.

## The clips

| Clip | File (owner's PC) | Length | What it shows |
|---|---|---|---|
| A | `C:\Users\gloce\Videos\str.mp4` | 1:00 | Open moonlit sand with dead trees: summoned spirit wolves, orbs, slashes, a barrier, bursts |
| B | `C:\Users\gloce\Videos\trtrmtmrtrrerm.mp4` | 0:38 | The same sands: crescent slashes, ground rings, a flying crescent, lightning, bursts |
| C | `C:\Users\gloce\Videos\badabumdatum.mp4` | 0:19 | A tiled indoor arena: a lattice shield, a fireball, a cinematic close-up |

All 4K60. Frames are local in `build/reference/type-soul/<a|b|c>/`: `survey/` (1 s contact sheets), `frames/` (every 0.5 s at 1280 px) and `bursts/` (20 fps sheets). Make more with `tools/reference/frames.py`.

## What it does well (OBSERVED)

- **Slashes in layers, fast.** A dark arc appears first (~0.1 s), then the bright crescent with a black smoky underside, gone by ~0.3 s (B 7.30–7.60). Another slash leaves three or four thin echo arcs and a small star spark at the target, all gone in ~0.45 s (B 31.35–31.80).
- **Punctuation frames.** A thick white ring shows for one frame, then a thin ring expands with rays (A 35.80–35.85).
- **Shields wrap the whole body,** so the player always sees their own guard: a translucent sphere with electric arcs inside (A 35.90–36.55); a lattice dome, a floor ring and a glow pulse (C 3.75–5.65).
- **Hot core over colour, dark for contrast:** white centres, saturated outer layers, black or dark layers so shapes read on bright ground; sparks and wisps finish each effect.
- **Timing:** combat effects live 0.3–0.5 s; flashes one or two frames.
- **Not for us:** screen-filling bursts (A 0:00, A 0:20, C 1.0, C 5.8–6.3), the scale our study rules out.
- **UI:** small and clean at 4K: a thin bar pair with an emblem at bottom centre, a row of skill slots, two vertical bars at bottom right, a rank letter top right.
- **Maps:** stylized, moderate detail, strong moon shadows across sand and ruins (A, B); an indoor arena with stairs (C). These clips don't show vertical play.

## The checklist (DESIGN)

Every effect, before it's called done, from the player's own camera:
1. **Its shape reads in one frame** (crescent, ring, ray), at the scale the Duskbloods study gives, never larger.
2. **Its brightest frame is seen,** even at 15 fps (`Kit.Tween` shows the first frame whole).
3. **Layers:** a hot core, a colour body, something dark for contrast, then sparks or wisps.
4. **Combat effects are short** (0.1–0.6 s, the Duskbloods measure); ritual effects may linger.
5. **It reads in the real world:** checked in a Cathedral Quarter street as well as on the test pad.

## The check on 2026-10-31

- **The ward (C1.6):** passes. Its parry whirl, ring and starburst show around the buckler from the player's camera; a block flashes gold; a break shatters it.
- **The Crimson Crescent:** failed, then fixed. Its black inside vanished against the night sky, leaving a thin red line; now a bold band, crimson-black inside with an outline, its light shortened (`docs/combat-rework.md`, C1.3).
- **The SMG burst:** its layers pass (rays, bloom, casings). It fires about 1.5 times too fast against the measured reference, and the gun is up only ~0.2 s a burst; both go to the SMG pass (`docs/combat-rework.md`, "Next: the SMG pass").

Images looked at, so nobody repeats them: survey sheets A 1–5, B 1–4, C 1–2; bursts B 6.4, B 26.6, B 30.4, A 35.4, C 3.6.
