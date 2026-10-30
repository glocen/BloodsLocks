--!strict
-- Plate: the thin bars over an enemy, a hunter or a companion (Duskbloods' target bars, our art). From the top: the
-- name (when the controller asks for it, with a level for hunters), the HP bar (actual HP over a dark track, with a pale
-- chip that drains after a hit) and the posture bar under it (ember, filling from the centre; full and pulsing while
-- staggered). Beside the HP bar, the running total of the damage you've dealt. Set(view) takes the state, Place()
-- pins it over the head, Alpha() fades the whole plate.

local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)

export type View = {
	Name: string?, -- nil: no name line
	NameColor: Color3?,
	Wide: boolean,
	Hp: number, -- 0..1
	Posture: number, -- 0..1
	Staggered: boolean,
	Total: number?, -- the damage you've dealt lately, or nil
}
export type Plate = {
	Frame: Frame,
	Set: (self: Plate, view: View, dt: number) -> (),
	Place: (self: Plate, position: UDim2) -> (),
	Depth: (self: Plate, scale: number, order: number) -> (),
	Alpha: (self: Plate, alpha: number) -> (),
	Destroy: (self: Plate) -> (),
}

local P = Theme.Plate
local C = Theme.Colors
local NAME_HEIGHT = P.NameSize + 4
local BARS = P.HpHeight + P.Gap + P.PostureHeight
local LAG_DELAY, LAG_RATE = 0.15, 1 / 0.35 -- the chip waits, then drains its whole length in 0.35 s
local FILL_RATE = 18 -- how fast the shown HP and posture catch up (per second)

local Plate = {}
Plate.__index = Plate

local function bar(parent: Instance, name: string, color: Color3, transparency: number, height: number, y: number): Frame
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = transparency
	frame.BorderSizePixel = 0
	frame.Position = UDim2.fromOffset(0, y)
	frame.Size = UDim2.new(1, 0, 0, height)
	frame.Parent = parent
	return frame
end

function Plate.new(parent: Instance): Plate
	local frame = Instance.new("Frame")
	frame.Name = "Plate"
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Size = UDim2.fromOffset(P.Width, NAME_HEIGHT + BARS)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local depth = Instance.new("UIScale")
	depth.Parent = frame
	local name = Text.new(frame, "Caption", {
		Name = "Name",
		Size = UDim2.new(1, 120, 0, NAME_HEIGHT), -- names may run wider than the bars
		Position = UDim2.fromOffset(-60, 0),
		TextSize = P.NameSize,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		Visible = false, -- until Set gives it a name
	})
	local bars = Instance.new("Frame")
	bars.Name = "Bars"
	bars.BackgroundTransparency = 1
	bars.Position = UDim2.fromOffset(0, NAME_HEIGHT)
	bars.Size = UDim2.new(1, 0, 0, BARS)
	bars.Parent = frame
	local hpTrack = bar(bars, "HpTrack", C.HealthDark, 0.15, P.HpHeight, 0)
	local lag = bar(hpTrack, "Lag", C.HealthLag, 0, P.HpHeight, 0)
	local hp = bar(hpTrack, "Hp", C.Health, 0, P.HpHeight, 0)
	local edge = Instance.new("UIStroke")
	edge.Color = C.Background
	edge.Transparency = 0.35
	edge.Thickness = Theme.Stroke.Hairline
	edge.Parent = hpTrack
	local postureTrack = bar(bars, "PostureTrack", C.Background, 0.45, P.PostureHeight, P.HpHeight + P.Gap)
	local posture = bar(postureTrack, "Posture", Color3.new(1, 1, 1), 0, P.PostureHeight, 0)
	posture.AnchorPoint = Vector2.new(0.5, 0)
	posture.Position = UDim2.fromScale(0.5, 0)
	local shade = Instance.new("UIGradient")
	shade.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.PostureDark),
		ColorSequenceKeypoint.new(0.5, C.Posture),
		ColorSequenceKeypoint.new(1, C.PostureDark),
	})
	shade.Parent = posture
	local total = Text.new(bars, "Numeric", {
		Name = "Total",
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 6, 0, P.HpHeight / 2),
		Size = UDim2.fromOffset(60, P.TotalSize + 4),
		TextSize = P.TotalSize,
		Visible = false, -- until there's damage to count
	})
	-- every piece and its own transparency, so Alpha() can fade them together
	local faders = {
		{ name, "TextTransparency", 0 },
		{ total, "TextTransparency", 0 },
		{ hpTrack, "BackgroundTransparency", hpTrack.BackgroundTransparency },
		{ lag, "BackgroundTransparency", 0 },
		{ hp, "BackgroundTransparency", 0 },
		{ postureTrack, "BackgroundTransparency", postureTrack.BackgroundTransparency },
		{ posture, "BackgroundTransparency", 0 },
		{ edge, "Transparency", edge.Transparency },
	}
	return (setmetatable({
		Frame = frame,
		_depth = depth,
		_name = name,
		_hp = hp,
		_lag = lag,
		_posture = posture,
		_total = total,
		_faders = faders,
		_alpha = -1,
		_shownHp = -1,
		_lagHp = 1,
		_lagWait = 0,
		_shownPosture = 0,
		_pulse = 0,
		-- what's on screen now, so Set writes only changes
		_wide = nil,
		_nameText = nil,
		_nameColor = nil,
		_totalText = nil,
		_drawnHp = -1,
		_drawnLag = -1,
		_drawnPosture = -1,
	}, Plate) :: any) :: Plate
