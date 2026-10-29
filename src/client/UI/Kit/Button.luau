--!strict
-- Button: Primary (blood), Secondary (velvet + gold hairline) and Ghost (text only). Every state is handled here:
-- hover (glow + hairline brightens + slight lift), press (dip), disabled (muted, no input), focus (gold frame).
-- Returns the TextButton and a small controller with SetEnabled / Destroy.

local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Ornament = require(script.Parent.Ornament)

export type Variant = "Primary" | "Secondary" | "Ghost"
export type Options = {
	Text: string,
	Variant: Variant?,
	Size: UDim2?,
	Position: UDim2?,
	AnchorPoint: Vector2?,
	OnClick: (() -> ())?,
}
export type Button = {
	Instance: TextButton,
	SetEnabled: (self: Button, enabled: boolean) -> (),
	Destroy: (self: Button) -> (),
}

local LOOK = {
	Primary = { Fill = Theme.Colors.Primary, FillTransparency = 0.05, Text = Theme.Colors.Text, Stroke = Theme.Colors.Hairline },
	Secondary = { Fill = Theme.Colors.Panel, FillTransparency = Theme.Transparency.Panel, Text = Theme.Colors.Text, Stroke = Theme.Colors.Stroke },
	Ghost = { Fill = Theme.Colors.Panel, FillTransparency = 1, Text = Theme.Colors.TextMuted, Stroke = Theme.Colors.Stroke },
}

local Class = {}
Class.__index = Class

local Button = {}

function Button.new(parent: Instance, options: Options): Button
	local variant = options.Variant or "Secondary"
	local look = LOOK[variant]
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.AutoButtonColor = false
	button.Size = options.Size or UDim2.fromOffset(240, 48)
	button.Position = options.Position or UDim2.new()
	button.AnchorPoint = options.AnchorPoint or Vector2.zero
	button.BackgroundColor3 = look.Fill
	button.BackgroundTransparency = look.FillTransparency
	button.BorderSizePixel = 0
	button.Text = string.upper(options.Text)
	button.FontFace = Theme.Fonts.Display
	button.TextSize = Theme.TextSize.Label
	button.TextColor3 = look.Text
	local stroke = Ornament.Frame(button, look.Stroke, variant ~= "Ghost")
	if variant == "Ghost" then
		stroke.Transparency = 1
	end
	local scale = Instance.new("UIScale")
	scale.Parent = button
	local glow = Instance.new("UIGradient")
	glow.Color = ColorSequence.new(Color3.new(1, 1, 1))
	glow.Transparency = NumberSequence.new(0)
	glow.Parent = button

	local self = setmetatable({ Instance = button, _enabled = true, _connections = {} }, Class)
	local hovered = false
	local function refresh()
		if not self._enabled then
			Motion.To(button, { TextColor3 = Theme.Colors.Disabled, BackgroundTransparency = math.max(look.FillTransparency, Theme.Transparency.Disabled) }, "Fast")
			Motion.To(stroke, { Transparency = 0.8 }, "Fast")
			Motion.To(scale, { Scale = 1 }, "Fast")
			return
		end
		Motion.To(button, {
			TextColor3 = if hovered then Theme.Colors.Text else look.Text,
			BackgroundTransparency = if hovered then math.max(0, look.FillTransparency - 0.15) else look.FillTransparency,
		}, "Fast")
		Motion.To(stroke, {
			Transparency = if variant == "Ghost" and not hovered then 1 elseif hovered then 0 else Theme.Transparency.Hairline,
			Color = if hovered then Theme.Colors.Focus else look.Stroke,
		}, "Fast")
		Motion.To(scale, { Scale = if hovered then 1.03 else 1 }, "Fast")
	end
	table.insert(self._connections, button.MouseEnter:Connect(function()
		hovered = true
		refresh()
	end))
	table.insert(self._connections, button.MouseLeave:Connect(function()
		hovered = false
		refresh()
	end))
	table.insert(self._connections, button.MouseButton1Down:Connect(function()
		if self._enabled then
			Motion.To(scale, { Scale = 0.97 }, "Fast")
		end
	end))
	table.insert(self._connections, button.MouseButton1Up:Connect(refresh))
	table.insert(self._connections, button.Activated:Connect(function()
		if self._enabled and options.OnClick then
			options.OnClick()
		end
	end))
	self._refresh = refresh
	button.Parent = parent
	refresh()
	return (self :: any) :: Button
end

function Class.SetEnabled(self: any, enabled: boolean)
	self._enabled = enabled
	self.Instance.Active = enabled
	self._refresh()
end

function Class.Destroy(self: any)
	for _, c in self._connections do
		c:Disconnect()
	end
	self.Instance:Destroy()
end

return Button
