# Combat, movement and camera: the plan

Item 5 on the owner's order (team notes, "Now", 2026-10-31), and the combat framework rework the production plan kept for after C1. The owner: the camera and the movement are "so final... it should take us a long time and it's fine, it is one of the core systems of the game". The reference to capture is the owner's Albert clip ("this is what I want to capture"), knowing the game is more than that one fight. Piece by piece, to the bar, inside every limit.

- **When:** written now for the owner's review. Building starts after items 3 and 4 (the SMG burst, the ward and the parry, the push) and the Crimson Crescent fix in progress. Measuring the reference for P1 changes no code, so it can start sooner.
- **Labels:** OBSERVED (seen in the footage, with its timestamp) and DESIGN (our choice).
- **Homes:** the reference's facts live in the network-test study, and this plan links to them. Tunable numbers live in `src/shared/Config`.

## 1. The loop every piece goes through

1. **Measure the reference.**
   - **Sources:** the Albert clip (`C:\Users\gloce\Videos\hqqXe55ZlnZNd6P.mov`, 30 fps) and the full recording, in dense bursts of the piece's moments at 15–30 fps (`tools/reference/frames.py burst`).
   - **What's measured:** frames and timings; distances in body heights; the camera's framing (where the hero sits in the frame, how much sky shows, how late the camera follows).
   - **Where it goes:** the study's topic file (movement, combat, animation or vfx), as OBSERVED with timestamps.
2. **Read ours:** the piece's Config, simulation and controller code, by section, and its self-test cases.
3. **Set the target (DESIGN):** the reference's feel in our numbers, animations and effects; close, never a 1:1 copy. The piece's section below grows into its spec: targets, tests, progress.
4. **Build it**, with a rollback commit first.
   - The simulation under server authority (`.claude/rules/server-authority.md`).
   - Animations in Blender (`.agents/skills/bl-asset-pipeline`).
   - Effects through the tracked texture pipeline; sounds by AGENTS.md rule 2.
   - The camera in `CameraController`, its numbers in `Config.Camera`.
5. **Test it.** Every rule and number gets a self-test case that reads Config, never literals. Then the full self-test and the logic tests, in both places.
6. **Review side by side.** Our capture from the player's camera next to the reference frame of the same moment. Critique it harshly, fix it, and capture again until it holds up.
7. **Owner gate.** The owner plays the piece. Report four facts apart: implemented, tested, visually reviewed, owner-accepted. Only an accepted piece opens the next one.

## 2. What we want to capture (DESIGN)

The facts are in the study:
- [movement.md](reference/network-test/movement.md): the moves, and in §3 the camera, with first framing readings (2026-10-31);
- [animation.md](reference/network-test/animation.md): measured actions and poses;
- [combat.md](reference/network-test/combat.md): the controls and the kit;
- [vfx.md](reference/network-test/vfx.md): the trails and afterimages.

What they add up to:
- **A calm camera.** The hero near the middle, a gentle look down, and no shake on your own swings: hits read through the target's reaction and the effects.
- **Speed and height.** Sprint, high jumps and air jumps make the roofs a fast lane; long falls are free; landings are crisp.
- **Fast, light contacts.** Very short sabre arcs; the weight comes from the target's instant flinch and push, never from slow swings.
- **Clear holds for big moves:** one readable pose each, and planted power for the beam.

## 3. Ours today (from the code, 2026-10-31)

- **Camera** (`CameraController`, `LockOnController`, `Config.Camera`):
  - third person over the right shoulder (`ShoulderOffset`);
  - field-of-view kicks for sprint and dash, a framed bite, Souls-style lock-on with flick switching;
  - shakes (`CombatFxController`) when you're hit, when your own hit lands (stronger for heavy hits), and on your blocks, parries, howls and bite beats.
