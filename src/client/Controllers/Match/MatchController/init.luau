--!strict
-- MatchController (match places): turns the replicated match state into the match screens. Each frame it reads one
-- Snapshot and hands every screen its view (the *View modules beside this one build them):
--   the Clock (HUD, with the region you're in) and the objectives (HUD, left);
--   the Antechamber screen (Waiting, Countdown: your hunter on stage under the full menu);
--   the Intro; the intermission (where to begin a phase, where to rise after a death, or the map on demand: MAP_KEY
--   during a phase); the death band; banners (phase arrivals, the final, entering a region).
-- Screens that take the input go through Focus, so leaving them always gives control back. Choices go to the server
-- (ChooseRegion), which validates them. Once the Antechamber's art is finished (Dressed), STEP_OUT_KEY steps out into
-- the room and back. The loading screen (Passage) lifts after the first frame is drawn.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local Tips = require(Shared.Definitions.Tips)
local MatchState = require(Shared.Match.MatchState)
local Net = require(Shared.Net)
local Parts = require(Shared.Util.Parts)
local Numerals = require(Shared.Util.Numerals)
local PlaceRole = require(Shared.Util.PlaceRole)
local GameConfig = require(Shared.Config.Game)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Focus = require(UI.Core.Focus)
local Stage = require(UI.Core.Stage)
local Clock = require(UI.Match.Clock)
local Banner = require(UI.Match.Banner)
local Antechamber = require(UI.Match.Antechamber)
local Intro = require(UI.Match.Intro)
local Intermission = require(UI.Match.Intermission)
local DeathBand = require(UI.Match.DeathBand)
local ObjectivesHud = require(UI.Hud.Objectives)
local Passage = require(ReplicatedFirst:WaitForChild("BL_First"):WaitForChild("Passage"))
local Snapshot = require(script.Snapshot)
local AntechamberView = require(script.AntechamberView)
local IntermissionView = require(script.IntermissionView)
local ObjectivesView = require(script.ObjectivesView)
local Budget = require(script.Parent.Parent.Parent.Util.Budget) -- times the per-frame update (self-test: Frame budget)

local S = MatchState.States
local PASSAGE_HOLD = "Match" -- the loading screen stays until the match's first state is on screen
local URGENT = 10 -- seconds left that turn the clock red
local REGION_REPEAT = 6 -- seconds before the same region's banner may show again
local STEP_OUT_KEY = Enum.KeyCode.P -- the Antechamber: step out into the room and back (only once it's dressed)
local MAP_KEY = Enum.KeyCode.M -- the map during a phase
local DEATH_HOLD = 1.6 -- seconds the death band holds before the map opens to choose where to rise
local FALLEN = "You fell"
local VIEW_RATE = 10 -- full-screen view rebuilds per second
local CALM = { Cursor = true, Gameplay = false, Hud = false } -- a full screen that takes the input

local MatchController = {}

local player = Players.LocalPlayer

function MatchController.Init()
	Passage.Hold(PASSAGE_HOLD)
end

function MatchController.Start()
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, 30)
	if not root then
		Passage.Release(PASSAGE_HOLD)
		return
	end
	local participants = root:WaitForChild(MatchState.ParticipantsName)
	root:WaitForChild(MatchState.RegionsName, 15) -- published by the server's Atlas at boot
	root:WaitForChild(MatchState.ReliefName, 15)
	local map = Registry.MapForPlace(game.PlaceId)
	local regions = Snapshot.Regions(root)

	local clock = Clock.new(Layers.Get("HUD"))
	local objectives = ObjectivesHud.new(Layers.Get("HUD"))
	local antechamber = Antechamber.new(Layers.Get("Menus"))
	antechamber:SetTips(Tips.For(PlaceRole.Current, Registry.Rule(root:GetAttribute(MatchState.Match.Rule)) or Registry.DefaultRuleDef()))
	local banner = Banner.new(Layers.Get("Overlay"))
	local deathBand = DeathBand.new(Layers.Get("Overlay"))
	local intro = Intro.new(Layers.Get("Transition"))
	local intermission = Intermission.new(Layers.Get("Menus"))
	intermission:Build(regions, root:FindFirstChild(MatchState.ReliefName) :: Model?)

	local chosen: string? = nil
	intermission:Chose(function(id)
		chosen = id
		Net.Client.Fire("ChooseRegion", id)
	end)

	local lastState, lastPhase = "", -1
	local releaseIntro: (() -> ())? = nil
	local currentRegion: string? = nil
	local regionShownAt: { [string]: number } = {}
	local sinceRegionCheck = 0
	local presented = false

	-- the Antechamber screen: Focus while it's up, your hunter on stage behind it (a velvet backdrop until the room
	-- is dressed). Closing into the Intro waits for the Intro's black to cover the stage before the camera returns.
	local releaseAntechamber: (() -> ())? = nil
	local stage: Stage.Handle? = nil
	local steppedOut = false
	local function endStage()
		local handle = stage
		stage = nil
		if handle then
			handle:End()
		end
	end
	local function setAntechamber(open: boolean, dressed: boolean, intoIntro: boolean?)
		if open then
			if not releaseAntechamber then
				releaseAntechamber = Focus.Push("Antechamber", CALM)
				antechamber.Frame.Visible = true
			end
			if not stage and player.Character then -- (the character may arrive a moment after the screen)
				stage = Stage.Begin({ Backdrop = not dressed })
			end
		elseif releaseAntechamber then
			releaseAntechamber()
			releaseAntechamber = nil
			if intoIntro then
				task.delay(Theme.Motion.Slow, function()
					antechamber.Frame.Visible = false
					endStage()
				end)
			else
				antechamber.Frame.Visible = false
				endStage()
			end
		end
	end

	-- the intermission: one screen, three modes (IntermissionView)
	local releaseMap: (() -> ())? = nil
	local mapMode: IntermissionView.Mode? = nil
	local browsing = false
	local function setIntermission(mode: IntermissionView.Mode?)
		if mode == mapMode then
			return
		end
		if mode and not releaseMap then
			releaseMap = Focus.Push("Intermission", CALM)
			intermission.Frame.Visible = true
		elseif not mode and releaseMap then
			releaseMap()
			releaseMap = nil
			intermission.Frame.Visible = false
		end
		if mode == "Choose" or mode == "Rise" then
			chosen = nil -- every choice starts fresh
		end
		mapMode = mode
	end

	-- falling: the band over the world, input paused, then the map to choose where to rise
	local wasAlive = true
	local diedAt: number? = nil
	local releaseFallen: (() -> ())? = nil
	local function setFallen(fallen: boolean)
		if fallen and not releaseFallen then
			releaseFallen = Focus.Push("Fallen", { Cursor = false, Gameplay = false, Hud = false })
			deathBand:Show(FALLEN)
		elseif not fallen and releaseFallen then
			releaseFallen()
			releaseFallen = nil
			deathBand:Hide()
		end
	end

	UserInputService.InputBegan:Connect(function(input)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		local state = root:GetAttribute(MatchState.Match.State)
		if input.KeyCode == STEP_OUT_KEY and root:GetAttribute(MatchState.Match.Dressed) == true and (state == S.Waiting or state == S.Countdown) then
			steppedOut = not steppedOut
		elseif input.KeyCode == MAP_KEY and state == S.Phase then
			browsing = not browsing
		end
	end)

	local function onTransition(s: Snapshot.Snapshot)
		if s.State == S.Intro and not releaseIntro then
			releaseIntro = Focus.Push("Intro", { Cursor = false, Gameplay = false, Hud = false })
			local list = {}
			for _, e in s.Field do
				table.insert(list, { Name = e.Name, Class = e.Class, Ai = e.Ai, You = e.Id == player.UserId })
			end
			intro:Play({ World = if map then map.DisplayName else "", Rule = s.Rule.DisplayName, Field = list })
		elseif s.State ~= S.Intro and releaseIntro then
			releaseIntro()
			releaseIntro = nil
			intro:Hide()
		end
		if s.State ~= S.Phase then
			browsing = false
		end
		if s.State == S.Phase then
			local region = s.Me and s.Me.Region or nil
			local name: string? = nil
			for _, r in regions do
				if r.Id == region then
					name = r.Name
				end
			end
			-- a full region sent you elsewhere: say so where you arrive
			local subtitle = if s.Me and s.Me.Moved and name then `{name} · your region was full` else name
			banner:Show(`Phase {Numerals.Roman(s.Phase)}`, subtitle)
			if region then
				currentRegion = region
				regionShownAt[region] = time()
			end
		elseif s.State == S.Final then
			banner:Show("The Final", `{s.Rule.Final.Lives} lives each. The last hunter standing wins.`, 3)
		elseif s.State == S.Results then
			banner:Show("The hunt is over", nil, 3)
		end
	end

	-- the full screens' words and lists change a few times a second at most: they're rebuilt VIEW_RATE times a second
	-- (and at once on any transition); the clock's ring and the deaths' timing still run every frame
	local sinceViews = math.huge
	RunService.RenderStepped:Connect(Budget.Wrap("Match", function(dt)
		local s = Snapshot.Read(root, participants, regions)
		local me = s.Me
		local body = Parts.Root(player.Character)

		local transition = s.State ~= lastState or s.Phase ~= lastPhase
		if transition then
			lastState, lastPhase = s.State, s.Phase
			onTransition(s)
		end
		sinceViews += dt
		local rebuild = transition or sinceViews >= 1 / VIEW_RATE
		if rebuild then
			sinceViews = 0
		end

		-- the region you're in (the clock's area line, and a banner when you enter a new one)
		sinceRegionCheck += dt
		if s.State == S.Phase and body and sinceRegionCheck >= 0.25 then
			sinceRegionCheck = 0
			local here = Snapshot.RegionAt(regions, body.Position)
			if here and here.Id ~= currentRegion then
				currentRegion = here.Id
				if s.Now - (regionShownAt[here.Id] or -math.huge) >= REGION_REPEAT then
					regionShownAt[here.Id] = s.Now
					banner:Show(here.Name, if map and map.Zones[here.Id] then map.Zones[here.Id].District else nil)
				end
			end
		end
		local areaName: string? = nil
		for _, region in regions do
			if region.Id == currentRegion and (s.State == S.Phase or s.State == S.PhaseResolve) then
				areaName = region.Name
			end
		end

		-- the clock
		if s.State == S.Idle then
			clock:Update(nil)
		else
			local span = math.max(0.001, s.Deadline - s.StartedAt)
			local phaseDef = s.Rule.Phases[s.Phase]
			local line = ({
				[S.Waiting] = "Waiting for hunters",
				[S.Countdown] = `The hunt begins · {Snapshot.Clock(s.Left)}`,
				[S.Intro] = "The hunt begins",
				[S.RegionChoice] = `Choose a region · {Snapshot.Clock(s.Left)}`,
				[S.Phase] = `Phase {Numerals.Roman(s.Phase)} · {Snapshot.Clock(s.Left)}`,
				[S.PhaseResolve] = `Phase {Numerals.Roman(s.Phase)} ends`,
				[S.FinalSetup] = "The final",
				[S.Final] = if s.SuddenDeath then "Sudden death" else `Final · {Snapshot.Clock(s.Left)}`,
				[S.Results] = "The hunt is over",
				[S.Return] = `Returning to {GameConfig.HubName}`,
			})[s.State] or s.State
			clock:Update({
				Numeral = if s.State == S.Final or s.State == S.FinalSetup then Numerals.Roman(#s.Rule.Phases + 1) elseif s.Phase > 0 then Numerals.Roman(s.Phase) else "◆",
				Line = line,
				Area = areaName,
				Progress = if s.Deadline > 0 then math.clamp((s.Now - s.StartedAt) / span, 0, 1) else 0,
				Urgent = s.Deadline > 0 and s.Left <= URGENT,
				Ritual = if s.State == S.Phase and phaseDef and phaseDef.Ritual then s.Rule.Ritual.ActivateAt else nil,
			})
		end

		-- the Antechamber screen
		local gathering = s.State == S.Waiting or s.State == S.Countdown
		if not gathering then
			steppedOut = false
		end
		if gathering and not steppedOut then
			setAntechamber(true, s.Dressed)
			if rebuild then
				antechamber:Update(AntechamberView.Build(s, map, STEP_OUT_KEY.Name))
			end
		else
			setAntechamber(false, s.Dressed, s.State == S.Intro)
		end

		-- falling during a phase: the band first, then the map
		local alive = me ~= nil and me.Alive
		if s.State == S.Phase and wasAlive and me and not alive and me.Eligible then
			diedAt = s.Now
		end
		if alive or s.State ~= S.Phase then
			diedAt = nil
		end
		wasAlive = alive
		local riseReady = diedAt ~= nil and s.Now - diedAt >= DEATH_HOLD
		setFallen(diedAt ~= nil and not riseReady)

		-- the intermission
		local mode = IntermissionView.ModeFor(s, browsing, riseReady)
		if mode ~= "Browse" then
			browsing = false -- a death or a state change closes the map you opened
		end
		local opened = mode ~= mapMode
		setIntermission(mode)
		if mode and (rebuild or opened) then
			local you: Vector3? = nil
			if mode == "Rise" and me then
				you = me.FellAt
			elseif body then
				you = body.Position
			end
			if you and not Snapshot.RegionAt(regions, you) then
				you = nil -- outside the district (the Antechamber): no mark
			end
			intermission:Update(IntermissionView.Build(s, mode, chosen, you, map))
		end

		-- the checklist
		if rebuild or opened then
			objectives:Set(if mode == nil then ObjectivesView.Build(s) else nil)
		end

		-- the first frame is on screen: the loading screen can lift
		if not presented then
			presented = true
			Passage.Release(PASSAGE_HOLD)
		end
	end))
end

return MatchController
