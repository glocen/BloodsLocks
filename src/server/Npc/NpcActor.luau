--!strict
-- NpcActor: what every AI-driven entity (training dummy, Shinigami, enemy) does with its body, so brains only
-- decide *what* to do. NPCs don't run the player simulation (ActionSim, Locomotion); the server drives their
-- action attributes here and CombatService detects their hits like anyone else's.
--   Update (every brain tick): holds a hit's knockback (Knock), ends a finished action, drives its lunge, plays
--   animations. True while acting or being pushed, so the brain doesn't steer.
--   CanAct: alive, in the world, not stunned.
--   Telegraph: a coloured flash before an attack. Begin: face a direction and start an action.
--   Face, Approach, Hold: body control.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Npc)
local Parts = require(Shared.Util.Parts)
local Vector = require(Shared.Util.Vector)
local EntityState = require(Shared.Simulation.EntityState)
local AnimationSim = require(Shared.Simulation.AnimationSim)
local Knock = require(Shared.Simulation.Knock)

local A = EntityState.Attr
local num = EntityState.Number

local MOVING = 0.1 -- MoveDirection magnitude that counts as walking

local NpcActor = {}

local beingPushed: { [Model]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- bodies a hit is pushing

function NpcActor.CanAct(model: Model, now: number): boolean
	return model.Parent ~= nil and num(model, A.HP, 0) > 0 and not EntityState.IsStunned(model, now)
end

local function animator(humanoid: Humanoid): Animator
	local found = humanoid:FindFirstChildOfClass("Animator")
	if found then
		return found
	end
	local created = Instance.new("Animator")
	created.Parent = humanoid
	return created
end

-- Ends a finished action, drives the current one's lunge and keeps animations in sync. True while acting.
function NpcActor.Update(model: Model, now: number): boolean
	local root, humanoid = Parts.Root(model), Parts.Humanoid(model)
	if not root or not humanoid then
		return false
	end
	local pushed = Knock.Hold(model, humanoid, root, now)
	if pushed > 0 then
		humanoid.WalkSpeed = pushed -- a lower walk speed would brake the push
		beingPushed[model] = true
		AnimationSim.Step(animator(humanoid), model, now, true, true)
		return true
	elseif beingPushed[model] then
		beingPushed[model] = nil
		humanoid:Move(Vector3.zero) -- the push is over: stop, or the humanoid keeps walking along it
	end
	local acting = false
	local _, action, startedAt = EntityState.CurrentAction(model)
	if action then
		local elapsed = now - startedAt
		if elapsed >= action.Duration then
			model:SetAttribute(A.ActionId, "")
		else
			acting = true
			local lunge = action.Lunge
			if lunge and elapsed >= lunge.From and elapsed < lunge.To then
				-- steer the humanoid at lunge speed (setting velocity alone gets braked by its walk controller)
				humanoid.WalkSpeed = lunge.Speed
				humanoid:Move(model:GetAttribute(A.ActionFacing) :: Vector3)
			else
				humanoid:Move(Vector3.zero)
			end
		end
	end
	AnimationSim.Step(animator(humanoid), model, now, true, humanoid.MoveDirection.Magnitude > MOVING)
	return acting
end

-- A short flash in `color`, so the attack that follows can be read.
function NpcActor.Telegraph(model: Model, color: Color3, seconds: number)
	local flash = Instance.new("Highlight")
	flash.FillColor = color
	flash.FillTransparency = 0.25
	flash.OutlineColor = Config.Telegraph.Outline
	flash.OutlineTransparency = 0
	flash.Parent = model
	TweenService:Create(flash, TweenInfo.new(seconds), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(seconds + 0.05, function()
		flash:Destroy()
	end)
end

-- Turns to face a flat direction (ignored when it's zero).
function NpcActor.Face(model: Model, direction: Vector3)
	local root = Parts.Root(model)
	local flat = Vector.Flat(direction)
	if root and flat ~= Vector3.zero then
		model:PivotTo(CFrame.lookAt(root.Position, root.Position + flat))
	end
end

-- Faces `direction` and starts an action now.
function NpcActor.Begin(model: Model, actionId: string, direction: Vector3, now: number)
	local root = Parts.Root(model)
	local facing = Vector.Flat(direction)
	if facing == Vector3.zero and root then
		facing = Vector.Flat(root.CFrame.LookVector)
	end
	NpcActor.Face(model, facing)
	model:SetAttribute(A.ActionFacing, facing)
	model:SetAttribute(A.ActionId, actionId)
	model:SetAttribute(A.ActionStart, now)
end

-- Walks toward a point at `speed`.
function NpcActor.Approach(humanoid: Humanoid, position: Vector3, speed: number)
	if humanoid.WalkSpeed ~= speed then
		humanoid.WalkSpeed = speed
	end
	humanoid:MoveTo(position)
end

-- Stands still.
function NpcActor.Hold(humanoid: Humanoid)
	humanoid:Move(Vector3.zero)
end

return NpcActor
