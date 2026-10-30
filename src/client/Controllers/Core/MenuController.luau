--!strict
-- MenuController: the Blood Table menu. Approaching the Blood Table in the Manor shows a prompt (G). Opening it
-- dips to black, turns your hunter to face away from the table (so the table stands behind them) and reveals them on
-- stage (UI.Core.Stage: full-body, front-on, on a blood ritual circle under a warm key light, all local to this
-- client), with the menu around it: the tab ribbon on top, the current tab's screen, key hints bottom-right.
-- Gameplay input and the HUD pause while it's open.
-- The menu is a plain Frame (no CanvasGroup: those render through a low-resolution texture and blur text).
-- Keys: Q/E change tab, Enter acts (Seek a Hunt on the Hunt tab), Backspace leaves.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Motion = require(UI.Core.Motion)
local Focus = require(UI.Core.Focus)
local Stage = require(UI.Core.Stage)
local Veil = require(UI.Kit.Veil)
local TabBar = require(UI.Kit.TabBar)
local KeyHints = require(UI.Kit.KeyHints)
local Hunt = require(UI.Menu.Hunt)
local Classes = require(UI.Menu.Classes)
local Placeholder = require(UI.Menu.Placeholder)

local TABLE_PATH = { "Vigil", "GreatHall", "ManorHall", "BloodTable" }

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
local stage: Stage.Handle? = nil
local prompt: ProximityPrompt? = nil
local bloodTable: Model? = nil

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

local function build()
	root = Instance.new("Frame")
	root.Name = "BloodTableMenu"
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundTransparency = 1
	root.Visible = false
	root.Parent = Layers.Get("Menus")
	Veil.Menu(root) -- darken the left (behind the panel) and the top and bottom edges, so the UI reads over the world
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

-- Away from the Blood Table: the table stands behind the hunter instead of between them and the camera.
local function awayFromTable(body: BasePart): Vector3?
	if not bloodTable then
		return nil
	end
	local away = body.Position - bloodTable:GetBoundingBox().Position
	return if Vector3.new(away.X, 0, away.Z).Magnitude > 0.5 then away else nil
end

local releaseFocus: (() -> ())? = nil

-- The menu owns the cursor and pauses gameplay input and the combat HUD while it's open (Focus).
local function setGameplay(enabled: boolean)
	if not enabled and not releaseFocus then
		releaseFocus = Focus.Push("BloodTable", { Cursor = true, Gameplay = false, Hud = false })
	elseif enabled and releaseFocus then
		releaseFocus()
		releaseFocus = nil
	end
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
		stage = Stage.Begin({ Facing = awayFromTable(character) })
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
		root.Visible = false
		if stage then
			stage:End() -- hands the camera back exactly as CameraController had it
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
	bloodTable = findTable()
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
	approach.Style = Enum.ProximityPromptStyle.Custom -- drawn by PromptController in our style
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
