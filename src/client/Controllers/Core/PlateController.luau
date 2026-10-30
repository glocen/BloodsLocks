--!strict
-- PlateController: a Plate (UI/World/Plate) over the combat entities worth reading right now, drawn in the World layer
-- (projected each frame, so plates stay crisp, scale with the UI and sit under the HUD). Who gets one:
--   the target you've locked; anything hit in the last REVEAL seconds; an enemy that noticed you in the last
--   ALERT_HOLD seconds (it's coming for you); enemies (and training dummies) within NEAR; hunters (players, AI hunters)
--   and companions within PEOPLE. Never your own character.
-- A plate also needs a clear line of sight from the camera (checked every SIGHT_EVERY s, except for your lock) and is
-- dropped beyond FAR. At most MAX plates show, nearest first; they fade in and out.
-- What a plate says comes from attributes the entity already carries (HP, HPMax, Stagger, StaggerUntil, OwnerId,
-- Level, EnemyId) and the hit events on its Humanoid (EntityState.Fx). Names: always for hunters and companions, for
-- heavier enemies, and for whatever you lock. The running total counts the damage you and your companion dealt.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EntityState = require(Shared.Simulation.EntityState)
local Registry = require(Shared.Definitions.Registry)
local CombatConfig = require(Shared.Config.Combat)
local Parts = require(Shared.Util.Parts)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Plate = require(UI.World.Plate)
local WorldPin = require(UI.World.WorldPin)
local LockOnController = require(script.Parent.LockOnController)
local Budget = require(script.Parent.Parent.Parent.Util.Budget)

local A = EntityState.Attr
local num = EntityState.Number

local NEAR = 32 -- studs: enemies and dummies get a plate this close
local PEOPLE = 48 -- hunters and companions
local FAR = 90 -- never beyond this
local REVEAL = 6 -- seconds a hit keeps a plate up
local ALERT_HOLD = 8 -- seconds an enemy that noticed you keeps its plate up (out to FAR)
local TOTAL_HOLD = 3 -- seconds the damage total stays after your last hit
local SIGHT_EVERY = 0.2 -- seconds between line-of-sight checks per entity
local MAX = 12
local DEPTH_FROM, DEPTH_SHRINK = 12, 0.3 -- plates beyond DEPTH_FROM studs shrink, by up to 30% at FAR
local KIND_RECHECK = 1 -- seconds between side checks on a side-less (dummy) model
local FADE_RATE = 1 / Theme.Motion.Base -- alpha per second
local NAMED_TIERS = { Heavy = true, Elite = true } -- bosses get their own bar (B2)

local PlateController = {}

type Kind = "Enemy" | "Hunter" | "Companion" | "Dummy"
type Tracked = {
	Model: Model,
	Fx: Instance, -- where its hit and alert events land (EntityState.Fx)
	Plate: Plate.Plate?,
	Alpha: number,
	Total: number,
	TotalAt: number,
	SightAt: number,
	Seen: boolean,
	Top: number, -- studs from the root to just above the head
	Kind: Kind?, -- cached once known (an entity's side is set when it's made)
	KindAt: number,
	Def: any?, -- an enemy's or a companion's definition
	Connections: { RBXScriptConnection },
}

local player = Players.LocalPlayer
local tracked: { [Model]: Tracked } = {}
local layer: ScreenGui

-- Who a model is to you.
local function kindOf(model: Model): Kind
	if Players:GetPlayerFromCharacter(model) then
		return "Hunter"
	end
	local owner = model:GetAttribute(A.OwnerId)
	if owner == EntityState.HostileSide then
		return "Enemy"
	elseif type(owner) == "number" and owner < 0 then
		return "Hunter" -- an AI hunter's body
	elseif type(owner) == "number" then
		return "Companion"
	end
	return "Dummy"
end

-- Whether a hit on `model` was dealt by you or your companion (Fx LastHitBy holds the attacker's model name).
local function byYou(model: Model): boolean
	local by = EntityState.Fx(model):GetAttribute(A.LastHitBy)
	if type(by) ~= "string" or by == "" then
		return false
	end
	if player.Character and by == player.Character.Name then
		return true
	end
	for other in tracked do
		if other.Name == by and kindOf(other) == "Companion" and other:GetAttribute(A.OwnerId) == player.UserId then
			return true
		end
	end
	return false
end

-- Studs from the root to just above the head (measured once the model has its parts).
local function topOf(model: Model): number
	return model:GetExtentsSize().Y / 2 + 0.6
end

-- The entry's kind, worked out once the entity has its side (a side-less model is re-checked now and then: its side
-- may arrive a moment after its tag), and an enemy's definition.
local function refresh(entry: Tracked, now: number): Kind
	if entry.Kind and (entry.Kind ~= "Dummy" or now - entry.KindAt < KIND_RECHECK) then
		return entry.Kind
	end
	local kind = kindOf(entry.Model)
	entry.Kind, entry.KindAt = kind, now
	entry.Def = if kind == "Enemy" then Registry.Enemy(entry.Model:GetAttribute(A.EnemyId))
		elseif kind == "Companion" then Registry.Shinigami(entry.Model:GetAttribute(A.ShinigamiId))
		else nil
	return kind
end

local function track(model: Instance)
	if not model:IsA("Model") or tracked[model] or model == player.Character then
		return
	end
	local fx = EntityState.Fx(model)
	local entry: Tracked = {
		Model = model,
		Fx = fx,
		Plate = nil,
		Alpha = 0,
		Total = 0,
		TotalAt = -math.huge,
		SightAt = 0,
		Seen = false,
		Top = 0, -- measured when first needed
		Kind = nil,
		KindAt = -math.huge,
		Def = nil,
		Connections = {},
	}
	table.insert(entry.Connections, fx:GetAttributeChangedSignal(A.LastHitAt):Connect(function()
		if byYou(model) then
			local now = time()
			if now - entry.TotalAt > TOTAL_HOLD then
				entry.Total = 0
			end
			entry.Total += num(fx, A.LastHitDamage, 0)
			entry.TotalAt = now
		end
	end))
	tracked[model] = entry
end

local function untrack(model: Instance)
	local entry = tracked[model :: Model]
	if not entry then
		return
	end
	for _, connection in entry.Connections do
		connection:Disconnect()
	end
	if entry.Plate then
		entry.Plate:Destroy()
	end
	tracked[model :: Model] = nil
end

local function name(entry: Tracked, kind: Kind, locked: boolean): (string?, Color3?)
	local model = entry.Model
	if kind == "Hunter" then
		return `{model.Name}  <font transparency="0.4">Lv {num(model, A.Level, 1)}</font>`, Theme.Colors.Text
	elseif kind == "Companion" then
		local yours = model:GetAttribute(A.OwnerId) == player.UserId
		return if entry.Def then entry.Def.DisplayName else model.Name, if yours then Theme.Colors.Accent else Theme.Colors.TextMuted
	end
	local def = entry.Def
	if locked or (def and NAMED_TIERS[def.Tier]) then
		return if def then def.DisplayName else model.Name, Theme.Colors.Text
	end
	return nil, nil
end

local function wanted(entry: Tracked, kind: string, distance: number, locked: boolean, now: number): boolean
	if locked then
		return true
	end
	if distance > FAR or num(entry.Model, A.HP, 0) <= 0 then
		return false
	end
	local fx = entry.Fx
	if now - num(fx, A.LastHitAt, -math.huge) < REVEAL then
		return true
	end
	local character = player.Character
	if kind == "Enemy" and character and now - num(fx, A.AlertAt, -math.huge) < ALERT_HOLD and fx:GetAttribute(A.AlertTarget) == character.Name then
		return true
	end
	return distance <= (if kind == "Hunter" or kind == "Companion" then PEOPLE else NEAR)
end

local sight = RaycastParams.new() -- reused: one line-of-sight check per entity every SIGHT_EVERY seconds
sight.FilterType = Enum.RaycastFilterType.Exclude

local function inSight(entry: Tracked, top: Vector3, now: number): boolean
	if now - entry.SightAt >= SIGHT_EVERY then
		entry.SightAt = now
		local camera = workspace.CurrentCamera.CFrame.Position
		sight.FilterDescendantsInstances = { entry.Model, player.Character :: any }
		entry.Seen = workspace:Raycast(camera, top - camera, sight) == nil
	end
	return entry.Seen
end

local function update(dt: number)
	local now = time()
	local myRoot = Parts.Root(player.Character)
	local locked = LockOnController.GetTarget()
	local chosen: { { Entry: Tracked, Distance: number } } = {}
	for model, entry in tracked do
		local root = Parts.Root(model)
		if not model.Parent or not root then
			untrack(model)
		elseif myRoot and model ~= player.Character then
			if entry.Top < 2.5 then
				entry.Top = topOf(model)
			end
			local kind = refresh(entry, now)
			local distance = (root.Position - myRoot.Position).Magnitude
			local isLocked = model == locked
			local top = root.Position + Vector3.new(0, entry.Top, 0)
			if wanted(entry, kind, distance, isLocked, now) and (isLocked or inSight(entry, top, now)) then
				table.insert(chosen, { Entry = entry, Distance = distance })
			end
		end
	end
	table.sort(chosen, function(a, b)
		return a.Distance < b.Distance
	end)
	local show: { [Tracked]: number } = {} -- the plate's distance rank (1 = nearest)
	for i = 1, math.min(MAX, #chosen) do
		show[chosen[i].Entry] = i
	end
	for model, entry in tracked do
		local rank = show[entry]
		entry.Alpha = math.clamp(entry.Alpha + (if rank then 1 else -1) * FADE_RATE * dt, 0, 1)
		if entry.Alpha <= 0 then
			if entry.Plate then
				entry.Plate:Alpha(0)
			end
			continue
		end
		local root = Parts.Root(model) :: BasePart
		local position = WorldPin.Project(root.Position + Vector3.new(0, entry.Top, 0), 40)
		if not position then
			if entry.Plate then
				entry.Plate:Alpha(0)
			end
			continue
		end
		local plate = entry.Plate or Plate.new(layer)
		entry.Plate = plate
		local kind = refresh(entry, now)
		local isLocked = model == locked
		local label, color = name(entry, kind, isLocked)
		local def = entry.Def
		plate:Set({
			Name = label,
			NameColor = color,
			Wide = isLocked or (def and NAMED_TIERS[def.Tier]) == true,
			Hp = num(model, A.HP, 0) / math.max(1, num(model, A.HPMax, 1)),
			Posture = num(model, A.Stagger, 0) / CombatConfig.StaggerMax,
			Staggered = num(model, A.StaggerUntil, 0) > now,
			Total = if now - entry.TotalAt <= TOTAL_HOLD and entry.Total > 0 then entry.Total else nil,
		}, dt)
		plate:Place(position - UDim2.fromOffset(0, Theme.Plate.Rise))
		local distance = if myRoot then (root.Position - myRoot.Position).Magnitude else 0
		plate:Depth(1 - DEPTH_SHRINK * math.clamp((distance - DEPTH_FROM) / (FAR - DEPTH_FROM), 0, 1), MAX + 1 - (rank or MAX))
		plate:Alpha(entry.Alpha)
	end
end

-- For the self-test: what each tracked entity's plate shows right now.
function PlateController.Snapshot(): { [Model]: { Shown: boolean, Hp: number, Total: number? } }
	local out = {}
	local now = time()
	for model, entry in tracked do
		out[model] = {
			Shown = entry.Alpha > 0 and entry.Plate ~= nil and entry.Plate.Frame.Visible,
			Hp = num(model, A.HP, 0) / math.max(1, num(model, A.HPMax, 1)),
			Total = if now - entry.TotalAt <= TOTAL_HOLD and entry.Total > 0 then entry.Total else nil,
		}
	end
	return out
end

function PlateController.Start()
	layer = Layers.Get("World")
	for _, model in CollectionService:GetTagged(EntityState.Tag) do
		track(model)
	end
	CollectionService:GetInstanceAddedSignal(EntityState.Tag):Connect(track)
	CollectionService:GetInstanceRemovedSignal(EntityState.Tag):Connect(untrack)
	RunService.RenderStepped:Connect(Budget.Wrap("Plates", update))
end

return PlateController
