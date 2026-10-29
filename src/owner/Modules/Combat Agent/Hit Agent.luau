local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local stundurationmodule = require(game.ReplicatedStorage.Modules.SharedModules.StunHandlerV2)
local HitAgent = {}

function HitAgent.hit(hittedhum:Humanoid,DAMAGE: number,STUNDURATION:number,KB,GB:boolean)
	
	local hittedcha = hittedhum.Parent
	local hittedhrp = hittedcha:FindFirstChild("HumanoidRootPart")
	local blocking = hittedcha:GetAttribute("IsBlocking")
	local iframecha = hittedcha:GetAttribute("IsIFrameMode")
	local parried = hittedcha:GetAttribute("Parried")
	
	if iframecha then local iframeeffect = Instance.new("Highlight",hittedcha)
		iframeeffect.OutlineColor = Color3.fromRGB(106, 37, 112)
		iframeeffect.OutlineTransparency = .3
		iframeeffect.FillTransparency =.5
		iframeeffect.FillColor = Color3.fromRGB(141, 63, 157)
		game.Debris:AddItem(iframeeffect,.3)
		
		return end
	
	if parried then
		hittedhum.Health += 30
	end
	
	if not GB and blocking then
		hittedhum:TakeDamage(DAMAGE/4.5) 
		return end
	if GB and blocking then
	   hittedcha:SetAttribute("IsBlocking",nil)
	   stundurationmodule.Stun(hittedhum, 5)
	end

	hittedhum:TakeDamage(DAMAGE)
	stundurationmodule.Stun(hittedhum,STUNDURATION)
	local highlight = Instance.new("Highlight",hittedcha)
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = .7
	highlight.FillTransparency = .6
	highlight.FillColor = Color3.fromRGB(255, 41, 45)
	game.Debris:AddItem(highlight,.45)
	if KB then
		local bv = Instance.new("BodyVelocity",hittedhrp)

		bv.MaxForce = Vector3.new(1,1,1) * math.huge
		bv.P = 1000
		bv.Velocity = KB
		
		bv.Parent = hittedhum.Parent:FindFirstChild("HumanoidRootPart")
		
		game.Debris:AddItem(bv,.15)
		
	end
	end

return HitAgent

