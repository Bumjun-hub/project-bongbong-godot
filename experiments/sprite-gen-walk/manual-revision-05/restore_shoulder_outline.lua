local spr=app.open("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-05/revision15-walk_cycle_8.aseprite")
assert(spr and #spr.frames==8)
local pc=app.pixelColor
local ink=pc.rgba(5,4,6,255)
local dy={0,1,0,-1,0,1,0,-1}
local delta={{-1,0},{1,0},{0,-1},{0,1}}
local changes={}
local function red(p)
 local r,g,b,a=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)
 return a>0 and r>85 and r>g+50 and g<65
end
for i=1,8 do
 local cel=spr.layers[1]:cel(i)
 local src=cel.image
 local img=src:clone()
 local count=0
 for y=111+dy[i],126+dy[i] do
  for x=67,88 do
   local p=src:getPixel(x,y)
   local a=pc.rgbaA(p)
   local dark=a>0 and math.max(pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p))<=40
   local touchesRed=false
   local touchesClear=false
   for _,d in ipairs(delta) do
    local q=src:getPixel(x+d[1],y+d[2])
    if red(q) then touchesRed=true end
    if pc.rgbaA(q)==0 then touchesClear=true end
   end
   if (a==0 and touchesRed) or (dark and touchesRed and touchesClear) then
    if p~=ink then img:drawPixel(x,y,ink) count=count+1 end
   end
  end
 end
 cel.image=img
 changes[i]=count
end
spr:saveCopyAs("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-05/walk_cycle_8_candidate.aseprite")
io.write("__RESULT__"..json.encode({success=true,data={frameChanges=changes,savedTo="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-05/walk_cycle_8_candidate.aseprite"}}))
