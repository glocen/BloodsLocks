--!strict
-- PlaceRole: which kind of place this server or client is running in. Each place sets the Workspace attribute
-- "PlaceRole" to one of Config.Game.PlaceRoles; boot picks role-specific services and controllers from it, and
-- rules that differ between the Manor (hub) and a match read IsManor / IsMatch. Read once: a place never changes role.

local GameConfig = require(script.Parent.Parent.Config.Game)

local current: string = workspace:GetAttribute("PlaceRole") or GameConfig.DefaultPlaceRole

return {
	Current = current,
	IsManor = current == GameConfig.PlaceRoles.Manor,
	IsMatch = current == GameConfig.PlaceRoles.Match,
}
