# Asset requests

The queue between the builder (Claude) and Claude (assets) (`docs/asset-maker.md`). The builder or the owner adds requests at the bottom; Claude (assets) takes the first "Open" one. Statuses: Open → In progress → Delivered (in `build/handoff/<Name>/`) → In game (the builder put it in and checked it) → Accepted (the owner). "Back" sends it back with the reason.

## WeaponHolds: Gustave's idle, walk and sprint with the sabre and the SMG

- **Status:** Open.
- **Why** (owner, 2026-10-31): "the way we hold the SMG while being idle, walking and running is stupid, same for the sabre".
- **Today:** the SMG rides at the left hip pointing down and the sabre lies across the right hip; the gun is drawn only during a burst (the code's weapon welds).
- **Reference:** Albert in the owner's clip (`C:\Users\gloce\Videos\hqqXe55ZlnZNd6P.mov`, 30 fps) and the network-test recording (`docs/reference/network-test/animation.md` §1, `movement.md`): how he carries both weapons standing, walking and sprinting. Our poses, never a copy.
- **Make:**
  1. a pose sheet first (each loop's key poses from the player's camera, the weapons in place), for the owner's OK in your chat;
  2. three R6 loops: idle, walk (`Config.Movement.WalkSpeed`) and sprint (`SprintSpeed`), feet planted to the speed, with weight and follow-through.
- **Say in the delivery** where each weapon must sit (in hand or holstered, and how), so the builder changes the welds.
- Later, core-feel P2 adds turns and strafing (`docs/core-feel-plan.md`); these loops are its base.

## SMGReload: a simple R6 reload

- **Status:** Open (after WeaponHolds).
- **Owner** (2026-10-31): "we won't make a reloading model, just a simple R6 animation".
- **Make:** one clip with the SMG in the left hand (`Definitions/Weapons/BurstSMG`, `Hand = "Left"`), timed to its `Reload` seconds, readable from the player's camera.

## SMGBurstHold: the gun up for the whole burst

- **Status:** Open (after WeaponHolds: it starts from and returns to its idle SMG pose). Take it before SMGReload: it unblocks the builder's SMG pass.
- **Today:** the burst clip (`SMGBurst`) raises the gun for only 0.1–0.2 s and holsters it by 0.3 s.
- **Timing** (the new burst, `docs/combat-rework.md`, "The new burst"): one 0.75 s clip.
  - the gun up and aimed by 0.07 s;
  - 8 rounds, the first at 0.08 s, then every 0.085 s (the last at 0.675 s), each with a small, readable recoil kick;
  - held until 0.75 s.
- **Pose:** the gun one-handed at chest height, the arm out toward the target (the recording at 19:22.7–19:23.4 and 19:23.2). The body turns with the aim in code, so the clip keeps the arm straight ahead. What the free hand does comes from the reference.
- **Deliver** the baked clip; the builder publishes it, sets the new numbers and checks every round leaves the muzzle in the game.
