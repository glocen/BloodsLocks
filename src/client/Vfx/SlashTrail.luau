--!strict
-- SlashTrail: what a sabre leaves in the air (docs/combat-rework.md, C1.2), from our drawn textures
-- (tools/blender/vfx_sprites.py): a dark blood smear between the blade's base and point, a hot hairline along the
-- point's path, blood flung off the point and a breath of dark mist, drawn only while the blow sweeps through.
-- Play(model, id, action, startedAt): schedules one swing's trail on the model's held blade (its BladeBase and BladeTip
-- points, Simulation/Equipment), from just before the action's hit window to just after; a swing cancelled before it
-- comes (a dodge, a stagger) draws nothing. Heavy blows leave a longer smear and more blood.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Equipment = require(ReplicatedStorage.Shared.Simulation.Equipment)
local EntityState = require(ReplicatedStorage.Shared.Simulation.EntityState)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)

local T = Kit.Textures
local V = Theme.Vfx

local LEAD = 0.07 -- the smear starts this long before the hit window opens (the blade is already sweeping)
local TAIL = 0.05 -- and keeps drawing this long after it closes
local EDGE_FROM = 0.75 -- the hairline covers the blade from here (0 the base point, 1 the point) to the point
local MIST_AT = 0.6 -- the mist breathes off the blade here
local SMEAR_LIFE, EDGE_LIFE = 0.16, 0.1 -- seconds a stretch of smear / hairline lasts
local DROPS, MIST = 60, 20 -- particles a second while the blade draws
local HEAVY = 1.4 -- heavy blows: the smear lasts longer, more blood flies

type Rig = { Smear: Trail, Edge: Trail, Drops: ParticleEmitter, Mist: ParticleEmitter, Until: number }

local SlashTrail = {}

local rigs: { [Model]: Rig } = setmetatable({}, { __mode = "k" }) :: any

local function point(parent: BasePart, position: Vector3): Attachment
	local attachment = Instance.new("Attachment")
	attachment.Position = position
	attachment.Parent = parent
	return attachment
end

local function trail(from: Attachment, to: Attachment, props: { [string]: any }): Trail
	local t = Instance.new("Trail")
	t.Attachment0, t.Attachment1 = from, to
	t.TextureMode = Enum.TextureMode.Stretch
	t.FaceCamera = false -- the smear lies in the swing's plane
	t.MinLength = 0.05
	t.Enabled = false
	for key, value in props do
		(t :: any)[key] = value
	end
	t.Parent = to.Parent
	return t
end

-- The trail's pieces on a held weapon, built once and kept with it (nil for a model without blade points).
local function rig(weapon: Model): Rig?
	local built = rigs[weapon]
	if built then
		return built
	end
	local base = Equipment.Point(weapon, Equipment.Points.BladeBase)
	local tip = Equipment.Point(weapon, Equipment.Points.BladeTip)
	local blade = tip and tip.Parent
	if not base or not tip or not blade or not blade:IsA("BasePart") then
		return nil
	end
	local made: Rig = {
		Smear = trail(base, tip, {
			Texture = T.SlashSmear,
			Color = Kit.Colors(V.BloodWet, V.BloodDark),
			Transparency = Kit.Seq({ { 0, 0.05 }, { 0.6, 0.35 }, { 1, 1 } }),
			LightEmission = 0, -- alpha-blended: blood reads dark, never neon
			LightInfluence = 0.4,
			Lifetime = SMEAR_LIFE,
		}),
		Edge = trail(point(blade, base.Position:Lerp(tip.Position, EDGE_FROM)), tip, {
			Texture = T.SlashEdge,
			Color = Kit.Colors(V.BloodCore, V.Blood),
			Transparency = Kit.Seq(0, 1),
			LightEmission = 1,
			LightInfluence = 0,
			Lifetime = EDGE_LIFE,
		}),
		Drops = Kit.Emitter(tip, { -- blood flung off the point: it falls along the arc behind the blade
			Texture = T.Spark,
			Orientation = Enum.ParticleOrientation.VelocityParallel,
			Color = Kit.Colors(V.BloodWet, V.BloodDeep),
			LightInfluence = 0.5,
			Size = Kit.Seq({ { 0, 0.16 }, { 1, 0.05 } }),
			Lifetime = NumberRange.new(0.25, 0.45),
			Speed = NumberRange.new(2, 6),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -60, 0),
			Drag = 1,
		}),
		Mist = Kit.Emitter(point(blade, base.Position:Lerp(tip.Position, MIST_AT)), { -- a breath of dark mist left hanging
			Texture = T.SmokePuff,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(V.BloodDark),
			LightInfluence = 0.5,
			Transparency = Kit.Seq({ { 0, 0.6 }, { 1, 1 } }),
			Size = Kit.Seq({ { 0, 0.5 }, { 1, 1.3 } }),
			Lifetime = NumberRange.new(0.4, 0.6),
			Speed = NumberRange.new(0.3, 0.8),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 4,
			Rotation = NumberRange.new(0, 360),
		}),
		Until = 0,
	}
	rigs[weapon] = made
	return made
end

local function draw(pieces: Rig, on: boolean, heavy: boolean)
	local scale = if heavy then HEAVY else 1
	pieces.Smear.Lifetime = SMEAR_LIFE * scale
	pieces.Smear.Enabled, pieces.Edge.Enabled = on, on
	pieces.Drops.Rate = if on then DROPS * scale else 0
	pieces.Mist.Rate = if on then MIST * scale else 0
end

function SlashTrail.Play(model: Model, id: string, action: any, startedAt: number)
	local hit = action and action.Hit
	local weapon = Equipment.Held(model, "Right")
	local pieces = hit and weapon and rig(weapon)
	if not pieces then
		return
	end
	local heavy = hit.Damage >= Combat.Hitstop.HeavyDamage -- the blows that hit hard enough for the long hitstop
	local from, to = startedAt + hit.From - LEAD, startedAt + hit.To + TAIL
	pieces.Until = math.max(pieces.Until, to)
	task.delay(math.max(from - time(), 0), function()
		local current, _, started = EntityState.CurrentAction(model)
		if current == id and started == startedAt then
			draw(pieces, true, heavy)
		end
	end)
	task.delay(math.max(to - time(), 0), function()
		if time() >= pieces.Until - 1e-3 then
			draw(pieces, false, heavy)
		end
	end)
end

return SlashTrail
