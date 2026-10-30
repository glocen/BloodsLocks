# ChatGPT → Claude: Victorian art rebuild in progress

Owner approved the complete Victorian Quarter rebuild on 2026-10-30. Please keep Victorian world geometry, markers and Lighting under ChatGPT ownership while this pass runs. Existing W1 has been cloned into `ServerStorage.WorldBackups.PreArtRebuild_20261030`, with archived tags removed and stored as BackupTags. Live roots are still present at this checkpoint. Do not run the W1 generator after the replacement is installed.

## Confirmed world direction

- At least three times usable area; initial 800×960 stud envelope, terraced city, PC first.
- Existing region IDs retained: LamplightersReach, Cloister, BellWorks, ChapterClose.
- Exterior-only houses/workshops; larger cathedral with nave, side aisles, chapels, gallery and compact two-exit lower passage.
- All art original, no asset packs or Roblox AI; no gore or graphic remains. Owner references govern wear and lighting, not copied names/assets.

## Engineering integration requested

Please add the phase presentation controller in src (your ownership), consuming existing `Shared.Match.MatchState` constants and replicated State/Phase. ChatGPT supplies art presets under `ServerStorage.WorldAssets.VictorianKit` and publishes client-readable preset data when validated.

- Phase I Dusk (amber key/cool shadows), II Twilight (muted violet), III and Final Night (blue-violet, warm practicals).
- Six-second interpolation on phase entry; immediate correct state on late join. Hold the current preset during PhaseResolve. Night remains through FinalSetup, Final and Results. Idle/Waiting/Intro use Dusk. No independent wall-clock day/night cycle.
- Preserve all durations, culls, rewards and rules. Do not bake phase colour into UI Theme or material albedo.
- Atlas currently clones every large anchored part in region bounds. For the detailed city, use an authored simplified `ServerStorage.WorldAssets.VictorianMapRelief` model when present, with the current behavior as fallback; keep tags/scripts/lighting out of the proxy.
- Validate AI stair navigation, leash/home floor and attacks across different floors before enabling lower/roof groups. Keep group F inactive until those cases pass.
- ChatGPT will relocate the 17 player spawns and live encounter markers and update route probes. Re-read the installation status before testing.

## Current status

Backup completed; drawings and Blender package/PBR validation in progress. This is a coordination checkpoint, not a completed/visually accepted city or a request to rebuild the world.

Working artifacts: `C:/Users/gloce/.codex/visualizations/2026/10/30/01a18a5f-e9f8-7873-9f0e-2de939c44258/victorian-rebuild`.

