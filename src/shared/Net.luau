--!strict
-- Net: every RemoteEvent and RemoteFunction the game uses is declared in REMOTES below.
-- The server creates them under Shared.Remotes at boot; clients wait for them.
-- Server handlers are rate limited per player and wrapped in pcall, so spammed or malformed payloads
-- can't break anything. Handlers still check their own arguments: client data is untrusted.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Log = require(script.Parent.Util.Log)

type Kind = "Event" | "Unreliable" | "Function"
type Spec = {
	Kind: Kind,
	RatePerSecond: number, -- client-to-server calls allowed per second per player (bursts up to 2x)
}

local REMOTES: { [string]: Spec } = {
	ClientReady = { Kind = "Event", RatePerSecond = 1 }, -- client finished booting; arg: boot error count
	ShotFx = { Kind = "Unreliable", RatePerSecond = 0 }, -- server -> clients: (shooter, origin, hitPosition)
	ProjectileFx = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (id, visual, origin, direction, speed, range)
	ProjectileEnd = { Kind = "Event", RatePerSecond = 0 }, -- server -> clients: (id, position)
	ShinigamiToggle = { Kind = "Event", RatePerSecond = 2 }, -- client -> server: summon / dismiss your Shinigami
	SelectClass = { Kind = "Event", RatePerSecond = 2 }, -- client -> server: (classId) pick your Bloodsworn at the Blood Table
	DebugCommand = { Kind = "Function", RatePerSecond = 30 }, -- client -> server, answered only in Studio: (name, ...) runs a DebugService command (self-test)
}

local CLASS_FOR_KIND: { [Kind]: string } = {
	Event = "RemoteEvent",
	Unreliable = "UnreliableRemoteEvent",
	Function = "RemoteFunction",
}

local FOLDER_NAME = "Remotes"
local WAIT_TIMEOUT = 30
local DROP_WARN_INTERVAL = 10

local Net = {}
Net.Server = {}
Net.Client = {}

local folder: Folder? = nil
local cache: { [string]: any } = {}

local function spec(name: string): Spec
	local found = REMOTES[name]
	if not found then
		error(`Net: unknown remote "{name}" (declare it in Net's REMOTES table)`, 3)
	end
	return found
end

local function remote(name: string): any
	local found = cache[name]
	if found then
		return found
	end
	local remoteSpec = spec(name)
	if RunService:IsServer() then
		assert(folder, "Net.Server.Setup() must run before remotes are used")
		found = folder:FindFirstChild(name)
	else
		local remotes = script.Parent:WaitForChild(FOLDER_NAME, WAIT_TIMEOUT)
		assert(remotes, "Net: the Remotes folder never appeared")
		found = remotes:WaitForChild(name, WAIT_TIMEOUT)
	end
	assert(found and found.ClassName == CLASS_FOR_KIND[remoteSpec.Kind], `Net: remote "{name}" is missing or has the wrong class`)
	cache[name] = found
	return found
end

-- Rate limiting: one token bucket per player per remote.
type Bucket = { tokens: number, last: number, dropped: number, warnedAt: number }
local buckets: { [Player]: { [string]: Bucket } } = {}
local droppedTotal: { [string]: number } = {}

local function allow(player: Player, name: string): boolean
	local rate = REMOTES[name].RatePerSecond
	local perPlayer = buckets[player]
	if not perPlayer then
		perPlayer = {}
		buckets[player] = perPlayer
	end
	local now = os.clock()
	local bucket = perPlayer[name]
	if not bucket then
		bucket = { tokens = rate * 2, last = now, dropped = 0, warnedAt = -math.huge }
		perPlayer[name] = bucket
	end
	bucket.tokens = math.min(rate * 2, bucket.tokens + (now - bucket.last) * rate)
	bucket.last = now
	if bucket.tokens >= 1 then
		bucket.tokens -= 1
		return true
	end
	bucket.dropped += 1
	droppedTotal[name] = (droppedTotal[name] or 0) + 1
	if now - bucket.warnedAt >= DROP_WARN_INTERVAL then
		bucket.warnedAt = now
		Log.Warn("Net", `dropping "{name}" from {player.Name}: over {rate}/s ({bucket.dropped} dropped so far)`)
	end
	return false
end

local function guard(name: string, handler: (Player, ...any) -> ...any): (Player, ...any) -> ...any
	return function(player: Player, ...: any): ...any
		if not allow(player, name) then
			return nil
		end
		local results = table.pack(pcall(handler, player, ...))
		if not results[1] then
			Log.Warn("Net", `handler for "{name}" errored (player {player.Name}): {results[2]}`)
			return nil
		end
		return table.unpack(results, 2, results.n)
	end
end

-- Server --------------------------------------------------------------------------------------------

-- Creates every declared remote. The server Boot calls this once, before anything else.
function Net.Server.Setup()
	assert(RunService:IsServer(), "Net.Server.Setup is server-only")
	if folder then
		return
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = FOLDER_NAME
	for name, remoteSpec in REMOTES do
		local instance = Instance.new(CLASS_FOR_KIND[remoteSpec.Kind])
		instance.Name = name
		instance.Parent = newFolder
	end
	newFolder.Parent = script.Parent
	folder = newFolder

	Players.PlayerRemoving:Connect(function(player)
		buckets[player] = nil
	end)
end

function Net.Server.On(name: string, handler: (Player, ...any) -> ())
	assert(spec(name).Kind ~= "Function", `Net: "{name}" is a Function; use Net.Server.Handle`)
	remote(name).OnServerEvent:Connect(guard(name, handler))
end

function Net.Server.Handle(name: string, handler: (Player, ...any) -> ...any)
	assert(spec(name).Kind == "Function", `Net: "{name}" is not a Function`)
	remote(name).OnServerInvoke = guard(name, handler)
end

function Net.Server.Fire(name: string, player: Player, ...: any)
	remote(name):FireClient(player, ...)
end

function Net.Server.FireAll(name: string, ...: any)
	remote(name):FireAllClients(...)
end

function Net.Server.FireList(name: string, players: { Player }, ...: any)
	local instance = remote(name)
	for _, player in players do
		instance:FireClient(player, ...)
	end
end

-- How many calls the rate limiter dropped since the server started, by remote name.
function Net.Server.DroppedCounts(): { [string]: number }
	return table.clone(droppedTotal)
end

-- Client --------------------------------------------------------------------------------------------

function Net.Client.Fire(name: string, ...: any)
	remote(name):FireServer(...)
end

function Net.Client.On(name: string, handler: (...any) -> ())
	remote(name).OnClientEvent:Connect(handler)
end

function Net.Client.Invoke(name: string, ...: any): ...any
	return remote(name):InvokeServer(...)
end

return Net
