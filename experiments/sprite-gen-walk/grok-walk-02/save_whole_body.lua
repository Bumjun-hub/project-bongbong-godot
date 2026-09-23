local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-walk/grok-walk-02/whole-body-159'
local sprite=app.open(root..'/walk_01.png')
assert(sprite and #sprite.frames==24,'Expected the 24 whole-body frames')
sprite.layers[1].name='Grok walk: head, neck and body together'
for i=1,24 do
  sprite.frames[i].duration=({0.042,0.042,0.041})[(i-1)%3+1]
end
sprite:saveCopyAs(root..'/walk_cycle_24.aseprite')
io.write('__RESULT__'..json.encode({success=true,frames=#sprite.frames}))
