--!strict
-- HudController: the in-match HUD, laid out like Duskbloods' (docs/ui-research.md 2c) with our own art:
--   top-left Vitals (level + XP, HP with damage chip, stamina), the Shinigami card under it,
--   bottom-left Arsenal (SMG rounds, skill emblems with ring gauges), bottom-centre the stagger gauge, the crosshair.
-- Each section is its own module in Client.UI.Hud; this controller only gathers state each frame and hands it over.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local EntityState = require(Shared.Simulation.EntityState)
local PlayerState = require(Shared.Simulation.PlayerState)
local ActionSim = require(Shared.Simulation.ActionSim)
local Registry = require(Shared.Definitions.Registry)
local SHINIGAMI_KEY = "T"
local CombatConfig = require(Shared.Config.Combat)
local Zones = require(Shared.Util.Zones)
local UI = script.Parent.Parent.Parent.UI
local Theme = require(UI.Theme)
local Layers = require(UI.Core.Layers)
local Crosshair = require(UI.Components.Crosshair)
local Vitals = require(UI.Hud.Vitals)
local ShinigamiCard = require(UI.Hud.ShinigamiCard)
local Arsenal = require(UI.Hud.Arsenal)
local StaggerGauge = require(UI.Hud.StaggerGauge)
local LockOnController = require(script.Parent.LockOnController)

local A = EntityState.Attr
local P = PlayerState.Attr
local num = EntityState.Number

-- Emblem tint per icon name (skill definitions name their Icon from Theme.Images).
local ICON_TINT: { [string]: Color3 } = {
	BloodCrescent = Color3.new(1, 1, 1),
	Glint = Theme.Colors.Radiance,
}

local HudController = {}

local function skillStates(character: Model, class: any): { Arsenal.SkillState }
	local list = {}
	for slot, skillId in class.Skills or {} do
		local skill = Registry.Action(skillId)
		local attributes = EntityState.SkillSlots[slot]
		local charges = num(character, attributes.Charges, 0)
		local missing = if charges < skill.Charges then math.clamp((num(character, attributes.RechargeAt, 0) - time()) / skill.Recharge, 0, 1) else 0
		local icon = skill.Icon or "Glint"
		list[slot] = {
			Name = skill.DisplayName or skillId,
			Key = tostring(slot),
			Emblem = (Theme.Images :: any)[icon] or Theme.Images.Glint,
			EmblemColor = ICON_TINT[icon] or Theme.Colors.Text,
			Charges = charges,
			MaxCharges = skill.Charges,
			NextCharge = 1 - missing,
			LockedLevel = if ActionSim.SkillUnlocked(character, skill) then nil else skill.UnlockLevel,
		}
	end
	return list
end

function HudController.Start()
	local player = Players.LocalPlayer
	local layer = Layers.Get("HUD")
	local vitals = Vitals.new(layer)
	local shinigami = ShinigamiCard.new(layer)
	local arsenal = Arsenal.new(layer)
	local stagger = StaggerGauge.new(layer)
	local crosshair = Crosshair.new(layer)
	local sections = { vitals.Frame, shinigami.Frame, arsenal.Frame, stagger.Frame }

	RunService.RenderStepped:Connect(function(dt)
		local character = player.Character
		-- the combat HUD only exists where combat does (everywhere in matches; the training yard in the Manor)
		local ready = character ~= nil and character:GetAttribute(A.HPMax) ~= nil and Zones.ModelInCombat(character)
		for _, frame in sections do
			if frame ~= shinigami.Frame then
				frame.Visible = ready
			end
		end
		if not ready then
			shinigami.Frame.Visible = false
		end
		crosshair.Visible = ready
		crosshair.BackgroundTransparency = if LockOnController.GetTarget() then 0.6 else 0
		if not character or not ready then
			return
		end

		local stamina = num(character, A.Stamina, 0)
		vitals:Update({
			Level = num(character, A.Level, 1),
			Xp = 0, -- in-match experience arrives with Step 11
			Hp = num(character, A.HP, 0) / math.max(1, num(character, A.HPMax, 1)),
			Stamina = stamina / math.max(1, num(character, A.StaminaMax, 1)),
			StaminaEmpty = stamina <= 0,
		}, dt)
		local pactId = player:GetAttribute(P.ShinigamiId)
		local pactDef = Registry.Shinigami(pactId)
		if pactDef then
			local summoned = player:GetAttribute(P.ShinigamiOut) == true
			local cooldown = (player:GetAttribute(P.ShinigamiCooldown) or 0) - time()
			shinigami:Update({
				Name = pactDef.DisplayName,
				Level = player:GetAttribute(P.ShinigamiLevel) or 1,
				Hp = player:GetAttribute(P.ShinigamiHp) or 1,
				Summoned = summoned,
				Status = if summoned then nil elseif cooldown > 0 then `Returns in {math.ceil(cooldown)}s` else `[{SHINIGAMI_KEY}] Summon`,
			}, dt)
		else
			shinigami:Update(nil, dt)
		end

		local class = Registry.Class(character:GetAttribute(A.ClassId))
		local gun = class.Ranged and Registry.Weapon(class.Ranged)
		arsenal:Update({
			Rounds = num(character, A.Ammo, 0),
			Magazine = if gun then gun.Magazine else 0,
			Reloading = num(character, A.ReloadUntil, 0) > 0,
			Skills = skillStates(character, class),
		})
		stagger:Update(num(character, A.Stagger, 0) / CombatConfig.StaggerMax, dt)
	end)
end

return HudController
