--!strict
-- Culling: how many eligible participants survive the end of a phase. Pure math, no state; MatchService applies it to
-- the standings. Plan section 3: finalists = min(rule.Finalists, entrants). Each phase in rule.CullAfter cuts its
-- share of the participants still above the finalist count; the last one leaves exactly the finalists. Participants
-- who left are no longer eligible, so the numbers follow who is actually still in the match.
-- With 8 entrants and the default rule (culls after phases 2 and 3): 8 → 8 → 6 → 3.

local Culling = {}

-- The number of finalists a match that started with `entrants` will have.
function Culling.Finalists(rule: any, entrants: number): number
	return math.min(rule.Finalists, entrants)
end

-- How many of `eligible` participants are kept at the end of phase `phase`.
function Culling.KeepCount(rule: any, phase: number, entrants: number, eligible: number): number
	local finalists = Culling.Finalists(rule, entrants)
	local culls = rule.CullAfter
	local index = table.find(culls, phase)
	if not index or eligible <= finalists then
		return eligible
	end
	local remaining = #culls - index + 1 -- this cull and the ones after it
	local cut = math.floor((eligible - finalists) / remaining)
	return eligible - cut
end

return Culling