- **Movement** (`Config.Movement`, the simulation): walk; a sprint toggle; a ground jump and three air jumps; a held high jump; an air dash; a dodge that becomes a backstep without input; faster falls; turning toward a lock-on target.
- **Animations** (`Config.Animations`): one dodge clip and a backstep, a sprint, the high jump's launch and a landing. No strafing clips.
- **Combat** (C1): the M1 chain with knockback, hitstop and the slash trail; the bite; the ward (guard, block, parry, guard break); the howl; the SMG; two skills.

**Gaps against the reference:**
- our shoulder offset, where the reference centres the hero;
- our camera shakes on our own hits, where the reference shows none;
- no trails on jumps, air jumps or dodges (movement.md §4);
- one dodge clip for every direction, and no strafing while locked: both are owner asks (combat-rework.md, "Later in C1");
- the owner judged C1's animations "bad" (production plan, 2026-10-30), so every new clip here gets far more craft;
- no ledge grabs, wall jumps or climbing (movement.md §4).

## 4. The pieces, in order

Each piece takes one session or more and ends at the owner's gate. The camera comes first: every other piece is judged through it.

### P1 · The camera
- **Measure:** the framing while running, in close duels and through jumps (Albert 0:05–0:43 and 1:29.6–1:31.5; the recording 3:25–3:27 and 37:38–37:40): the hero's place and size, the share of sky, the follow lag, the lock-on's framing.
- **Build:**
  - **Framing:** the hero centred (question 1), with the distance, focus height and resting pitch tuned to the measured framing; the field of view by state (run, sprint, dash, lock).
  - **Follow:** smooth, with no bob; a soft vertical follow that lets the hero climb in the frame through jumps and settles on landing; a slight lag in turns. To try: a gentle automatic look down near a high jump's peak, kept only if it never fights the mouse.
  - **Collision:** pulls in smoothly near walls, never clips, eases back out.
  - **Lock-on:** both kept in frame, a steady orbit, clean switches and breaks, working with dodges and the bite camera. The reticle's new look comes with the UI rework.
  - **Shakes:** one table of presets in `Config.Camera` instead of numbers in `CombatFxController`. The camera stays steady on your own light hits; hits taken, heavy impacts and big skills keep a shake, judged side by side.
- **Tests:** distance and offsets, the collision pull-in, the lock-on's framing, the vertical follow through a jump, no shake on your own light hit.

