--!strict
-- Spawn: player character setup, inside the simulation. On the first step: movement and stamina state, then the
-- class. The class is the one the server mirrored from the player's profile (PlayerState.Class), else the default.
-- It's checked every step, so a profile that loads after the character spawned (or a new pick in the Manor)
-- applies as soon as the character is idle: class, combat state, ammo and skills, and (server) the welded weapon.

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)
local PlayerState = require(script.Parent.PlayerState)
local Stamina = require(script.Parent.Stamina)
local ActionSim = require(script.Parent.ActionSim)
local Equipment = require(script.Parent.Equipment)

local A = EntityState.Attr

local Spawn = {}

local function wantedClass(player: Player): string
	return Registry.Class(player:GetAttribute(PlayerState.Attr.Class)).Id
end

local function applyClass(character: Model, classId: string, now: number)
	character:SetAttribute(A.ClassId, classId)
	EntityState.InitCombat(character, Registry.Class(classId).BaseHealth, now)
	ActionSim.ResetLoadout(character)
	if RunService:IsServer() then
		Equipment.AttachMelee(character)
	end
end

function Spawn.EnsureReady(player: Player, character: Model, humanoid: Humanoid, now: number)
	local classId = wantedClass(player)
	if character:GetAttribute(A.Ready) == true then
		local idle = EntityState.CurrentAction(character) == "" and not EntityState.IsStunned(character, now)
		if idle and character:GetAttribute(A.ClassId) ~= classId then
			applyClass(character, classId, now)
		end
		return
	end
	EntityState.Apply(character, EntityState.Defaults.Movement, now)
	Stamina.Reset(character, now)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) -- every jump is scripted (Locomotion)
	applyClass(character, classId, now)
	character:SetAttribute(A.Ready, true)
end

return Spawn
