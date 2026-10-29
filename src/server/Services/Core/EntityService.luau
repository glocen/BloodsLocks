--!strict
-- EntityService: makes every player character a combat entity (the tag hit detection and feedback look for)
-- and turns 0 HP into a real death, since Humanoid.Health isn't simulation state. MakeDummy builds a non-player
-- target entity (the Manor's training dummies, the self-test's dummy).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local EntityState = require(Shared.Simulation.EntityState)

local EntityService = {}

local function watch(player: Player)
	local function tag(character: Model)
		CollectionService:AddTag(character, EntityState.Tag)
	end
	player.CharacterAdded:Connect(tag)
	if player.Character then
		tag(player.Character)
	end
end

-- A dummy entity cloned from a rig template, standing at `cframe`. Its Humanoid never dies (combat HP is the
-- entity's attribute) and shows no name or health bar.
function EntityService.MakeDummy(template: Model, name: string, cframe: CFrame, health: number, parent: Instance): Model
	local model = template:Clone()
	model.Name = name
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth, humanoid.Health = math.huge, math.huge
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	model:PivotTo(cframe)
	EntityState.InitCombat(model, health, time())
	CollectionService:AddTag(model, EntityState.Tag)
	model.Parent = parent
	return model
end

function EntityService.Start()
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = Parts.Humanoid(character)
			if character and humanoid and humanoid.Health > 0 and EntityState.Number(character, EntityState.Attr.HP, 1) <= 0 then
				humanoid.Health = 0
			end
		end
	end)
end

return EntityService
