--!strict
-- TrainingService: training dummies in the castle. Each dummy is an entity (same combat pipeline as players),
-- regenerates to full a few seconds after the last hit and revives right after "dying". Dummies stand on the
-- BaseParts in Workspace.TrainingDummies; a spot with the attribute Aggressive = true gets a dummy that swings
-- at players in reach (see DummyBrain).

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local DummyBrain = require(script.DummyBrain)

local A = EntityState.Attr
local num = EntityState.Number

local DUMMY_HEALTH = 2000
local REGEN_AFTER = 3
local REVIVE_AFTER = 1.5

local TrainingService = {}

type Dummy = { Model: Model, Brain: DummyBrain.Brain? }
local dummies: { Dummy } = {}

-- Each dummy is named after its spot (DummySpot1 -> TrainingDummy1), so names don't depend on child order.
local function spawnDummy(template: Model, spot: BasePart)
	local model = template:Clone()
	model.Name = "TrainingDummy" .. (spot.Name:match("%d+$") or spot.Name)
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth, humanoid.Health = math.huge, math.huge
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	model:PivotTo(spot.CFrame * CFrame.new(0, 3 + spot.Size.Y / 2, 0))
	EntityState.InitCombat(model, DUMMY_HEALTH, time())
	CollectionService:AddTag(model, EntityState.Tag)
	model.Parent = spot.Parent
	table.insert(dummies, {
		Model = model,
		Brain = if spot:GetAttribute("Aggressive") == true then DummyBrain.new(model) else nil,
	})
end

local function heal(model: Model, now: number)
	local lastHit = num(EntityState.Fx(model), A.LastHitAt, 0)
	local hp, max = num(model, A.HP, 0), num(model, A.HPMax, 0)
	if (hp <= 0 and now - lastHit >= REVIVE_AFTER) or (hp < max and now - lastHit >= REGEN_AFTER) then
		model:SetAttribute(A.HP, max)
	end
end

function TrainingService.Start()
	local folder = workspace:FindFirstChild("TrainingDummies")
	local template = Shared.Assets:FindFirstChild("TrainingDummy")
	if not folder or not template then
		return
	end
	for _, spot in folder:GetChildren() do
		if spot:IsA("BasePart") then
			spawnDummy(template, spot)
		end
	end
	RunService.Heartbeat:Connect(function(dt)
		local now = time()
		for _, dummy in dummies do
			CombatSim.StepStagger(dummy.Model, now, dt)
			heal(dummy.Model, now)
			if dummy.Brain then
				dummy.Brain:Step(now)
			end
		end
	end)
end

return TrainingService
