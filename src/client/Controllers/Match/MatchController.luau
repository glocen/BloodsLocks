--!strict
-- MatchController (match places): turns the replicated match state (ReplicatedStorage.MatchState) into the match
-- screens. Every frame it reads the state and deadline and feeds: the Clock (HUD), the Antechamber panel (Waiting,
-- Countdown), the Intro, the region map (RegionChoice, and revival while dead in a phase) and banners (phase
-- arrivals, the final, entering a region). Screens that take the input go through Focus, so leaving them always
-- gives control back. Choices go to the server (ChooseRegion), which validates them.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)
local Culling = require(Shared.Match.Culling)
local MatchConfig = require(Shared.Config.Match)
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local UI = script.Parent.Parent.Parent.UI
local Layers = require(UI.Core.Layers)
local Focus = require(UI.Core.Focus)
local Clock = require(UI.Match.Clock)
local Banner = require(UI.Match.Banner)
local Lobby = require(UI.Match.Lobby)
local Intro = require(UI.Match.Intro)
local RegionMap = require(UI.Match.RegionMap)

local S = MatchState.States
local M = MatchState.Match
local PA = MatchState.Participant
local R = MatchState.Region

local NUMERALS = { "I", "II", "III", "IV", "V" }
local URGENT = 10 -- seconds left that turn the clock red
local REGION_REPEAT = 6 -- seconds before the same region's banner may show again

local MatchController = {}

local player = Players.LocalPlayer

