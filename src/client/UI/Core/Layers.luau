--!strict
-- Layers: one ScreenGui per UI layer (HUD, Menus, Overlay, Toasts, Transition), created on first use, ordered by
-- Theme.Layers and fitted to the screen by a UIScale: everything is authored at Theme.ReferenceResolution and
-- scales uniformly, so offsets, strokes and paddings stay proportional on every screen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.Theme)
local Signal = require(ReplicatedStorage.Shared.Util.Signal)

export type LayerName = "HUD" | "Menus" | "Overlay" | "Toasts" | "Transition"

local MIN_SCALE, MAX_SCALE = 0.5, 1.5

local Layers = {}

-- Fires (scale) when the fit scale changes (window resized): Text keeps rendered sizes legible from it.
Layers.ScaleChanged = Signal.new() :: Signal.Signal<number>

local guis: { [string]: ScreenGui } = {}
local scales: { UIScale } = {}
local current = 1

local function fit()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local viewport = camera.ViewportSize
	local reference = Theme.ReferenceResolution
	local scale = math.clamp(math.min(viewport.X / reference.X, viewport.Y / reference.Y), MIN_SCALE, MAX_SCALE)
	for _, uiScale in scales do
		uiScale.Scale = scale
	end
	if scale ~= current then
		current = scale
		Layers.ScaleChanged:Fire(scale)
	end
end

local watching = false
local function watchViewport()
	if watching then
		return
	end
	watching = true
	local function bind()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
		end
		fit()
	end
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bind)
	bind()
end

-- The ScreenGui for a layer. Every layer but the HUD ignores the GUI inset and covers the whole screen.
function Layers.Get(name: LayerName): ScreenGui
	local existing = guis[name]
	if existing then
		return existing
	end
	local order = (Theme.Layers :: any)[name]
	assert(order, `unknown UI layer {name}`)
	local gui = Instance.new("ScreenGui")
	gui.Name = "BL_" .. name
	gui.DisplayOrder = order
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	-- every layer covers the whole screen, top bar included (owner, 2026-10-29), except the HUD: its vitals sit just
	-- below Roblox's own icon and chat buttons
	local respectsInset = name == "HUD"
	gui.IgnoreGuiInset = not respectsInset
	gui.ScreenInsets = if respectsInset then Enum.ScreenInsets.CoreUISafeInsets else Enum.ScreenInsets.None
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = gui
	table.insert(scales, uiScale)
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	guis[name] = gui
	watchViewport()
	fit()
	return gui
end

-- The current fit scale (for code that converts screen pixels into authored units).
function Layers.Scale(): number
	return current
end

return Layers
