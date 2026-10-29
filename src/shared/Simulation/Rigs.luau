--!strict
-- Rigs: the characters the simulation steps. The server steps every player's character; a client steps only
-- its own. Instances are looked up here, outside the simulation, because only Simulation Access members may
-- be used inside it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local EntityState = require(script.Parent.EntityState)
local Input = require(script.Parent.Input)

export type Rig = {
	Player: Player,
	Character: Model,
	Humanoid: Humanoid,
	Root: BasePart,
	Animator: Animator,
	Input: Input.Handles?, -- nil until the player's InputContext arrives
}

local Rigs = {}

local rigs: { [Player]: Rig } = {}
local handlesByPlayer: { [Player]: Input.Handles } = {}

local function track(player: Player)
	local function onCharacter(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local root = character:WaitForChild("HumanoidRootPart") :: BasePart
		local animator = humanoid:WaitForChild("Animator") :: Animator
		if player.Character == character then
			rigs[player] = {
				Player = player,
				Character = character,
				Humanoid = humanoid,
				Root = root,
				Animator = animator,
				Input = handlesByPlayer[player],
			}
		end
	end
	local function onContext(child: Instance)
		if child.Name ~= EntityState.InputContextName then
			return
		end
		local handles = Input.Bind(child)
		handlesByPlayer[player] = handles
		local rig = rigs[player]
		if rig then
			rig.Input = handles
		end
	end

	player.CharacterAdded:Connect(onCharacter)
	player.ChildAdded:Connect(onContext)
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	local context = player:FindFirstChild(EntityState.InputContextName)
	if context then
		task.spawn(onContext, context)
	end
end

function Rigs.Initialize()
	if RunService:IsServer() then
		Players.PlayerAdded:Connect(track)
		for _, player in Players:GetPlayers() do
			track(player)
		end
		Players.PlayerRemoving:Connect(function(player)
			rigs[player] = nil
			handlesByPlayer[player] = nil
		end)
	else
		track(Players.LocalPlayer)
	end
end

function Rigs.All(): { [Player]: Rig }
	return rigs
end

-- Client: the local player's rig.
function Rigs.Local(): Rig?
	return rigs[Players.LocalPlayer]
end

return Rigs
