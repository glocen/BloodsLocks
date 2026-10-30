--!strict
-- Hunt (Blood Table tab 1): where you set out. The world and your character stay centre stage; on the left, the mode
-- card (our painted art of the map), one clear "Seek a Hunt" button, and a rules selector. Seeking asks the server
-- (TravelService) to send you to the Victorian Quarter and hands Roblox the Passage picture for the teleport; while
-- the request is pending a small ring turns beside the status, and HuntStatus messages report back here.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchConfig = require(Shared.Config.Match)
local PlayerState = require(Shared.Simulation.PlayerState)
local Net = require(Shared.Net)
local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)
local ModeCard = require(script.Parent.Parent.Kit.ModeCard)
local Passage = require(ReplicatedFirst:WaitForChild("BL_First"):WaitForChild("Passage"))

local M = Theme.Menu
local SPINNER = 20 -- the pending ring's size
local SPIN = 240 -- degrees per second
local TOP = M.Top + M.TabHeight + 40 -- below the tab ribbon
local RULES = Registry.Rules() -- Definitions/Rules, in display order
local MAP_ID = "Victorian"

export type Screen = { Frame: Frame, Begin: (self: Screen) -> (), Hints: { { string } } }

local Hunt = {}
Hunt.__index = Hunt

local function band(parent: Instance, y: number, height: number): TextButton
	local button = Instance.new("TextButton")
	button.AutoButtonColor = false
	button.Text = ""
	button.Position = UDim2.fromOffset(0, y)
	button.Size = UDim2.fromOffset(M.CardWidth, height)
	button.BackgroundColor3 = M.Panel
	button.BackgroundTransparency = 0.18
	button.BorderSizePixel = 0
	button.Parent = parent
	local shade = Instance.new("UIGradient")
	shade.Rotation = 90
	shade.Color = ColorSequence.new(Color3.new(1, 1, 1), Theme.PanelShade)
	shade.Parent = button
	local stroke = Ornament.Frame(button, Theme.Colors.Stroke, false)
	button.MouseEnter:Connect(function()
		Motion.To(button, { BackgroundTransparency = 0 }, "Fast")
		Motion.To(stroke, { Color = Theme.Colors.Hairline }, "Fast")
	end)
	button.MouseLeave:Connect(function()
		Motion.To(button, { BackgroundTransparency = 0.18 }, "Fast")
		Motion.To(stroke, { Color = Theme.Colors.Stroke }, "Fast")
	end)
	return button
end

function Hunt.new(parent: Instance): Screen
	local frame = Instance.new("Frame")
	frame.Name = "Hunt"
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromOffset(M.Margin, TOP)
	frame.Size = UDim2.fromOffset(M.CardWidth, 700)
	frame.Parent = parent

	-- mode card: the map's art, the mode, the map's name
	local map = Registry.Map(MAP_ID)
	ModeCard.new(frame):Set(if map then map.DisplayName else MAP_ID, MatchConfig.ModeName)

	local self = setmetatable({ Frame = frame, Rule = 1, Seeking = false }, Hunt)

	-- the one action
	local seek = band(frame, M.CardHeight + 16, M.ButtonHeight)
	seek.Name = "Seek"
	Text.new(seek, "Body", {
		Text = "Seek a Hunt",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(1, -44, 1, 0),
		TextSize = M.ButtonTextSize,
		ZIndex = 3,
	})
	local glyph = KeyHints.Glyph(seek, "Enter")
	glyph.AnchorPoint = Vector2.new(1, 0.5)
	glyph.Position = UDim2.new(1, -16, 0.5, 0)
	glyph.ZIndex = 3
	seek.Activated:Connect(function()
		self:Begin()
	end)

	-- rules: click to cycle
	local rules = band(frame, M.CardHeight + 16 + M.ButtonHeight + 10, 46)
	rules.Name = "Rules"
	Text.new(rules, "Body", {
		Text = "Rules",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.fromOffset(22, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
		TextSize = M.RowTextSize,
		TextColor3 = Theme.Colors.TextMuted,
		ZIndex = 3,
	})
	self._ruleLabel = Text.new(rules, "Body", {
		TextXAlignment = Enum.TextXAlignment.Right,
		Position = UDim2.new(0.4, 0, 0, 0),
		Size = UDim2.new(0.6, -22, 1, 0),
		TextSize = M.RowTextSize,
		RichText = true,
		ZIndex = 3,
	})
	rules.Activated:Connect(function()
		self:_setRule(self.Rule % #RULES + 1)
	end)

	local statusY = M.CardHeight + 16 + M.ButtonHeight + 10 + 46 + 16
	-- the pending ring: turns beside the status while a request is out
	local spinner = Instance.new("ImageLabel")
	spinner.Name = "Pending"
	spinner.BackgroundTransparency = 1
	spinner.Image = Theme.Images.Ring
	spinner.ImageColor3 = Theme.Colors.Hairline
	spinner.Position = UDim2.fromOffset(4, statusY + 2)
	spinner.Size = UDim2.fromOffset(SPINNER, SPINNER)
	spinner.Visible = false
	spinner.Parent = frame
	local gap = Instance.new("UIGradient") -- a gap in the ring so its turning reads
	gap.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0), NumberSequenceKeypoint.new(1, 1) })
	gap.Parent = spinner
	self._spinner = spinner
	self._status = Text.new(frame, "Body", {
		Name = "Status",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(4, statusY),
		Size = UDim2.fromOffset(M.CardWidth - 8, 80),
		TextSize = M.RowTextSize - 1,
		TextColor3 = Theme.Colors.TextMuted,
	})
	RunService.RenderStepped:Connect(function(dt)
		if spinner.Visible then
			spinner.Rotation = (spinner.Rotation + SPIN * dt) % 360
		end
	end)
	self:_setRule(1)
	Net.Client.On("HuntStatus", function(message: string, done: boolean?)
		self._status.Text = message
		if done then
			self:_setPending(false)
		end
	end)
	self.Hints = { { "Enter", "Seek a Hunt" }, { "Q E", "Change tab" }, { "Backspace", "Leave the table" } }
	return (self :: any) :: Screen
end

function Hunt._setRule(self: any, index: number)
	self.Rule = index
	local rule = RULES[index]
	self._ruleLabel.Text = `‹  {rule.DisplayName}  ›   <font transparency="0.45">{rule.Summary}</font>`
end

-- Pending: the ring turns and the status line steps right to make room for it.
function Hunt._setPending(self: any, pending: boolean)
	self.Seeking = pending
	self._spinner.Visible = pending
	self._status.Position = UDim2.fromOffset(if pending then 4 + SPINNER + 10 else 4, self._status.Position.Y.Offset)
end

function Hunt.Begin(self: any)
	if self.Seeking then
		return
	end
	local rule = RULES[self.Rule]
	if not rule.Playable then
		self._status.Text = `{rule.DisplayName} hunts aren't open yet. Choose another rule.`
		return
	end
	local map = Registry.Map(MAP_ID)
	local class = Registry.Class(Players.LocalPlayer:GetAttribute(PlayerState.Attr.Class))
	self:_setPending(true)
	self._status.Text = `{class.DisplayName} prepares the passage…`
	Passage.PrepareTeleport({ Caption = Passage.Captions.Depart, Destination = if map then map.DisplayName else MAP_ID })
	Net.Client.Fire("SeekHunt", MAP_ID, RULES[self.Rule].Id)
end

return Hunt
