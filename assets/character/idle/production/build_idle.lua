-- Offline Aseprite pixel authoring; no rig, rotation, interpolation or runtime code.
local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/'
local output=root..'idle/'
local base=Image{fromFile=root..'source/bongbong_sd17_base.png'}
local rgba=app.pixelColor.rgba
local colors={ink=rgba(24,14,20,255),skin=rgba(252,209,180,255),light=rgba(255,222,194,255),shade=rgba(235,170,138,255),deep=rgba(188,113,87,255),denim=rgba(96,140,181,255),denimLight=rgba(141,183,216,255),red=rgba(173,19,41,255)}
local function line(im,x0,y0,x1,y1,c)
  local dx,dy=math.abs(x1-x0),-math.abs(y1-y0)
  local sx,sy=x0<x1 and 1 or -1,y0<y1 and 1 or -1
  local err=dx+dy
  while true do
    im:putPixel(x0,y0,c)
    if x0==x1 and y0==y1 then break end
    local e=2*err
    if e>=dy then err=err+dy;x0=x0+sx end
    if e<=dx then err=err+dx;y0=y0+sy end
  end
end
local function poly(im,pts,c,outline)
  local minx,miny,maxx,maxy=192,192,0,0
  for _,p in ipairs(pts) do minx=math.min(minx,p[1]);miny=math.min(miny,p[2]);maxx=math.max(maxx,p[1]);maxy=math.max(maxy,p[2]) end
  for y=miny,maxy do for x=minx,maxx do
    local inside=false;local j=#pts
    for i=1,#pts do
      local a,b=pts[i],pts[j]
      if ((a[2]>y)~=(b[2]>y)) and (x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1]) then inside=not inside end
      j=i
    end
    if inside then im:putPixel(x,y,c) end
  end end
  if outline then for i,a in ipairs(pts) do local b=pts[i%#pts+1];line(im,a[1],a[2],b[1],b[2],outline) end end
end
local function clearOldArms(im)
  for y=131,152 do
    for x=57,78 do im:putPixel(x,y,0) end
    for x=112,132 do im:putPixel(x,y,0) end
  end
  -- Restore any original trouser pixels at the outer hip. Arms are not blue.
  for y=142,152 do for x=57,132 do
    local c=base:getPixel(x,y)
    if app.pixelColor.rgbaB(c)>app.pixelColor.rgbaR(c)+12 and app.pixelColor.rgbaB(c)>app.pixelColor.rgbaG(c) then im:putPixel(x,y,c) end
  end end
end
local revisedPoses=dofile(output..'production/pose_revision/pose_patch.lua')
local function pockets() return Image(revisedPoses.pockets) end
local function crossed() return Image(revisedPoses.arms_crossed) end
local poses={default=Image(base),pockets=pockets(),arms_crossed=crossed()}
local poseOrder={'default','pockets','arms_crossed'}
-- Holds intentionally share a drawing. All loops start/end in the same pose.
local states={
  default={durations={600,400,500,450,450,600},phases={0,1,2,2,1,0}},
  pockets={durations={750,500,450,650,550,700},phases={0,1,2,2,1,0}},
  arms_crossed={durations={650,450,500,600,450,650},phases={0,1,2,2,1,0}}
}
local function breathe(pose,kind,phase)
  if phase==0 then return Image(pose) end
  local result=Image(pose)
  -- Move upper-body pixels by exactly one grid cell; preserve widths and colors.
  -- Phase 1 lifts only shoulders/chest. Phase 2 carries the rigid head with them.
  local top=(phase==2) and 0 or 113
  local bottom=kind=='default' and 136 or (kind=='pockets' and 126 or 140)
  for y=top,bottom do for x=0,191 do result:putPixel(x,y,0) end end
  for y=top,bottom do for x=0,191 do
    local c=pose:getPixel(x,y)
    if y>0 then result:putPixel(x,y-1,c) end
  end end
  -- Reconnect at an interior shirt row instead of shifting hips/legs/feet.
  for x=0,191 do
    local c=pose:getPixel(x,bottom)
    if app.pixelColor.rgbaA(c)>0 then result:putPixel(x,bottom,c) end
  end
  if kind=='default' then
    -- Hanging arms respond after the shoulders, only at peak inhalation.
    for y=137,150 do for x=58,132 do
      if x<79 or x>111 then result:putPixel(x,y,pose:getPixel(x,y)) end
    end end
    if phase==2 then
      for y=131,151 do for x=58,132 do
        if (x<79 or x>111) then
          local c=pose:getPixel(x,y)
          local blue=app.pixelColor.rgbaB(c)>app.pixelColor.rgbaR(c)+12 and app.pixelColor.rgbaB(c)>app.pixelColor.rgbaG(c)
          if not blue then result:putPixel(x,y,0) end
        end
      end end
      for y=131,150 do for x=58,132 do
        if x<79 or x>111 then
          local c=pose:getPixel(x,y)
          local blue=app.pixelColor.rgbaB(c)>app.pixelColor.rgbaR(c)+12 and app.pixelColor.rgbaB(c)>app.pixelColor.rgbaG(c)
          if app.pixelColor.rgbaA(c)>0 and not blue then result:putPixel(x,y-1,c) end
        end
      end end
    end
  end
  return result
end
local metadata={canvas={192,192},anchor={95,174},blink_included=false,whole_sprite_scaling=false,states={}}
local overview=Image(192*3,192,ColorMode.RGB)
local framesByState={}
for index,kind in ipairs(poseOrder) do
  local publish=not (app.params['special-only']=='true' and kind=='default')
  local folder=output..kind..'/';app.fs.makeAllDirectories(folder)
  local def=states[kind];local name='idle_'..kind
  local spr=Sprite(192,192,ColorMode.RGB);spr.layers[1].name='Complete pixel frames'
  local sheet=Image(192*6,192,ColorMode.RGB)
  local frames={};local rects={};local unique={};local count=0
  for i,phase in ipairs(def.phases) do
    local im=breathe(poses[kind],kind,phase);frames[i]=im
    if i>1 then spr:newEmptyFrame() end
    spr:newCel(spr.layers[1],spr.frames[i],im,Point(0,0))
    spr.frames[i].duration=def.durations[i]/1000
    if publish then im:saveAs(folder..name..string.format('_%02d.png',i)) end
    sheet:drawImage(im,Point((i-1)*192,0))
    rects[i]={x=(i-1)*192,y=0,w=192,h=192,duration_ms=def.durations[i],phase=phase}
    local sum=0;for y=0,191 do for x=0,191 do sum=(sum+im:getPixel(x,y)*(x+1+y*193))%2147483647 end end
    if not unique[sum] then unique[sum]=true;count=count+1 end
  end
  local tag=spr:newTag(1,6);tag.name=string.upper(name)
  if publish then
    spr:saveAs(folder..name..'.aseprite')
    sheet:saveAs(folder..name..'.png')
    spr:saveCopyAs(folder..name..'.gif')
  end
  overview:drawImage(frames[1],Point((index-1)*192,0))
  local fullDuration=0;for _,ms in ipairs(def.durations) do fullDuration=fullDuration+ms end
  metadata.states[string.upper(name)]={directory=kind,sheet=name..'.png',source=name..'.aseprite',loop=true,frames=rects,total_duration_ms=fullDuration,unique_drawings=count}
  framesByState[kind]=frames
  spr:close()
end
overview:saveAs(output..'idle_poses.png')
local enlarged=Image(1152,384,ColorMode.RGB)
for y=0,383 do for x=0,1151 do enlarged:putPixel(x,y,overview:getPixel(math.floor(x/2),math.floor(y/2))) end end
enlarged:saveAs(output..'production/idle_poses_2x.png')
local f=assert(io.open(output..'manifest.json','w'));f:write(json.encode(metadata));f:close()
-- Verify actual completed frames, not just requested geometry.
local checks={base_head_preserved=true,feet_identical_to_base=true,legs_stable_in_loop=true,seamless_endpoints=true,max_head_translation_px=1,states={}}
for _,kind in ipairs(poseOrder) do
  local frames=framesByState[kind];local changed={}
  for i,im in ipairs(frames) do
    local n=0
    for y=0,191 do for x=0,191 do
      if im:getPixel(x,y)~=frames[1]:getPixel(x,y) then n=n+1 end
      if y>=153 and im:getPixel(x,y)~=base:getPixel(x,y) then checks.feet_identical_to_base=false end
      if y>=153 and im:getPixel(x,y)~=frames[1]:getPixel(x,y) then checks.legs_stable_in_loop=false end
    end end
    changed[i]=n
    for y=0,110 do for x=0,191 do
      local sy=y+(states[kind].phases[i]==2 and 1 or 0)
      if im:getPixel(x,y)~=base:getPixel(x,sy) then checks.base_head_preserved=false end
    end end
  end
  for y=0,191 do for x=0,191 do if frames[1]:getPixel(x,y)~=frames[6]:getPixel(x,y) then checks.seamless_endpoints=false end end end
  checks.states[kind]={changed_pixels_from_rest=changed}
end
f=assert(io.open(output..'production/validation.json','w'));f:write(json.encode(checks));f:close()
print(json.encode(checks))
