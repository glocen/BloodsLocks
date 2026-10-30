--!strict
-- Original locally drawn cube sky. Cooler continuous values replace the black/purple cloud bands.
local S={}
local IDS={Rt="rbxassetid://89959770244590",Dn="rbxassetid://77386947776324",Up="rbxassetid://72842733983291",Lf="rbxassetid://133084599268997",Ft="rbxassetid://85856954623312",Bk="rbxassetid://138065317024554"}
function S.Apply(_root:Instance)
 local l=game.Lighting;local sky=l:FindFirstChildOfClass("Sky");assert(sky,"Owner sky stack required")
 for face,id in IDS do sky["Skybox"..face]=id end
 sky.MoonAngularSize=0;sky.SunAngularSize=0;sky.StarCount=0
 return "Original cool dusk / crimson moon"
end
return S
