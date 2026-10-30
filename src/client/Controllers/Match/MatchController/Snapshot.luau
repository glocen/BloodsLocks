--!strict
-- Snapshot (MatchController): the replicated match state (ReplicatedStorage.MatchState) read into plain tables once
-- per frame, so every screen builds from the same picture: the state and its times, the rule, every entrant and you,
-- and the regions (built once: volumes and marks; live: how many chose each, how many each takes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Registry = require(Shared.Definitions.Registry)
local MatchState = require(Shared.Match.MatchState)

local M = MatchState.Match
local PA = MatchState.Participant
local R = MatchState.Region

export type Entrant = {
	Id: number,
	Name: string,
	Class: string,
	Ai: boolean,
	Eligible: boolean,
	Alive: boolean,
	Score: number,
	RevivalAt: number,
	Region: string,
	FellAt: Vector3,
	Moved: boolean,
	ProtectedUntil: number,
}
export type Feature = { Kind: string, Position: Vector3, Label: string, Count: number }
export type Box = { Min: Vector3, Max: Vector3 }
export type Region = { Id: string, Name: string, Boxes: { Box }, Features: { Feature }, Chosen: number, Capacity: number, Instance: Instance }
export type Snapshot = {
	State: string,
	Phase: number,
	Deadline: number,
	StartedAt: number,
	Now: number,
	Left: number, -- seconds to the deadline (0 without one)
	Rule: any,
	Entrants: number, -- seats filled when the countdown ended
	Locked: boolean,
	SuddenDeath: boolean,
	Dressed: boolean,
	Field: { Entrant },
	Me: Entrant?,
	Regions: { Region },
}

local Snapshot = {}

-- "m:ss"
function Snapshot.Clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	return string.format("%d:%02d", s // 60, s % 60)
end

-- The regions published by the server's Atlas, in a fixed order (their number keys follow it).
function Snapshot.Regions(root: Instance): { Region }
	local list = {}
	local folder = root:FindFirstChild(MatchState.RegionsName)
	for _, region in if folder then folder:GetChildren() else {} do
		local boxes, features = {}, {}
		for _, child in region:GetChildren() do
			if child.Name == MatchState.BoxName then
				table.insert(boxes, { Min = child:GetAttribute(R.Min), Max = child:GetAttribute(R.Max) })
			elseif child.Name == MatchState.FeatureName then
				table.insert(features, {
					Kind = child:GetAttribute(R.Kind) or "",
					Position = child:GetAttribute(R.Position) or Vector3.zero,
					Label = child:GetAttribute(R.Label) or "",
					Count = child:GetAttribute(R.Count) or 1,
				})
			end
		end
		table.insert(list, {
			Id = region.Name,
			Name = region:GetAttribute(R.DisplayName) or region.Name,
			Boxes = boxes,
			Features = features,
			Chosen = 0,
			Capacity = 0,
			Instance = region,
		})
	end
	table.sort(list, function(a, b)
		return a.Id < b.Id
	end)
	return list
end

-- The region whose volumes hold `position`, or nil.
function Snapshot.RegionAt(regions: { Region }, position: Vector3): Region?
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
				FellAt = bag:GetAttribute(PA.FellAt) or Vector3.zero,
				Moved = bag:GetAttribute(PA.Moved) == true,
				ProtectedUntil = bag:GetAttribute(PA.ProtectedUntil) or 0,
			})
		end
	end
	return list
end

function Snapshot.Read(root: Instance, participants: Instance, regions: { Region }): Snapshot
	local now = time()
	local deadline = root:GetAttribute(M.Deadline) or 0
	local field = entrants(participants)
	local me: Entrant? = nil
	for _, entrant in field do
		if entrant.Id == Players.LocalPlayer.UserId then
			me = entrant
		end
	end
	for _, region in regions do
		region.Chosen = region.Instance:GetAttribute(R.Chosen) or 0
		region.Capacity = region.Instance:GetAttribute(R.Capacity) or 0
	end
	return {
		State = root:GetAttribute(M.State) or MatchState.States.Idle,
		Phase = root:GetAttribute(M.Phase) or 0,
		Deadline = deadline,
		StartedAt = root:GetAttribute(M.StartedAt) or now,
		Now = now,
		Left = if deadline > 0 then deadline - now else 0,
		Rule = Registry.Rule(root:GetAttribute(M.Rule)) or Registry.DefaultRuleDef(),
		Entrants = root:GetAttribute(M.Entrants) or #field,
		Locked = root:GetAttribute(M.Locked) == true,
		SuddenDeath = root:GetAttribute(M.SuddenDeath) == true,
		Dressed = root:GetAttribute(M.Dressed) == true,
		Field = field,
		Me = me,
		Regions = regions,
	}
end

-- Eligible entrants by standing: more Renown first, then by id (the server's tie-break is first-to-reach; the
-- screens only need a stable order).
function Snapshot.Standing(field: { Entrant }): { Entrant }
	local list = {}
	for _, entrant in field do
		if entrant.Eligible then
			table.insert(list, entrant)
		end
	end
	table.sort(list, function(a, b)
		return if a.Score ~= b.Score then a.Score > b.Score else a.Id < b.Id
	end)
	return list
end

return Snapshot
