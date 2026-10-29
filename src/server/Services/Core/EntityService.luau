--!strict
-- EntityService: makes every player character a combat entity (the tag hit detection and feedback look for)
-- and turns 0 HP into a real death, since Humanoid.Health isn't simulation state. MakeEntity builds a non-player
-- entity from a rig template (training dummies, the self-test's dummy, enemies).
-- PlayerDied fires once per death with the credit: damage on a character is tallied by the attacker's side
-- (CombatSim.Side: a player's UserId, the master of a Shinigami or minion, an AI hunter's negative id), and the
-- killer is the side that landed the killing blow. Enemies (the hostile side) and the victim's own side never get
-- credit. The tally starts over with each new character.
-- Watch(model) gives any other body the same bookkeeping (AI hunters): BodyDied fires once when it reaches 0 HP.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Parts = require(Shared.Util.Parts)
local Signal = require(Shared.Util.Signal)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)

type Tally = { Shares: { [number]: number }, Killer: number? }

local EntityService = {}

-- Fires (player, killerSide: number?, sharesBySide) once when a player's character reaches 0 HP.
EntityService.PlayerDied = Signal.new() :: Signal.Signal<Player, number?, { [number]: number }>
-- Fires (model, killerSide: number?, sharesBySide) once when a watched body (Watch) reaches 0 HP.
EntityService.BodyDied = Signal.new() :: Signal.Signal<Model, number?, { [number]: number }>

local tallies: { [Model]: Tally } = {}
local bodies: { [Model]: boolean } = {} -- watched non-player bodies: true once their death has fired

-- Tallies credit for `model` and reports its death once (BodyDied). For bodies that aren't player characters.
function EntityService.Watch(model: Model)
	tallies[model] = { Shares = {}, Killer = nil }
	bodies[model] = false
	model.Destroying:Connect(function()
		tallies[model], bodies[model] = nil, nil
	end)
end

local function watch(player: Player)
	local function tag(character: Model)
		CollectionService:AddTag(character, EntityState.Tag)
		tallies[character] = { Shares = {}, Killer = nil }
		character.Destroying:Connect(function()
			tallies[character] = nil
		end)
	end
	player.CharacterAdded:Connect(tag)
	if player.Character then
		tag(player.Character)
	end
end

-- The side that gets credit for a hit on `target`, or nil (enemies, its own side, unowned dummies).
local function creditSide(target: Model, attacker: Model): number?
	local side = CombatSim.Side(attacker)
	if side == nil or side == EntityState.HostileSide or side == CombatSim.Side(target) then
		return nil
	end
	return side
end

local function onDamaged(target: Model, attacker: Model, amount: number, hpLeft: number)
	local tally = tallies[target]
	if not tally then
		return
	end
	local side = creditSide(target, attacker)
	if side then
		tally.Shares[side] = (tally.Shares[side] or 0) + amount
	end
	if hpLeft <= 0 then
		tally.Killer = side -- an enemy's killing blow leaves no killer
	end
end

-- A non-player entity cloned from a rig template, standing at `cframe`. Its Humanoid never dies (combat HP is the
-- entity's attribute) and shows no name or health bar. `tint` recolours the body (placeholder looks); `scale`
-- sizes the whole rig.
function EntityService.MakeEntity(template: Model, name: string, cframe: CFrame, health: number, parent: Instance, tint: Color3?, scale: number?): Model
	local model = template:Clone()
	model.Name = name
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif tint and d:IsA("BasePart") and d.Name ~= "HumanoidRootPart" then
			d.Color = tint
		end
	end
	if scale and scale ~= 1 then
		model:ScaleTo(scale)
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
	CombatSim.Damaged:Connect(onDamaged)
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = Parts.Humanoid(character)
			if character and humanoid and humanoid.Health > 0 and EntityState.Number(character, EntityState.Attr.HP, 1) <= 0 then
				humanoid.Health = 0 -- only once: the next check sees a dead Humanoid
				local tally = tallies[character] or { Shares = {}, Killer = nil }
				EntityService.PlayerDied:Fire(player, tally.Killer, tally.Shares)
			end
		end
		for model, fired in bodies do
			if not fired and EntityState.Number(model, EntityState.Attr.HP, 1) <= 0 then
				bodies[model] = true
				local tally = tallies[model]
				EntityService.BodyDied:Fire(model, tally.Killer, tally.Shares)
			end
		end
	end)
end

return EntityService
