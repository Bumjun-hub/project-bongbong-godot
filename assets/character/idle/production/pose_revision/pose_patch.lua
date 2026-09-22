-- Approved Base supplies every head and leg pixel. Generated stills are only
-- arm/sleeve drawing references; explicit integer sampling is done offline.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/'
local base=Image{fromFile=root..'source/bongbong_sd17_base.png'}
local folder=root..'idle/production/pose_revision/'
local refs={
  pockets={image=Image{fromFile=folder..'pockets_pose_reference.png'},cx=639,chin=714,scale=6.4},
  arms_crossed={image=Image{fromFile=folder..'crossed_pose_reference.png'},cx=634,chin=700,scale=6.4}
}
local function sample(ref,x,y)
  local sx=math.floor(ref.cx+(x-95)*ref.scale+0.5)
  local sy=math.floor(ref.chin+(y-110)*ref.scale+0.5)
  local c=ref.image:getPixel(sx,sy)
  if app.pixelColor.rgbaA(c)<100 then return 0 end
  return c
end
local function clearArms(im)
  for y=131,152 do for x=57,132 do
    if x<79 or x>111 then
      local c=base:getPixel(x,y)
      local denim=app.pixelColor.rgbaB(c)>app.pixelColor.rgbaR(c)+12 and app.pixelColor.rgbaB(c)>app.pixelColor.rgbaG(c)
      if not denim then im:putPixel(x,y,0) end
    end
  end end
end
local out={}
for _,kind in ipairs({'pockets','arms_crossed'}) do
  local im=Image(base);clearArms(im);local ref=refs[kind]
  if kind=='arms_crossed' then
    for y=118,139 do for x=65,126 do
      im:putPixel(x,y,sample(ref,x,y))
    end end
    -- Keep the approved neckline/pendant and shoulder roots above the fold.
    for y=118,122 do for x=85,104 do im:putPixel(x,y,base:getPixel(x,y)) end end
  else
    for y=119,148 do for x=65,126 do
      if x<83 or x>107 then im:putPixel(x,y,sample(ref,x,y)) end
    end end
  end
  out[kind]=im
  im:saveAs(folder..kind..'_pose.png')
end
return out
