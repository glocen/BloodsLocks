--!strict
-- ShinigamiService: companions bound by pact (our take on Duskbloods' Kin; docs/duskbloods-manual-summary.md §3).
--   Pact: at a summoning circle (a part tagged BL_PactCircle with a "Shinigami" attribute). One pact per player;
--     a new pact replaces the old one and resets its level to 1.
--   Summon / dismiss: the client fires ShinigamiToggle (key T). A summoned Shinigami is a combat entity on its
--     master's side (EntityState OwnerId) driven by ShinigamiBrain.
--   Death: it's dismissed and can't be resummoned for ResummonCooldown seconds.
--   Regen: it recovers Regen (fraction of max HP per second) while dismissed or out of combat.
--   Level: it levels with its master (never below the level it reached); its special Skill unlocks at
--     Skill.UnlockLevel (everything is unlocked in the Manor, like player skills).
-- The HUD reads the pact from the Player's PlayerState.Shinigami* attributes.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local Equipment = require(Shared.Simulation.Equipment)
local Parts = require(Shared.Util.Parts)
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)
local DebugService = require(script.Parent.DebugService)
local ShinigamiBrain = require(script.ShinigamiBrain)

local A = EntityState.Attr
local num = EntityState.Number

local CIRCLE_TAG = "BL_PactCircle"
local OUT_OF_COMBAT = 5 -- seconds without a hit before it regenerates while summoned
local P = PlayerState.Attr

type Pact = {
	Id: string,
	Level: number,
	Hp: number, -- fraction of max, kept while dismissed
	CooldownUntil: number,
	Model: Model?,
	Brain: ShinigamiBrain.Brain?,
}

local ShinigamiService = {}

local pacts: { [Player]: Pact } = {}
local folder: Folder

local function publish(player: Player, pact: Pact?)
	player:SetAttribute(P.ShinigamiId, if pact then pact.Id else nil)
	player:SetAttribute(P.ShinigamiLevel, if pact then pact.Level else nil)
	player:SetAttribute(P.ShinigamiHp, if pact then pact.Hp else nil)
	player:SetAttribute(P.ShinigamiOut, if pact then pact.Model ~= nil else nil)
	player:SetAttribute(P.ShinigamiCooldown, if pact then pact.CooldownUntil else nil)
end

local function maxHealth(def: any, level: number): number
	return math.floor(def.BaseHealth * (1 + 0.1 * (level - 1)))
end

local function despawn(pact: Pact)
	local model = pact.Model
	if model then
		pact.Hp = math.clamp(num(model, A.HP, 0) / math.max(1, num(model, A.HPMax, 1)), 0, 1)
		pact.Model, pact.Brain = nil, nil
		model:Destroy()
	end
end

local function build(player: Player, def: any, pact: Pact): Model?
	local template = Shared.Assets:FindFirstChild("TrainingDummy")
	local character = player.Character
	local ownerRoot = Parts.Root(character)
	if not template or not ownerRoot then
		return nil
	end
	local model = template:Clone() :: Model
	model.Name = `{def.DisplayName}_{player.Name}`
	for _, d in model:GetDescendants() do
		if d:IsA("BaseScript") then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Color = Color3.fromRGB(26, 20, 30)
			d.Material = Enum.Material.SmoothPlastic
		elseif d:IsA("Decal") then
			d.Color3 = Color3.fromRGB(200, 30, 50)
		end
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.MaxHealth, humanoid.Health = math.huge, math.huge
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.WalkSpeed = def.WalkSpeed
	local aura = Instance.new("Highlight")
	aura.FillTransparency = 1
	aura.OutlineColor = Color3.fromRGB(176, 22, 44)
	aura.OutlineTransparency = 0.35
	aura.Parent = model
	-- placeholder look (a dark spectral swordsman) until the modelled version lands
	local max = maxHealth(def, pact.Level)
	EntityState.InitCombat(model, max, time())
	model:SetAttribute(A.HP, math.max(1, math.floor(max * pact.Hp)))
	model:SetAttribute(A.OwnerId, player.UserId)
	model:SetAttribute(A.Level, pact.Level)
	model:PivotTo(ownerRoot.CFrame * CFrame.new(4, 0, 3))
	-- (no SetNetworkOwner: it throws under Server Authority; server-created NPCs are server-simulated already)
	model.Parent = folder
	if def.Weapon then
		Equipment.AttachMelee(model, def.Weapon)
	end
	CollectionService:AddTag(model, EntityState.Tag)
	return model
