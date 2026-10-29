--!strict
-- Arsenal (bottom-left, Duskbloods H/J): the ranged-attack resource box (SMG "rounds / magazine" with a segmented
-- bar) and the Bloodsworn skills: the first skill as a large emblem with a ring gauge that drains on use and refills
-- with its charges, the second as the small emblem at its lower left, and the first skill's name on a ribbon.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)
local RingMeter = require(script.Parent.Parent.Kit.RingMeter)

export type SkillState = {
	Name: string,
	Key: string,
	Emblem: string, -- image id
	EmblemColor: Color3,
	Charges: number,
	MaxCharges: number,
	NextCharge: number, -- 0..1 progress of the charge being restored
	LockedLevel: number?,
}
export type State = {
	Rounds: number,
	Magazine: number,
	Reloading: boolean,
	Skills: { SkillState },
}
export type Arsenal = { Frame: Frame, Update: (self: Arsenal, state: State) -> () }

local BIG, SMALL = 96, 56
local SEGMENTS_MAX = 40

local Arsenal = {}
Arsenal.__index = Arsenal

local function disc(parent: Instance, size: number, position: UDim2): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = position
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundColor3 = Theme.Colors.Background
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = f
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Theme.Palette.Velvet, Theme.Palette.Ink)
	shade.Parent = f
	f.Parent = parent
	return f
end

local function image(parent: Instance, name: string, id: string, size: UDim2, color: Color3, transparency: number, z: number): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = name
	i.AnchorPoint = Vector2.new(0.5, 0.5)
	i.Position = UDim2.fromScale(0.5, 0.5)
	i.Size = size
	i.BackgroundTransparency = 1
	i.Image = id
	i.ImageColor3 = color
	i.ImageTransparency = transparency
	i.ZIndex = z
	i.Parent = parent
	return i
end

local function skillView(parent: Instance, size: number, center: UDim2)
	local ring = RingMeter.new(parent, math.floor(size * 1.32), center, Theme.Colors.Hairline) -- sits just outside the bezel
	local base = disc(parent, size, center)
	-- a coloured glow pooled behind the emblem, then the engraved bronze bezel on the rim
	local glow = image(base, "Glow", Theme.Images.SoftGlow, UDim2.fromScale(1.1, 1.1), Theme.Colors.Health, 0.35, 1)
	image(base, "Bezel", Theme.Images.Medallion, UDim2.fromScale(1.08, 1.08), Theme.Palette.GoldDim, 0, 4)
	local emblem = Instance.new("ImageLabel")
	emblem.Name = "Emblem"
	emblem.AnchorPoint = Vector2.new(0.5, 0.5)
	emblem.Position = UDim2.fromScale(0.5, 0.5)
	emblem.Size = UDim2.fromScale(0.74, 0.74)
	emblem.BackgroundTransparency = 1
	emblem.ScaleType = Enum.ScaleType.Fit
	emblem.ZIndex = 2
	emblem.Parent = base
	local charges = Text.new(base, "Numeric", {
		Name = "Charges",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 18),
		TextSize = if size >= BIG then 18 else 14,
	})
	-- key hint: a small dark badge on the ring's lower right
	local badge = Instance.new("Frame")
	badge.Name = "KeyBadge"
	badge.AnchorPoint = Vector2.new(0.5, 0.5)
	badge.Position = UDim2.fromScale(0.86, 0.86)
	badge.Size = UDim2.fromOffset(if size >= BIG then 22 else 18, if size >= BIG then 22 else 18)
	badge.BackgroundColor3 = Theme.Colors.Background
	badge.BorderSizePixel = 0
	badge.ZIndex = 5
	badge.Parent = base
	local badgeRound = Instance.new("UICorner")
	badgeRound.CornerRadius = UDim.new(0.5, 0)
	badgeRound.Parent = badge
	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Theme.Colors.Stroke
	badgeStroke.Parent = badge
	local key = Text.new(badge, "Caption", {
		Name = "Key",
		Size = UDim2.fromScale(1, 1),
		TextSize = if size >= BIG then 14 else 12,
		ZIndex = 6,
	})
	local lock = Text.new(base, "Label", {
		Name = "Lock",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 0.4),
		TextColor3 = Theme.Colors.TextMuted,
	})
	charges.ZIndex = 6
	lock.ZIndex = 6
	return { Base = base, Ring = ring, Glow = glow, Emblem = emblem, Charges = charges, Key = key, Lock = lock }
end

