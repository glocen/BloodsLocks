--!strict
-- DummyBrain: an aggressive training dummy. When a player is in reach it flashes (telegraph), then swings a saber
-- light attack at them through the normal action pipeline, so guard, parry, howl and dodging can be practised.
-- It doesn't attack while stunned, staggered or "dead". Body control: NpcActor.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local NpcConfig = require(Shared.Config.Npc)
local Parts = require(Shared.Util.Parts)
local EntityState = require(Shared.Simulation.EntityState)
local NpcActor = require(ServerScriptService.Server.Npc.NpcActor)

local A = EntityState.Attr

local ATTACK = "Saber.Light1"
local REACH = 7
local INTERVAL = 2.2
local TELEGRAPH = 0.45

export type Brain = {
	Model: Model,
	NextAttack: number,
	Step: (self: Brain, now: number) -> (),
}

local DummyBrain = {}
DummyBrain.__index = DummyBrain

function DummyBrain.new(model: Model): Brain
	return (setmetatable({ Model = model, NextAttack = 0 }, DummyBrain) :: any) :: Brain
end

local function nearestPlayerRoot(origin: Vector3): BasePart?
	local best, bestDistance = nil, REACH
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = Parts.Root(character)
		if character and root and EntityState.Number(character, A.HP, 0) > 0 then
			local distance = (root.Position - origin).Magnitude
			if distance < bestDistance then
				best, bestDistance = root, distance
			end
		end
	end
	return best
end

function DummyBrain.Step(self: Brain, now: number)
	local model = self.Model
	if NpcActor.Update(model, now) then
		return
	end
	local root = Parts.Root(model)
	if not root or not NpcActor.CanAct(model, now) or now < self.NextAttack then
		return
	end
	local target = nearestPlayerRoot(root.Position)
	if not target then
		return
	end
	self.NextAttack = now + INTERVAL
	NpcActor.Telegraph(model, NpcConfig.Telegraph.Attack, TELEGRAPH)
	task.delay(TELEGRAPH, function()
		if NpcActor.CanAct(model, time()) and target.Parent then
			NpcActor.Begin(model, ATTACK, target.Position - root.Position, time())
		end
	end)
end

return DummyBrain
