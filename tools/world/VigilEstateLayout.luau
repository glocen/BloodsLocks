--!strict
-- Estate-layout enlargement, 2026-10-29. This is a recoverable layout pass, not final art.
-- Owner: larger manor and yard; two storeys, timber and red wool remain; animations deferred.
-- Scale the architectural shell coherently; keep hand-use furniture at R6 size.
-- Rebuild the grounds from layout data so the combat rectangle cannot leak into the manor.
local E={}
local ORIGIN=CFrame.new(0,0,-1000)
local L={ManorScale=1.5,YardHalf=120,YardSouth=64,YardNorth=340,WallHeight=18,
 Duel=Vector3.new(0,.5,-185),DummyLine=Vector3.new(-90,.5,-280),Pact=Vector3.new(86,.15,-280),Tower=370}
E.Layout=L
local stone=Color3.fromRGB(78,77,84)
local trim=Color3.fromRGB(109,105,105)
local dark=Color3.fromRGB(39,35,42)
local function group(parent:Instance,name:string):Model local m=Instance.new("Model");m.Name=name;m.Parent=parent;return m end
local function p(parent:Instance,name:string,size:Vector3,cf:CFrame,material:Enum.Material,color:Color3,solid:boolean?):Part
 local b=Instance.new("Part");b.Name=name;b.Anchored=true;b.Size=size;b.CFrame=ORIGIN*cf;b.Material=material;b.Color=color;b.CanCollide=solid~=false;b.CanTouch=false;b.TopSurface=Enum.SurfaceType.Smooth;b.BottomSurface=Enum.SurfaceType.Smooth;b.Parent=parent;return b
end
local function bar(parent:Instance,name:string,a:Vector3,b:Vector3,w:number,d:number)
 p(parent,name,Vector3.new(w,(b-a).Magnitude+.015,d),CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0),Enum.Material.Limestone,trim,false)
end
local function arch(parent:Instance,cx:number,z:number,span:number,spring:number,broken:boolean?)
 for _,s in {-1,1} do
  local last=Vector3.new(cx+s*span/2,spring,z)
  local n=if broken and s==1 then 10 else 18
  for i=1,n do
   local a=math.pi/3*i/18
   local v=Vector3.new(cx+s*(-span/2+span*math.cos(a)),spring+span*math.sin(a),z)
   bar(parent,"ArchStone",last,v,.9,1.5);last=v
  end
 end
end
function E.Spots():{[string]:CFrame}
 return {Spawn=ORIGIN*CFrame.new(0,.5,28*L.ManorScale),DummyAggressive=ORIGIN*CFrame.new(L.Duel),DummyLine=ORIGIN*CFrame.new(L.DummyLine)}
end
local function scaleRegion(region:Instance,f:number)
 -- Named architectural Models retain their hierarchy so menu lookups remain valid.
 if region:IsA("Model") then
  local pivot=region:GetPivot();local localPosition=ORIGIN:PointToObjectSpace(pivot.Position)
  region:ScaleTo(region:GetScale()*f)
  region:PivotTo(CFrame.new(ORIGIN:PointToWorldSpace(localPosition*f))*pivot.Rotation)
 else
  local wrapper=Instance.new("Model");wrapper.Name="TemporaryLayoutScale";wrapper.WorldPivot=ORIGIN;wrapper.Parent=region
  for _,c in region:GetChildren() do if c~=wrapper then c.Parent=wrapper end end
  wrapper:ScaleTo(f)
  for _,c in wrapper:GetChildren() do c.Parent=region end
  wrapper:Destroy()
 end
end
local function preserveHandScale(root:Instance)
 local props={}
 for _,m in root:GetDescendants() do
  if m:IsA("Model") and (m.Name=="BloodTable" or m.Name=="WindowSettle" or m.Name=="Keeper" or m.Name=="Mannequin") then
   table.insert(props,{model=m,pivot=m:GetPivot(),bounds=m:GetExtentsSize(),scale=m:GetScale()})
  elseif m:IsA("BasePart") and m.Name=="Counter" then
   table.insert(props,{part=m,pivot=m.CFrame,size=m.Size})
  end
 end
 return props
end
local function restoreHandScale(props:any,f:number)
 for _,r in props do
  local position=ORIGIN:PointToObjectSpace(r.pivot.Position)
  local target=CFrame.new(ORIGIN:PointToWorldSpace(Vector3.new(position.X*f,position.Y,position.Z*f)))*r.pivot.Rotation
  if r.model then
   local m=r.model
   local current=m:GetExtentsSize()
   m:ScaleTo(m:GetScale()*r.bounds.X/current.X)
   m:PivotTo(target)
  else r.part.Size=r.size;r.part.CFrame=target end
 end
