--!strict
-- SlashTrail: a blade's motion smear, after the network-test study (docs/reference/network-test/vfx.md, "The sabre
-- M1"): during the swing's fast arc a pale, translucent wedge follows the blade for a few frames, denser toward the
-- point, with a brighter line on the point's path. It takes the scene's light (gold by firelight, silver at night) and
-- nothing lingers. From our drawn textures (tools/blender/vfx_sprites.py:
-- blade_smear, slash_edge), between the held blade's BladeBase and BladeTip points (Simulation/Equipment).
-- Play(model, id, action, startedAt): draws one swing's smear around its hit window; a swing cancelled before it
-- comes (a dodge, a stagger) draws nothing. Heavy blows smear a little longer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(script.Parent.Kit)
local Theme = require(script.Parent.Parent.UI.Theme)
local Equipment = require(ReplicatedStorage.Shared.Simulation.Equipment)
local EntityState = require(ReplicatedStorage.Shared.Simulation.EntityState)
local Combat = require(ReplicatedStorage.Shared.Config.Combat)

local T = Kit.Textures
local V = Theme.Vfx

local LEAD = 0.05 -- the smear starts this long before the hit window opens (the blade is already fast)
local TAIL = 0.02 -- and stops this long after it closes
local EDGE_FROM = 0.7 -- the bright line covers the blade from here (0 the base point, 1 the point) to the point
local SMEAR_LIFE, EDGE_LIFE = 0.085, 0.06 -- seconds a stretch of smear / line lasts (2-3 frames at 30 fps)
local HEAVY = 1.5 -- heavy blows: the smear lasts this much longer

type Rig = { Smear: Trail, Edge: Trail, Until: number }

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
	t.MinLength = 0.02
	t.Enabled = false
	for key, value in props do
		(t :: any)[key] = value
	end
	t.Parent = to.Parent
	return t
end

-- The smear's pieces on a held weapon, built once and kept with it (nil for a model without blade points).
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
			Texture = T.BladeSmear,
			Color = ColorSequence.new(V.BladeSmear),
			Transparency = Kit.Seq({ { 0, 0.1 }, { 1, 1 } }),
			LightEmission = 0.15,
			LightInfluence = 0.75, -- it takes the scene's light, as a real blur of the steel would
			Lifetime = SMEAR_LIFE,
		}),
		Edge = trail(point(blade, base.Position:Lerp(tip.Position, EDGE_FROM)), tip, {
			Texture = T.SlashEdge,
			Color = ColorSequence.new(V.BladeEdge),
			Transparency = Kit.Seq({ { 0, 0.35 }, { 1, 1 } }),
			LightEmission = 0.6,
			LightInfluence = 0.3,
			Lifetime = EDGE_LIFE,
		}),
		Until = 0,
	}
	rigs[weapon] = made
	return made
end

local function draw(pieces: Rig, on: boolean, heavy: boolean)
	local scale = if heavy then HEAVY else 1
	pieces.Smear.Lifetime = SMEAR_LIFE * scale
	pieces.Edge.Lifetime = EDGE_LIFE * scale
	pieces.Smear.Enabled, pieces.Edge.Enabled = on, on
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
