local root="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-07"
local spr=app.open(root.."/backup-revision-06/run_cycle_8.aseprite")
assert(spr and #spr.frames==8,"Expected the approved eight-frame Run")
local pc=app.pixelColor

local function rgba(r,g,b,a) return pc.rgba(r,g,b,a or 253) end
local function parts(pixel)
 return pc.rgbaR(pixel),pc.rgbaG(pixel),pc.rgbaB(pixel),pc.rgbaA(pixel)
end
local function skin(pixel)
 local r,g,b,a=parts(pixel)
 return a>160 and r>220 and g>145 and b>115
end
local function blend_skin(img,x,y,mouth_y,fill_fallback)
 local upper=img:getPixel(x,mouth_y-2)
 local lower=img:getPixel(x,mouth_y+10)
 if not skin(upper) then upper=fill_fallback end
 if not skin(lower) then lower=fill_fallback end
 local t=(y-(mouth_y-2))/12
 local ar,ag,ab=parts(upper)
 local br,bg,bb=parts(lower)
 return rgba(math.floor(ar*(1-t)+br*t+0.5),math.floor(ag*(1-t)+bg*t+0.5),math.floor(ab*(1-t)+bb*t+0.5))
end
local function line(img,x,y,points,color)
 for _,p in ipairs(points) do img:drawPixel(x+p[1],y+p[2],color) end
end

local positions={}
for frame=1,8 do
 local cel=spr.layers[1]:cel(frame)
 assert(cel,"Missing Run cel "..frame)
 local img=Image(cel.image)
 local minx,miny=192,192
 local lip_count=0
 for y=88,107 do
  for x=103,129 do
   local r,g,b,a=parts(img:getPixel(x,y))
   if a>180 and r>=185 and r<=210 and g>=45 and g<=75 and b>=42 and b<=80 then
    if x<minx then minx=x end
    if y<miny then miny=y end
    lip_count=lip_count+1
   end
  end
 end
 assert(lip_count==39,"Unexpected mouth landmarks on frame "..frame..": "..lip_count)
 local mx,my=minx,miny
 local fallback=img:getPixel(mx+8,my-3)
 assert(skin(fallback),"No skin color around mouth on frame "..frame)

 -- Replace only the lens interiors.  The original glasses and face contour stay.
 for y=my-12,my-8 do
  for x=mx-11,mx do
   local fill=img:getPixel(x,my-6)
   img:drawPixel(x,y,skin(fill) and fill or fallback)
  end
  for x=mx+15,mx+23 do
   local fill=img:getPixel(x,my-6)
   img:drawPixel(x,y,skin(fill) and fill or fallback)
  end
 end
 local ink=rgba(49,31,29)
 line(img,mx,my,{{-9,-8},{-8,-9},{-7,-9},{-6,-10},{-5,-10},{-4,-10},{-3,-9},{-2,-9}},ink)
 line(img,mx,my,{{16,-9},{17,-10},{18,-10},{19,-10},{20,-11},{21,-11},{22,-10}},ink)

 -- Remove the former wide laugh and draw a small raised-corner smirk.
 for y=my,my+8 do
  for x=mx,mx+17 do img:drawPixel(x,y,blend_skin(img,x,y,my,fallback)) end
 end
 local lip=rgba(155,55,63)
 local deep=rgba(91,38,47)
 local pink=rgba(216,103,113)
 line(img,mx,my,{{2,3},{3,3},{4,3},{5,3},{6,3},{7,3},{8,3},{9,2},{10,2}},lip)
 line(img,mx,my,{{1,4},{2,4},{3,4},{4,5},{5,5},{6,5},{7,5},{8,4},{9,4},{10,3},{11,2}},deep)
 line(img,mx,my,{{5,6},{6,6},{7,5}},pink)
 cel.image=img
 positions[frame]={frame=frame,mouth_x=mx,mouth_y=my}
end
local output=root.."/run_expression_candidate.aseprite"
spr:saveCopyAs(output)
io.write("__RESULT__"..json.encode({success=true,data={savedTo=output,positions=positions}}))
