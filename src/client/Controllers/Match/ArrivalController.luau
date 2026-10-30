--!strict
-- ArrivalController (match places): what an arrival and a fall look like. When an entrant's body appears in a phase or
-- the final (their participant bag turns Alive), the dark-red mist reveal plays at their feet (Vfx/Arrival); when it's
-- you, the camera swings behind you, facing the way you were placed. When an entrant falls, their body breaks into the
-- same mist and fades away (a fallen hunter never just stands there; no gore). While an entrant is protected
-- (ProtectedUntil: it ends early the moment they attack), their body carries a cool outline, so everyone can read who
-- can't be hurt yet; it fades when the protection ends.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local MatchState = require(Shared.Match.MatchState)
local EntityState = require(Shared.Simulation.EntityState)
local Parts = require(Shared.Util.Parts)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Motion = require(UI.Core.Motion)
local Arrival = require(script.Parent.Parent.Parent.Vfx.Arrival)
local Kit = require(script.Parent.Parent.Parent.Vfx.Kit)
local CameraController = require(script.Parent.Parent.Core.CameraController)

local S = MatchState.States
local PA = MatchState.Participant
local A = EntityState.Attr
local OUTLINE = Theme.Colors.Accent -- cool: "not yet"; it never reads as damage or danger
local LIVE = { [S.Phase] = true, [S.Final] = true }
local CHECK_EVERY = 0.1 -- seconds
local FALL_FADE = 0.6 -- seconds a fallen body takes to fade into its mist

local ArrivalController = {}

local player = Players.LocalPlayer

-- The body a participant moves in: a player's character, or an AI hunter's body (it fights for their id).
local function bodyOf(id: number): Model?
	if id > 0 then
		local who = Players:GetPlayerByUserId(id)
		return who and who.Character
	end
	local folder = workspace:FindFirstChild(MatchState.HuntersFolder)
	for _, model in if folder then folder:GetChildren() else {} do
		if model:IsA("Model") and model:GetAttribute(A.OwnerId) == id then
			return model
		end
	end
	return nil
end

function ArrivalController.Start()
	local root = ReplicatedStorage:WaitForChild(MatchState.FolderName, 30)
	if not root then
		return
	end
	local participants = root:WaitForChild(MatchState.ParticipantsName)
	local alive: { [number]: boolean } = {}
	local outlines: { [number]: Highlight } = {}
	local since = 0

	local function arrive(id: number)
		-- the body may land a moment after the bag says Alive
		task.spawn(function()
			local deadline = os.clock() + 2
			local body = bodyOf(id)
			while (not body or not Parts.Root(body)) and os.clock() < deadline do
				task.wait()
				body = bodyOf(id)
			end
			local rootPart = Parts.Root(body)
			if body and rootPart then
				Arrival.Play(body)
				if id == player.UserId then
					CameraController.Face(rootPart.CFrame.LookVector)
				end
			end
		end)
	end

	-- the body breaks into mist and fades (only here: the server keeps it until the entrant rises elsewhere)
	local function fall(id: number)
		local body = bodyOf(id)
		if not body or not Parts.Root(body) then
			return
		end
		Arrival.Play(body)
		local pieces: { Instance } = {}
		for _, d in body:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				table.insert(pieces, d)
			end
		end
		Kit.Tween(FALL_FADE, function(alpha)
			for _, piece in pieces do
				(piece :: any).LocalTransparencyModifier = alpha
			end
		end)
	end

	RunService.Heartbeat:Connect(function(dt)
		since += dt
		if since < CHECK_EVERY then
			return
		end
		since = 0
		local state = root:GetAttribute(MatchState.Match.State)
		local now = time()
		for _, bag in participants:GetChildren() do
			local id = tonumber(bag.Name)
			if not id then
				continue
			end
			local isAlive = bag:GetAttribute(PA.Alive) == true
			if isAlive and not alive[id] and LIVE[state] then
				arrive(id)
			elseif not isAlive and alive[id] and LIVE[state] then
				fall(id)
			end
			alive[id] = isAlive
			-- the protection outline
			local protected = isAlive and LIVE[state] == true and (bag:GetAttribute(PA.ProtectedUntil) or 0) > now
			local outline = outlines[id]
			if protected and not outline then
				local body = bodyOf(id)
				if body then
					local created = Instance.new("Highlight")
					created.Name = "BL_Protected"
					created.FillTransparency = 1
					created.OutlineColor = OUTLINE
					created.OutlineTransparency = 1
					created.DepthMode = Enum.HighlightDepthMode.Occluded
					created.Adornee = body
					created.Parent = body
					Motion.To(created, { OutlineTransparency = 0.25 }, "Fast")
					outlines[id] = created
				end
			elseif not protected and outline then
				outlines[id] = nil
				Motion.To(outline, { OutlineTransparency = 1 }, "Slow").Completed:Connect(function()
					outline:Destroy()
				end)
			end
		end
	end)
end

return ArrivalController
