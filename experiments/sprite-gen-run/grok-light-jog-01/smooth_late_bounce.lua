-- Smooth the late flight-to-landing transition without separating body parts.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/grok-light-jog-01/loop-cut-21'
local sprite=app.open(root..'/run_light_21.aseprite')
assert(sprite and #sprite.frames==21,'Expected twenty-one jogging frames')
local pc=app.pixelColor
for _,entry in ipairs({{15,3},{16,-1}}) do
  local index,delta=entry[1],entry[2]
  local cel=sprite.layers[1]:cel(index)
  local src=cel.image
  local out=Image{width=192,height=192,colorMode=ColorMode.RGB}
  for y=0,191 do
    local to_y=y+delta
    if to_y>=0 and to_y<192 then
      for x=0,191 do
        local pixel=src:getPixel(x,y)
        if pc.rgbaA(pixel)>0 then out:drawPixel(x,to_y,pixel) end
      end
    end
  end
  cel.image=out
  cel.position=Point(0,0)
end
sprite.layers[1].name='Connected character / smooth late bounce'
sprite:saveCopyAs(root..'/run_light_21_smooth.aseprite')
io.write('__RESULT__'..json.encode({success=true,data={frames=21,whole_body_dy={['15']=3,['16']=-1}}}))