end

function ShinigamiService.MakePact(player: Player, id: string): boolean
	local def = Registry.Shinigami(id)
	if not def then
		return false
	end
	local current = pacts[player]
	if current and current.Id == id then
		return true
	end
	if current then
		despawn(current)
	end
	pacts[player] = { Id = id, Level = 1, Hp = 1, CooldownUntil = 0 }
	publish(player, pacts[player])
	Log.Info("Shinigami", `{player.Name} made a pact with {id}`)
	return true
end

function ShinigamiService.Toggle(player: Player): boolean
	local pact = pacts[player]
	if not pact then
		return false
	end
	if pact.Model then
		despawn(pact)
	elseif time() >= pact.CooldownUntil then
		local def = Registry.Shinigami(pact.Id)
		local model = build(player, def, pact)
		if model then
			pact.Model = model
			pact.Brain = ShinigamiBrain.new(model, player, def)
		end
	end
	publish(player, pact)
	return pact.Model ~= nil
end

local function step(dt: number)
	local now = time()
	for player, pact in pacts do
		local def = Registry.Shinigami(pact.Id)
		local model = pact.Model
		local masterLevel = if player.Character then num(player.Character, A.Level, 1) else 1
		if masterLevel > pact.Level then
			pact.Level = masterLevel
			if model then
				model:SetAttribute(A.Level, pact.Level)
				model:SetAttribute(A.HPMax, maxHealth(def, pact.Level))
			end
		end
		if model then
			local hp = num(model, A.HP, 0)
			local max = num(model, A.HPMax, 1)
			local character = player.Character
			if hp <= 0 then
				despawn(pact)
				pact.Hp = 0
				pact.CooldownUntil = now + def.ResummonCooldown
			elseif not character or num(character, A.HP, 1) <= 0 then
				despawn(pact) -- master died or left: it fades with them
			else
				if hp < max and now - num(EntityState.Fx(model), A.LastHitAt, -10) >= OUT_OF_COMBAT then
					model:SetAttribute(A.HP, math.min(max, hp + max * def.Regen * dt))
				end
				pact.Hp = num(model, A.HP, 0) / math.max(1, max)
				if pact.Brain then
					pact.Brain:Step(now)
				end
			end
		else
			pact.Hp = math.min(1, pact.Hp + def.Regen * dt)
		end
		publish(player, pact)
	end
end

function ShinigamiService.Init()
	DebugService.Register("ShinigamiPact", function(name: any, id: any)
		local player = DebugService.ResolvePlayer(name)
		return player ~= nil and ShinigamiService.MakePact(player, tostring(id))
	end)
	DebugService.Register("ShinigamiLevel", function(name: any, level: any)
		local player = DebugService.ResolvePlayer(name)
		local pact = player and pacts[player]
		if not pact then
			return false
		end
		pact.Level = math.max(1, math.floor(tonumber(level) or 1))
		if pact.Model then
			pact.Model:SetAttribute(A.Level, pact.Level)
		end
		return pact.Level
	end)
	DebugService.Register("ShinigamiToggle", function(name: any)
		local player = DebugService.ResolvePlayer(name)
		return player ~= nil and ShinigamiService.Toggle(player)
	end)
end

local function addPrompt(circle: Instance)
	if not circle:IsA("BasePart") then
		return
	end
	local def = Registry.Shinigami(circle:GetAttribute("Shinigami"))
	if not def then
		Log.Warn("Shinigami", `pact circle {circle:GetFullName()} names no known Shinigami`)
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Make a Pact"
	prompt.ObjectText = `{def.DisplayName} · {def.Role}`
	prompt.KeyboardKeyCode = Enum.KeyCode.G
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = circle
	prompt.Triggered:Connect(function(player)
		ShinigamiService.MakePact(player, def.Id)
	end)
end

function ShinigamiService.Start()
	folder = Instance.new("Folder")
	folder.Name = "Shinigami"
	folder.Parent = workspace
	for _, circle in CollectionService:GetTagged(CIRCLE_TAG) do
		addPrompt(circle)
	end
	CollectionService:GetInstanceAddedSignal(CIRCLE_TAG):Connect(addPrompt)
	Net.Server.On("ShinigamiToggle", function(player: Player)
		ShinigamiService.Toggle(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local pact = pacts[player]
		if pact then
			despawn(pact)
		end
		pacts[player] = nil
	end)
	RunService.Heartbeat:Connect(step)
end

return ShinigamiService