end

-- Writes only what changed: this runs every frame for up to a dozen plates, and every text write re-syncs a shadow.
function Plate.Set(self: any, view: View, dt: number)
	if view.Wide ~= self._wide then
		self._wide = view.Wide
		self.Frame.Size = UDim2.fromOffset(if view.Wide then P.WideWidth else P.Width, NAME_HEIGHT + BARS)
	end
	if view.Name ~= self._nameText then
		self._nameText = view.Name
		self._name.Visible = view.Name ~= nil
		if view.Name then
			self._name.Text = view.Name
		end
	end
	local nameColor = view.NameColor or C.Text
	if nameColor ~= self._nameColor then
		self._nameColor = nameColor
		self._name.TextColor3 = nameColor
	end
	-- HP: the fill follows at once (confirmed loss is immediate); the chip waits, then drains to it
	local hp = math.clamp(view.Hp, 0, 1)
	if self._shownHp < 0 then
		self._shownHp, self._lagHp = hp, hp
	end
	if hp < self._shownHp then
		self._lagWait = LAG_DELAY
	end
	self._shownHp = hp
	if self._lagHp > hp then
		if self._lagWait > 0 then
			self._lagWait -= dt
		else
			self._lagHp = math.max(hp, self._lagHp - LAG_RATE * dt)
		end
	else
		self._lagHp = hp
	end
	if math.abs(hp - self._drawnHp) > 1e-3 or math.abs(self._lagHp - self._drawnLag) > 1e-3 then
		self._drawnHp, self._drawnLag = hp, self._lagHp
		self._hp.Size = UDim2.new(hp, 0, 1, 0)
		self._lag.Size = UDim2.new(self._lagHp, 0, 1, 0)
	end
	-- posture: full and pulsing while staggered
	local posture = if view.Staggered then 1 else math.clamp(view.Posture, 0, 1)
	self._shownPosture += (posture - self._shownPosture) * math.min(1, dt * FILL_RATE)
	if math.abs(self._shownPosture - self._drawnPosture) > 1e-3 then
		self._drawnPosture = self._shownPosture
		self._posture.Size = UDim2.new(self._shownPosture, 0, 1, 0)
	end
	if view.Staggered then
		self._pulse = (self._pulse + dt * 6) % (2 * math.pi)
		self._posture.BackgroundColor3 = Color3.new(1, 1, 1):Lerp(C.Warm, 0.5 + 0.5 * math.sin(self._pulse))
	elseif self._pulse ~= 0 then
		self._pulse = 0
		self._posture.BackgroundColor3 = Color3.new(1, 1, 1)
	end
	local total = if view.Total then tostring(math.floor(view.Total)) else nil
	if total ~= self._totalText then
		self._totalText = total
		self._total.Visible = total ~= nil
		if total then
			self._total.Text = total
		end
	end
end

function Plate.Place(self: any, position: UDim2)
	if position ~= self.Frame.Position then
		self.Frame.Position = position
	end
end

-- Distance cues: farther plates draw smaller (`scale`), nearer ones on top (higher `order`).
function Plate.Depth(self: any, scale: number, order: number)
	if math.abs(scale - self._depth.Scale) > 1e-3 then
		self._depth.Scale = scale
	end
	if order ~= self.Frame.ZIndex then
		self.Frame.ZIndex = order
	end
end

-- 1 = fully shown, 0 = gone.
function Plate.Alpha(self: any, alpha: number)
	if math.abs(alpha - self._alpha) < 0.01 then
		return
	end
	self._alpha = alpha
	self.Frame.Visible = alpha > 0.01
	for _, fader in self._faders do
		(fader[1] :: any)[fader[2]] = 1 - (1 - fader[3]) * alpha
	end
end

function Plate.Destroy(self: any)
	self.Frame:Destroy()
end

return Plate
