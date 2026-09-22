local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local out=root..'default_three_quarter_right/'
app.fs.makeAllDirectories(out)
local base=Image{fromFile=root..'production/turn_default/pose.png'}
local durations={600,400,500,450,450,600}
local phases={0,1,2,2,1,0}
local frames={}
local name='idle_default_three_quarter_right'
local sheet=Image(1152,192,ColorMode.RGB)
local spr=Sprite(192,192,ColorMode.RGB)
spr.layers[1].name='Complete pixel frames'
local rects={}
for i,phase in ipairs(phases) do
 local im=Image(base)
 if phase>0 then
  local start=phase==2 and 0 or 115
  for y=start,137 do for x=0,191 do im:putPixel(x,y,0) end end
  for y=start,137 do for x=0,191 do
   if y>0 then im:putPixel(x,y-1,base:getPixel(x,y)) end
  end end
  -- Pixel seam at the interior shirt/upper-arm row; hips, hands, legs and feet
  -- remain at their original coordinates, without scale or fractional pixels.
  for x=0,191 do im:putPixel(x,137,base:getPixel(x,137)) end
 end
 frames[i]=im
 if i>1 then spr:newEmptyFrame() end
 spr:newCel(spr.layers[1],spr.frames[i],im,Point(0,0))
 spr.frames[i].duration=durations[i]/1000
 im:saveAs(out..name..string.format('_%02d.png',i))
 sheet:drawImage(im,Point((i-1)*192,0))
 rects[i]={x=(i-1)*192,y=0,w=192,h=192,duration_ms=durations[i],phase=phase}
end
local tag=spr:newTag(1,6);tag.name='IDLE_DEFAULT_THREE_QUARTER_RIGHT'
spr:saveAs(out..name..'.aseprite')
spr:saveCopyAs(out..name..'.gif')
sheet:saveAs(out..name..'.png')
spr:close()
local manifest={canvas={192,192},anchor={95,174},facing='screen-right-three-quarter',state='IDLE_DEFAULT_THREE_QUARTER_RIGHT',loop=true,total_duration_ms=3000,frames=rects,sheet=name..'.png',source=name..'.aseprite',blink_included=false}
local file=assert(io.open(out..'manifest.json','w'));file:write(json.encode(manifest));file:close()
local checks={canvas={192,192},feet_fixed=true,lower_body_fixed=true,head_drawing_unchanged=true,loop_endpoints_identical=frames[1]:isEqual(frames[6]),max_head_offset_px=1,changed_pixels={}}
for i,im in ipairs(frames) do
 local n=0
 for y=0,191 do for x=0,191 do
  if im:getPixel(x,y)~=base:getPixel(x,y) then n=n+1 end
  if y>=138 and im:getPixel(x,y)~=base:getPixel(x,y) then checks.lower_body_fixed=false end
  if y>=159 and im:getPixel(x,y)~=base:getPixel(x,y) then checks.feet_fixed=false end
  if y<=112 then
   local sy=y+(phases[i]==2 and 1 or 0)
   if im:getPixel(x,y)~=base:getPixel(x,sy) then checks.head_drawing_unchanged=false end
  end
 end end
 checks.changed_pixels[i]=n
end
assert(checks.feet_fixed and checks.lower_body_fixed and checks.head_drawing_unchanged and checks.loop_endpoints_identical)
-- Reopen the authored source and verify actual persisted frames and timing.
local saved=app.open(out..name..'.aseprite')
assert(saved.width==192 and saved.height==192 and #saved.frames==6)
for i,frame in ipairs(saved.frames) do
 assert(math.floor(frame.duration*1000+0.5)==durations[i])
 local cel=saved.layers[1]:cel(i)
 for y=0,191 do for x=0,191 do
  local sx,sy=x-cel.position.x,y-cel.position.y
  local c=(sx>=0 and sy>=0 and sx<cel.image.width and sy<cel.image.height) and cel.image:getPixel(sx,sy) or 0
  assert(c==frames[i]:getPixel(x,y),'Persisted frame differs')
 end end
end
saved:close()
local gif=app.open(out..name..'.gif');local ms=0
for _,frame in ipairs(gif.frames) do ms=ms+math.floor(frame.duration*1000+0.5) end
assert(#gif.frames==6 and ms==3000);gif:close()
checks.exports_verified=true
file=assert(io.open(root..'production/turn_default/validation.json','w'));file:write(json.encode(checks));file:close()
local preview=Image(768,384,ColorMode.RGB)
local original=Image{fromFile=root..'default/idle_default_01.png'}
for y=0,383 do for x=0,767 do
 local src=x<384 and original or base
 preview:putPixel(x,y,src:getPixel(math.floor((x%384)/2),math.floor(y/2)))
end end
preview:saveAs(root..'production/turn_default/front_and_right_2x.png')
print(json.encode(checks))
