local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local prod=root..'production/turn_specials/'
local base=Image{fromFile=root..'default_three_quarter_right/idle_default_three_quarter_right_01.png'}
local pc=app.pixelColor
local function normalize(src)
 local x0,y0,x1,y1=src.width,src.height,0,0
 for y=0,src.height-1 do for x=0,src.width-1 do
  if pc.rgbaA(src:getPixel(x,y))>=128 then x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y) end
 end end
 local w=math.floor((x1-x0+1)*156/(y1-y0+1)+0.5)
 local dx=math.floor(95-w/2+0.5);local im=Image(192,192,ColorMode.RGB)
 for y=0,155 do for x=0,w-1 do
  local sx=math.min(x1,x0+math.floor((x+0.5)*(x1-x0+1)/w))
  local sy=math.min(y1,y0+math.floor((y+0.5)*(y1-y0+1)/156))
  local c=src:getPixel(sx,sy)
  if pc.rgbaA(c)<128 then c=0 else c=pc.rgba(pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c),255) end
  im:putPixel(dx+x,18+y,c)
 end end
 print(json.encode({source={x0,y0,x1,y1},destination={dx,18,w,156}}))
 return im
end
local poses={base}
for _,kind in ipairs({'arms_crossed','pockets'}) do
 local raw=Image{fromFile=prod..kind..'_reference.png'}
 local ref=normalize(raw);ref:saveAs(prod..kind..'_normalized.png')
 local pose=Image(base)
 -- Erase only the original hanging arms, preserving all original denim.
 for y=131,155 do for x=57,133 do
  if x<84 or x>111 then
   local c=base:getPixel(x,y)
   local denim=pc.rgbaB(c)>pc.rgbaR(c)+12 and pc.rgbaB(c)>pc.rgbaG(c)
   if not denim then pose:putPixel(x,y,0) end
  end
 end end
 if kind=='arms_crossed' then
  for y=116,143 do for x=62,133 do pose:putPixel(x,y,ref:getPixel(x,y)) end end
  -- The approved neck and necklace above the folded hands are retained.
  for y=116,121 do for x=94,113 do pose:putPixel(x,y,base:getPixel(x,y)) end end
 else
  for y=119,148 do for x=62,133 do
   if x<86 or x>111 then pose:putPixel(x,y,ref:getPixel(x,y)) end
  end end
 end
 -- No new head/face/foot drawing is imported: these stay identical across poses.
 for y=0,114 do for x=0,191 do pose:putPixel(x,y,base:getPixel(x,y)) end end
 for y=153,191 do for x=0,191 do pose:putPixel(x,y,base:getPixel(x,y)) end end
 pose:saveAs(prod..kind..'_pose.png');poses[#poses+1]=pose
end
local preview=Image(1152,384,ColorMode.RGB)
for y=0,383 do for x=0,1151 do
 local im=poses[math.floor(x/384)+1]
 preview:putPixel(x,y,im:getPixel(math.floor((x%384)/2),math.floor(y/2)))
end end
preview:saveAs(prod..'right_idle_set_2x.png')
