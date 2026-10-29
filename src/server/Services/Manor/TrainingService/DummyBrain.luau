--!strict
-- DummyBrain: an aggressive training dummy. When a player is in reach it flashes orange (telegraph), then swings
-- a saber light attack at them through the normal action pipeline, so guard, parry, howl and dodging can be
-- practised. It doesn't attack while stunned, staggered or "dead".

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Vector = require(Shared.Util.Vector)
local EntityState = require(Shared.Simulation.EntityState)

local A = EntityState.Attr

local ATTACK = "Saber.Light1"
local REACH = 7
local INTERVAL = 2.2
local TELEGRAPH = 0.45
local TELEGRAPH_COLOR = Color3.fromRGB(222, 150, 64)

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

local function telegraph(model: Model)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = TELEGRAPH_COLOR
	highlight.FillTransparency = 0.2
	highlight.OutlineTransparency = 0
	highlight.Parent = model
	TweenService:Create(highlight, TweenInfo.new(TELEGRAPH), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(TELEGRAPH + 0.05, function()
		highlight:Destroy()
	end)
end

local function canAct(model: Model, now: number): boolean
	return not EntityState.IsStunned(model, now) and EntityState.Number(model, A.HP, 0) > 0
end

function DummyBrain.Step(self: Brain, now: number)
	local model = self.Model
	local _, action, startedAt = EntityState.CurrentAction(model)
	if action then
		if now - startedAt >= action.Duration then
			model:SetAttribute(A.ActionId, "")
		end
		return
	end
	local root = Parts.Root(model)
	if not root or not canAct(model, now) or now < self.NextAttack then
		return
	end
	local target = nearestPlayerRoot(root.Position)
	if not target then
		return
	end
	self.NextAttack = now + INTERVAL
	telegraph(model)
	task.delay(TELEGRAPH, function()
		if not canAct(model, time()) or not target.Parent then
			return
		end
		local facing = Vector.Flat(target.Position - root.Position)
		model:PivotTo(CFrame.lookAt(root.Position, root.Position + facing))
		model:SetAttribute(A.ActionFacing, facing)
		model:SetAttribute(A.ActionId, ATTACK)
		model:SetAttribute(A.ActionStart, time())
	end)
end

return DummyBrain