local function clockText(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

type Entrant = { Id: number, Name: string, Class: string, Ai: boolean, Eligible: boolean, Alive: boolean, Score: number, RevivalAt: number, Region: string }

local function entrants(folder: Instance): { Entrant }
	local list = {}
	for _, bag in folder:GetChildren() do
		local id = tonumber(bag.Name)
		if id then
			local classId = bag:GetAttribute(PA.Class)
			table.insert(list, {
				Id = id,
				Name = bag:GetAttribute(PA.Name) or "?",
				Class = Registry.Class(classId).DisplayName or tostring(classId),
				Ai = bag:GetAttribute(PA.Ai) == true,
				Eligible = bag:GetAttribute(PA.Eligible) == true,
				Alive = bag:GetAttribute(PA.Alive) == true,
				Score = bag:GetAttribute(PA.Score) or 0,
				RevivalAt = bag:GetAttribute(PA.RevivalAt) or 0,
				Region = bag:GetAttribute(PA.Region) or "",
			})
		end
	end
	return list
end

local function regionsOf(root: Instance): { RegionMap.Region }
	local list = {}
	local folder = root:FindFirstChild(MatchState.RegionsName)
	for _, region in if folder then folder:GetChildren() else {} do
		local boxes = {}
		for _, box in region:GetChildren() do
			table.insert(boxes, { Min = box:GetAttribute(R.Min), Max = box:GetAttribute(R.Max) })
		end
		table.insert(list, { Id = region.Name, Name = region:GetAttribute(R.DisplayName) or region.Name, Boxes = boxes })
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return list
end

local function regionAt(regions: { RegionMap.Region }, position: Vector3): RegionMap.Region?
	for _, region in regions do
		for _, box in region.Boxes do
			if position.X >= box.Min.X and position.X <= box.Max.X and position.Z >= box.Min.Z and position.Z <= box.Max.Z
				and position.Y >= box.Min.Y and position.Y <= box.Max.Y then
				return region
			end
		end
	end
	return nil
end

function MatchController.Start()
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, 30)
	if not root then
		return
	end
	local participants = root:WaitForChild(MatchState.ParticipantsName)
	root:WaitForChild(MatchState.RegionsName, 15) -- published by the server's Atlas at boot
	root:WaitForChild(MatchState.ReliefName, 15)
	local map = Registry.MapForPlace(game.PlaceId)
	local regions = regionsOf(root)
	local regionName: { [string]: string } = {}
	for _, region in regions do
		regionName[region.Id] = region.Name
	end

	local clock = Clock.new(Layers.Get("HUD"))
	local lobby = Lobby.new(Layers.Get("Overlay"))
	local banner = Banner.new(Layers.Get("Overlay"))
	local intro = Intro.new(Layers.Get("Transition"))
	local regionMap = RegionMap.new(Layers.Get("Menus"))
	regionMap:Build(regions, root:FindFirstChild(MatchState.ReliefName) :: Model?)

	local chosen: string? = nil
	regionMap:Chose(function(id)
		chosen = id
		Net.Client.Fire("ChooseRegion", id)
	end)

	local lastState, lastPhase = "", -1
	local releaseIntro: (() -> ())? = nil
	local releaseMap: (() -> ())? = nil
	local currentRegion: string? = nil
	local regionShownAt: { [string]: number } = {}
	local sinceRegionCheck = 0

	local function setMapOpen(open: boolean)
		if open and not releaseMap then
			chosen = nil
			releaseMap = Focus.Push("RegionMap", { Cursor = true, Gameplay = false, Hud = false })
			regionMap.Frame.Visible = true
		elseif not open and releaseMap then
			releaseMap()
			releaseMap = nil
			regionMap.Frame.Visible = false
		end
	end

	local function onTransition(state: string, phase: number, field: { Entrant })
		if state == S.Intro and not releaseIntro then
			releaseIntro = Focus.Push("Intro", { Cursor = false, Gameplay = false, Hud = false })
			local list = {}
			for _, e in field do
				table.insert(list, { Name = e.Name, Class = e.Class, Ai = e.Ai, You = e.Id == player.UserId })
			end
			intro:Play({ World = if map then map.DisplayName else "", Rule = (Registry.Rule(root:GetAttribute(M.Rule)) or {}).DisplayName or "", Field = list })
		elseif state ~= S.Intro and releaseIntro then
			releaseIntro()
			releaseIntro = nil
			intro:Hide()
		end
		if state == S.Phase then
			local me = participants:FindFirstChild(tostring(player.UserId))
			local region = me and me:GetAttribute(PA.Region)
			banner:Show(`Phase {NUMERALS[phase] or phase}`, region and regionName[region] or nil)
			if region then
				currentRegion = region
				regionShownAt[region] = time()
			end
		elseif state == S.Final then
			banner:Show("The Final", "Two lives each. The last hunter standing wins.", 3)
		elseif state == S.Results then
			banner:Show("The hunt is over", nil, 3)
		end
	end

	RunService.RenderStepped:Connect(function(dt)
		local state = root:GetAttribute(M.State) or S.Idle
		local phase = root:GetAttribute(M.Phase) or 0
		local deadline = root:GetAttribute(M.Deadline) or 0
		local startedAt = root:GetAttribute(M.StartedAt) or time()
		local rule = Registry.Rule(root:GetAttribute(M.Rule)) or Registry.Rule("Standard")
		local now = time()
		local left = if deadline > 0 then deadline - now else 0
		local field = entrants(participants)
		local me: Entrant? = nil
		for _, e in field do
			if e.Id == player.UserId then
				me = e
			end
		end

		if state ~= lastState or phase ~= lastPhase then
			lastState, lastPhase = state, phase
			onTransition(state, phase, field)
		end

		-- the clock
		if state == S.Idle then
			clock:Update(nil)
		else
			local span = math.max(0.001, deadline - startedAt)
			local phaseDef = rule.Phases[phase]
			local line = ({
				[S.Waiting] = "Waiting for hunters",
				[S.Countdown] = `The hunt begins · {clockText(left)}`,
				[S.Intro] = "The hunt begins",
				[S.RegionChoice] = `Choose a region · {clockText(left)}`,
				[S.Phase] = `Phase {NUMERALS[phase] or phase} · {clockText(left)}`,
				[S.PhaseResolve] = `Phase {NUMERALS[phase] or phase} ends`,
				[S.FinalSetup] = "The final",
				[S.Final] = if root:GetAttribute(M.SuddenDeath) then "Sudden death" else `Final · {clockText(left)}`,
				[S.Results] = "The hunt is over",
				[S.Return] = "Returning to the Manor",
			})[state] or state
			clock:Update({
				Numeral = if state == S.Final or state == S.FinalSetup then "IV" elseif phase > 0 then NUMERALS[phase] or tostring(phase) else "◆",
				Line = line,
				Progress = if deadline > 0 then math.clamp((now - startedAt) / span, 0, 1) else 0,
				Urgent = deadline > 0 and left <= URGENT,
				Ritual = if state == S.Phase and phaseDef and phaseDef.Ritual then rule.Ritual.ActivateAt else nil,
			})
		end

		-- the Antechamber panel
		if state == S.Waiting or state == S.Countdown then
			local players = 0
			local roster = {}
			for _, e in field do
				if not e.Ai then
					players += 1
				end
				table.insert(roster, { Name = e.Name, Class = e.Class, Ai = e.Ai })
			end
			local seats = MatchConfig.Lobby.MaxPlayers - #field
			lobby:Update({
				Map = if map then map.DisplayName else "",
				Rule = rule.DisplayName,
				Status = if state == S.Countdown then `The hunt begins in {clockText(left)}` else `Waiting for hunters  {players} / {MatchConfig.Lobby.MinPlayers}`,
				Note = if root:GetAttribute(M.Locked) then "Joins are closed."
					elseif seats > 0 then `{seats} seat{if seats == 1 then "" else "s"} left: AI hunters take them when the hunt begins.`
					else "Every seat is taken.",
				Roster = roster,
			})
		else
			lobby:Update(nil)
		end

		-- the region map: before a phase, and while dead in one
		local reviving = state == S.Phase and me ~= nil and me.Eligible and not me.Alive and me.RevivalAt > 0
		local choosing = state == S.RegionChoice and me ~= nil and me.Eligible
		setMapOpen(choosing or reviving)
		if choosing or reviving then
			local standings, eligible = {}, {}
			for _, e in field do
				if e.Eligible then
					table.insert(eligible, e)
				end
			end
			table.sort(eligible, function(a, b)
				return if a.Score ~= b.Score then a.Score > b.Score else a.Id < b.Id
			end)
			for _, e in eligible do
				table.insert(standings, { Name = e.Name, Score = e.Score, You = e.Id == player.UserId })
			end
			local cut = if table.find(rule.CullAfter, phase) then Culling.KeepCount(rule, phase, root:GetAttribute(M.Entrants) or #field, #eligible) else nil
			regionMap:Update({
				Heading = if reviving then "You fell" else `Phase {NUMERALS[phase] or phase}`,
				Subheading = if reviving then "Choose where to rise" else "Choose where to begin",
				Timer = clockText(if reviving and me then me.RevivalAt - now else left),
				Fallback = if reviving then "Without a choice you rise where you last stood."
					else "Without a choice you start in a random region with room. A full region sends you to another.",
				Chosen = chosen,
				Standings = standings,
				Cut = cut,
			})
		end

		-- entering a region during a phase: its name, once in a while
		sinceRegionCheck += dt
		if state == S.Phase and sinceRegionCheck >= 0.25 then
			sinceRegionCheck = 0
			local root3 = Parts.Root(player.Character)
			local here = root3 and regionAt(regions, root3.Position)
			if here and here.Id ~= currentRegion then
				currentRegion = here.Id
				if now - (regionShownAt[here.Id] or -math.huge) >= REGION_REPEAT then
					regionShownAt[here.Id] = now
					banner:Show(here.Name, if map then map.Zones[here.Id] and map.Zones[here.Id].District or nil else nil)
				end
			end
		end
	end)
end

return MatchController
