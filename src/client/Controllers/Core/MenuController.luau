--!strict
-- MenuController: the Blood Table menu. Approaching the Blood Table in the Manor shows a prompt (G). Opening it
-- dips to black, then reveals your character centre stage, full-body and front-on, standing on a blood ritual circle
-- under a warm key light (all local to this client), with the menu around it: the tab ribbon on top, the current
-- tab's screen, key hints bottom-right. Gameplay input and the HUD pause while it's open.
-- The menu is a plain Frame (no CanvasGroup: those render through a low-resolution texture and blur text).
-- Keys: Q/E change tab, Enter acts (Seek a Hunt on the Hunt tab), Backspace leaves.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Motion = require(UI.Core.Motion)
local TabBar = require(UI.Kit.TabBar)
local KeyHints = require(UI.Kit.KeyHints)
local Hunt = require(UI.Menu.Hunt)
local Classes = require(UI.Menu.Classes)
local Placeholder = require(UI.Menu.Placeholder)

local TABLE_PATH = { "Vigil", "GreatHall", "ManorHall", "BloodTable" }
local RENDER_NAME = "BL_MenuCamera"
local CAMERA_DISTANCE = 11 -- studs in front of the character
local CAMERA_HEIGHT = 1.0 -- above the root: a slightly low, heroic angle
local CIRCLE_SIZE = 11
local KEY_LIGHT = { Offset = Vector3.new(3, 5, -6), Brightness = 2.2, Range = 18 }

local MenuController = {}

local player = Players.LocalPlayer
local opened = false
local busy = false
local root: Frame
local curtain: Frame
local tabs: TabBar.TabBar
local hints: KeyHints.Hints
local screens: { any } = {}
local current = 1
local shot: CFrame? = nil
local stage: Model? = nil
local prompt: ProximityPrompt? = nil
local cameraTypeBefore = Enum.CameraType.Custom

local TAB_DEFS = {
	{ "Hunt", function(parent) return Hunt.new(parent) end },
	{ "Classes", function(parent) return Classes.new(parent) end },
	{ "Relics", function(parent) return Placeholder.new(parent, "Relics", "Relics won on the hunt are set here before you depart.") end },
	{ "Atelier", function(parent) return Placeholder.new(parent, "Atelier", "Garments for your hunter, bought with Bloodgems.") end },
	{ "Archive", function(parent) return Placeholder.new(parent, "Archive", "What you have learned of the night: rules, foes and lore.") end },
	{ "System", function(parent) return Placeholder.new(parent, "System", "Controls, camera, sound and display settings.") end },
}

local function select(index: number)
	current = math.clamp(index, 1, #TAB_DEFS)
	for i, screen in screens do
		screen.Frame.Visible = i == current
	end
	tabs:Select(current)
	hints:Set(screens[current].Hints)
	if screens[current].Shown then
		screens[current]:Shown()
	end
end

local function veil(parent: Instance, rotation: number, keypoints: { NumberSequenceKeypoint })
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new(keypoints)
	g.Parent = frame
end

local function build()
	root = Instance.new("Frame")
	root.Name = "BloodTableMenu"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = Layers.Get("Menus")
	-- darken the left (behind the panel) and the top and bottom edges, so the UI reads over the world
	veil(root, 0, { NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.36, 0.8), NumberSequenceKeypoint.new(0.6, 1), NumberSequenceKeypoint.new(1, 1) })
	veil(root, 90, { NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(0.16, 1), NumberSequenceKeypoint.new(0.82, 1), NumberSequenceKeypoint.new(1, 0.4) })
	local labels = {}
	for i, def in TAB_DEFS do
		labels[i] = def[1]
	end
	tabs = TabBar.new(root, labels, select)
	hints = KeyHints.new(root)
	for i, def in TAB_DEFS do
		screens[i] = def[2](root)
	end
	tabs.Frame.ZIndex = 10 -- chrome stays above every screen (some screens dim the whole world)
	hints.Frame.ZIndex = 10

	curtain = Instance.new("Frame")
	curtain.Name = "MenuCurtain"
	curtain.Size = UDim2.fromScale(1, 1)
	curtain.BackgroundColor3 = Theme.Palette.Ink
	curtain.BackgroundTransparency = 1
	curtain.BorderSizePixel = 0
	curtain.Parent = Layers.Get("Transition")
end

local function hrp(): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Full-body, front-on, character centred, from slightly low.
local function cameraShot(body: BasePart): CFrame
	local flat = Vector3.new(body.CFrame.LookVector.X, 0, body.CFrame.LookVector.Z).Unit
	local eye = body.Position + flat * CAMERA_DISTANCE + Vector3.new(0, CAMERA_HEIGHT, 0)
	return CFrame.lookAt(eye, body.Position + Vector3.new(0, 0.4, 0))
end