end
function E.Apply(root:Instance)
 if root:GetAttribute("EstateLayoutRevision")==1 then return root end
 assert(not game:GetService("RunService"):IsRunning(),"Estate rebuilding is edit-time only")
 local props=preserveHandScale(root)
 for _,child in root.GreatHall:GetChildren() do scaleRegion(child,L.ManorScale);task.wait() end
 scaleRegion(root.HallOfOaths,L.ManorScale);task.wait()
 scaleRegion(root.Atelier,L.ManorScale);task.wait()
 restoreHandScale(props,L.ManorScale)
 -- Re-lay real-width oak boards rather than leaving oversized scaled planks.
 local manor=root.GreatHall.ManorHall
 local boards=manor:FindFirstChild("TimberGroundFloor");if boards then boards:Destroy() end
 local floor=group(manor,"TimberGroundFloor")
 local row=0
 for z=-59,59,2 do
  row+=1;local limit=math.min(60,60*math.sqrt(2)-math.abs(z)-.95)
  local x=-limit;local j=0
  while x<limit-.08 do
   j+=1;local length=math.min(8+(row+j*3)%5,limit-x)
   if length>.05 then
    local tint=(row*3+j*7)%7-3
    p(floor,"OakBoard",Vector3.new(length-.025,.4,1.975),CFrame.new(x+length/2,-.18,z),Enum.Material.Wood,Color3.fromRGB(67+tint,46+tint*.7,35+tint*.5))
   end
   x+=length
  end
  if row%12==0 then task.wait() end
 end
 -- A larger ground apron supports the wider wings and the expanded rear court.
 local ground=root.Ground:FindFirstChild("Yard")
 if ground and ground:IsA("BasePart") then ground.Size=Vector3.new(360,2,510);ground.CFrame=ORIGIN*CFrame.new(0,-1,-135) end
 local oldYard=root.Yard
 local pact=oldYard:FindFirstChild("ShinigamiCircle")
 local pactCopy=pact and pact:Clone()
 local oldPact=pact and pact:FindFirstChild("Sigil")
 if pactCopy and oldPact and oldPact:IsA("BasePart") then
  local delta=ORIGIN:PointToWorldSpace(L.Pact)-oldPact.Position
  for _,v in pactCopy:GetDescendants() do if v:IsA("BasePart") then v.CFrame+=delta end end
 end
 oldYard:Destroy()
 local yard=group(root,"Yard")
 -- Forecourt left and right connect back to the wings; the playable training court begins beyond the manor.
 local wallSouth=27
 local wallLength=L.YardNorth-wallSouth
 for _,s in {-1,1} do
  p(yard,"PerimeterSide",Vector3.new(3,18,wallLength),CFrame.new(s*(L.YardHalf+1.5),9,-(wallSouth+L.YardNorth)/2),Enum.Material.Limestone,stone)
  p(yard,"WingReturn",Vector3.new(58,18,3),CFrame.new(s*91,9,-wallSouth),Enum.Material.Limestone,stone)
  for z=wallSouth+8,L.YardNorth-8,26 do
   p(yard,"PerimeterPier",Vector3.new(4,20,4.5),CFrame.new(s*119.5,10,-z),Enum.Material.Limestone,stone)
   p(yard,"PierCap",Vector3.new(4.8,.5,5.3),CFrame.new(s*119.5,20.25,-z),Enum.Material.Limestone,trim)
  end
 end
 for _,s in {-1,1} do p(yard,"NorthWall",Vector3.new(110,18,3),CFrame.new(s*65,9,-L.YardNorth),Enum.Material.Limestone,stone) end
 p(yard,"GateLintel",Vector3.new(20,4,3),CFrame.new(0,16,-L.YardNorth),Enum.Material.Limestone,stone)
 -- A processional route connects the manor, practice ground and distant bell tower.
 p(yard,"ProcessionalStoneWalk",Vector3.new(16,.1,L.YardNorth-62),CFrame.new(0,.05,-(L.YardNorth+62)/2),Enum.Material.Cobblestone,Color3.fromRGB(87,83,86))
 local ring=p(yard,"DuelRing",Vector3.new(.18,42,42),CFrame.new(0,.19,L.Duel.Z)*CFrame.Angles(0,0,math.pi/2),Enum.Material.Sand,Color3.fromRGB(117,99,82));ring.Shape=Enum.PartType.Cylinder
 for i=0,3 do p(yard,"DummyPost",Vector3.new(3,.18,3),CFrame.new(L.DummyLine.X+i*10,.12,L.DummyLine.Z),Enum.Material.WoodPlanks,Color3.fromRGB(63,44,35)) end
 -- Movement heights remain 8/16/24: architectural enlargement must not invalidate the movement kit.
 local course=group(yard,"MovementCourse")
 for i,spec in {
  {Vector3.new(12,8,12),Vector3.new(-100,4,-116)},
  {Vector3.new(12,16,12),Vector3.new(-100,8,-134)},
  {Vector3.new(14,24,14),Vector3.new(-98,12,-158)},
  {Vector3.new(8,16,8),Vector3.new(-70,8,-158)}
 } do p(course,"Ledge"..i,spec[1],CFrame.new(spec[2]),Enum.Material.Limestone,stone) end
 for i=1,6 do p(course,"Step",Vector3.new(7,i*1.3,3),CFrame.new(-83,i*.65,-105-i*3),Enum.Material.Limestone,stone) end
 local ruins=group(yard,"RuinedArches")
 for _,z in {-120,-158} do
  for _,x in {72,100} do p(ruins,"Pier",Vector3.new(3.5,12,4),CFrame.new(x,6,z),Enum.Material.Limestone,stone) end
  arch(ruins,86,z,28,12,true)
 end
 for i=1,5 do p(ruins,"FallenStone",Vector3.new(2.5,1.4,2),CFrame.new(91+i*2,1,-139-i*4)*CFrame.Angles(0,i*.6,.13),Enum.Material.Limestone,trim) end
 if pactCopy then pactCopy.Parent=yard;game:GetService("CollectionService"):AddTag(pactCopy.Sigil,"BL_PactCircle") end
 -- A north arcade encloses the vista without filling the practice lanes.
 local arcade=group(yard,"NorthArcade")
 p(arcade,"Paving",Vector3.new(236,.16,18),CFrame.new(0,.08,-329),Enum.Material.Limestone,Color3.fromRGB(86,83,86))
 for x=-110,110,20 do
  for _,s in {-1,1} do p(arcade,"ArcadePier",Vector3.new(2.3,10,2.8),CFrame.new(x+s*8.2,5,-323),Enum.Material.Limestone,stone) end
  arch(arcade,x,-323,16.4,10)
 end
 p(arcade,"RoofBeam",Vector3.new(238,1,16),CFrame.new(0,24.7,-330),Enum.Material.Limestone,dark)
 task.wait()
 local zone=p(yard,"TrainingZone",Vector3.new(L.YardHalf*2,140,L.YardNorth-L.YardSouth),CFrame.new(0,60,-(L.YardNorth+L.YardSouth)/2),Enum.Material.SmoothPlastic,stone,false)
 zone.Transparency=1;zone.CanQuery=false;zone.CastShadow=false
 game:GetService("CollectionService"):AddTag(zone,"BL_CombatZone")
 -- Move and enlarge the landmark about its base rather than lifting it off the ground.
 local tower=root.BellTower
 local towerWrapper=Instance.new("Model");towerWrapper.Name="TowerLayoutScale";towerWrapper.WorldPivot=ORIGIN*CFrame.new(0,0,-198);towerWrapper.Parent=tower
 for _,c in tower:GetChildren() do if c~=towerWrapper then c.Parent=towerWrapper end end
 towerWrapper:ScaleTo(1.3);towerWrapper:PivotTo(ORIGIN*CFrame.new(0,0,-L.Tower))
 for _,c in towerWrapper:GetChildren() do c.Parent=tower end;towerWrapper:Destroy()
 local spots=E.Spots()
 local spawn=workspace:FindFirstChildOfClass("SpawnLocation");if spawn then spawn.CFrame=spots.Spawn;spawn.Transparency=1;spawn.CanCollide=false end
 local training=workspace:FindFirstChild("TrainingDummies")
 if training then
  local a=training:FindFirstChild("DummySpot1");local b=training:FindFirstChild("DummySpot2")
  if a and a:IsA("BasePart")then a.CFrame=spots.DummyAggressive end
  if b and b:IsA("BasePart")then b.CFrame=spots.DummyLine end
 end
 root:SetAttribute("EstateLayoutRevision",1)
 root:SetAttribute("ManorLayoutScale",L.ManorScale)
 root:SetAttribute("ArtStatus","Placeholder layout; larger manor and yard; final Blender art pending")
 return root
end
return E
