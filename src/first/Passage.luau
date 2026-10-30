--!strict
-- Passage (ReplicatedFirst.BL_First): the screen between places. It replaces Roblox's loading screen on arrival and is
-- the picture Roblox shows during a teleport, so leaving, travelling and arriving read as one passage: ink, a slowly
-- turning blood circle, where you're going, one tip, and a thin line that fills while the game loads.
--   Show(view) puts the live screen up (or updates it). Hold(name) / Release(name) keep it up while something is still
--   getting ready (loading, the boot, the match screens, a teleport in flight); it fades once nothing holds it, never
--   sooner than MIN_SHOW after it appeared, and at the latest MAX_SHOW after (a stuck holder can't trap a player).
--   PrepareTeleport(view) hands Roblox the same picture for the teleport, carrying the view so the next place opens on
--   it (ArrivingView). Captions holds the lines callers use above the destination.
-- Uses only ThemeBase: it runs before the rest of the game has loaded.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local ThemeBase = require(script.Parent.ThemeBase)

export type View = { Caption: string?, Destination: string?, Tip: string?, Progress: number? }

local P = ThemeBase.Palette
local SIZE = ThemeBase.TextSize
local REFERENCE = ThemeBase.ReferenceResolution
local NAME = "BL_Passage"
local DISPLAY_ORDER = 1000 -- above every layer (Transition is 100)
local MIN_SHOW, MAX_SHOW = 1.2, 25 -- seconds
local FADE = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local FILL = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TURN = 5 -- degrees per second
local CIRCLE, GLOW = 300, 780
local CENTER_Y = 420 -- the circle's centre on the 1920×1080 canvas
local COLUMN = 760 -- the text column's width
local LINE = 420 -- the progress line's width
local CARRIED = { "Caption", "Destination", "Tip" } -- the view travels on the teleport GUI as these attributes

local Passage = {}

Passage.Captions = table.freeze({
	Depart = "Setting out for",
	Return = "Returning to",
	Gather = "The hunt gathers in",
	Enter = "Entering",
})

type Label = { Label: TextLabel, Authored: number, Minimum: number }
type Screen = {
	Gui: ScreenGui,
	Canvas: Frame,
	Scale: UIScale,
	Circle: ImageLabel,
	Caption: TextLabel,
	Destination: TextLabel,
	Tip: TextLabel,
	Fill: Frame,
	Labels: { Label },
	Faders: { { Instance: Instance, Property: string } },
	Connections: { RBXScriptConnection },
}

local function label(screen: Screen, family: string, weight: Enum.FontWeight, size: number, minimum: number, color: Color3, y: number, height: number): TextLabel
	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.FontFace = Font.new(family, weight)
	text.TextSize = size
	text.TextColor3 = color
	text.TextWrapped = true
	text.Text = ""
	text.AnchorPoint = Vector2.new(0.5, 0)
	text.Position = UDim2.fromOffset(REFERENCE.X / 2, y)
	text.Size = UDim2.fromOffset(COLUMN, height)
	text.Parent = screen.Canvas
	table.insert(screen.Labels, { Label = text, Authored = size, Minimum = minimum })
	table.insert(screen.Faders, { Instance = text, Property = "TextTransparency" })
	return text
end

local function image(screen: Screen, id: string, size: number, color: Color3, transparency: number): ImageLabel
	local picture = Instance.new("ImageLabel")
	picture.BackgroundTransparency = 1
	picture.Image = id
	picture.ImageColor3 = color
	picture.ImageTransparency = transparency
	picture.AnchorPoint = Vector2.new(0.5, 0.5)
	picture.Position = UDim2.fromOffset(REFERENCE.X / 2, CENTER_Y)
	picture.Size = UDim2.fromOffset(size, size)
	picture.Parent = screen.Canvas
	table.insert(screen.Faders, { Instance = picture, Property = "ImageTransparency" })
	return picture
end

local function bar(parent: Instance, color: Color3, transparency: number, size: UDim2, position: UDim2): Frame
	local frame = Instance.new("Frame")
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.Size = size
	frame.Position = position
	frame.Parent = parent
	return frame
end

-- Fits the canvas to the screen and keeps every line legible at that scale.
local function fit(screen: Screen)
	local camera = workspace.CurrentCamera
	local scale = if camera then ThemeBase.FitScale(camera.ViewportSize) else 1
	screen.Scale.Scale = scale
	for _, entry in screen.Labels do
		entry.Label.TextSize = ThemeBase.LegibleSize(entry.Authored, entry.Minimum, scale)
	end
end

local function build(): Screen
	local gui = Instance.new("ScreenGui")
	gui.Name = NAME
	gui.DisplayOrder = DISPLAY_ORDER
	gui.IgnoreGuiInset = true
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local back = bar(gui, P.Ink, 0, UDim2.fromScale(1, 1), UDim2.new())
	back.Name = "Back"
	local canvas = Instance.new("Frame") -- the 1920×1080 authored canvas, centred and scaled to fit
	canvas.Name = "Canvas"
	canvas.AnchorPoint = Vector2.new(0.5, 0.5)
	canvas.Position = UDim2.fromScale(0.5, 0.5)
	canvas.Size = UDim2.fromOffset(REFERENCE.X, REFERENCE.Y)
	canvas.BackgroundTransparency = 1
	canvas.Parent = back
	local scale = Instance.new("UIScale")
	scale.Parent = canvas
	local screen: Screen = {
		Gui = gui,
		Canvas = canvas,
		Scale = scale,
		Circle = nil :: any,
		Caption = nil :: any,
		Destination = nil :: any,
		Tip = nil :: any,
		Fill = nil :: any,
		Labels = {},
		Faders = { { Instance = back, Property = "BackgroundTransparency" } },
		Connections = {},
	}
	image(screen, ThemeBase.Images.SoftGlow, GLOW, P.BloodDeep, 0.45) -- a low warm bloom behind the circle
	screen.Circle = image(screen, ThemeBase.Images.RitualCircle, CIRCLE, Color3.new(1, 1, 1), 0.2)
	screen.Caption = label(screen, ThemeBase.Families.Body, Enum.FontWeight.Bold, SIZE.Caption + 2, SIZE.MinCaption, P.Gold, 618, 24)
	screen.Destination = label(screen, ThemeBase.Families.Display, Enum.FontWeight.Regular, SIZE.Display, SIZE.MinRendered, P.Bone, 646, 60)
	local rule = bar(canvas, P.Gold, 0.55, UDim2.fromOffset(280, 1), UDim2.fromOffset(REFERENCE.X / 2 - 140, 718))
	table.insert(screen.Faders, { Instance = rule, Property = "BackgroundTransparency" })
	screen.Tip = label(screen, ThemeBase.Families.Body, Enum.FontWeight.Regular, SIZE.Body + 2, SIZE.MinRendered, P.Ash, 862, 64)
	local track = bar(canvas, P.InkSoft, 0, UDim2.fromOffset(LINE, 2), UDim2.fromOffset(REFERENCE.X / 2 - LINE / 2, 960))
	table.insert(screen.Faders, { Instance = track, Property = "BackgroundTransparency" })
	screen.Fill = bar(track, P.Gold, 0.15, UDim2.fromScale(0, 1), UDim2.new())
	table.insert(screen.Faders, { Instance = screen.Fill, Property = "BackgroundTransparency" })
	fit(screen)
	return screen
end

local function apply(screen: Screen, view: View)
	if view.Caption ~= nil then
		screen.Caption.Text = string.upper(view.Caption)
	end
	if view.Destination ~= nil then
		screen.Destination.Text = view.Destination
	end
	if view.Tip ~= nil then
		screen.Tip.Text = view.Tip
	end
	if view.Progress ~= nil then
		TweenService:Create(screen.Fill, FILL, { Size = UDim2.fromScale(math.clamp(view.Progress, 0, 1), 1) }):Play()
	end
end

local current: Screen? = nil
local holds: { [string]: boolean } = {}
local shownAt = 0
local fading = false

local function fadeOut()
	local screen = current
	if not screen or fading then
		return
	end
	fading = true
	for _, fader in screen.Faders do
		TweenService:Create(fader.Instance, FADE, { [fader.Property] = 1 }):Play()
	end
	task.delay(FADE.Time, function()
		for _, connection in screen.Connections do
			connection:Disconnect()
		end
		screen.Gui:Destroy()
		if current == screen then
			current = nil
		end
		fading = false
	end)
end

local function settle()
	if not current or fading or next(holds) ~= nil then
		return
	end
	local wait = MIN_SHOW - (os.clock() - shownAt)
	if wait > 0 then
		task.delay(wait, settle)
	else
		fadeOut()
	end
end

-- Puts the live passage up with `view` (or updates the one that's up).
function Passage.Show(view: View)
	if current and not fading then
		apply(current, view)
		return
	end
	local screen = build()
	apply(screen, view)
	local camera = workspace.CurrentCamera
	if camera then
		table.insert(screen.Connections, camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			fit(screen)
		end))
	end
	table.insert(screen.Connections, RunService.RenderStepped:Connect(function(dt)
		screen.Circle.Rotation = (screen.Circle.Rotation + TURN * dt) % 360
	end))
	screen.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	current, shownAt, fading = screen, os.clock(), false
	task.delay(MAX_SHOW, function()
		if current == screen and not fading and next(holds) ~= nil then
			local names = {}
			for name in holds do
				table.insert(names, name)
			end
			warn(`[BL] Passage: still held by {table.concat(names, ", ")} after {MAX_SHOW} s; lifting it anyway`)
			table.clear(holds)
			fadeOut()
		end
	end)
	settle()
end

-- Updates the passage that's up (no-op when none is).
function Passage.Update(view: View)
	if current and not fading then
		apply(current, view)
	end
end

function Passage.IsShown(): boolean
	return current ~= nil and not fading
end

-- Keeps the passage up until Release(name).
function Passage.Hold(name: string)
	holds[name] = true
end

function Passage.Release(name: string)
	holds[name] = nil
	settle()
end

-- Gives Roblox this picture to show during the next teleport from this client; the next place opens on it.
function Passage.PrepareTeleport(view: View)
	local screen = build()
	apply(screen, view)
	for _, attribute in CARRIED do
		screen.Gui:SetAttribute(attribute, (view :: any)[attribute])
	end
	TeleportService:SetTeleportGui(screen.Gui)
end

-- The view the previous place sent along with the teleport, or nil when we didn't arrive by one.
function Passage.ArrivingView(): View?
	local gui = TeleportService:GetArrivingTeleportGui()
	if not gui then
		return nil
	end
	local view = {}
	for _, attribute in CARRIED do
		(view :: any)[attribute] = gui:GetAttribute(attribute)
	end
	return view :: View
end

return Passage