### P2 · Locomotion: walk, run, sprint, turns, strafing
- **Measure:** speeds in body heights a second (stride and cadence, or crossing a landmark of known size), how long starts and stops take, the turning arc, the sprint's lean.
- **Build:**
  - acceleration and braking in the simulation, and turns that never slide;
  - our run, sprint, start and stop cycles in Blender: weight, the sabre held low, no robot steps;
  - 8-way strafing while locked (the owner's ask), its clips blended inside the Animator's track limit (`server-authority.md`).
- **Tests:** speeds and acceleration times from Config; strafing keeps facing the target.
- **Question 2:** sprint as a toggle (ours today) or a hold (the reference).

### P3 · Jumps and air jumps
- **Measure:** air time and peak for the tap, high and air jumps; the high jump's crouch; the air jump's tucked spin; landings.
- **Build:**
  - heights and gravity tuned to the reference's rhythm, with air control, and a hang at the peak if the footage shows one;
  - the crouch and launch, the spin, light and heavy landings;
  - our trails: a ribbon for the high jump, streaks for air jumps.
- **Tests:** peak heights and air times from Config; the jump count resets on landing.
- **World:** if heights change, update the envelope rule (`worlds/world-contract.md`) and the world to-do on the Now board.

### P4 · The dodge
- **Measure:** distance, duration and the visible invulnerability, on the ground and in the air; the afterimage.
- **Build:** directional dodges (the owner's ask): forward, to the sides and the backstep, plus the air dodge (our air dash, retuned); our afterimage; cancel windows out of attacks.
- **Tests:** each direction's distance, duration and invulnerable window, from Config.

### P5 · The light chain (M1)
- **Measure:** each swing's wind-up, active arc and recovery; the lunge; the target's push; hits while moving.
- **Build:** new swing clips with anticipation, an arc as short as the reference's (animation.md §1) and follow-through; hitstop and knockback retuned; chain windows and input buffering; a dodge cancel; the air chain; the slash trail fitted to the new arcs.
- **Tests:** the chain's windows, the buffer, the cancel and the push distances, from Config.

### P6 · Strong, charged and air attacks
- **Measure:** wind-ups, holds and launches (not measured yet: combat.md §2).
- **Build:** the clips; the charge's tell (pose, light, sound) and its stagger; every attack also in the air, as the reference teaches (combat.md §1).

### P7 · Defence: guard, parry, howl
- **Measure:** the guard sphere and the parry flash in a duel (Albert 1:30.7–1:31.4); the howl.
- **Build:** the windows and stamina tuned by play; the parry's timing feel; the howl's shockwave in our style; guarding in the air (combat.md §1). The ward's look is done (C1.6).

### P8 · Hit reactions and weight
- **Build:** flinch, heavy hit, knockdown, the stagger (the kneel exists) and getting up; knockback and hitstop per hit, from Config. The weight comes from the reaction on the hit's frame, never from slow swings.

### P9 · The gun in motion
- **Build:** aiming and firing while moving and strafing, the camera's answer to firing (judged side by side), reloading on the move. The burst itself is C1's (its rebuild is in progress).

### P10 · Input feel
- **Build:** buffering, priorities, coyote time and cancel rules, the same on keyboard and mouse and on a controller. Every rule gets a test.

### P11 · The fight, against the clip
- **Review:** a full fight (the Manor yard's dummies, and a second player when the owner can join) next to Albert 0:06–1:45: the camera, movement, combat, sound and effects together. Fix what reads worse; then the owner accepts the core feel.

### P12 · Ledge grabs and wall jumps
- **Measure:** the grab's reach and the climb up (the recording 25:05, 41:19, 43:31); the wall jump (8:16–8:17).
- **Build:** edge detection on any ledge; the hang and the climb up; the wall jump; their clips and camera.
- **World:** the ledge rules go into the world contract before the Victorian map's blockout (the map is vertical).

### P13 · Climbing
- **Measure:** grabbing ivy and grips, climbing up and down, hand over hand (3:42, 43:17–43:27).
- **Build:** climbable surfaces as a world tag (`worlds/world-contract.md`, `World/Tags`), the climb's movement, its clips and camera.

**Outside this plan,** for later planning with the owner: instant travel (a match-flow feature, though movement.md §4 lists it with the rework), the companions, and the other mechanics in [takeaways.md](reference/network-test/takeaways.md) §6.

## 5. Limits, on every piece

- **No gore (AGENTS.md rule 4):** a hit shows as the body's red flash with a white outline (`UI/Components/Flash`), never blood of any kind.
- **IP (rule 3):** our own animations, effects and framing; never a 1:1 shot or move; the fan test on every name.
- **Server authority** (`.claude/rules/server-authority.md`): no instance destroyed inside simulation callbacks, the Animator's track limit, animations published before the simulation plays them.
- **Zero spend and custom only (rules 1 and 2):** our Blender clips and textures; sounds by rule 2.
- **Cheap frames:** camera and movement code runs every frame (`Util/Budget`).
- **Never break what exists:** a rollback commit before each piece; every self-test and logic test still passes after it.

## 6. Who does what

- **Claude:** every piece: the measuring, building, testing and review.
- **The owner:** plays and accepts each piece and answers the questions below. Claudius, the lead designer, can review the plan against the vision if the owner wants.

## 7. Questions for the owner

1. **The camera:** centre the hero like the reference (recommended), or keep our over-the-shoulder view? A small offset could come back only while aiming the gun, if aiming needs it.
2. **Sprint:** keep our toggle (today's default, movement.md §4), or hold to sprint like the reference?
3. **The order:** the camera; locomotion; jumps; the dodge; the combat pieces; the fight against the clip; then ledge grabs, wall jumps and climbing (recommended)?
