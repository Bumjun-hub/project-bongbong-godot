-- Offline baked pixel frames; never used at runtime.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local prod=root..'production/turn_specials/'
local approved=Image{fromFile=root..'default_three_quarter_right/idle_default_three_quarter_right_01.png'}
local recipes={
 arms_crossed={durations={650,450,500,600,450,650},bottom=139,total=3300},
 pockets={durations={750,500,450,650,550,700},bottom=126,total=3600}
}
local phases={0,1,2,2,1,0}
local report={ok=true,states={}}
for _,kind in ipairs({'arms_crossed','pockets'}) do
 local recipe=recipes[kind]
 local name='idle_'..kind..'_three_quarter_right'
 local out=root..kind..'_three_quarter_right/'
 app.fs.makeAllDirectories(out)
 local pose=Image{fromFile=prod..kind..'_pose.png'}
 local frames={};local rects={}
 local sheet=Image(1152,192,ColorMode.RGB)
 local spr=Sprite(192,192,ColorMode.RGB);spr.layers[1].name='Complete pixel frames'
 for i,phase in ipairs(phases) do
  local im=Image(pose)
  if phase>0 then
   local top=phase==2 and 0 or 115
   for y=top,recipe.bottom do for x=0,191 do im:putPixel(x,y,0) end end
   for y=top,recipe.bottom do for x=0,191 do
    if y>0 then im:putPixel(x,y-1,pose:getPixel(x,y)) end
   end end
   for x=0,191 do im:putPixel(x,recipe.bottom,pose:getPixel(x,recipe.bottom)) end
  end
  frames[i]=im
  if i>1 then spr:newEmptyFrame() end
  spr:newCel(spr.layers[1],spr.frames[i],im,Point(0,0))
  spr.frames[i].duration=recipe.durations[i]/1000
  im:saveAs(out..name..string.format('_%02d.png',i))
  sheet:drawImage(im,Point((i-1)*192,0))
  rects[i]={x=(i-1)*192,y=0,w=192,h=192,duration_ms=recipe.durations[i],phase=phase}
 end
 local tag=spr:newTag(1,6);tag.name=string.upper(name)
 spr:saveAs(out..name..'.aseprite');spr:saveCopyAs(out..name..'.gif');sheet:saveAs(out..name..'.png');spr:close()
 local manifest={canvas={192,192},anchor={95,174},facing='screen-right-three-quarter',state=string.upper(name),loop=true,total_duration_ms=recipe.total,frames=rects,sheet=name..'.png',source=name..'.aseprite',blink_included=false}
 local file=assert(io.open(out..'manifest.json','w'));file:write(json.encode(manifest));file:close()
 local check={head_matches_approved=true,feet_match_approved=true,feet_fixed=true,loop_seamless=frames[1]:isEqual(frames[6]),max_head_offset_px=1,changed_pixels={}}
 for i,im in ipairs(frames) do
  local changed=0
  for y=0,191 do for x=0,191 do
   if im:getPixel(x,y)~=pose:getPixel(x,y) then changed=changed+1 end
   if y<=112 then
    local sy=y+(phases[i]==2 and 1 or 0)
    if im:getPixel(x,y)~=approved:getPixel(x,sy) then check.head_matches_approved=false end
   end
   if y>=153 and im:getPixel(x,y)~=approved:getPixel(x,y) then check.feet_match_approved=false end
   if y>=153 and im:getPixel(x,y)~=pose:getPixel(x,y) then check.feet_fixed=false end
  end end
  check.changed_pixels[i]=changed
 end
 assert(check.head_matches_approved and check.feet_match_approved and check.feet_fixed and check.loop_seamless)
 local saved=app.open(out..name..'.aseprite')
 assert(saved.width==192 and saved.height==192 and #saved.frames==6)
 local savedSheet=Image{fromFile=out..name..'.png'}
 assert(savedSheet.width==1152 and savedSheet.height==192)
 for i,frame in ipairs(saved.frames) do
  assert(math.floor(frame.duration*1000+0.5)==recipe.durations[i])
  local png=Image{fromFile=out..name..string.format('_%02d.png',i)}
  local cel=saved.layers[1]:cel(i)
  for y=0,191 do for x=0,191 do
   local sx,sy=x-cel.position.x,y-cel.position.y
   local c=(sx>=0 and sy>=0 and sx<cel.image.width and sy<cel.image.height) and cel.image:getPixel(sx,sy) or 0
   assert(c==frames[i]:getPixel(x,y),'Aseprite frame differs')
   assert(png:getPixel(x,y)==c,'PNG frame differs')
   assert(savedSheet:getPixel((i-1)*192+x,y)==c,'Sheet frame differs')
  end end
 end
 saved:close()
 local gif=app.open(out..name..'.gif');local total=0
 for _,frame in ipairs(gif.frames) do total=total+math.floor(frame.duration*1000+0.5) end
 assert(#gif.frames==6 and total==recipe.total);gif:close()
 check.exports_verified=true;check.total_duration_ms=total
 report.states[kind]=check
end
local file=assert(io.open(prod..'validation.json','w'));file:write(json.encode(report));file:close()
print(json.encode(report))
