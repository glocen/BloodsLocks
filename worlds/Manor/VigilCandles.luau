--!strict
-- Original Blender candle meshes: uneven melted lips, recessed pools, joined wax runs and charred wicks.
-- Applied after estate scaling, so human-scale wax details are not stretched with storey height.
-- Masters live outside workspace.Vigil and survive generator rebuilds. No gameplay code is changed.
local C={}
local kit=game.ServerStorage.WorldAssets.VigilKit.MeltedCandles
local function verticalExtent(p:BasePart):number
 local cf=p.CFrame;local s=p.Size
 return math.abs(cf.RightVector.Y)*s.X+math.abs(cf.UpVector.Y)*s.Y+math.abs(cf.ZVector.Y)*s.Z
end
function C.Apply(root:Instance):number
 if root:GetAttribute("CandleArtRevision")==1 then return 0 end
 assert(not game:GetService("RunService"):IsRunning(),"Candle art replacement is edit-time only")
 local originals={}
 for _,p in root.GreatHall:GetDescendants()do
  if p:IsA("BasePart") and (p.Name=="WaxCandle" or (p.Name=="Wax" and p.Parent.Name=="CandleBrackets"))then table.insert(originals,p) end
 end
 table.sort(originals,function(a,b)
  if math.abs(a.Position.Y-b.Position.Y)>.01 then return a.Position.Y<b.Position.Y end
  if math.abs(a.Position.X-b.Position.X)>.01 then return a.Position.X<b.Position.X end
  return a.Position.Z<b.Position.Z
 end)
 for index,p in originals do
  local label=({"Short","Medium","Tall"})[(index-1)%3+1]
  local master=kit[label];local model=master:Clone();model.Name="MeltedCandle_"..label
  local wax=assert(model:FindFirstChild("Vigil_Candle_"..label.."_Wax",true))::BasePart
  local oldHeight=verticalExtent(p)
  local factor=oldHeight/wax.Size.Y
  model:ScaleTo(model:GetScale()*factor)
  local y=p.Position.Y-oldHeight/2-.07*factor
  model:PivotTo(CFrame.new(p.Position.X,y,p.Position.Z)*CFrame.Angles(0,index*2.39996,0))
  -- A sconce already has a shared tray. Its individual drip catchers are omitted.
  if p.Name=="Wax" then local tray=model:FindFirstChild("Vigil_Candle_"..label.."_IronDripTray",true);if tray then tray:Destroy()end end
  local oldFlame:BasePart?=nil;local best=.15
  for _,v in p.Parent:GetChildren()do
   if v:IsA("BasePart")and(v.Name=="SmallFlame"or v.Name=="Flame")then
    local dx=v.Position.X-p.Position.X;local dz=v.Position.Z-p.Position.Z
    local d=math.sqrt(dx*dx+dz*dz)
    if d<best then best=d;oldFlame=v end
   end
  end
  local ember=model:FindFirstChild("Vigil_Candle_"..label.."_Ember",true)::BasePart
  local flame=Instance.new("Part");flame.Name="CandleFlame";flame.Shape=Enum.PartType.Ball
  flame.Size=Vector3.new(.085,.24,.085)*math.clamp(oldHeight,.7,1.4)
  flame.CFrame=CFrame.new(ember.Position+Vector3.new(.015,flame.Size.Y*.4,0))*CFrame.Angles(0,0,-.12)
  flame.Anchored=true;flame.CanCollide=false;flame.CanTouch=false;flame.CanQuery=false;flame.CastShadow=false
  flame.Material=Enum.Material.Neon;flame.Color=Color3.fromRGB(255,194,112);flame.Parent=model
  if oldFlame then
   for _,light in oldFlame:GetChildren()do if light:IsA("Light")then light.Parent=flame end end
   oldFlame:Destroy()
  end
  model:SetAttribute("OriginalBlenderMesh",true)
  model.Parent=p.Parent;p:Destroy()
  if index%20==0 then task.wait()end
 end
 root:SetAttribute("CandleArtRevision",1)
 return #originals
end
return C
