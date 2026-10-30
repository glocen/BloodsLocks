--!strict
-- Flash: a quick coloured highlight pulse on a model: the body turns a colour with a white outline, then fades (the
-- hit flash, parry flash). This is how a hit shows on a body: never blood (AGENTS.md rule 4: Roblox ToS). One
-- Highlight per model, re-armed by every pulse, so rapid hits (an SMG burst) don't stack highlights (Roblox draws at
-- most 31 at once).

local TweenService = game:GetService("TweenService")

local DURATION = 0.18
local FILL, OUTLINE = 0.35, 0.3 -- transparency at the pulse's start

local Flash = {}

local active: { [Model]: { Highlight: Highlight, Tween: Tween?, Token: number } } = setmetatable({}, { __mode = "k" }) :: any

function Flash.Pulse(model: Model, color: Color3)
	local entry = active[model]
	if not entry or not entry.Highlight.Parent then
		local highlight = Instance.new("Highlight")
		highlight.OutlineColor = Color3.new(1, 1, 1)
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Parent = model
		entry = { Highlight = highlight, Tween = nil, Token = 0 }
		active[model] = entry
	end
	local current = entry :: { Highlight: Highlight, Tween: Tween?, Token: number }
	local highlight = current.Highlight
	if current.Tween then
		current.Tween:Cancel()
	end
	highlight.FillColor = color
	highlight.FillTransparency, highlight.OutlineTransparency = FILL, OUTLINE
	local tween = TweenService:Create(highlight, TweenInfo.new(DURATION), { FillTransparency = 1, OutlineTransparency = 1 })
	current.Tween = tween
	current.Token += 1
	local token = current.Token
	tween:Play()
	task.delay(DURATION + 0.02, function()
		if active[model] == current and current.Token == token then
			active[model] = nil
			highlight:Destroy()
		end
	end)
end

return Flash
