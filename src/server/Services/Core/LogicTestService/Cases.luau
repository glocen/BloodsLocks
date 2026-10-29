--!strict
-- Cases: the logic tests, in run order. Each gets a tester with Check(name, ok, detail?) and Equal(name, got, want).
-- Rule numbers are read from the definitions, except the cull sequences the owner decided (D1) and the reward
-- examples, which spell out what the plan promises so a silent change to the rule data shows up here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local Culling = require(Shared.Match.Culling)
local Rewards = require(Shared.Match.Rewards)
local WorldTags = require(Shared.World.Tags)

local standard = Registry.Rule("Standard")

-- Eligible counts after each phase, when `leavers[phase]` participants leave during that phase.
local function cullSequence(rule: any, entrants: number, leavers: { [number]: number }?): { number }
	local eligible = entrants
	local sequence = {}
	for phase = 1, #rule.Phases do
		eligible -= (leavers and leavers[phase]) or 0
		eligible = Culling.KeepCount(rule, phase, entrants, eligible)
		table.insert(sequence, eligible)
	end
	return sequence
end

local function joined(list: { number }): string
	return table.concat(list, " ")
end

return {
	{
		Name = "Rules",
		Run = function(t)
			local order = {}
			for _, rule in Registry.Rules() do
				table.insert(order, rule.Id)
			end
			t.Equal("display order", table.concat(order, ","), "Standard,Solo,Bound")
			t.Equal("Standard culls after phases 2 and 3 (D1)", joined(standard.CullAfter), "2 3")
			t.Equal("Solo inherits the defaults", joined(Registry.Rule("Solo").CullAfter), "2 3")
			t.Equal("Solo refuses alliances", Registry.Rule("Solo").Alliances, "None")
			t.Equal("Bound is sealed until designed", Registry.Rule("Bound").Playable, false)
			t.Check("rules are read-only", table.isfrozen(standard) and table.isfrozen(standard.Rewards))
			t.Equal("final lives", standard.Final.Lives, 2)
			t.Equal("player kills give Renown in ritual sites only (D4)", standard.PlayerKill.RitualOnly, true)
		end,
	},
	{
		Name = "Culls",
		Run = function(t)
			t.Equal("8 entrants: 8 → 8 → 6 → 3", joined(cullSequence(standard, 8)), "8 6 3")
			t.Equal("7 entrants", joined(cullSequence(standard, 7)), "7 5 3")
			t.Equal("6 entrants", joined(cullSequence(standard, 6)), "6 5 3")
			t.Equal("4 entrants: nobody cut until the last cull", joined(cullSequence(standard, 4)), "4 4 3")
			t.Equal("3 entrants: all reach the final", joined(cullSequence(standard, 3)), "3 3 3")
			t.Equal("2 entrants: both reach the final", joined(cullSequence(standard, 2)), "2 2 2")
			t.Equal("8 entrants, one leaves in phase 2", joined(cullSequence(standard, 8, { [2] = 1 })), "8 5 3")
			t.Equal("8 entrants, three leave in phase 1", joined(cullSequence(standard, 8, { [1] = 3 })), "5 4 3")
			t.Equal("8 entrants, six leave: the two left are the finalists", joined(cullSequence(standard, 8, { [1] = 6 })), "2 2 2")
			t.Equal("no cull in a phase that doesn't cull", Culling.KeepCount(standard, 1, 8, 8), 8)
			t.Equal("finalists for 8", Culling.Finalists(standard, 8), 3)
		end,
	},
	{
		Name = "Rewards",
		Run = function(t)
			local r = standard.Rewards
			t.Equal("winner, 120 Renown, 3 player kills", Rewards.Bloodgems(standard, { Placement = 1, Score = 120, PlayerKills = 3 }),
				r.Participation + r.Placement[1] + 2 + 3 * r.PerPlayerKill)
			t.Equal("5th place, nothing else", Rewards.Bloodgems(standard, { Placement = 5, Score = 0, PlayerKills = 0 }),
				r.Participation + r.OtherPlacement)
			t.Equal("capped", Rewards.Bloodgems(standard, { Placement = 1, Score = 100000, PlayerKills = 50 }), r.Cap)
			t.Equal("a leaver gets participation only (D9)", Rewards.Bloodgems(standard, { Placement = 1, Score = 500, PlayerKills = 5, Left = true }),
				r.Participation)
			t.Equal("plan formula: 1st, 0 score = 75", Rewards.Bloodgems(standard, { Placement = 1, Score = 0, PlayerKills = 0 }), 75)
			t.Equal("final HP bonus at 0 Renown", Rewards.FinalHpBonus(standard, 0), 0)
			local bonus = Rewards.FinalHpBonus(standard, 100)
			t.Check("final HP bonus at 100 Renown", math.abs(bonus - 100 * standard.Final.HpBonusPerRenown) < 1e-9, tostring(bonus))
			t.Equal("final HP bonus is capped (D2)", Rewards.FinalHpBonus(standard, 5000), standard.Final.HpBonusCap)
		end,
	},
	{
		Name = "World contract",
		Run = function(t)
			local seen = {}
			local unique = true
			for _, spec in WorldTags do
				if seen[spec.Tag] then
					unique = false
				end
				seen[spec.Tag] = true
			end
			t.Check("every tag is listed once", unique)
			t.Check("every tag starts with BL_", (function()
				for _, spec in WorldTags do
					if string.sub(spec.Tag, 1, 3) ~= "BL_" then
						return false
					end
				end
				return true
			end)())
			local victorian = Registry.Map("Victorian")
			t.Check("the Victorian map has the four regions (D8)", victorian ~= nil and victorian.Zones.LamplightersReach ~= nil
				and victorian.Zones.Cloister ~= nil and victorian.Zones.BellWorks ~= nil and victorian.Zones.ChapterClose ~= nil)
		end,
	},
}
