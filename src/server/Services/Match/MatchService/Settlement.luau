--!strict
-- Settlement (MatchService): what each entrant earned, paid once. The rewards formula is Shared.Match.Rewards (rule
-- data); payment goes through the owner's data layer (PlayerHandlerData.SettleMatch, which refuses a second payment
-- for the same match id). Culled entrants are paid by their placement; anyone leaving before that gets
-- participation only (D9). A player who disconnects is settled inside ProfileStore's OnLastSave, so the payment is
-- in the profile's final save (no race with DataInit ending the session).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.Shared
local Rewards = require(Shared.Match.Rewards)
local Log = require(Shared.Util.Log)
local PlayerHandlerData = require(ServerScriptService.Data.PlayerHandlerData)
local Core = script.Parent.Parent.Parent.Core
local ScoreService = require(Core.ScoreService)

export type Line = {
	Id: number,
	Name: string,
	Ai: boolean,
	Placement: number, -- 0: left before being placed
	Score: number,
	Kills: number,
	Deaths: number,
	Bloodgems: number,
}

local Settlement = {}

local hooked: { [Player]: boolean } = {}

-- One entrant's result line from their participant record.
function Settlement.Line(rule: any, record: any): Line
	local left = record.Left and record.Placement == 0
	local outcome = { Placement = record.Placement, Score = ScoreService.Total(record.Id), PlayerKills = record.Kills, Left = left }
	return {
		Id = record.Id,
		Name = record.Name,
		Ai = record.Ai,
		Placement = record.Placement,
		Score = outcome.Score,
		Kills = record.Kills,
		Deaths = record.Deaths,
		Bloodgems = Rewards.Bloodgems(rule, outcome),
	}
end

-- Pays a player's line (true if this call paid; false if already paid or the profile is gone).
function Settlement.Pay(player: Player, matchId: string, line: Line): boolean
	local stats = {
		Matches = 1,
		Wins = if line.Placement == 1 then 1 else 0,
		Finals = if line.Placement >= 1 and line.Placement <= 3 then 1 else 0,
		PlayerKills = line.Kills,
		Deaths = line.Deaths,
		VirtueEarned = line.Score,
	}
	local paid = PlayerHandlerData.SettleMatch(player, matchId, line.Bloodgems, stats)
	if paid then
		Log.Info("Settlement", `{player.Name}: {line.Bloodgems} Bloodgems for placement {line.Placement} (match {matchId})`)
	end
	return paid
end

-- Settles `player` in their profile's last save if the match hasn't paid them by then (they left early).
-- `lineFor()` builds their line at that moment.
function Settlement.OnLeave(player: Player, matchId: string, lineFor: () -> Line?)
	if hooked[player] then
		return
	end
	local profile = PlayerHandlerData.Profiles[player]
	if not profile then
		return
	end
	hooked[player] = true
	profile.OnLastSave:Connect(function()
		local ok, err = pcall(function()
			local line = lineFor()
			if line then
				Settlement.Pay(player, matchId, line)
			end
		end)
		if not ok then
			Log.Warn("Settlement", `settling {player.Name} on leave failed: {err}`)
		end
	end)
	Players.PlayerRemoving:Connect(function(leaving)
		if leaving == player then
			hooked[player] = nil
		end
	end)
end

return Settlement
