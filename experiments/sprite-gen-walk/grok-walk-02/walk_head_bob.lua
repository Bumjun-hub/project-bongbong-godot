-- Keep the Idle-sized head, and restore a small two-step walking bounce.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot'
local work=root..'/experiments/sprite-gen-walk/grok-walk-02'
local idle=app.open(root..'/assets/character/idle/default_three_quarter_right/idle_default_three_quarter_right_01.png')
local walk=app.open(work..'/before-head-match/walk_01.png')
assert(idle and walk and #walk.frames==24,'Expected Idle and original 24 Walk frames')
local head=idle.layers[1]:cel(1).image
local pc=app.pixelColor
local dx={0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0,-1,-1,-1,-1,0,0,0}
local dy={0,0,1,1,2,2,1,1,0,0,1,1,2,2,1,1,0,0,1,1,2,2,1,0}
for i=1,24 do
  local cel=walk.layers[1]:cel(i)
  local out=Image(cel.image)
  for y=0,110 do
    for x=0,191 do out:drawPixel(x,y,0) end
  end
  for y=0,110 do
    for x=0,191 do
      local p=head:getPixel(x,y)
      if pc.rgbaA(p)>0 and x+dx[i]>=0 and x+dx[i]<192 then
        out:drawPixel(x+dx[i],y+dy[i],p)
      end
    end
  end
  cel.image=out
  cel.position=Point(0,0)
  walk.frames[i].duration=({0.042,0.042,0.041})[(i-1)%3+1]
end
walk.layers[1].name='Idle-sized moving head / calm walk body'
walk:saveCopyAs(work..'/walk_head_bob_candidate.aseprite')
io.write('__RESULT__'..json.encode({success=true,data={dx=dx,dy=dy}}))
