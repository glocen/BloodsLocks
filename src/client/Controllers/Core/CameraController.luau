--!strict
-- CameraController: mouse-locked third-person camera. Free orbit with the mouse; while locked on (see
-- LockOnController) it swings to frame the target. Collides with solid geometry only, widens the FOV for
-- sprint and air dash, and exposes Shake (the owner's CameraShaker) for hit feedback.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Camera)
local Parts = require(Shared.Util.Parts)
local Raycast = require(Shared.Util.Raycast)
local Vector = require(Shared.Util.Vector)
local EntityState = require(Shared.Simulation.EntityState)
local CameraShaker = require(ReplicatedStorage.Modules.SharedModules.CameraShaker)
local LockOnController = require(script.Parent.LockOnController)
local Focus = require(script.Parent.Parent.Parent.UI.Core.Focus)

local A = EntityState.Attr

local CameraController = {}

local player = Players.LocalPlayer
local yaw, pitch = 0, math.rad(-10)
local distance = Config.Distance
local focus: Vector3? = nil
local shaker: any = nil
-- When the mouse locks again (a menu screen closed), the cursor's jump back to the centre is reported as movement and
-- would fling the camera to a pitch limit: the movement of the first SETTLE frames after that, or after a spawn
-- snap, is dropped.
local SETTLE = 2
local settle = 0
local wasCursor = true

-- Swings the camera behind the character looking along `direction` (a spawn: you see where you face), and snaps the
-- follow point to the character so the camera doesn't sweep across the map from where it was.
function CameraController.Face(direction: Vector3)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	yaw = math.atan2(-flat.X, -flat.Z)
	pitch = math.rad(-10)
	focus = nil
	settle = SETTLE
end

-- Short camera shake for hit feedback.
function CameraController.Shake(magnitude: number, roughness: number, fadeOut: number)
	if shaker then
		shaker:ShakeOnce(magnitude, roughness, 0, fadeOut)
	end
end

local function wantedFov(character: Model): number
	if time() < EntityState.Number(character, A.DashEnd, 0) then
		return Config.DashFov
	elseif character:GetAttribute(A.Sprinting) then
		return Config.SprintFov
	end
	return Config.BaseFov
end

local function update(dt: number)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = Parts.Root(character)
	if not character or not root then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	local cursor = GuiService.MenuIsOpen or Focus.CursorFree()
	UserInputService.MouseBehavior = if cursor then Enum.MouseBehavior.Default else Enum.MouseBehavior.LockCenter
	UserInputService.MouseIconEnabled = cursor
	if wasCursor and not cursor then
		settle = SETTLE
	end
	wasCursor = cursor
	local still = cursor or settle > 0 -- no mouse movement counts this frame
	settle = math.max(0, settle - 1)

	local wantedFocus = root.Position + Vector3.new(0, Config.FocusHeight, 0)
	focus = if focus then focus:Lerp(wantedFocus, Vector.Smooth(Config.FollowSharpness, dt)) else wantedFocus
	local currentFocus = focus :: Vector3

	local targetRoot = Parts.Root(LockOnController.GetTarget())
	if targetRoot then
		local toTarget = (targetRoot.Position - currentFocus).Unit
		local alpha = Vector.Smooth(Config.LockSharpness, dt)
		yaw = Vector.LerpAngle(yaw, math.atan2(-toTarget.X, -toTarget.Z), alpha)
		local wantedPitch = math.clamp(math.asin(toTarget.Y) + Config.LockPitchBias, Config.PitchMin, Config.PitchMax)
		pitch += (wantedPitch - pitch) * alpha
	else
		local delta = if still then Vector2.zero else UserInputService:GetMouseDelta()
		yaw -= delta.X * Config.Sensitivity
		pitch = math.clamp(pitch - delta.Y * Config.Sensitivity, Config.PitchMin, Config.PitchMax)
	end

	local rotation = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local offset = rotation:VectorToWorldSpace(Vector3.new(Config.ShoulderOffset, 0, distance))
	local hit = workspace:Spherecast(currentFocus, Config.CollisionRadius, offset, Raycast.Exclude({ character }, true))
	local length = if hit then math.max(hit.Distance - 0.1, 0.5) else offset.Magnitude
	camera.CFrame = CFrame.new(currentFocus + offset.Unit * length) * rotation
	camera.FieldOfView += (wantedFov(character) - camera.FieldOfView) * Vector.Smooth(Config.FovSharpness, dt)
end

function CameraController.Start()
	UserInputService.InputChanged:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseWheel then
			distance = math.clamp(distance - input.Position.Z * Config.ZoomStep, Config.MinDistance, Config.MaxDistance)
		end
	end)
	player.CharacterAdded:Connect(function()
		focus = nil
	end)
	RunService:BindToRenderStep("BL_Camera", Enum.RenderPriority.Camera.Value + 1, update)
	shaker = CameraShaker.new(Enum.RenderPriority.Camera.Value + 2, function(shakeCFrame: CFrame)
		local camera = workspace.CurrentCamera
		camera.CFrame = camera.CFrame * shakeCFrame
	end)
	shaker:Start()
end

return CameraController