function Arsenal.new(parent: Instance): Arsenal
	local frame = Instance.new("Frame")
	frame.Name = "Arsenal"
	frame.BackgroundTransparency = 1
	frame.AnchorPoint = Vector2.new(0, 1)
	frame.Position = UDim2.new(0, 36, 1, -30)
	frame.Size = UDim2.fromOffset(420, 220)
	frame.Parent = parent

	-- H: ranged resources box
	local box = Instance.new("Frame")
	box.Name = "Ammo"
	box.Position = UDim2.fromOffset(8, 52)
	box.Size = UDim2.fromOffset(196, 36)
	box.BackgroundColor3 = Theme.Colors.Background
	box.BackgroundTransparency = 0.35
	box.BorderSizePixel = 0
	box.Parent = frame
	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = Theme.Colors.Stroke
	boxStroke.Transparency = 0.35
	boxStroke.Parent = box
	local icon = Instance.new("ImageLabel")
	icon.Name = "BulletIcon"
	icon.BackgroundTransparency = 1
	icon.Image = Theme.Images.Bullet
	icon.ImageColor3 = Theme.Colors.Text
	icon.Position = UDim2.fromOffset(10, 3)
	icon.Size = UDim2.fromOffset(16, 16)
	icon.Rotation = 35
	icon.Parent = box
	local rounds = Text.new(box, "Numeric", {
		Name = "Rounds",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(32, 1),
		Size = UDim2.fromOffset(170, 20),
		TextSize = 17,
	})
	local strip = Instance.new("Frame")
	strip.Name = "Segments"
	strip.BackgroundTransparency = 1
	strip.Position = UDim2.fromOffset(12, 23)
	strip.Size = UDim2.fromOffset(172, 6)
	strip.Parent = box
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.Padding = UDim.new(0, 1)
	layout.Parent = strip
	local segments = {}
	for i = 1, SEGMENTS_MAX do
		local seg = Instance.new("Frame")
		seg.BorderSizePixel = 0
		seg.BackgroundColor3 = Theme.Colors.Text
		seg.Size = UDim2.fromOffset(3, 6)
		seg.LayoutOrder = i
		seg.Parent = strip
		segments[i] = seg
	end

	-- J: skills
	local bigCenter = UDim2.fromOffset(84, 150)
	local smallCenter = UDim2.fromOffset(28, 196)
	local views = { skillView(frame, BIG, bigCenter), skillView(frame, SMALL, smallCenter) }
	local ribbon = Instance.new("Frame")
	ribbon.Name = "Ribbon"
	ribbon.AnchorPoint = Vector2.new(0, 0.5)
	ribbon.Position = UDim2.fromOffset(140, 150)
	ribbon.Size = UDim2.fromOffset(240, 28)
	ribbon.BackgroundColor3 = Theme.Colors.Background
	ribbon.BorderSizePixel = 0
	ribbon.Parent = frame
	local fade = Instance.new("UIGradient")
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.7, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = ribbon
	local skillName = Text.new(ribbon, "Label", {
		Name = "SkillName",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -12, 1, 0),
		TextSize = 18,
	})

	return (setmetatable({ Frame = frame, _rounds = rounds, _segments = segments, _views = views, _skillName = skillName }, Arsenal) :: any) :: Arsenal
end

function Arsenal.Update(self: any, state: State)
	-- H
	self._rounds.Text = if state.Reloading then "Reloading" else `{state.Rounds} / {state.Magazine}`
	self._rounds.TextColor3 = if state.Reloading or state.Rounds == 0 then Theme.Colors.TextMuted else Theme.Colors.Text
	for i, seg in self._segments do
		seg.Visible = i <= state.Magazine
		seg.BackgroundTransparency = if i <= state.Rounds and not state.Reloading then 0.05 else 0.75
	end
	-- J
	for slot, view in self._views do
		local skill = state.Skills[slot]
		view.Base.Visible = skill ~= nil
		view.Ring.Frame.Visible = skill ~= nil
		if skill then
			local locked = skill.LockedLevel ~= nil
			local ready = not locked and skill.Charges > 0
			view.Emblem.Image = skill.Emblem
			view.Emblem.ImageColor3 = skill.EmblemColor
			view.Emblem.ImageTransparency = if ready then 0 elseif locked then 0.8 else 0.55
			view.Glow.ImageColor3 = if skill.EmblemColor == Color3.new(1, 1, 1) then Theme.Colors.Health else skill.EmblemColor
			view.Glow.ImageTransparency = if ready then 0.35 else 0.85
			view.Key.Text = skill.Key
			view.Charges.Text = if locked or skill.MaxCharges <= 1 then "" else `{skill.Charges}/{skill.MaxCharges}`
			view.Lock.Text = if locked then `Lv {skill.LockedLevel}` else ""
			local progress = if locked then 0 else (skill.Charges + (if skill.Charges < skill.MaxCharges then skill.NextCharge else 0)) / skill.MaxCharges
			view.Ring:Set(progress, if ready then Theme.Colors.Hairline else Theme.Colors.Stroke)
		end
	end
	local first = state.Skills[1]
	self._skillName.Text = if first then first.Name else ""
end

return Arsenal
