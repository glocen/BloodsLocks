--!strict
-- Hunt (Blood Table tab 1): where you set out. The world and your character stay centre stage; on the left, the mode
-- card (our painted art of the map), one clear "Seek a Hunt" button, and a rules selector. Seeking asks the server
-- (MatchmakingService) to send you to the Victorian Quarter; HuntStatus messages report back here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local PlayerState = require(Shared.Simulation.PlayerState)
local Net = require(Shared.Net)
local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)
local Ornament = require(script.Parent.Parent.Kit.Ornament)
local KeyHints = require(script.Parent.Parent.Kit.KeyHints)

local M = Theme.Menu
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
	local card = Instance.new("ImageLabel")
	card.Name = "ModeCard"
	card.Size = UDim2.fromOffset(M.CardWidth, M.CardHeight)
	card.Image = Theme.Images.HuntCard
	card.ScaleType = Enum.ScaleType.Crop
	card.BackgroundColor3 = Theme.Palette.Ink
	card.BorderSizePixel = 0
	card.Parent = frame
	local foot = Instance.new("Frame") -- darkens the bottom so the title reads
	foot.Size = UDim2.fromScale(1, 1)
	foot.BackgroundColor3 = Theme.Palette.Ink
	foot.BorderSizePixel = 0
	foot.Parent = card
	local footFade = Instance.new("UIGradient")
	footFade.Rotation = 90
	footFade.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 1), NumberSequenceKeypoint.new(0.62, 0.15), NumberSequenceKeypoint.new(1, 0.02) })
	footFade.Parent = foot
	Ornament.Frame(card)
	Text.new(card, "Caption", {
		Text = string.upper(if map then map.DisplayName else MAP_ID),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 16,
		Position = UDim2.new(0, 20, 1, -70),
		Size = UDim2.fromOffset(M.CardWidth - 40, 18),
		TextColor3 = Theme.Colors.Hairline,
		ZIndex = 3,
	})
	Text.new(card, "Title", {
		Text = "Open Hunt",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 20, 1, -50),
		Size = UDim2.fromOffset(M.CardWidth - 40, 38),
		TextSize = 32,
		ZIndex = 3,
	})

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

	self._status = Text.new(frame, "Body", {
		Name = "Status",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		Position = UDim2.fromOffset(4, M.CardHeight + 16 + M.ButtonHeight + 10 + 46 + 16),
		Size = UDim2.fromOffset(M.CardWidth - 8, 80),
		TextSize = M.RowTextSize - 1,
		TextColor3 = Theme.Colors.TextMuted,
	})
	self:_setRule(1)
	Net.Client.On("HuntStatus", function(message: string, done: boolean?)
		self._status.Text = message
		if done then
			self.Seeking = false
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

function Hunt.Begin(self: any)
	if self.Seeking then
		return
	end
	local rule = RULES[self.Rule]
	if not rule.Playable then
		self._status.Text = `{rule.DisplayName} hunts aren't open yet. Choose another rule.`
		return
	end
	self.Seeking = true
	local class = Registry.Class(Players.LocalPlayer:GetAttribute(PlayerState.Attr.Class))
	self._status.Text = `{class.DisplayName} sets out for the hunt…`
	Net.Client.Fire("SeekHunt", MAP_ID, RULES[self.Rule].Id)
end

return Hunt
