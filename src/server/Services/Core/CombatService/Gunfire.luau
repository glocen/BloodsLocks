--!strict
-- Gunfire: hitscan actions. A gun's Shots list fires one bullet per entry, each in its own cone of the action's
-- Spread (it blooms through the burst), and tells every client where it went (ShotFx: the muzzle, where it stopped,
-- the surface's facing, whether it hit a body). A Beam fires a tick every Interval between From and To along the
-- current aim (the beam visual is drawn by clients from the shooter's state, so ticks send nothing).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local Hitscan = require(Shared.Util.Hitscan)
local Muzzle = require(Shared.Util.Muzzle)
local EntityState = require(Shared.Simulation.EntityState)

type OnHit = (attacker: Model, target: Model, hit: any) -> ()

local Gunfire = {}

local fired: { [Model]: { Start: number, Count: number } } = {}
local random = Random.new()
local scheduleCache: { [any]: { number } } = {}

-- Seconds into the action at which each shot or beam tick fires.
local function schedule(action: any): { number }
	if action.Shots then
		return action.Shots
	end
	local cached = scheduleCache[action]
	if not cached then
		cached = {}
		local beam = action.Beam
		local t = beam.From
		while t < beam.To - 1e-6 do
			table.insert(cached, t)
			t += beam.Interval
		end
		scheduleCache[action] = cached
	end
	return cached
end

-- `direction` turned by a point picked uniformly over a cone of `degrees` around it.
local function scatter(direction: Vector3, degrees: number): Vector3
	if degrees <= 0 then
		return direction
	end
	local turn = random:NextNumber(0, 2 * math.pi)
	local radius = math.rad(degrees) * math.sqrt(random:NextNumber()) -- the square root spreads points evenly over the disc
	return (CFrame.lookAt(Vector3.zero, direction) * CFrame.Angles(radius * math.sin(turn), radius * math.cos(turn), 0)).LookVector
end

-- Fires shot number `shot` (1-based) of the action, or one beam tick.
local function fire(model: Model, root: BasePart, action: any, shot: number, onHit: OnHit)
	local origin, direction = Muzzle.Get(root, model:GetAttribute(EntityState.Attr.Aim))
	local spread = action.Spread
	if spread then
		direction = scatter(direction, math.min(spread.Base + (shot - 1) * spread.Bloom, spread.Max))
	end
	local range = if action.Beam then action.Beam.Range else action.Range
	local result = Hitscan.Cast(origin, direction, range, 0, { model }, EntityState.Tag)
	if result.Entity then
		onHit(model, result.Entity, action.Hit)
	end
	if not action.Beam then
		Net.Server.FireAll("ShotFx", model, origin, result.Position, result.Normal, result.Entity ~= nil)
	end
end

-- Fires every shot or tick of the action that's due by `now`.
function Gunfire.Update(model: Model, action: any, startedAt: number, now: number, onHit: OnHit)
	local root = Parts.Root(model)
	local times = schedule(action)
	local record = fired[model]
	if not record or record.Start ~= startedAt then
		record = { Start = startedAt, Count = 0 }
		fired[model] = record
	end
	while root and record.Count < #times and now - startedAt >= times[record.Count + 1] do
		record.Count += 1
		fire(model, root, action, record.Count, onHit)
	end
end

function Gunfire.Forget(model: Model)
	fired[model] = nil
end

return Gunfire
