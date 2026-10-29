--!strict
-- Flash: a quick colored highlight pulse on a model (hit flash, parry flash).

local TweenService = game:GetService("TweenService")

local DURATION = 0.18

local Flash = {}

function Flash.Pulse(model: Model, color: Color3)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = color
	highlight.FillTransparency = 0.35
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.OutlineTransparency = 0.3
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	TweenService:Create(highlight, TweenInfo.new(DURATION), { FillTransparency = 1, OutlineTransparency = 1 }):Play()
	task.delay(DURATION + 0.02, function()
		highlight:Destroy()
	end)
end

return Flash
