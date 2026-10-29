--!strict
-- LockOnController: Souls-style lock-on. Tab or middle mouse locks the best target in front of the camera;
-- flicking the mouse switches left/right; the lock drops if the target dies or gets too far. It also feeds the
-- simulation's Face input (face the target, except while sprinting) and Aim input (the target, or whatever is
-- under the crosshair when not locked).

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config.Camera)
local Parts = require(Shared.Util.Parts)
local Raycast = require(Shared.Util.Raycast)
local Vector = require(Shared.Util.Vector)
local EntityState = require(Shared.Simulation.EntityState)
local Input = require(Shared.Simulation.Input)
local Theme = require(script.Parent.Parent.Parent.UI.Theme)

local AIM_RANGE = 300
local AIM_HEIGHT = 1.2 -- bullets leave from about chest height
local MAX_LOCK_ANGLE = math.rad(70)

local LockOnController = {}

local player = Players.LocalPlayer
local target: Model? = nil
local lastSwitch = 0
local marker: BillboardGui? = nil

local function alive(model: Model?): boolean
	local humanoid = Parts.Humanoid(model)
	return model ~= nil and model.Parent ~= nil and humanoid ~= nil and humanoid.Health > 0
end

-- Lockable targets: living humanoid models in range with a clear line of sight.
local function candidates(): { Model }
	local character = player.Character
	local myRoot = Parts.Root(character)
	if not character or not myRoot then
		return {}
	end
	local found, seen = {}, {}
	for _, part in workspace:GetPartBoundsInRadius(myRoot.Position, Config.LockRange, Raycast.ExcludeOverlap({ character })) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not seen[model] and part.Name == "HumanoidRootPart" and alive(model) then
			seen[model] = true
			local blocked = workspace:Raycast(myRoot.Position, part.Position - myRoot.Position, Raycast.Exclude({ character, model }, true))
			if not blocked then
				table.insert(found, model)
			end
		end
	end
	return found
end

-- Best target: closest to the screen center, then nearest.
local function pickTarget(): Model?
	local camera = workspace.CurrentCamera
	local best, bestScore = nil, math.huge
	for _, model in candidates() do
		local toTarget = (Parts.Root(model) :: BasePart).Position - camera.CFrame.Position
		local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(toTarget.Unit), -1, 1))
		local score = angle * 40 + toTarget.Magnitude * 0.2
		if angle < MAX_LOCK_ANGLE and score < bestScore then
			best, bestScore = model, score
		end
	end
	return best
end

-- Next target to the left (-1) or right (1) of the current one on screen.
local function switchTarget(side: number)
	local camera = workspace.CurrentCamera
	local current = Parts.Root(target)
	if not current then
		return
	end
	local currentX = camera.CFrame:PointToObjectSpace(current.Position).X
	local best, bestGap = nil, math.huge
	for _, model in candidates() do
		if model ~= target then
			local gap = (camera.CFrame:PointToObjectSpace((Parts.Root(model) :: BasePart).Position).X - currentX) * side
			if gap > 0 and gap < bestGap then
				best, bestGap = model, gap
			end
		end
	end
	if best then
		target = best
		lastSwitch = os.clock()
	end
end

local function setTarget(model: Model?)
	target = model
	lastSwitch = os.clock()
end

-- The locked target, or nil.
function LockOnController.GetTarget(): Model?
	return target
end

local function buildMarker()
	local gui = Instance.new("ScreenGui")
	gui.Name = "BL_LockOn"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Marker"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(Theme.LockMarkerSize * 2, Theme.LockMarkerSize * 2)
	billboard.Enabled = false
	billboard.Parent = gui
	local diamond = Instance.new("Frame")
	diamond.AnchorPoint = Vector2.new(0.5, 0.5)
	diamond.Position = UDim2.fromScale(0.5, 0.5)
	diamond.Size = UDim2.fromOffset(Theme.LockMarkerSize, Theme.LockMarkerSize)
	diamond.Rotation = 45
	diamond.BackgroundTransparency = 1
	diamond.Parent = billboard
	local ring = Instance.new("UIStroke")
	ring.Color = Theme.Colors.Warm
	ring.Thickness = 2
	ring.Parent = diamond
	marker = billboard
end

-- Before the camera each frame: validate the lock, handle flick switching, place the marker.
local function update()
	local myRoot = Parts.Root(player.Character)
	local targetRoot = Parts.Root(target)
	if target and (not alive(target) or not targetRoot or not myRoot or (targetRoot.Position - myRoot.Position).Magnitude > Config.LockBreakRange) then
		setTarget(nil)
	end
	if target then
		local delta = UserInputService:GetMouseDelta()
		if math.abs(delta.X) > Config.FlickThreshold and os.clock() - lastSwitch > Config.SwitchCooldown then
			switchTarget(if delta.X > 0 then 1 else -1)
		end
	end
	if marker then
		marker.Adornee = Parts.Root(target)
		marker.Enabled = target ~= nil
	end
end

local function facing(): Vector3?
	local character = player.Character
	local myRoot, targetRoot = Parts.Root(character), Parts.Root(target)
	if not character or not myRoot or not targetRoot or character:GetAttribute(EntityState.Attr.Sprinting) then
		return nil
	end
	local direction = Vector.Flat(targetRoot.Position - myRoot.Position)
	return if direction ~= Vector3.zero then direction else nil
end

local function aim(): Vector3?
	local character = player.Character
	local myRoot = Parts.Root(character)
	if not character or not myRoot then
		return nil
	end
	local origin = myRoot.Position + Vector3.new(0, AIM_HEIGHT, 0)
	local targetRoot = Parts.Root(target)
	if targetRoot then
		return (targetRoot.Position - origin).Unit
	end
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * AIM_RANGE, Raycast.Exclude({ character }, true))
	local point = if hit then hit.Position else ray.Origin + ray.Direction * AIM_RANGE
	return (point - origin).Unit
end

function LockOnController.Start()
	buildMarker()
	-- Tab is also the player-list key, so the engine marks it processed; only skip while typing.
	UserInputService.InputBegan:Connect(function(input)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == Enum.KeyCode.Tab or input.UserInputType == Enum.UserInputType.MouseButton3 then
			setTarget(if target then nil else pickTarget())
		end
	end)
	player.CharacterAdded:Connect(function()
		setTarget(nil)
	end)
	Input.SetFacingProvider(facing)
	Input.SetAimProvider(aim)
	RunService:BindToRenderStep("BL_LockOn", Enum.RenderPriority.Camera.Value, update)
end

return LockOnController
