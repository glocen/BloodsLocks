--!strict
-- FloatingText: a short text that rises and fades above a model's head (damage numbers, PARRY, ...).

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Parent.Theme)

local LIFETIME = 0.8

local FloatingText = {}

function FloatingText.Pop(model: Model, text: string, color: Color3, big: boolean?)
	local head = model:FindFirstChild("Head") :: BasePart?
	if not head then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Size = if big then UDim2.fromOffset(130, 40) else UDim2.fromOffset(90, 30)
	gui.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 1.6, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.FontFace = Theme.FontBold
	label.Text = text
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeColor3 = Theme.Colors.Background
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	TweenService:Create(gui, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 2.2, 0),
	}):Play()
	TweenService:Create(label, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.4), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	task.delay(LIFETIME, function()
		gui:Destroy()
	end)
end

return FloatingText
