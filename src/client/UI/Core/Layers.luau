--!strict
-- Layers: one ScreenGui per UI layer (HUD, Menus, Overlay, Toasts, Transition), created on first use, ordered by
-- Theme.Layers and fitted to the screen by a UIScale: everything is authored at Theme.ReferenceResolution and
-- scales uniformly, so offsets, strokes and paddings stay proportional on every screen.

local Players = game:GetService("Players")

local Theme = require(script.Parent.Parent.Theme)

export type LayerName = "HUD" | "Menus" | "Overlay" | "Toasts" | "Transition"

local MIN_SCALE, MAX_SCALE = 0.5, 1.5

local Layers = {}

local guis: { [string]: ScreenGui } = {}
local scales: { UIScale } = {}

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

-- The ScreenGui for a layer. Interactive layers stay inside the core-UI safe area; Transition covers everything.
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
	if name == "Transition" then
		gui.IgnoreGuiInset = true
		gui.ScreenInsets = Enum.ScreenInsets.None
	else
		gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
	end
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
	return if scales[1] then scales[1].Scale else 1
end

return Layers
