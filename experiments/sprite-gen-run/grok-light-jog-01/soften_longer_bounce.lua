-- Keep each 24-frame pose intact while reducing the few excessive airborne gaps.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/grok-light-jog-01/loop-long-47-70'
local sprite=app.open(root..'/run_01.png')
assert(sprite and #sprite.frames==24,'Expected twenty-four extracted jogging frames')
local pc=app.pixelColor
local shifts={}
for i=1,24 do
  local cel=sprite.layers[1]:cel(i)
  local src=cel.image
  local bottom=-1
  for y=0,191 do
    for x=0,191 do
      if pc.rgbaA(src:getPixel(x,y))>=128 then bottom=y end
    end
  end
  local gap=math.max(0,174-(bottom+1))
  local down=math.min(6,math.max(0,gap-2))
  shifts[i]=down
  local out=Image{width=192,height=192,colorMode=ColorMode.RGB}
  for y=0,191-down do
    for x=0,191 do
      local pixel=src:getPixel(x,y)
      if pc.rgbaA(pixel)>0 then out:drawPixel(x,y+down,pixel) end
    end
  end
  cel.image=out
  cel.position=Point(0,0)
  sprite.frames[i].duration=({0.042,0.042,0.041})[(i-1)%3+1]
end
sprite.layers[1].name='Connected character / extended light jog'
sprite:saveCopyAs(root..'/run_light_24.aseprite')
io.write('__RESULT__'..json.encode({success=true,data={frames=24,whole_body_down_px=shifts}}))
