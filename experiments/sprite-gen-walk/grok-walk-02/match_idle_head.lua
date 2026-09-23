-- Keep the accepted walk legs and torso, while matching the Idle head pixels.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot'
local idle=app.open(root..'/assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png')
local walk=app.open(root..'/assets/character/walk/grok_right_calm/walk_01.png')
assert(idle and walk and #walk.frames==24,'Expected Idle and 24 Walk frames')
local head=idle.layers[1]:cel(1).image
local changed={}
for i=1,24 do
  local cel=walk.layers[1]:cel(i)
  local img=Image(cel.image)
  local n=0
  for y=0,110 do
    for x=0,191 do
      local pixel=head:getPixel(x,y)
      if img:getPixel(x,y)~=pixel then n=n+1 end
      img:drawPixel(x,y,pixel)
    end
  end
  cel.image=img
  cel.position=Point(0,0)
  -- 42 + 42 + 41 ms, repeated eight times, gives an exact 1 s source cycle.
  walk.frames[i].duration=({0.042,0.042,0.041})[(i-1)%3+1]
  changed[i]=n
end
walk.layers[1].name='Idle-matched head / calm walk body'
walk:saveCopyAs(root..'/experiments/sprite-gen-walk/grok-walk-02/walk_idle_head_candidate.aseprite')
io.write('__RESULT__'..json.encode({success=true,data={changed_pixels_per_frame=changed}}))
