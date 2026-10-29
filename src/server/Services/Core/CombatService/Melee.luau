--!strict
-- Melee: one MuchachoHitbox (the owner's module) per action Hit window, following the attacker's root part.
-- Each target is hit at most once per window.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local Raycast = require(Shared.Util.Raycast)
local EntityState = require(Shared.Simulation.EntityState)
local MuchachoHitbox = require(ReplicatedStorage.Modules.SharedModules.MuchachoHitbox)

type OnHit = (attacker: Model, target: Model, hit: any) -> ()
type Active = { Hitbox: any, Start: number, ActionId: string }

local Melee = {}

local active: { [Model]: Active } = {}

function Melee.Stop(model: Model)
	local current = active[model]
	if current then
		active[model] = nil
		current.Hitbox:Stop()
	end
end

local function start(model: Model, root: BasePart, actionId: string, startedAt: number, hit: any, onHit: OnHit)
	local hitbox = MuchachoHitbox.CreateHitbox()
	hitbox.Size = hit.Size
	hitbox.CFrame = root
	hitbox.Offset = hit.Offset
	hitbox.Visualizer = Config.ShowHitboxes and RunService:IsStudio()
	hitbox.VisualizerColor = Color3.fromRGB(220, 40, 60)
	hitbox.OverlapParams = Raycast.ExcludeOverlap({ model })
	hitbox.Touched:Connect(function(_part: BasePart, humanoid: Humanoid)
		local target = humanoid.Parent
		if target and target:IsA("Model") and CollectionService:HasTag(target, EntityState.Tag) then
			onHit(model, target, hit)
		end
	end)
	hitbox:Start()
	active[model] = { Hitbox = hitbox, Start = startedAt, ActionId = actionId }
end

function Melee.Update(model: Model, actionId: string, action: any, startedAt: number, now: number, onHit: OnHit)
	local current = active[model]
	if current and (current.Start ~= startedAt or current.ActionId ~= actionId) then
		Melee.Stop(model)
		current = nil
	end
	local elapsed = now - startedAt
	local inWindow = elapsed >= action.Hit.From and elapsed < action.Hit.To
	if inWindow and not current then
		local root = Parts.Root(model)
		if root then
			start(model, root, actionId, startedAt, action.Hit, onHit)
		end
	elseif current and elapsed >= action.Hit.To then
		Melee.Stop(model)
	end
end

return Melee
