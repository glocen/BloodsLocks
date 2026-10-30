--!strict
-- PactSiteController: dresses every pact circle (BL_PactCircle markers) on this client, in the layers of Duskbloods'
-- Kin circles (docs/duskbloods-evidence-appendix.md, "Kin circle and presence"):
--   from afar, a soft shaft of moonlight falling on the site with motes drifting up in it, seen over the rooftops;
--   close up, the blood sigil turning slowly on the ground (unless the marker is a visible circle of its own), a cold
--   pool of light from above, and the Shinigami itself waiting in it, head bowed, facing the way the marker faces
--   (Simulation/ShinigamiBody: the same body it has when summoned);
--   the pact (its prompt is on the marker: ShinigamiService): the waiting figure breaks into mist, the sigil flares,
--   and the same mist rises around you as it binds to you.
-- While your pact is with that Shinigami it isn't waiting there (it's with you) and the circle offers no pact; the
-- sigil and the light stay. Everything is local and built from the marker, so a world's authors only place and turn
-- markers.

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local PlayerState = require(Shared.Simulation.PlayerState)
local ShinigamiBody = require(Shared.Simulation.ShinigamiBody)
local WorldTags = require(Shared.World.Tags)
local Markers = require(Shared.World.Markers)
local Client = script.Parent.Parent.Parent
local Theme = require(Client.UI.Theme)
local Kit = require(Client.Vfx.Kit)
local Arrival = require(Client.Vfx.Arrival)

local K = Theme.Pact
local P = PlayerState.Attr
local TAG = WorldTags.PactCircle.Tag
local FLOOR_PROBE = 20 -- studs looked down from a marker for the floor it stands on
local OWN_ART = 0.95 -- a marker less transparent than this is a drawn circle of its own: no sigil over it
local STAND = 3 -- studs from the floor to the rig's root
local SPIN_RANGE = 150 -- studs: sigils farther from the camera don't turn (nobody sees it)

local PactSiteController = {}

type Site = {
	Marker: BasePart,
	Def: any,
	Root: Model,
	Floor: Vector3,
	Sigil: ImageLabel?,
	Surface: SurfaceGui?,
	Figure: Model?,
}

local player = Players.LocalPlayer
local sites: { [Instance]: Site } = {}
local folder: Folder

local probe = RaycastParams.new()
probe.FilterType = Enum.RaycastFilterType.Exclude
probe.RespectCanCollide = true -- through limbs and other non-solid things, down to the ground

