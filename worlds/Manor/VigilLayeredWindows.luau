--!strict
-- Original Blender window orders. Masters survive graybox rebuilds.
-- Diffuse trim finish is provisional; geometric depth is the purpose of this revision.
local W={}
local O=CFrame.new(0,0,-1000)
function W.Apply(root:Instance)
 local kit=game.ServerStorage.WorldAssets.VigilKit.LayeredWindows
 local old=root:FindFirstChild("LayeredWindows");if old then old:Destroy() end
 local shell=root:FindFirstChild("ManorExterior")
 assert(shell,"Fit exterior before window art")
 for _,p in shell:GetDescendants()do
  if p:IsA("MeshPart")and string.sub(p.Name,1,11)=="WingWindow_"then p:Destroy() end
 end
 local folder=Instance.new("Model");folder.Name="LayeredWindows";folder.Parent=root
 local count=0
 for _,side in {-1,1}do
  for _,face in {-1,1}do
   for _,x in {75,95,116,135}do
    for _,spec in {{name="Lower",height=6.2},{name="Upper",height=37.8}}do
     local m=kit[spec.name]:Clone();m.Name=spec.name.."_"..side.."_"..face.."_"..x
     m:PivotTo(O*CFrame.new(side*x,spec.height,face*21.75)*CFrame.Angles(0,if face==1 then 0 else math.pi,0))
     m.Parent=folder;count+=1
    end
   end
   task.wait()
  end
 end
 root:SetAttribute("WindowArtRevision",1)
 return count
end
return W
