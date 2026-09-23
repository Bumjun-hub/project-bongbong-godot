local spr=app.open("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-04/revision14-walk_cycle_8.aseprite")
assert(spr and #spr.frames==8,"Expected 8 frames")
local rgba=app.pixelColor.rgba
local clear=rgba(0,0,0,0)
local edge=rgba(24,25,31,255)
local inner=rgba(63,42,35,255)
local skin=rgba(255,215,179,255)
local shade=rgba(240,173,131,255)
local light=rgba(255,219,181,255)
local dy={0,1,0,-1,0,1,0,-1}
local neck={{109,87,90},{110,86,89},{111,83,88},{112,81,87}}
local oldForward={{123,131},{123,132},{124,133},{124,134},{124,135},{125,136},{125,135},{125,134},{126,134},{126,133},{127,132},{129,131}}
local newForward={{123,131},{124,132},{125,133},{126,133},{126,134},{126,135},{126,135},{127,134},{127,134},{128,133},{129,132}}
local oldMid={{117,127},{118,128},{118,128},{119,129},{119,130},{120,131},{120,130},{120,129},{121,129},{121,128},{122,127},{124,126}}
local newMid={{117,127},{118,127},{119,128},{120,128},{120,129},{120,130},{120,130},{121,129},{121,129},{122,128},{123,127}}
local oldNeutral={{110,120},{109,120},{109,120},{109,119},{110,119},{110,118},{111,117},{114,116}}
local newNeutral={{111,119},{110,120},{110,120},{110,119},{111,119},{112,118},{113,117}}
local function redraw(img,startY,oldRows,newRows,crease)
 for j,row in ipairs(oldRows) do for x=row[1],row[2] do img:drawPixel(x,startY+j-1,clear) end end
 for j,row in ipairs(newRows) do
  local y=startY+j-1
  for x=row[1],row[2] do
   local color=skin
   if j==#newRows then color=edge
   elseif x==row[1] then color=(j<#newRows-2) and inner or edge
   elseif x==row[2] then color=edge
   elseif j>=#newRows-2 then color=shade
   elseif x==row[1]+1 then color=light
   end
   img:drawPixel(x,y,color)
  end
 end
 for _,p in ipairs(crease) do img:drawPixel(p[1],p[2],shade) end
end
for i=1,8 do
 local cel=spr.layers[1]:cel(i)
 assert(cel.position.x==0 and cel.position.y==0,"Expected full-frame cels")
 local img=cel.image:clone()
 for _,row in ipairs(neck) do for x=row[2],row[3] do img:drawPixel(x,row[1]+dy[i],clear) end end
 if i==1 then
  redraw(img,138,oldForward,newForward,{{128,143},{128,144},{129,145}})
 elseif i==2 or i==8 then
  local shift=(i==8) and -2 or 0
  redraw(img,141+shift,oldMid,newMid,{{122,146+shift},{122,147+shift},{123,148+shift}})
 elseif i==3 or i==7 then
  redraw(img,145,oldNeutral,newNeutral,{{113,146},{113,147},{114,148}})
 end
 if i==3 or i==7 then
  for y=145,152 do for x=109,120 do
   local p=cel.image:getPixel(x,y)
   local r,g,b,a=app.pixelColor.rgbaR(p),app.pixelColor.rgbaG(p),app.pixelColor.rgbaB(p),app.pixelColor.rgbaA(p)
   if a>0 and b>r+18 and b>g+3 then img:drawPixel(x,y,p) end
  end end
 end
 cel.image=img
end
spr:saveCopyAs("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-04/walk_cycle_8_candidate.aseprite")
io.write("__RESULT__"..json.encode({success=true,data={savedTo="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/manual-revision-04/walk_cycle_8_candidate.aseprite",frames=#spr.frames}}))
