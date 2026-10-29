--!strict
-- DebugService: a Studio-only bridge that lets tools (the Studio MCP, the command bar) run checks inside
-- the game's own script context. Plugin and command-bar code get separate module instances, so they
-- can't see live game state any other way.
-- While playtesting, from the server side:  game.ServerStorage.BL_Debug:Invoke("Commands")
-- The bridge never exists on live servers.

local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Net = require(Shared.Net)
local Log = require(Shared.Util.Log)

local DebugService = {}

local commands: { [string]: (...any) -> ...any } = {}

-- Any service may register commands at any time (Init included); this only writes to a table.
function DebugService.Register(name: string, command: (...any) -> ...any)
	assert(commands[name] == nil, `debug command "{name}" registered twice`)
	commands[name] = command
end

function DebugService.Init()
	DebugService.Register("Ping", function()
		return "pong"
	end)
	DebugService.Register("Commands", function()
		local names = {}
		for name in commands do
			table.insert(names, name)
		end
		table.sort(names)
		return names
	end)
	DebugService.Register("NetDropped", function()
		return Net.Server.DroppedCounts()
	end)

	if not RunService:IsStudio() then
		return
	end
	local bridge = Instance.new("BindableFunction")
	bridge.Name = "BL_Debug"
	bridge.OnInvoke = function(name: any, ...: any)
		local command = commands[name]
		if not command then
			return false, `unknown debug command "{tostring(name)}"`
		end
		return pcall(command, ...)
	end
	bridge.Parent = ServerStorage
	Log.Info("DebugService", "Studio debug bridge ready (ServerStorage.BL_Debug)")
end

return DebugService
