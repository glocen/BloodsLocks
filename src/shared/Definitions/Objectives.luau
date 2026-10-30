--!strict
-- Objectives: the short checklist under your vitals during a match (Duskbloods keeps one on the left all match), per
-- stage of the hunt. Every line is something the player can act on now, checked from state the client can see:
--   Check "Level": you reached level Value.   "Pact": you have a Shinigami pact.
--   "AboveCut": your standing is inside the cut at this phase's end (live; it can come undone).
--   "Aim": the stage's goal, never ticked.
--   Needs: a world feature the place must have for the line to show (MatchState.Features: "Pact"...).
-- Phases with a cull use Culling; a phase with no line of its own uses Default.

return {
	Phases = {
		[1] = {
			{ Text = "Explore the quarter and grow stronger", Check = "Level", Value = 3 },
			{ Text = "Make a pact with a Shinigami", Check = "Pact", Needs = "Pact" },
		},
	},
	Culling = {
		{ Text = "Stay above the cut", Check = "AboveCut" },
		{ Text = "Keep growing: every level counts in the final", Check = "Aim" },
	},
	Default = {
		{ Text = "Grow stronger before the cut", Check = "Aim" },
	},
	Final = {
		{ Text = "Be the last hunter standing", Check = "Aim" },
	},
}
