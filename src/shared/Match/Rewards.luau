--!strict
-- Rewards: what a participant earns from a match. Pure math from the rule's numbers (RuleDefaults); Settlement pays it
-- once through the owner's data layer.
--   Bloodgems: participation + placement bonus + floor(score / PerScore) + PerPlayerKill per player kill, capped.
--   Someone who left before the end gets participation only (owner decision D9).
--   FinalHpBonus: the share of max HP a finalist gains from the Renown they earned (D2).

local Rewards = {}

export type Outcome = {
	Placement: number, -- 1 = winner
	Score: number,
	PlayerKills: number,
	Left: boolean?, -- left the match before it ended (culled players stay and don't count as leavers)
}

function Rewards.Bloodgems(rule: any, outcome: Outcome): number
	local r = rule.Rewards
	if outcome.Left then
		return r.Participation
	end
	local placement = r.Placement[outcome.Placement] or r.OtherPlacement
	local total = r.Participation + placement + math.floor(math.max(0, outcome.Score) / r.PerScore) + r.PerPlayerKill * outcome.PlayerKills
	return math.min(total, r.Cap)
end

function Rewards.FinalHpBonus(rule: any, renown: number): number
	local final = rule.Final
	return math.min(math.max(0, renown) * final.HpBonusPerRenown, final.HpBonusCap)
end

return Rewards
