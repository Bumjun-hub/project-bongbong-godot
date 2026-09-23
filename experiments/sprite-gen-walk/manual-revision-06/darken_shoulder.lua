local spr=app.open("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-06/revision16-walk_cycle_8.aseprite")
assert(spr and #spr.frames==8)
local pc=app.pixelColor
local prior=pc.rgba(5,4,6,255)
local black=pc.rgba(0,0,0,255)
local darkred=pc.rgba(128,8,26,255)
local deeperred=pc.rgba(103,10,17,255)
local dy={0,1,0,-1,0,1,0,-1}
local delta={{-1,0},{1,0},{0,-1},{0,1}}
local report={}
local function isRed(p)
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
   if p==prior then img:drawPixel(x,y,black) count=count+1
   else
    local r,g,b,a=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p)
    if a>0 and r<=40 and g<=40 and b<=40 then
     local red=false
     local clear=false
     for _,d in ipairs(delta) do
      local q=src:getPixel(x+d[1],y+d[2])
      if isRed(q) then red=true end
      if pc.rgbaA(q)==0 then clear=true end
     end
     if red and clear and p~=black then img:drawPixel(x,y,black) count=count+1 end
    end
   end
  end
 end
 local y=113+dy[i]
 for x=85,87 do
  local p=src:getPixel(x,y)
  if isRed(p) then
   local color=(x==87) and deeperred or darkred
   if p~=color then img:drawPixel(x,y,color) count=count+1 end
  end
 end
 local baseRim={{93,0,7},{102,1,14},{123,4,25},{134,4,21},{145,10,30},{159,10,31},{165,5,29}}
 for yy=112+dy[i],126+dy[i] do
  for x=67,87 do
   local p=img:getPixel(x,yy)
   if isRed(p) then
    local exterior=false
    for _,d in ipairs(delta) do
     local nx,ny=x+d[1],yy+d[2]
     local q=img:getPixel(nx,ny)
     if pc.rgbaA(q)>0 and math.max(pc.rgbaR(q),pc.rgbaG(q),pc.rgbaB(q))<=40 then
      for _,e in ipairs(delta) do
       if pc.rgbaA(img:getPixel(nx+e[1],ny+e[2]))==0 then exterior=true end
      end
     end
    end
    if exterior then
     local r,g,b=pc.rgbaR(p)*0.78,pc.rgbaG(p)*0.78,pc.rgbaB(p)*0.78
     local best,bestDist=nil,math.huge
     for _,c in ipairs(baseRim) do
      local dist=(r-c[1])^2+(g-c[2])^2+(b-c[3])^2
      if dist<bestDist then best,bestDist=c,dist end
     end
     local color=pc.rgba(best[1],best[2],best[3],255)
     if p~=color then img:drawPixel(x,yy,color) count=count+1 end
    end
   end
  end
 end
 cel.image=img
 report[i]=count
end
spr:saveCopyAs("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-06/walk_cycle_8_candidate.aseprite")
io.write("__RESULT__"..json.encode({success=true,data={savedTo="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-06/walk_cycle_8_candidate.aseprite",frameChanges=report}}))
