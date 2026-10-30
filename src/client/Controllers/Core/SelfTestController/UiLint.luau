--!strict
-- UiLint: checks every label the player can see right now, on whatever screen is open (the self-test's "UI lint"
-- case runs it without moving you to the test pad). For each visible, non-empty label:
--   its Text-kit shadow mirrors it (a stale shadow draws a ghost copy of the text);
--   its text fits its box, unless it truncates on purpose (a line box may overrun by FIT_TOLERANCE pixels: at small
--   windows the legible text size rounds up a pixel past a box sized for the authored one, and nothing is clipped);
--   it renders at least its legible minimum (Text.Minimum), or the caption floor when it isn't managed;
--   it lies inside its screen;
--   it doesn't show Roblox's default "Label" (a label nobody filled in).
-- World labels (BillboardGuis) skip the size and screen checks: their size depends on distance.
-- Only our own containers are checked (names starting BL_, like the Layers): Roblox's prompts and core UI aren't ours.

local Players = game:GetService("Players")

local UI = script.Parent.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Text = require(UI.Kit.Text)

local LIST = 6 -- offenders named per check
local OURS = "BL_" -- prefix of every ScreenGui/BillboardGui we create
local TOLERANCE = 1 -- pixels
local FIT_TOLERANCE = 2 -- pixels a line box may overrun its frame
local DERIVED = { Position = true, TextTransparency = true, ZIndex = true } -- the shadow offsets these on purpose
local PLACEHOLDER = "Label" -- Roblox's default TextLabel text

local UiLint = {}

export type Report = { Checked: number, Shadow: { string }, Fit: { string }, Size: { string }, Screen: { string }, Placeholder: { string } }

-- Whether a GUI object actually draws: visible all the way up, in an enabled container, not faded out.
local function shown(object: GuiObject): boolean
	if object:IsA("TextLabel") and (object.TextTransparency >= 0.95 or object.Text == "") then
		return false
	end
	local node: Instance? = object
	while node and not node:IsA("LayerCollector") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("CanvasGroup") and node.GroupTransparency >= 0.95 then
			return false
		end
		node = node.Parent
	end
	return node ~= nil and (node :: LayerCollector).Enabled and string.sub(node.Name, 1, #OURS) == OURS
end

-- The product of the UIScales that apply to `object` (Layers fits each layer with one).
local function scaleOf(object: Instance): number
	local scale = 1
	local node: Instance? = object
	while node do
		local uiScale = node:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale *= uiScale.Scale
		end
		node = node.Parent
	end
	return scale
end

-- The label's last three names, enough to find it.
local function short(object: Instance): string
	local parts = {}
	local node: Instance? = object
	for _ = 1, 3 do
		if not node or node:IsA("PlayerGui") then
			break
		end
		table.insert(parts, 1, node.Name)
		node = node.Parent
	end
	return table.concat(parts, ".")
end

local function shadowMismatch(label: TextLabel, shadow: TextLabel): string?
	for _, prop in Text.ShadowMirrors do
		if not DERIVED[prop] and (shadow :: any)[prop] ~= (label :: any)[prop] then
			return prop
		end
	end
	if shadow.Position ~= label.Position + UDim2.fromOffset(1, 2) then
		return "Position"
	end
	return nil
end

function UiLint.Run(): Report
	local report: Report = { Checked = 0, Shadow = {}, Fit = {}, Size = {}, Screen = {}, Placeholder = {} }
	local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local shadowSet: { [Instance]: boolean } = {}
	for _, object in gui:GetDescendants() do
		if object:IsA("TextLabel") then
			local shadow = Text.ShadowOf(object)
			if shadow then
				shadowSet[shadow] = true
			end
		end
	end
	for _, object in gui:GetDescendants() do
		if not object:IsA("TextLabel") or shadowSet[object] or not shown(object) then
			continue
		end
		local label = object :: TextLabel
		report.Checked += 1
		local name = short(label)
		local shadow = Text.ShadowOf(label)
		local mismatch = shadow and shadowMismatch(label, shadow)
		if mismatch then
			table.insert(report.Shadow, `{name} ({mismatch})`)
		end
		if label.Text == PLACEHOLDER then
			table.insert(report.Placeholder, name)
		end
		local bounds, box = label.TextBounds, label.AbsoluteSize
		local overruns = bounds.X > box.X + FIT_TOLERANCE or bounds.Y > box.Y + FIT_TOLERANCE
		if not label.TextFits and overruns and not label.TextScaled and label.TextTruncate == Enum.TextTruncate.None then
			table.insert(report.Fit, `{name} ({math.ceil(bounds.X)}x{math.ceil(bounds.Y)} in {math.floor(box.X)}x{math.floor(box.Y)})`)
		end
		local screen = label:FindFirstAncestorOfClass("ScreenGui")
		if screen then
			local rendered = label.TextSize * scaleOf(label)
			local minimum = Text.Minimum(label) or Theme.TextSize.MinCaption
			if rendered < minimum - 0.5 then
				table.insert(report.Size, `{name} ({string.format("%.1f", rendered)} px < {minimum})`)
			end
			-- measured from the screen's own origin: layers that ignore the GUI inset start above y = 0
			local position = label.AbsolutePosition - screen.AbsolutePosition
			local size, bounds = label.AbsoluteSize, screen.AbsoluteSize
			if position.X < -TOLERANCE or position.Y < -TOLERANCE or position.X + size.X > bounds.X + TOLERANCE or position.Y + size.Y > bounds.Y + TOLERANCE then
				table.insert(report.Screen, name)
			end
		end
	end
	return report
end

-- "a; b; c +2 more", or how many labels were checked when the list is empty.
function UiLint.Detail(list: { string }, checked: number): string
	if #list == 0 then
		return `{checked} labels`
	end
	local named = table.move(list, 1, math.min(#list, LIST), 1, {})
	return table.concat(named, "; ") .. (if #list > LIST then ` +{#list - LIST} more` else "")
end

return UiLint
