--!strict
-- DuskBattle (Blood Table tab 1): the matchmaking screen, Duskbloods-style: the world stays visible; a mode card
-- top-left (map + match type), the rules list under it, then join-by-code and party. Begin starts matchmaking
-- (the Victorian place arrives in Step 10; until then it reports that the quarter isn't open).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Registry = require(ReplicatedStorage.Shared.Definitions.Registry)
local PlayerState = require(ReplicatedStorage.Shared.Simulation.PlayerState)
local Theme = require(script.Parent.Parent.Theme)
local Text = require(script.Parent.Parent.Kit.Text)
local ListRow = require(script.Parent.Parent.Kit.ListRow)
local Ornament = require(script.Parent.Parent.Kit.Ornament)

local RULES = {
	{ Id = "Standard", Label = "Standard", Sub = "alliances allowed" },
	{ Id = "Solo", Label = "No alliances", Sub = "always alone" },
	{ Id = "Bloodbound", Label = "Bloodbound duo", Sub = "teams of two" },
}
local WIDTH = 420

export type Screen = { Frame: Frame, Begin: (self: Screen) -> (), Hints: { { string } } }

local DuskBattle = {}
DuskBattle.__index = DuskBattle

local function header(parent: Instance, text: string, order: number)
	local h = Text.new(parent, "Caption", {
		Text = string.upper(text),
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = UDim2.fromOffset(WIDTH, 26),
		TextColor3 = Theme.Colors.Hairline,
		LayoutOrder = order,
	})
	return h
end

function DuskBattle.new(parent: Instance): Screen
	local frame = Instance.new("Frame")
	frame.Name = "DuskBattle"
	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromOffset(56, 86)
	frame.Size = UDim2.fromOffset(WIDTH, 760)
	frame.Parent = parent
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = frame

	-- mode card: map banner + match type
	local card = Instance.new("Frame")
	card.Name = "ModeCard"
	card.Size = UDim2.fromOffset(WIDTH, 170)
	card.BackgroundColor3 = Theme.Palette.Velvet
	card.BorderSizePixel = 0
	card.LayoutOrder = 1
	card.Parent = frame
	local sky = Instance.new("UIGradient")
	sky.Rotation = 90
	sky.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Theme.ModeCard.Top),
		ColorSequenceKeypoint.new(0.55, Theme.ModeCard.Middle),
		ColorSequenceKeypoint.new(1, Theme.Palette.Ink),
	})
	sky.Parent = card
	Ornament.Frame(card)
	Text.new(card, "Caption", {
		Text = "CASUAL MATCH",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 1, -66),
		Size = UDim2.fromOffset(WIDTH - 36, 18),
		TextColor3 = Theme.Colors.Hairline,
	})
	Text.new(card, "Title", {
		Text = "The Victorian Quarter",
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 18, 1, -46),
		Size = UDim2.fromOffset(WIDTH - 36, 34),
		TextSize = 28,
	})

	header(frame, "Rules", 2).Text = "    RULES"
	local self = setmetatable({ Frame = frame, Rule = "Standard", _rows = {} }, DuskBattle)
	for i, rule in RULES do
		local row = ListRow.new(frame, rule.Label, function()
			self:_pick(rule.Id)
		end, WIDTH)
		row.Button.LayoutOrder = 2 + i
		row:SetSub(rule.Sub)
		self._rows[rule.Id] = row
	end
	header(frame, "Gathering", 6).Text = "    GATHERING"
	ListRow.new(frame, "Join with a code", function()
		self:_status("Private gatherings open with the Victorian quarter.")
	end, WIDTH).Button.LayoutOrder = 7
	ListRow.new(frame, "Party", function()
		self:_status("Parties open with the Victorian quarter.")
	end, WIDTH).Button.LayoutOrder = 8

	local status = Text.new(frame, "Body", {
		Name = "Status",
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
		Size = UDim2.fromOffset(WIDTH, 60),
		TextColor3 = Theme.Colors.TextMuted,
		LayoutOrder = 20,
	})
	self._statusLabel = status
	self:_pick("Standard")
	self.Hints = { { "Enter", "Begin matchmaking" }, { "Q E", "Change tab" }, { "Backspace", "Leave the table" } }
	return (self :: any) :: Screen
end

function DuskBattle._pick(self: any, id: string)
	self.Rule = id
	for ruleId, row in self._rows do
		row:SetSelected(ruleId == id)
	end
end

function DuskBattle._status(self: any, text: string)
	self._statusLabel.Text = text
end

function DuskBattle.Begin(self: any)
	local player = Players.LocalPlayer
	local class = Registry.Class(player:GetAttribute(PlayerState.Attr.Class))
	self:_status(`{class.DisplayName} waits at the Blood Table… The Victorian quarter isn't open yet.`)
end

return DuskBattle
