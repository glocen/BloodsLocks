--!strict
-- SelfTestService (Studio only): the server half of the regression self-test (client half: SelfTestController).
-- It builds a test pad far above the map (a floor, a combat zone and a passive target dummy) so every place runs the
-- same checks whatever its world looks like, puts the player on it, and queues scripted hits on request. Clients
-- call these through the Studio-only DebugCommand remote (the player goes first); the MCP bridge can too.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local EntityState = require(Shared.Simulation.EntityState)
local CombatSim = require(Shared.Simulation.CombatSim)
local Parts = require(Shared.Util.Parts)
local Zones = require(Shared.Util.Zones)
local DebugService = require(script.Parent.DebugService)
local EntityService = require(script.Parent.EntityService)

local A = EntityState.Attr

local PAD_NAME = "BL_TestPad"
local PAD_CENTER = CFrame.new(0, 3000, 0) -- far above any map
local PAD_SIZE = Vector3.new(300, 4, 300)
local STAND_HEIGHT = 3 -- root height above the floor
local DUMMY_DISTANCE = 8 -- studs in front of the player: in saber reach after the lunge
local DUMMY_HEALTH = 1e6 -- never dies during a run; tests read the HP it loses
local DEFAULT_HIT = "Saber.Light1"

-- Which character attribute starts a TestHitAfter countdown.
local TRIGGERS: { [string]: string } = {
	Dodge = A.DodgeStart,
	Guard = A.GuardStart,
}

local SelfTestService = {}

local returnTo: { [Player]: CFrame } = {}

local function floorTop(): number
	return PAD_CENTER.Position.Y + PAD_SIZE.Y / 2
end

local function buildPad(): Folder
	local pad = Instance.new("Folder")
	pad.Name = PAD_NAME
	local floor = Instance.new("Part")
	floor.Name = "Floor"
	floor.Anchored = true
	floor.Size = PAD_SIZE
	floor.CFrame = PAD_CENTER
	floor.Material = Enum.Material.Slate
	floor.Parent = pad
	local zone = Instance.new("Part") -- the Manor only allows combat inside zones
	zone.Name = "CombatZone"
	zone.Anchored, zone.CanCollide, zone.CanQuery, zone.CanTouch = true, false, false, false
	zone.Transparency = 1
	zone.Size = Vector3.new(PAD_SIZE.X, 80, PAD_SIZE.Z)
	zone.CFrame = PAD_CENTER * CFrame.new(0, 40, 0)
	CollectionService:AddTag(zone, Zones.Tag)
	zone.Parent = pad
	pad.Parent = workspace
	return pad
end

local function standAt(offset: Vector3): Vector3
	return Vector3.new(PAD_CENTER.X, floorTop() + STAND_HEIGHT, PAD_CENTER.Z) + offset
end

-- The pad's dummy, rebuilt at full health with no stagger. Nil if the place has no dummy template.
local function freshDummy(pad: Instance, facing: Vector3): Model?
	local template = Shared.Assets:FindFirstChild("TrainingDummy") :: Model?
	local old = pad:FindFirstChild("Dummy")
	if old then
		old:Destroy()
	end
	if not template then
		return nil
	end
	local position = standAt(Vector3.new(0, 0, -DUMMY_DISTANCE))
	return EntityService.MakeDummy(template, "Dummy", CFrame.lookAt(position, facing), DUMMY_HEALTH, pad)
end

local function padDummy(): Model?
	local pad = workspace:FindFirstChild(PAD_NAME)
	local dummy = pad and pad:FindFirstChild("Dummy")
	if dummy then
		return dummy :: Model
	end
	local yard = workspace:FindFirstChild("TrainingDummies")
	return yard and yard:FindFirstChildWhichIsA("Model")
end

local function characterOf(who: any): (Player, Model, BasePart)
	local player = assert(DebugService.ResolvePlayer(who), "no such player")
	local character = assert(player.Character, "player has no character")
	local root = assert(Parts.Root(character), "character has no root")
	return player, character, root
end

-- Puts the player on the pad facing a fresh dummy, at full HP. Returns the dummy's name.
local function testPad(who: any): string?
	local player, character, root = characterOf(who)
	local pad = workspace:FindFirstChild(PAD_NAME) or buildPad()
	local spot = standAt(Vector3.zero)
	if not returnTo[player] then
		returnTo[player] = root.CFrame
	end
	player:RequestStreamAroundAsync(spot)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(spot, spot + Vector3.new(0, 0, -1))
	character:SetAttribute(A.HP, EntityState.Number(character, A.HPMax, 0))
	local dummy = freshDummy(pad, spot)
	return dummy and dummy.Name
end

-- Queues a hit from the pad dummy on the player `delay` seconds after the trigger: "Now", or the start of the
-- player's next "Dodge" / "Guard". `actionId` picks the hit (default: the saber's first light hit).
local function testHitAfter(who: any, trigger: string, delay: number, actionId: string?): boolean
	local _, character = characterOf(who)
	local attacker = assert(padDummy(), "no dummy to attack with")
	local hit = Registry.Action(actionId or DEFAULT_HIT).Hit
	local attribute = TRIGGERS[trigger]
	assert(attribute or trigger == "Now", `unknown trigger "{trigger}"`)
	task.spawn(function()
		if attribute then
			repeat
				character:GetAttributeChangedSignal(attribute):Wait()
			until EntityState.Number(character, attribute, -1) >= 0
		end
		task.wait(delay)
		CombatSim.Queue({ Attacker = attacker, Target = character, Hit = hit })
	end)
	return true
end

-- Removes the pad and puts the player back where they were.
local function testPadClear(who: any): boolean
	local player, _, root = characterOf(who)
	local pad = workspace:FindFirstChild(PAD_NAME)
	if pad then
		pad:Destroy()
	end
	local back = returnTo[player]
	returnTo[player] = nil
	if back then
		root.AssemblyLinearVelocity = Vector3.zero
		root.CFrame = back
	end
	return true
end

function SelfTestService.Init()
	if not RunService:IsStudio() then
		return
	end
	DebugService.Register("TestPad", testPad)
	DebugService.Register("TestHitAfter", testHitAfter)
	DebugService.Register("TestPadClear", testPadClear)
	-- Older name for the i-frame test helper (CLAUDE.md).
	DebugService.Register("HitAfterNextDodge", function(who: any, delay: number)
		return testHitAfter(who, "Dodge", delay)
	end)
end

return SelfTestService