-- The local stage: the ritual circle under the character and a warm key light in front. Only this client sees it.
local function buildStage(body: BasePart): Model
	local model = Instance.new("Model")
	model.Name = "BL_MenuStage"
	-- the soles of the character's feet (a floor ray can miss carpets that don't take queries)
	local soles = body.Position.Y - 3
	for _, part in (player.Character :: Model):GetChildren() do
		if part:IsA("BasePart") and part.Name:find("Leg") then
			soles = math.min(soles, part.Position.Y - part.Size.Y / 2)
		end
	end
	local feet = Vector3.new(body.Position.X, soles, body.Position.Z)
	local circle = Instance.new("Part")
	circle.Name = "Circle"
	circle.Anchored, circle.CanCollide, circle.CanQuery, circle.CanTouch = true, false, false, false
	circle.Transparency = 1
	circle.Size = Vector3.new(CIRCLE_SIZE, 0.05, CIRCLE_SIZE)
	circle.CFrame = CFrame.new(feet + Vector3.new(0, 0.03, 0)) * body.CFrame.Rotation
	circle.Parent = model
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
	local key = Instance.new("Part")
	key.Name = "KeyLight"
	key.Anchored, key.CanCollide, key.CanQuery, key.CanTouch = true, false, false, false
	key.Transparency = 1
	key.Size = Vector3.one
	key.CFrame = body.CFrame * CFrame.new(KEY_LIGHT.Offset)
	key.Parent = model
	local light = Instance.new("PointLight")
	light.Color = Theme.Menu.StageLight
	light.Brightness = KEY_LIGHT.Brightness
	light.Range = KEY_LIGHT.Range
	light.Shadows = true
	light.Parent = key
	model.Parent = workspace
	return model
end

local function setGameplay(enabled: boolean)
	local context = player:FindFirstChild("BLGameplay") :: InputContext?
	if context then
		context.Enabled = enabled
	end
	Layers.Get("HUD").Enabled = enabled
end

-- Fades the curtain in, runs `between`, then fades it out.
local function dip(between: () -> ())
	busy = true
	Motion.To(curtain, { BackgroundTransparency = 0 }, "Base").Completed:Wait()
	between()
	Motion.To(curtain, { BackgroundTransparency = 1 }, "Slow").Completed:Wait()
	busy = false
end

function MenuController.Open()
	local character = hrp()
	if opened or busy or not character then
		return
	end
	opened = true
	setGameplay(false)
	if prompt then
		prompt.Enabled = false
	end
	task.spawn(dip, function()
		shot = cameraShot(character)
		stage = buildStage(character)
		local camera = workspace.CurrentCamera
		cameraTypeBefore = camera.CameraType
		RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 5, function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = shot :: CFrame
		end)
		select(current)
		root.Visible = true
	end)
end

function MenuController.Close()
	if not opened or busy then
		return
	end
	opened = false
	task.spawn(dip, function()
		RunService:UnbindFromRenderStep(RENDER_NAME)
		workspace.CurrentCamera.CameraType = cameraTypeBefore -- hand the camera back exactly as CameraController had it
		root.Visible = false
		if stage then
			stage:Destroy()
			stage = nil
		end
		setGameplay(true)
		if prompt then
			prompt.Enabled = true
		end
	end)
end

function MenuController.IsOpen(): boolean
	return opened
end

local function findTable(): Model?
	local node: Instance? = workspace
	for _, name in TABLE_PATH do
		node = node and node:FindFirstChild(name)
	end
	return if node and node:IsA("Model") then node else nil
end

local function addPrompt()
	local bloodTable = findTable()
	if not bloodTable then
		return
	end
	local center = bloodTable:GetBoundingBox()
	local anchor = Instance.new("Part")
	anchor.Name = "MenuPromptAnchor"
	anchor.Anchored, anchor.CanCollide, anchor.CanQuery, anchor.CanTouch = true, false, false, false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(center.Position + Vector3.new(0, 3, 0))
	anchor.Parent = workspace
	local approach = Instance.new("ProximityPrompt")
	approach.ActionText = "Approach"
	approach.ObjectText = "The Blood Table"
	approach.KeyboardKeyCode = Enum.KeyCode.G
	approach.MaxActivationDistance = 14
	approach.RequiresLineOfSight = false
	approach.Parent = anchor
	approach.Triggered:Connect(MenuController.Open)
	prompt = approach
end

function MenuController.Start()
	build()
	addPrompt()
	UserInputService.InputBegan:Connect(function(input)
		if not opened or busy or UserInputService:GetFocusedTextBox() then
			return
		end
		local key = input.KeyCode
		if key == Enum.KeyCode.Backspace then
			MenuController.Close()
		elseif key == Enum.KeyCode.Q then
			select(if current == 1 then #TAB_DEFS else current - 1)
		elseif key == Enum.KeyCode.E then
			select(if current == #TAB_DEFS then 1 else current + 1)
		elseif key == Enum.KeyCode.Return or key == Enum.KeyCode.KeypadEnter then
			screens[current]:Begin()
		end
	end)
end

return MenuController
