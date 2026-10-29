--!strict
-- Reversible terrain apron and raised banks around The Vigil. Never touches the old manor at Z=0.
-- Snapshot corner is stored on the TerrainRegion backup for exact voxel restoration.
local G={}
local O=Vector3.new(0,0,-1000)
function G.Apply(root:Instance)
 local t=workspace.Terrain;local backups=game.ServerStorage.WorldTools.Backups
 if not t:GetAttribute("VigilLandscapeRevision")then
  local min=Vector3int16.new(-55,-16,-365);local max=Vector3int16.new(55,22,-190)
  local snapshot=t:CopyRegion(Region3int16.new(min,max));snapshot.Name="Terrain_PreVigilLandscape_20261029"
  snapshot:SetAttribute("CornerX",min.X);snapshot:SetAttribute("CornerY",min.Y);snapshot:SetAttribute("CornerZ",min.Z);snapshot.Parent=backups
  t:FillBlock(CFrame.new(O+Vector3.new(0,-18,-135)),Vector3.new(420,36,600),Enum.Material.Rock)
  t:FillBlock(CFrame.new(O+Vector3.new(0,-3,-135)),Vector3.new(408,5.7,590),Enum.Material.LeafyGrass)
  for _,s in {-1,1}do
   for index,z in {110,-70,-200,-335}do
    local radius=if index==1 then 29 else 34
    t:FillBall(O+Vector3.new(s*(176+index%2*7),-9,z),radius,Enum.Material.Rock)
    t:FillBall(O+Vector3.new(s*(176+index%2*7),-13,z),radius,Enum.Material.LeafyGrass)
   end
   task.wait()
  end
  t:SetAttribute("VigilLandscapeRevision",1)
 end
 root.Ground.Yard.Transparency=1 -- Original level collider retained; turf sits just below it.
 local old=root:FindFirstChild("EstateApproach");if old then old:Destroy()end
 local model=Instance.new("Model");model.Name="EstateApproach";model.Parent=root
 for i=0,8 do
  local p=Instance.new("Part");p.Name="WornApproachSlab";p.Anchored=true;p.Size=Vector3.new(18,.16,4.7)
  p.CFrame=CFrame.new(O+Vector3.new((i%3-1)*.08,.03,88+i*4.8))
  p.Material=Enum.Material.Cobblestone;p.Color=Color3.fromRGB(71+i%3*3,72+i%3*3,80+i%3*3);p.Parent=model
 end
end
return G