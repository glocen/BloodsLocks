--!strict
-- Bloodsworn (Blood Table tab 2): class selection, Duskbloods-style: a row of tall portrait cards with name plates.
-- Playable classes show a live render of your character; the rest are sealed until they arrive. Picking one saves
-- it (SelectClass → ClassService → the owner's ProfileStore).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local PlayerState = require(Shared.Simulation.PlayerState)
local Net = require(Shared.Net)
local Theme = require(script.Parent.Parent.Theme)
local Motion = require(script.Parent.Parent.Core.Motion)
local Text = require(script.Parent.Parent.Kit.Text)

local CARD_W, CARD_H, GAP = 230, 500, 18
local SLOTS = 6 -- Duskbloods-like roster width; sealed cards fill the rest
local PLAYABLE = { "Gustave" }

export type Screen = { Frame: Frame, Begin: (self: Screen) -> (), Hints: { { string } } }

local Bloodsworn = {}
Bloodsworn.__index = Bloodsworn

-- A figure rendered in a viewport on the card: your own character for playable classes, a black silhouette for
-- sealed ones.
local function portrait(card: GuiObject, source: Model?, silhouette: boolean): ViewportFrame?
	if not source then
		return nil
	end
	local existing = card:FindFirstChild("Portrait")
	if existing then
		existing:Destroy()
	end
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Portrait"
	viewport.Position = UDim2.fromOffset(0, 46)
	viewport.Size = UDim2.new(1, 0, 0, CARD_H - 150)
	viewport.BackgroundTransparency = 1
	viewport.Ambient = Theme.Portrait.Ambient
	viewport.LightColor = Theme.Portrait.Light
	viewport.LightDirection = Vector3.new(-1, -1, -1)
	viewport.Parent = card
	local wasArchivable = source.Archivable
	source.Archivable = true
	local clone = source:Clone()
	source.Archivable = wasArchivable
	for _, d in clone:GetDescendants() do
		if d:IsA("BaseScript") or d:IsA("Highlight") then
			d:Destroy()
		elseif silhouette and d:IsA("BasePart") then
			d.Color = Theme.Portrait.Silhouette
			d.Material = Enum.Material.SmoothPlastic
		elseif silhouette and (d:IsA("Decal") or d:IsA("Shirt") or d:IsA("Pants")) then
			d:Destroy()
		end
	end
	if silhouette then
		viewport.Ambient = Theme.Portrait.SealedAmbient
		viewport.LightColor = Theme.Portrait.SealedLight
		viewport.ImageTransparency = 0.15
	end
	clone.Parent = viewport
	local root = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		clone:PivotTo(CFrame.new(0, 0, 0))
	end
	local camera = Instance.new("Camera")
	camera.FieldOfView = 30
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0.6, -17), Vector3.new(0, 0.1, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera
	return viewport
end

function Bloodsworn.new(parent: Instance): Screen
	-- full-screen: the world dims behind the roster
	local frame = Instance.new("Frame")
	frame.Name = "Bloodsworn"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.Palette.Ink
	frame.BackgroundTransparency = 0.25
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local roster = Instance.new("Frame")
	roster.Name = "Roster"
	roster.AnchorPoint = Vector2.new(0.5, 0.5)
	roster.Position = UDim2.fromScale(0.5, 0.53)
	roster.Size = UDim2.fromOffset(SLOTS * CARD_W + (SLOTS - 1) * GAP, CARD_H)
	roster.BackgroundTransparency = 1
	roster.Parent = frame
	local self = setmetatable({ Frame = frame, _cards = {} }, Bloodsworn)

	for slot = 1, SLOTS do
		local classId = PLAYABLE[slot]
		local class = classId and Registry.Class(classId)
		local card = Instance.new("TextButton")
		card.Name = class and class.Id or "Sealed"
		card.AutoButtonColor = false
		card.Text = ""
		card.Position = UDim2.fromOffset((slot - 1) * (CARD_W + GAP), 0)
		card.Size = UDim2.fromOffset(CARD_W, CARD_H)
		card.BackgroundColor3 = Theme.Palette.InkSoft
		card.BackgroundTransparency = 0.15
		card.BorderSizePixel = 0
		card.Parent = roster
		local shade = Instance.new("UIGradient")
		shade.Rotation = 90
		shade.Color = ColorSequence.new(Theme.Portrait.CardShade, Theme.Palette.Ink)
		shade.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = Theme.Colors.Stroke
		stroke.Transparency = 0.35
		stroke.Parent = card
		-- name plate
		local plate = Instance.new("Frame")
		plate.Size = UDim2.new(1, 0, 0, 40)
		plate.BackgroundColor3 = Theme.Palette.Ink
		plate.BackgroundTransparency = 0.2
		plate.BorderSizePixel = 0
		plate.Parent = card
		local name = Text.new(plate, "Title", {
			Text = if class then class.DisplayName else "Sealed",
			Size = UDim2.fromScale(1, 1),
			TextSize = 22,
			TextColor3 = if class then Theme.Colors.Text else Theme.Colors.TextMuted,
		})
		if not class then
			portrait(card, Shared.Assets:FindFirstChild("TrainingDummy") :: Model?, true)
		end
		Text.new(card, "Body", {
			Text = if class then class.Title or "" else "Not yet awakened",
			Position = UDim2.new(0, 0, 1, -96),
			Size = UDim2.new(1, 0, 0, 22),
			TextColor3 = Theme.Colors.TextMuted,
		})
		local chosen = Text.new(card, "Caption", {
			Name = "Chosen",
			Text = "",
			Position = UDim2.new(0, 0, 1, -58),
			Size = UDim2.new(1, 0, 0, 22),
			TextColor3 = Theme.Colors.Hairline,
		})
		card.MouseEnter:Connect(function()
			if class then
				Motion.To(stroke, { Transparency = 0, Color = Theme.Colors.Focus }, "Fast")
			end
		end)
		card.MouseLeave:Connect(function()
			self:_refresh()
		end)
		card.Activated:Connect(function()
			if class then
				Net.Client.Fire("SelectClass", class.Id)
			end
		end)
		self._cards[slot] = { Id = classId, Stroke = stroke, Chosen = chosen, Name = name, Card = card }
	end
	Players.LocalPlayer:GetAttributeChangedSignal(PlayerState.Attr.Class):Connect(function()
		self:_refresh()
	end)
	self:_refresh()
	self.Hints = { { "Click", "Choose" }, { "Q E", "Change tab" }, { "Backspace", "Leave the table" } }
	return (self :: any) :: Screen
end

function Bloodsworn._refresh(self: any)
	local current = Players.LocalPlayer:GetAttribute(PlayerState.Attr.Class) or Registry.DefaultClass
	for _, card in self._cards do
		local picked = card.Id ~= nil and card.Id == current
		Motion.To(card.Stroke, { Transparency = if picked then 0 else 0.35, Color = if picked then Theme.Colors.Hairline else Theme.Colors.Stroke }, "Fast")
		card.Chosen.Text = if picked then "— SWORN —" else ""
	end
end

function Bloodsworn.Begin(_self: any) end

-- Called when the tab is shown: renders playable portraits from your current character.
function Bloodsworn.Shown(self: any)
	for _, card in self._cards do
		if card.Id then
			portrait(card.Card, Players.LocalPlayer.Character, false)
		end
	end
end

return Bloodsworn
