--!strict
-- Cases: the logic tests, in run order. Each gets a tester with Check(name, ok, detail?) and Equal(name, got, want).
-- Rule numbers are read from the definitions, except the cull sequences the owner decided (D1) and the reward
-- examples, which spell out what the plan promises so a silent change to the rule data shows up here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local Culling = require(Shared.Match.Culling)
local Rewards = require(Shared.Match.Rewards)
local Ledger = require(Shared.Match.Ledger)
local Regions = require(Shared.Match.Regions)
local WorldTags = require(Shared.World.Tags)
local Bite = require(Shared.Simulation.Bite)
local Combat = require(Shared.Config.Combat)

local standard = Registry.DefaultRuleDef()

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
		Name = "Ledger",
		Run = function(t)
			local seq = 0
			local function gain(book: Ledger.Book, amount: number, key: string?): boolean
				seq += 1
				return Ledger.Add(book, { Source = "Objective", Amount = amount, Seq = seq, Phase = 1, Key = key })
			end
			local a, b, c = Ledger.new(), Ledger.new(), Ledger.new()
			t.Check("a keyed award pays", gain(a, 10, "Lantern:1"))
			t.Check("the same event can't pay twice", not gain(a, 10, "Lantern:1"))
			t.Equal("total after a replay", a.Total, 10)
			t.Check("nothing for zero", not gain(a, 0))
			gain(b, 10) -- b reaches 10 after a did
			t.Equal("tie: first to reach the total ranks higher", table.concat(Ledger.Rank({ [1] = a, [2] = b }, { 2, 1 }), " "), "1 2")
			gain(c, 4, "Pledge:R1")
			gain(c, 6)
			t.Equal("revoking a pledge takes its amount back", Ledger.Revoke(c, "Pledge:R1"), 4)
			t.Equal("total after the revoke", c.Total, 6)
			t.Equal("a revoked key stays used", gain(c, 4, "Pledge:R1"), false)
			t.Equal("revoking twice takes nothing", Ledger.Revoke(c, "Pledge:R1"), 0)
			t.Equal("by source", Ledger.BySource(a).Objective, 10)
			t.Equal("higher total first, then reach order, then id",
				table.concat(Ledger.Rank({ [5] = a, [-2] = b, [3] = c }, { 3, -2, 5, 9, -4 }), " "), "5 -2 3 -4 9")
		end,
	},
	{
		Name = "Regions",
		Run = function(t)
			local regions = { "A", "B", "C", "D" }
			t.Equal("capacity for 8 over 4 regions: ceil(8/4)+1", Regions.Capacity(8, 4), 3)
			local ids = { 1, 2, 3, 4, 5, 6, 7, 8 }
			local everyoneA = {}
			for _, id in ids do
				everyoneA[id] = "A"
			end
			local result = Regions.Allocate(ids, everyoneA, regions, Random.new(1))
			local inA, moved = 0, 0
			for _, id in ids do
				if result[id].Region == "A" then
					inA += 1
				end
				if result[id].Moved then
					moved += 1
				end
			end
			t.Equal("a full region takes only its capacity", inA, 3)
			t.Equal("the overflow is moved, and told so", moved, 5)
			t.Equal("first come, first served", result[1].Region, "A")
			local none = Regions.Allocate(ids, {}, regions, Random.new(2))
			local placed, notMoved = 0, true
			for _, id in ids do
				if table.find(regions, none[id].Region) then
					placed += 1
				end
				notMoved = notMoved and not none[id].Moved
			end
			t.Equal("no choice still gets a valid region", placed, 8)
			t.Check("and isn't reported as moved", notMoved)
			local bad = Regions.Allocate({ 1 }, { [1] = "Nowhere" }, regions, Random.new(3))
			t.Check("an unknown region falls back to a valid one", table.find(regions, bad[1].Region) ~= nil and not bad[1].Moved)
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
	{
		Name = "Bite pulses",
		Run = function(t)
			-- the drain's pulses (Simulation/Bite) move whole points, never go back, and add up to the total exactly
			local timeline = Bite.Timeline
			local count = timeline.Pulses
			for _, total in { 0, 1, 7, 90, 121, 999 } do
				local steady, last = true, 0
				for done = 1, count do
					local share = Bite.Share(total, done, count)
					steady = steady and share >= last and share == math.floor(share)
					last = share
				end
				t.Check(`{total} in {count} pulses: whole and rising`, steady)
				t.Equal(`{total} in {count} pulses adds up`, last, total)
			end
			t.Check("the pulses all land before the release", timeline.FirstPulse + (count - 1) * timeline.PulseEvery < timeline.Release)
			local hold = Registry.Action(Bite.HoldAction)
			t.Check("the biter recovers after the release", timeline.Release < hold.DodgeCancelFrom and hold.DodgeCancelFrom < hold.Duration)
			t.Check("the victim's clip ends with its knockdown", timeline.VictimClip <= timeline.Release + Combat.Hitstun.Knockdown)
		end,
	},
}
