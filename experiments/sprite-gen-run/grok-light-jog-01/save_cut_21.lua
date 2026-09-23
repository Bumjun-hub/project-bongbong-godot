-- Save the de-duplicated cycle as a native, editable Aseprite animation.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/grok-light-jog-01/loop-cut-21'
local sprite=app.open(root..'/run_01.png')
assert(sprite and #sprite.frames==21,'Expected twenty-one reviewed jogging frames')
for i=1,21 do
  sprite.frames[i].duration=(i==1 or i%3==0) and 0.047 or 0.048
end
sprite.layers[1].name='Connected character / even light jog'
sprite:saveCopyAs(root..'/run_light_21.aseprite')
io.write('__RESULT__'..json.encode({success=true,data={frames=21,duration_ms=1000}}))
