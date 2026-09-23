local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-08'
local spr=app.open(root..'/backup-revision-07/run_cycle_8.aseprite')
local pc=app.pixelColor
local sources={}
for i=1,8 do sources[i]=Image(spr.layers[1]:cel(i).image) end
local base=sources[1]
local function blank() return Image{width=192,height=192,colorMode=ColorMode.RGB} end
local function color(r,g,b,a) return pc.rgba(r,g,b,a or 255) end
local ink=color(28,23,29)
local function line(im,x0,y0,x1,y1,c)
 local dx,dy=math.abs(x1-x0),-math.abs(y1-y0)
 local sx,sy=x0<x1 and 1 or -1,y0<y1 and 1 or -1
 local err=dx+dy
 while true do
  im:drawPixel(x0,y0,c)
  if x0==x1 and y0==y1 then break end
  local e=2*err
  if e>=dy then err=err+dy;x0=x0+sx end
  if e<=dx then err=err+dx;y0=y0+sy end
 end
end
local function poly(im,pts,c)
 for y=100,145 do
  local xs={}
  for j=1,#pts do
   local a,b=pts[j],pts[j%#pts+1]
   if (a[2]<=y and b[2]>y) or (b[2]<=y and a[2]>y) then
    xs[#xs+1]=a[1]+(y-a[2])*(b[1]-a[1])/(b[2]-a[2])
   end
  end
  table.sort(xs)
  for j=1,#xs-1,2 do for x=math.ceil(xs[j]),math.floor(xs[j+1]) do im:drawPixel(x,y,c) end end
 end
 for j=1,#pts do local a,b=pts[j],pts[j%#pts+1];line(im,a[1],a[2],b[1],b[2],ink) end
end
local upper=blank()
-- Far arm recedes behind the shirt and head; near arm has an open, relaxed hand.
poly(upper,{{108,119},{107,124},{68,118},{57,114},{56,111},{60,110},{72,112}},color(238,173,122))
for y=0,141 do for x=0,191 do
 local p=base:getPixel(x,y)
 local keep=y<110 or (x>=78 and x<=113)
 if keep and pc.rgbaA(p)>0 then upper:drawPixel(x,y,p) end
end end
-- Restore the front shirt silhouette after removing the old forward sleeve/arm.
poly(upper,{{108,114},{114,119},{113,130},{111,139},{105,140},{108,131}},color(172,13,43))
-- Near sleeve and white cuff point backward from the shoulder.
poly(upper,{{83,111},{91,117},{85,125},{73,121},{72,117}},color(188,16,48))
poly(upper,{{73,117},{79,120},{76,125},{70,122}},color(241,239,226))
poly(upper,{{70,121},{76,125},{64,128},{51,128},{46,130},{43,128},{44,124},{49,122},{59,123}},color(255,204,155))
line(upper,49,126,62,126,color(237,164,114))
line(upper,46,126,47,128,color(226,144,95))
local body=spr.layers[1];body.name='Forward lean / arms back / playful face'
local trails=spr:newLayer();trails.name='Leg afterimages';trails.stackIndex=1
local bob={0,-1,-3,-4,0,-2,-1,-3}
for i=1,8 do
 local out=blank()
 -- Preserve the revised alternating leg poses.
 for y=138,191 do for x=0,191 do
  local p=sources[i]:getPixel(x,y)
  local r,g,b=pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p)
  if not (r>g*1.15 and r>b*1.3) then out:drawPixel(x,y,p) end
 end end
 -- Row-preserving integer lean keeps eyes and glasses crisp.
 for y=0,141 do for x=0,191 do
  local p=upper:getPixel(x,y)
  local dx=math.floor(math.max(0,142-y)*0.13+0.5)
  local yy=y+bob[i]
  if pc.rgbaA(p)>0 and x+dx<192 and yy>=0 then out:drawPixel(x+dx,yy,p) end
 end end
 body:cel(i).image=out;body:cel(i).position=Point(0,0)
 local ghost=blank()
 local prev=sources[(i+6)%8+1]
 for y=145,179 do for x=25,150 do
  local p=prev:getPixel(x,y)
  if pc.rgbaA(p)>80 then
   local fade=math.min(1,(y-145)/9)
   local r=math.floor(pc.rgbaR(p)*0.5+58)
   local g=math.floor(pc.rgbaG(p)*0.5+78)
   local b=math.floor(pc.rgbaB(p)*0.5+96)
   ghost:drawPixel(x-10,y,color(r,g,b,math.floor(65*fade)))
   if x>=43 then ghost:drawPixel(x-18,y,color(r,g,b,math.floor(27*fade))) end
  end
 end end
 spr:newCel(trails,i,ghost,Point(0,0))
 spr.frames[i].duration=0.06
end
spr.tags[1].name='RUN_ARMS_BACK_SPEED'
spr:saveCopyAs(root..'/run_dash.aseprite')
io.write('__RESULT__'..json.encode({success=true}))
