--!strict
-- Reference-led Blender shell, fitted after layout scaling and candle replacement.
-- Structure and first stone-detail pass; owner explicitly rejects this as final surface quality.
-- Keep all gameplay paths, furniture, floors and training positions authoritative in the original builders.
local X={}
local ORIGIN=CFrame.new(0,0,-1000)
local function stone(parent:Instance,name:string,size:Vector3,cf:CFrame,tint:number)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=ORIGIN*cf;p.Anchored=true
 p.Material=Enum.Material.Limestone;p.Color=Color3.fromRGB(75+tint,75+tint,82+tint)
 p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Parent=parent;return p
end
local function pier(parent:Instance,cf:CFrame,width:number,depth:number,height:number,seed:number)
 -- Individual ashlar courses create mortar shadow and actual relief, not painted outlines.
 local n=math.floor(height/1.6)
 for row=0,n-1 do
  local stage=math.floor(row/math.max(1,math.floor(n/4)))
  local d=depth-stage*.38
  local w=width+(if row%2==0 then .12 else 0)
  stone(parent,"AshlarCourse",Vector3.new(w,1.54,d),cf*CFrame.new(0,row*1.6+.8,d/2),(row*7+seed*3)%7-3)
 end
 for _,y in {0.4,height*.25,height*.5,height*.75,height}do
  local stage=math.floor(y/(height/4))
  local d=math.max(1,depth-stage*.38)
  stone(parent,"DressedPierCap",Vector3.new(width+.4,.42,d+.3),cf*CFrame.new(0,y,d/2),3)
 end
end
function X.Apply(root:Instance):{[string]:any}
 if root:GetAttribute("ExteriorArtRevision")==1 then return {alreadyApplied=true}end
 assert(not game:GetService("RunService"):IsRunning(),"Exterior art is edit-time only")
 local master=game.ServerStorage.WorldAssets.VigilKit:FindFirstChild("ManorExterior")
 assert(master and master:IsA("Model"),"Import and validate the Blender manor master first")
 local shell=master:Clone();shell.Name="ManorExterior";shell:PivotTo(ORIGIN)
 -- Only wing wall/roof shells are replaced; their floors, furniture and gameplay lights remain.
 for _,region in {root.HallOfOaths,root.Atelier}do
  for _,p in region:GetChildren()do
   if p:IsA("BasePart")and(p.Name=="SideWall"or p.Name=="EndWall"or p.Name=="Roof")then p:Destroy()
   elseif p:IsA("BasePart")and p.Name=="MoonWindow"then p.Transparency=1;p.CastShadow=false end
  end
 end
 local porch=root.GreatHall:FindFirstChild("SpawnPorch")
 if porch then for _,p in porch:GetChildren()do if p:IsA("BasePart")and(p.Name=="Roof"or p.Name=="Pillar")then p:Destroy()end end end
 for _,p in shell:GetDescendants()do
  if p:IsA("MeshPart")then
   local wall=string.find(p.Name,"WALL")~=nil
   p.CanCollide=wall and not string.find(p.Name,"ShoulderTower")
   p.CanQuery=p.CanCollide;p.CanTouch=false
  end
 end
 shell.Parent=root;task.wait()
 local detail=Instance.new("Model");detail.Name="ExteriorStonework";detail.Parent=root
 for k=0,7 do
  local bay=CFrame.Angles(0,math.rad(k*45),0)*CFrame.new(0,0,63.9)
  for _,side in {-1,1}do pier(detail,bay*CFrame.new(side*22.7,0,0),2.1,3.2,73,k)end
  if k%2==0 then task.wait()end
 end
 for _,side in {-1,1}do
  for _,face in {-1,1}do
   local turn=if face==1 then 0 else math.pi
   for index,x in {64.5,85.2,105.6,126,141}do
    pier(detail,CFrame.new(side*x,0,face*22.35)*CFrame.Angles(0,turn,0),1.3,1.8,64,index)
   end
   task.wait()
  end
 end
 root:SetAttribute("ExteriorArtRevision",1)
 root:SetAttribute("ExteriorArtStatus","Structural shell and first stone relief; weathering/landscape pending")
 return {meshParts=#shell:GetChildren(),detailParts=#detail:GetChildren()}
end
return X
