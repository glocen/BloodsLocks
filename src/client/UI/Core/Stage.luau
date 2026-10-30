--!strict
-- Stage: puts your hunter on show for a full-screen menu (the Blood Table, the Antechamber): a blood ritual circle at
-- their feet with a low crimson glow, a warm key light in front, and the camera full-body, front-on and slightly low.
-- Everything is local to this client. Begin(options) builds it and pins the camera; End() on the handle puts the
-- camera back exactly as it was and removes the stage.
--   Facing: a direction to turn the hunter toward first (the server turns them: TakeStage; e.g. away from the Blood
--   Table, so the table stands behind them instead of between them and the camera).
--   The camera stands DISTANCE studs along the hunter's facing; if something solid is in the way it moves in, so it
--   never sits inside a wall or a table.
--   Backdrop: a dark velvet curtain and floor disc around the hunter, for rooms whose art isn't finished yet.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Parts = require(ReplicatedStorage.Shared.Util.Parts)
local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Motion)

export type Options = { Facing: Vector3?, Backdrop: boolean? }
export type Handle = { End: (self: Handle) -> () }

local RENDER_NAME = "BL_StageCamera"
local DISTANCE = 11 -- studs in front of the hunter
local MIN_DISTANCE = 6
local HEIGHT = 1.0 -- above the root: a slightly low, heroic angle
local CLEARANCE = 1.5 -- studs kept between the camera and whatever blocks it
local CIRCLE_SIZE = 11
local KEY_LIGHT = { Offset = Vector3.new(3, 5, -6), Brightness = 2.2, Range = 18 }
local FACE_WAIT = 0.6 -- seconds to wait for the server to turn the hunter
local BACKDROP = { Distance = 18, Nearest = 4, Width = 80, Height = 48, Floor = 30 } -- studs
local SOLID = Enum.Material.SmoothPlastic

local Stage = {}

local Handle = {}
Handle.__index = Handle

local function part(model: Model, name: string, size: Vector3, cframe: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Size = size
	p.CFrame = cframe
	p.Parent = model
	return p
end

local function exclude(list: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = list
	return params
end

-- Where the hunter stands: the floor under them (the highest of a floor ray and the soles of their feet; the ray can
-- miss carpets that don't take queries, the soles sit a hair into thick ones).
local function feet(character: Model, root: BasePart): Vector3
	local soles = root.Position.Y - 3
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and child.Name:find("Leg") then
			soles = math.min(soles, child.Position.Y - child.Size.Y / 2)
		end
	end
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -8, 0), exclude({ character }))
	return Vector3.new(root.Position.X, if hit then math.max(soles, hit.Position.Y) else soles, root.Position.Z)
end

local function flat(direction: Vector3): Vector3
	local v = Vector3.new(direction.X, 0, direction.Z)
	return if v.Magnitude > 1e-3 then v.Unit else Vector3.new(0, 0, -1)
end

local function build(character: Model, root: BasePart, backdrop: boolean): Model
	local model = Instance.new("Model")
	model.Name = "BL_Stage"
	local base = feet(character, root)
	local facing = flat(root.CFrame.LookVector)
	local turn = CFrame.lookAt(base, base + facing)
	local circle = part(model, "Circle", Vector3.new(CIRCLE_SIZE, 0.05, CIRCLE_SIZE), turn + Vector3.new(0, 0.06, 0))
	circle.Transparency = 1
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = Theme.Images.RitualCircle
	decal.Transparency = 1
	decal.Parent = circle
	Motion.To(decal, { Transparency = 0.05 }, "Slow")
	local glow = Instance.new("PointLight") -- the circle's low crimson glow
	glow.Color = Theme.Menu.CircleGlow
	glow.Brightness = 1.4
	glow.Range = 9
	glow.Parent = circle
	local key = part(model, "KeyLight", Vector3.one, root.CFrame * CFrame.new(KEY_LIGHT.Offset))
	key.Transparency = 1
	local light = Instance.new("PointLight")
	light.Color = Theme.Menu.StageLight
	light.Brightness = KEY_LIGHT.Brightness
	light.Range = KEY_LIGHT.Range
	light.Shadows = true
	light.Parent = key
	if backdrop then
		-- a velvet curtain behind the hunter, in front of the nearest wall there, and a dark floor, wide enough to fill
		-- the frame
		local behind = workspace:Raycast(base + Vector3.new(0, 5, 0), -facing * BACKDROP.Distance, exclude({ character }))
		local distance = if behind then math.max(BACKDROP.Nearest, behind.Distance - 0.5) else BACKDROP.Distance
		local curtain = part(model, "Curtain", Vector3.new(BACKDROP.Width, BACKDROP.Height, 1), turn * CFrame.new(0, BACKDROP.Height / 2 - 6, distance))
		curtain.Material, curtain.Color = SOLID, Theme.Palette.Velvet
		-- the disc's top sits just above the real floor and just under the circle
		local floor = part(model, "Floor", Vector3.new(0.2, BACKDROP.Floor * 2, BACKDROP.Floor * 2), CFrame.new(base + Vector3.new(0, 0.02 - 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)))
		floor.Shape = Enum.PartType.Cylinder
		floor.Material, floor.Color = SOLID, Theme.Palette.InkSoft
	end
	model.Parent = workspace
	return model
end

-- Full-body and front-on from slightly low, pulled in if something stands between the camera and the hunter.
local function shot(character: Model, root: BasePart, stage: Model): CFrame
	local target = root.Position + Vector3.new(0, 0.4, 0)
	local offset = flat(root.CFrame.LookVector) * DISTANCE + Vector3.new(0, HEIGHT, 0)
	local hit = workspace:Raycast(target, offset, exclude({ character, stage }))
	local reach = if hit then math.max(MIN_DISTANCE, (hit.Position - target).Magnitude - CLEARANCE) else offset.Magnitude
	return CFrame.lookAt(target + offset.Unit * reach, target)
end

-- Builds the stage around your hunter and pins the camera on them. Call while the screen is hidden (a curtain): it
-- may wait a moment for the server to turn the hunter.
function Stage.Begin(options: Options?): Handle?
	local character = Players.LocalPlayer.Character
	local root = Parts.Root(character)
	if not character or not root then
		return nil
	end
	local opts = options or {}
	if opts.Facing then
		local want = flat(opts.Facing)
		Net.Client.Fire("TakeStage", want)
		local deadline = os.clock() + FACE_WAIT
		while flat(root.CFrame.LookVector):Dot(want) < 0.98 and os.clock() < deadline do
			task.wait()
		end
	end
	local stage = build(character, root, opts.Backdrop == true)
	local frame = shot(character, root, stage)
	local camera = workspace.CurrentCamera
	local before = camera.CameraType
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 5, function()
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = frame
	end)
	return (setmetatable({ _stage = stage, _before = before }, Handle) :: any) :: Handle
end

function Handle.End(self: any)
	RunService:UnbindFromRenderStep(RENDER_NAME)
	workspace.CurrentCamera.CameraType = self._before -- hand the camera back exactly as it was
	self._stage:Destroy()
end

return Stage
