--!strict
-- Vitals (top-left, Duskbloods A/B/C/D): an engraved medallion in the corner (our crest now; the Renown score in
-- matches), and growing out of it: "Lv. N" with the experience gauge, the long HP gauge (with a damage chip) and the
-- short, thin green stamina gauge (flashes when empty). Effects (E) join under it once that system exists.

local Theme = require(script.Parent.Parent.Theme)
local Gauge = require(script.Parent.Parent.Kit.Gauge)
local Text = require(script.Parent.Parent.Kit.Text)

export type State = { Level: number, Xp: number, Hp: number, Stamina: number, StaminaEmpty: boolean, Score: number? }
export type Vitals = { Frame: Frame, Update: (self: Vitals, state: State, dt: number) -> () }

local MARGIN = Vector2.new(36, 26)
local MEDALLION = 68
local BARS_X = MEDALLION - 8 -- the bars start just under the medallion's rim
local HP_WIDTH, STAMINA_WIDTH = 370, 200

local Vitals = {}
Vitals.__index = Vitals

local function image(parent: Instance, name: string, id: string, scale: number, color: Color3, transparency: number, z: number): ImageLabel
	local i = Instance.new("ImageLabel")
	i.Name = name
	i.AnchorPoint = Vector2.new(0.5, 0.5)
	i.Position = UDim2.fromScale(0.5, 0.5)
	i.Size = UDim2.fromScale(scale, scale)
	i.BackgroundTransparency = 1
	i.Image = id
	i.ImageColor3 = color
	i.ImageTransparency = transparency
	i.ZIndex = z
	i.Parent = parent
	return i
end

function Vitals.new(parent: Instance): Vitals
	local frame = Instance.new("Frame")
	frame.Name = "Vitals"
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromOffset(MARGIN.X, MARGIN.Y)
	frame.Size = UDim2.fromOffset(BARS_X + HP_WIDTH, MEDALLION)
	frame.Parent = parent

	-- the medallion: dark face with a blood glow, engraved bezel, centre crest or number
	local medallion = Instance.new("Frame")
	medallion.Name = "Medallion"
	medallion.Size = UDim2.fromOffset(MEDALLION, MEDALLION)
	medallion.BackgroundColor3 = Theme.Palette.Ink
	medallion.BorderSizePixel = 0
	medallion.ZIndex = 5
	medallion.Parent = frame
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = medallion
	image(medallion, "Glow", Theme.Images.SoftGlow, 1, Theme.Colors.Health, 0.3, 6)
	image(medallion, "Bezel", Theme.Images.Medallion, 1.06, Theme.Palette.GoldDim, 0, 9)
	local crest = image(medallion, "Crest", Theme.Images.BloodCrescent, 0.62, Color3.new(1, 1, 1), 0, 7)
	crest.ScaleType = Enum.ScaleType.Fit
	local score = Text.new(medallion, "Title", {
		Name = "Score",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 0.5),
		TextSize = 24,
		ZIndex = 8,
		Visible = false,
	})

	local level = Text.new(frame, "Numeric", {
		Name = "Level",
		Text = "Lv. 1",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(BARS_X + 12, 5),
		Size = UDim2.fromOffset(70, 20),
		TextSize = 18,
	})
	local xp = Gauge.new(frame, {
		Width = 120, Height = 3, Color = Theme.Colors.Hairline, ColorDark = Theme.Palette.GoldDim,
		Position = UDim2.fromOffset(BARS_X + 70, 15), AnchorPoint = Vector2.new(0, 0.5),
	})
	local hp = Gauge.new(frame, {
		Width = HP_WIDTH, Height = 8, Color = Theme.Colors.Health, ColorDark = Theme.Colors.HealthDark,
		Position = UDim2.fromOffset(BARS_X, 29), Lag = true,
	})
	local stamina = Gauge.new(frame, {
		Width = STAMINA_WIDTH, Height = 3, Color = Theme.Colors.Stamina, ColorDark = Theme.Colors.StaminaDark,
		Position = UDim2.fromOffset(BARS_X, 41),
	})
	return (setmetatable({ Frame = frame, _level = level, _xp = xp, _hp = hp, _stamina = stamina, _crest = crest, _score = score }, Vitals) :: any) :: Vitals
end

function Vitals.Update(self: any, state: State, dt: number)
	self._level.Text = `Lv. {state.Level}`
	self._xp:Set(state.Xp, dt)
	self._hp:Set(state.Hp, dt)
	self._stamina:Set(state.Stamina, dt)
	self._stamina.Fill.BackgroundTransparency = if state.StaminaEmpty then 0.5 + 0.5 * math.sin(os.clock() * 18) else 0
	local hasScore = state.Score ~= nil
	self._crest.Visible = not hasScore
	self._score.Visible = hasScore
	if hasScore then
		self._score.Text = tostring(state.Score)
	end
end

return Vitals
