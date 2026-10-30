--!strict
-- Tips: the hints the loading screen (Passage) and the Antechamber rotate through, per place role. Every number comes
-- from the live rule and config, so retuning a rule never leaves a stale tip. A tip only describes what exists today:
-- add one when a system lands (ritual sites, the heal, items, alliances...).

local Shared = script.Parent.Parent
local Registry = require(script.Parent.Registry)
local Culling = require(Shared.Match.Culling)
local Movement = require(Shared.Config.Movement)
local MatchConfig = require(Shared.Config.Match)
local GameConfig = require(Shared.Config.Game)
local Numerals = require(Shared.Util.Numerals)

local WORDS = { "One", "Two", "Three", "Four", "Five", "Six" }

local Tips = {}

local numeral = Numerals.Roman

local function word(n: number): string
	return WORDS[n] or tostring(n)
end

-- The culls for a full field, phase by phase: "after phase II only the top 6 go on; after phase III, the top 3".
local function cullLine(rule: any): string
	local field = MatchConfig.Lobby.MaxPlayers
	local remaining = field
	local parts = {}
	for i, phase in rule.CullAfter do
		remaining = Culling.KeepCount(rule, phase, field, remaining)
		table.insert(parts, if i == 1 then `after phase {numeral(phase)} only the top {remaining} go on` else `after phase {numeral(phase)}, the top {remaining}`)
	end
	return table.concat(parts, "; ")
end

local function matchTips(rule: any): { string }
	return {
		`{word(#rule.Phases)} phases, then the final. Renown decides the culls: {cullLine(rule)}.`,
		`Fall during a phase and you rise again {rule.Revival.Delay} seconds later, where you choose. Your level and Renown stay yours.`,
		`You arrive protected for {rule.Revival.Protection} seconds. Striking first ends the protection at once.`,
		`The final gives each hunter {string.lower(word(rule.Final.Lives))} lives. The last one standing wins the hunt.`,
		`Empty seats don't wait: AI hunters take them when the hunt begins, {MatchConfig.Lobby.MaxPlayers} hunters in all.`,
		`Defeating the quarter's creatures earns Renown and experience. Each level makes you stronger for the rest of the hunt.`,
		`Hold jump to charge a leap that clears the rooftops; {string.lower(word(Movement.MaxJumps - 1))} more jumps wait in the air.`,
		"Guard just as a blow lands to parry it. A staggered foe can be bitten, and the bite heals you.",
	}
end

local function manorTips(): { string }
	return {
		`Approach the Blood Table in {GameConfig.HubName} to seek a hunt or choose your hunter.`,
		"The yard outside is safe ground: practise on the training dummies before you set out.",
		"Bloodgems earned in the hunt stay yours between hunts.",
		`Hold jump to charge a leap that clears the rooftops; {string.lower(word(Movement.MaxJumps - 1))} more jumps wait in the air.`,
	}
end

-- The tips for a place role ("Manor" or "Match"), for `rule` (default: the default rule).
function Tips.For(role: string, rule: any?): { string }
	if role == GameConfig.PlaceRoles.Match then
		return matchTips(rule or Registry.DefaultRuleDef())
	end
	return manorTips()
end

return Tips
