--!strict
-- ShinigamiCard (top-left under the vitals, Duskbloods F "Kin Information"): the Shinigami you have a pact with:
-- a round crest, "Name  Lv. N" and a thin HP gauge. Hidden until a pact exists (Step 10a).

local Theme = require(script.Parent.Parent.Theme)
local Gauge = require(script.Parent.Parent.Kit.Gauge)
local Text = require(script.Parent.Parent.Kit.Text)

export type State = { Name: string, Level: number, Hp: number, Status: string?, Summoned: boolean }?
export type Card = { Frame: Frame, Update: (self: Card, state: State, dt: number) -> () }

local ShinigamiCard = {}
ShinigamiCard.__index = ShinigamiCard

function ShinigamiCard.new(parent: Instance): Card
	local frame = Instance.new("Frame")
	frame.Name = "ShinigamiCard"
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromOffset(40, 104)
	frame.Size = UDim2.fromOffset(300, 40)
	frame.Visible = false
	frame.Parent = parent

	local crest = Instance.new("Frame")
	crest.Name = "Crest"
	crest.Size = UDim2.fromOffset(34, 34)
	crest.BackgroundColor3 = Theme.Colors.HealthDark
	crest.BorderSizePixel = 0
	crest.Parent = frame
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = crest
	local ring = Instance.new("UIStroke")
	ring.Color = Theme.Colors.Hairline
	ring.Transparency = 0.3
	ring.Parent = crest

	local name = Text.new(frame, "Label", {
		Name = "Name",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.fromOffset(250, 22),
	})
	local hp = Gauge.new(frame, {
		Width = 180, Height = 4, Color = Theme.Colors.Health, ColorDark = Theme.Colors.HealthDark,
		Position = UDim2.fromOffset(44, 26), Lag = true,
	})
	return (setmetatable({ Frame = frame, _name = name, _hp = hp }, ShinigamiCard) :: any) :: Card
end

function ShinigamiCard.Update(self: any, state: State, dt: number)
	self.Frame.Visible = state ~= nil
	if state then
		local status = if state.Status then `   <font transparency="0.45">{state.Status}</font>` else ""
		self._name.Text = `{state.Name}   <font transparency="0.35">Lv. {state.Level}</font>{status}`
		self._name.RichText = true
		self._name.TextTransparency = if state.Summoned then 0 else 0.35
		self._hp:Set(state.Hp, dt)
	end
end

return ShinigamiCard
