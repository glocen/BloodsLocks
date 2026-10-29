--!strict
-- MenuController: the Blood Table menu (Duskbloods' House of Night menu, our way). Approaching the Blood Table in the
-- hall shows a prompt (G); opening it moves the camera onto your character, hides the HUD, frees the cursor, pauses
-- gameplay input, and lays the menu over the world: a top tab bar, the current tab's screen, key hints.
-- Keys: Q/E change tab, Enter begins (on Dusk Battle), Backspace leaves.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Motion = require(UI.Core.Motion)
local TabBar = require(UI.Kit.TabBar)
local KeyHints = require(UI.Kit.KeyHints)
local DuskBattle = require(UI.Menu.DuskBattle)
local Bloodsworn = require(UI.Menu.Bloodsworn)
local Placeholder = require(UI.Menu.Placeholder)

local TABLE_PATH = { "Vigil", "GreatHall", "ManorHall", "BloodTable" }
local RENDER_NAME = "BL_MenuCamera"

local MenuController = {}

local player = Players.LocalPlayer
local opened = false
local root: CanvasGroup
local tabs: TabBar.TabBar
local hints: KeyHints.Hints
local screens: { any } = {}
local current = 1
local shot: CFrame? = nil
local cameraTypeBefore = Enum.CameraType.Custom

local TAB_DEFS = {
	{ "Dusk Battle", function(parent) return DuskBattle.new(parent) end },
	{ "Classes", function(parent) return Bloodsworn.new(parent) end },
	{ "Relics", function(parent) return Placeholder.new(parent, "Relics", "Relics won in the Dusk Battle are set here before you depart.") end },
	{ "Atelier", function(parent) return Placeholder.new(parent, "Atelier", "Garments for your Bloodsworn, bought with Bloodgems.") end },
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

local function build()
	local layer = Layers.Get("Menus")
	root = Instance.new("CanvasGroup")
	root.Name = "BloodTableMenu"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.GroupTransparency = 1
	root.Visible = false
	root.Parent = layer
	-- darken the edges of the world so the UI reads (left side and the bottom most)
	for _, side in { { 0, Vector2.new(0, 0) }, { 90, Vector2.new(0, 0) } } do
		local veil = Instance.new("Frame")
		veil.Size = UDim2.fromScale(1, 1)
		veil.BackgroundColor3 = Theme.Palette.Ink
		veil.BorderSizePixel = 0
		veil.Parent = root
		local g = Instance.new("UIGradient")
		g.Rotation = side[1]
		g.Transparency = if side[1] == 0
			then NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(0.42, 0.75), NumberSequenceKeypoint.new(1, 1) })
			else NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.15, 1), NumberSequenceKeypoint.new(0.8, 1), NumberSequenceKeypoint.new(1, 0.35) })
		g.Parent = veil
	end
	local labels = {}
	for i, def in TAB_DEFS do
		labels[i] = def[1]
	end
	tabs = TabBar.new(root, labels, select)
	hints = KeyHints.new(root)
	for i, def in TAB_DEFS do
		screens[i] = def[2](root)
	end
	-- chrome stays above every screen (some screens dim the whole world)
	tabs.Frame.ZIndex = 10
	hints.Frame.ZIndex = 10
end

local function cameraShot(): CFrame?
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return nil
	end
	local look = hrp.CFrame.LookVector
	local right = hrp.CFrame.RightVector
	local focus = hrp.Position + Vector3.new(0, 1.2, 0)
	-- in front of the character, a little to its left, so it stands right of centre and the menu sits left
	local eye = focus + look * 8 + right * 3.4 + Vector3.new(0, 2.6, 0)
	return CFrame.lookAt(eye, focus + right * 2.4 + Vector3.new(0, 0.6, 0))
end

local function setGameplay(enabled: boolean)
	local context = player:FindFirstChild("BLGameplay") :: InputContext?
	if context then
		context.Enabled = enabled
	end
	Layers.Get("HUD").Enabled = enabled
end

function MenuController.Open()
	if opened then
		return
	end
	opened = true
	shot = cameraShot()
	setGameplay(false)
	root.Visible = true
	Motion.To(root, { GroupTransparency = 0 }, "Slow")
	select(current)
	local camera = workspace.CurrentCamera
	cameraTypeBefore = camera.CameraType
	local from = camera.CFrame
	local started = os.clock()
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Camera.Value + 5, function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		if shot then
			local t = math.min(1, (os.clock() - started) / Theme.Motion.Slow * 1.6)
			local eased = 1 - (1 - t) ^ 4
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = from:Lerp(shot, eased)
		end
	end)
end

function MenuController.Close()
	if not opened then
		return
	end
	opened = false
	RunService:UnbindFromRenderStep(RENDER_NAME)
	workspace.CurrentCamera.CameraType = cameraTypeBefore -- hand the camera back exactly as CameraController had it
	setGameplay(true)
	Motion.To(root, { GroupTransparency = 1 }, "Fast").Completed:Once(function()
		if not opened then
			root.Visible = false
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
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Approach"
	prompt.ObjectText = "The Blood Table"
	prompt.KeyboardKeyCode = Enum.KeyCode.G
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = anchor
	prompt.Triggered:Connect(MenuController.Open)
end

function MenuController.Start()
	build()
	addPrompt()
	UserInputService.InputBegan:Connect(function(input)
		if not opened or UserInputService:GetFocusedTextBox() then
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
