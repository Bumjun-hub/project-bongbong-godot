local spr=app.open("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-06/backup-revision-05/run_cycle_8.aseprite")
assert(spr and #spr.frames==8,"Expected 8 source frames")
local pc=app.pixelColor
local dx={0,1,2,2,0,1,2,2}
local dy={0,0,-1,-3,1,1,0,-2}
local duration={80,60,60,80,80,60,60,80}
local stats={}
for i=1,8 do
 local cel=spr.layers[1]:cel(i)
 assert(cel and cel.position.x==0 and cel.position.y==0,"Expected full-canvas cel")
 local src=cel.image
 local dst=Image{width=192,height=192,colorMode=ColorMode.RGB}
 local kept=0
 local cleaned=0
 for y=0,191 do
  for x=0,191 do
   local pixel=src:getPixel(x,y)
   local alpha=pc.rgbaA(pixel)
   if alpha>8 then
    local xx,yy=x+dx[i],y+dy[i]
    assert(xx>=0 and xx<192 and yy>=0 and yy<192,"Visible art would be clipped")
    dst:drawPixel(xx,yy,pixel)
    kept=kept+1
   elseif alpha>0 then cleaned=cleaned+1 end
  end
 end
 cel.image=dst
 spr.frames[i].duration=duration[i]/1000
 stats[i]={frame=i,dx=dx[i],dy=dy[i],duration_ms=duration[i],kept_pixels=kept,subvisible_pixels_removed=cleaned}
end
spr:saveCopyAs("C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-06/run_cycle_8_candidate.aseprite")
io.write("__RESULT__"..json.encode({success=true,data={savedTo="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-06/run_cycle_8_candidate.aseprite",frames=stats}}))