-- The floor a marker stands on (a marker's size is only a handle).
local function floorOf(marker: BasePart): Vector3
	probe.FilterDescendantsInstances = { marker, folder }
	local hit = workspace:Raycast(marker.Position + Vector3.new(0, 2, 0), Vector3.new(0, -FLOOR_PROBE, 0), probe)
	return if hit then hit.Position else marker.Position - Vector3.new(0, marker.Size.Y / 2, 0)
end

local function holder(site: Site, name: string, cframe: CFrame, size: Vector3?): BasePart
	local part = Kit.Anchor(cframe, size)
	part.Name = name
	part.Parent = site.Root
	return part
end

-- The blood sigil on the ground, lit by itself so it glows in the dark.
local function sigil(site: Site)
	local plate = holder(site, "Sigil", CFrame.new(site.Floor + Vector3.new(0, 0.05, 0)), Vector3.new(K.Sigil.Size, 0.05, K.Sigil.Size))
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Top
	surface.LightInfluence = 0
	surface.Brightness = K.Sigil.Brightness
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 24
	surface.Parent = plate
	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.fromScale(1, 1)
	image.Image = Theme.Images.RitualCircle
	image.ImageTransparency = K.Sigil.Transparency
	image.Parent = surface
	site.Sigil, site.Surface = image, surface
end

-- The landmark: a soft shaft of moonlight on the site, and motes drifting up in it; and the cold pool of light it
-- makes on the ground. The shaft is a round soft glow stretched from as far under the floor as it rises above it, so
-- the ground hides its lower half: brightest where it meets the circle, fading upward and to its sides. It stays off
-- until its texture has loaded (a beam draws as a solid band until then).
local function moonlight(site: Site)
	local base = holder(site, "Shaft", CFrame.new(site.Floor))
	local bottom = Instance.new("Attachment")
	bottom.Position = Vector3.new(0, -K.Shaft.Height, 0)
	bottom.Parent = base
	local top = Instance.new("Attachment")
	top.Position = Vector3.new(0, K.Shaft.Height, 0)
	top.Parent = base
	local beam = Instance.new("Beam")
	beam.Enabled = false
	beam.Attachment0, beam.Attachment1 = bottom, top
	beam.Texture = Kit.Textures.SoftGlow
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.TextureLength = 1
	beam.Width0, beam.Width1 = K.Shaft.Width, K.Shaft.Width
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Segments = 1
	beam.Color = ColorSequence.new(K.Moonlight)
	beam.Transparency = NumberSequence.new(K.Shaft.Transparency)
	beam.Parent = base
	task.spawn(function()
		ContentProvider:PreloadAsync({ beam })
		beam.Enabled = true
	end)
	local motes = holder(site, "Motes", CFrame.new(site.Floor + Vector3.new(0, K.Motes.Height / 2, 0)), Vector3.new(K.Motes.Radius * 2, K.Motes.Height, K.Motes.Radius * 2))
	local drift = Kit.Emitter(motes, {
		Texture = Kit.Textures.Dot,
		Color = ColorSequence.new(K.Moonlight),
		LightEmission = 1,
		Transparency = Kit.Seq({ { 0, 1 }, { 0.25, 0.35 }, { 0.75, 0.45 }, { 1, 1 } }),
		Size = Kit.Seq(0.18, 0.1),
		Lifetime = NumberRange.new(4, 7),
		Speed = NumberRange.new(0.4, 1.1),
		SpreadAngle = Vector2.new(10, 10),
		EmissionDirection = Enum.NormalId.Top,
		Shape = Enum.ParticleEmitterShape.Cylinder,
		ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume,
	})
	drift.Rate = K.Motes.Rate
	local lamp = holder(site, "Moonlight", CFrame.new(site.Floor + Vector3.new(0, K.Light.Height, 0)))
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Angle = K.Light.Angle
	spot.Range = K.Light.Height + 12
	spot.Brightness = K.Light.Brightness
	spot.Color = K.Moonlight
	spot.Shadows = true
	spot.Parent = lamp
end

-- The Shinigami waiting on its circle: its summoned body held in place (only the root is anchored; the joints keep
-- the limbs), head bowed, outlined only where you can see it.
local function figure(site: Site): Model?
	local model = ShinigamiBody.Make(site.Def)
	if not model then
		return nil
	end
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = d.Name == "HumanoidRootPart"
			d.CanCollide, d.CanQuery, d.CanTouch = false, false, false
		end
	end
	local aura = model:FindFirstChildOfClass("Highlight")
	if aura then
		aura.DepthMode = Enum.HighlightDepthMode.Occluded
	end
	local neck = model:FindFirstChild("Neck", true) :: Motor6D?
	if neck then
		neck.C0 *= CFrame.Angles(math.rad(K.Bow), 0, 0)
	end
	local look = site.Marker.CFrame.LookVector
	local facing = Vector3.new(look.X, 0, look.Z)
	facing = if facing.Magnitude > 1e-3 then facing.Unit else Vector3.new(0, 0, -1)
	local at = site.Floor + Vector3.new(0, STAND, 0)
	model:PivotTo(CFrame.lookAt(at, at + facing))
	model.Parent = site.Root
	return model
end

-- The sigil burns bright for a moment and settles.
local function flare(site: Site)
	local surface, image = site.Surface, site.Sigil
	if not surface or not image then
		return
	end
	Kit.Tween(K.Sigil.FlareTime, function(alpha)
		local glow = (1 - alpha) ^ 2
		surface.Brightness = K.Sigil.Brightness + (K.Sigil.Flare - K.Sigil.Brightness) * glow
		image.ImageTransparency = K.Sigil.Transparency * (1 - glow)
	end)
end

-- The waiting figure breaks into mist.
local function dissolve(model: Model)
	Arrival.Play(model)
	local parts = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	local aura = model:FindFirstChildOfClass("Highlight")
	local auraFrom = if aura then aura.OutlineTransparency else 1
	Kit.Tween(K.Fade, function(alpha)
		for _, part in parts do
			part.LocalTransparencyModifier = alpha
		end
		if aura then
			aura.OutlineTransparency = auraFrom + (1 - auraFrom) * alpha
		end
	end, function()
		model:Destroy()
	end)
end

-- Shows or clears the waiting figure (and the pact prompt) for whether your pact is with this site's Shinigami.
-- Returns true when the figure just left because the pact was made (`sealed`).
local function settle(site: Site, sealed: boolean): boolean
	local waiting = player:GetAttribute(P.ShinigamiId) ~= site.Def.Id
	local prompt = site.Marker:FindFirstChildOfClass("ProximityPrompt")
	if prompt then
		prompt.Enabled = waiting
	end
	if waiting and not site.Figure then
		site.Figure = figure(site)
	elseif not waiting and site.Figure then
		local model = site.Figure :: Model
		site.Figure = nil
		if sealed then
			dissolve(model)
			flare(site)
			return true
		end
		model:Destroy()
	end
	return false
end

local function add(instance: Instance)
	if not instance:IsA("BasePart") or sites[instance] then
		return
	end
	local def = Registry.Shinigami(instance:GetAttribute("Shinigami"))
	if not def then
		return -- the server warns about a circle naming no known Shinigami
	end
	local root = Instance.new("Model")
	root.Name = `{def.Id}Site`
	local site: Site = { Marker = instance, Def = def, Root = root, Floor = floorOf(instance), Sigil = nil, Surface = nil, Figure = nil }
	if instance.Transparency >= OWN_ART then
		sigil(site)
	end
	moonlight(site)
	root.Parent = folder
	sites[instance] = site
	settle(site, false)
end

local function remove(instance: Instance)
	local site = sites[instance]
	if site then
		sites[instance] = nil
		site.Root:Destroy()
	end
end

-- For the self-test: each dressed circle's waiting figure (nil when it isn't waiting) and whether it offers a pact.
function PactSiteController.Snapshot(): { [Instance]: { Figure: Model?, Offers: boolean } }
	local out = {}
	for marker, site in sites do
		local prompt = site.Marker:FindFirstChildOfClass("ProximityPrompt")
		out[marker] = { Figure = site.Figure, Offers = prompt ~= nil and prompt.Enabled }
	end
	return out
end

local function spin(dt: number)
	local camera = workspace.CurrentCamera.CFrame.Position
	for _, site in sites do
		local image = site.Sigil
		if image and (site.Floor - camera).Magnitude < SPIN_RANGE then
			image.Rotation = (image.Rotation + K.Sigil.Spin * dt) % 360
		end
	end
end

function PactSiteController.Start()
	folder = Instance.new("Folder")
	folder.Name = "BL_PactSites"
	folder.Parent = workspace
	Markers.Each(TAG, add)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(remove)
	player:GetAttributeChangedSignal(P.ShinigamiId):Connect(function()
		local sealed = false
		for _, site in sites do
			sealed = settle(site, true) or sealed
		end
		if sealed and player.Character then
			Arrival.Play(player.Character) -- it binds to you
		end
	end)
	RunService.RenderStepped:Connect(spin)
end

return PactSiteController
