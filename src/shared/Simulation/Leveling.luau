--!strict
-- Leveling: the in-match level formulas (Config.Progression), shared so the server (XP), the simulation (stats) and
-- the HUD (the XP bar) always agree.

local Config = require(script.Parent.Parent.Config.Progression)
local StaminaConfig = require(script.Parent.Parent.Config.Stamina)

local Leveling = {}

Leveling.MaxLevel = Config.MaxLevel

-- XP needed to go from `level` to the next (math.huge at the cap).
function Leveling.XpToNext(level: number): number
	if level >= Config.MaxLevel then
		return math.huge
	end
	return Config.XpBase + Config.XpPerLevel * (level - 1)
end

function Leveling.MaxHealth(baseHealth: number, level: number): number
	return math.floor(baseHealth * (1 + Config.HealthPercent * (level - 1)))
end

function Leveling.MaxStamina(level: number): number
	return StaminaConfig.Max + StaminaConfig.PerLevel * (level - 1)
end

function Leveling.DamageMultiplier(level: number): number
	return 1 + Config.DamagePercent * (level - 1)
end

return Leveling
