--!strict
-- Spawn: first-step setup for a player character, inside the simulation: movement and stamina state, class,
-- combat state, ammo, and (server) the welded weapon.

local RunService = game:GetService("RunService")

local Shared = script.Parent.Parent
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(script.Parent.EntityState)
local Stamina = require(script.Parent.Stamina)
local ActionSim = require(script.Parent.ActionSim)
local Equipment = require(script.Parent.Equipment)

local A = EntityState.Attr

local Spawn = {}

function Spawn.EnsureReady(character: Model, humanoid: Humanoid, now: number)
	if character:GetAttribute(A.Ready) == true then
		return
	end
	EntityState.Apply(character, EntityState.Defaults.Movement, now)
	Stamina.Reset(character, now)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) -- every jump is scripted (Locomotion)
	character:SetAttribute(A.ClassId, Registry.DefaultClass) -- the profile's SelectedClass once class select exists
	EntityState.InitCombat(character, Registry.Class(nil).BaseHealth, now)
	ActionSim.ResetLoadout(character)
	if RunService:IsServer() then
		Equipment.AttachMelee(character)
	end
	character:SetAttribute(A.Ready, true)
end

return Spawn
