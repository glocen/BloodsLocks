--!strict
-- Spawn: player character setup, inside the simulation. On the first step: movement and stamina state, then the
-- class and level. The class is the one the server mirrored from the player's profile (PlayerState.Class), else the
-- default; the level is the player's in-match level (PlayerState.Level, kept by ProgressionService).
-- Both are checked every step:
--   a new class (late profile load, a pick in the Manor) applies when the character is idle: class, combat state,
--   ammo and skills, and (server) the welded weapon;
--   a level gained mid-fight applies at once: max HP grows (and the gain is added to current HP), max stamina too.
-- Max HP includes the player's HpBonus (PlayerState; the final's bonus), read when a body spawns or levels.

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)
local PlayerState = require(script.Parent.PlayerState)
local Leveling = require(script.Parent.Leveling)
local Stamina = require(script.Parent.Stamina)
local ActionSim = require(script.Parent.ActionSim)
local Equipment = require(script.Parent.Equipment)

local A = EntityState.Attr
local num = EntityState.Number

local Spawn = {}

local function wantedClass(player: Player): string
	return Registry.Class(player:GetAttribute(PlayerState.Attr.Class)).Id
end

local function wantedLevel(player: Player): number
	local level = player:GetAttribute(PlayerState.Attr.Level)
	return if type(level) == "number" then level else 1
end

-- Max HP for the class at a level, with the player's bonus (the final's, from Renown) applied.
local function maxHealth(player: Player?, classId: string, level: number): number
	local bonus = if player then player:GetAttribute(PlayerState.Attr.HpBonus) else nil
	local base = Leveling.MaxHealth(Registry.Class(classId).BaseHealth, level)
	return math.floor(base * (1 + (if type(bonus) == "number" then bonus else 0)))
end

local function applyClass(character: Model, player: Player, classId: string, level: number, now: number)
	character:SetAttribute(A.ClassId, classId)
	EntityState.InitCombat(character, maxHealth(player, classId, level), now)
	character:SetAttribute(A.Level, level)
	ActionSim.ResetLoadout(character)
	if RunService:IsServer() then
		Equipment.AttachMelee(character)
	end
end

-- A new level on a living character: max HP and stamina grow, and the HP gained is added now.
local function applyLevel(character: Model, player: Player, classId: string, level: number)
	local oldMax = num(character, A.HPMax, 1)
	local newMax = maxHealth(player, classId, level)
	character:SetAttribute(A.HPMax, newMax)
	character:SetAttribute(A.HP, math.min(newMax, num(character, A.HP, 0) + math.max(0, newMax - oldMax)))
	character:SetAttribute(A.StaminaMax, Leveling.MaxStamina(level))
	character:SetAttribute(A.Level, level)
end

function Spawn.EnsureReady(player: Player, character: Model, humanoid: Humanoid, now: number)
	local classId = wantedClass(player)
	local level = wantedLevel(player)
	if character:GetAttribute(A.Ready) == true then
		local idle = EntityState.CurrentAction(character) == "" and not EntityState.IsStunned(character, now)
		if idle and character:GetAttribute(A.ClassId) ~= classId then
			applyClass(character, player, classId, level, now)
		elseif num(character, A.Level, 1) ~= level then
			applyLevel(character, player, classId, level)
		end
		return
	end
	EntityState.Apply(character, EntityState.Defaults.Movement, now)
	Stamina.Reset(character, now)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) -- every jump is scripted (Locomotion)
	applyClass(character, player, classId, level, now)
	local maxStamina = Leveling.MaxStamina(level)
	character:SetAttribute(A.StaminaMax, maxStamina)
	character:SetAttribute(A.Stamina, maxStamina)
	character:SetAttribute(A.Ready, true)
end

return Spawn
