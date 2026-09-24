local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/'
local work=root..'experiments/idle-softening-01/'
local f=assert(io.open(work..'motion_maps.json','r')); local maps=json.decode(f:read('*a'));f:close()
local pc=app.pixelColor
local accepted=Image{fromFile=work..'idle_soft_01.png'}
local function channels(p) return pc.rgbaR(p),pc.rgbaG(p),pc.rgbaB(p),pc.rgbaA(p) end
local function mix(p,q,t)
 local r,g,b,a=channels(p);local s,u,v,c=channels(q)
 local z=a*(1-t)+c*t
 if z<8 then return 0 end
 return pc.rgba(math.floor((r*a*(1-t)+s*c*t)/z+0.5),math.floor((g*a*(1-t)+u*c*t)/z+0.5),math.floor((b*a*(1-t)+v*c*t)/z+0.5),math.floor(z+0.5))
end
for _,state in ipairs({'default','pockets','arms_crossed'}) do
 local original=Image{fromFile=root..'assets/character/idle/'..state..'_three_quarter_right/idle_'..state..'_three_quarter_right_01.png'}
 local base=Image(accepted)
 if state~='default' then
  for y=114,157 do for x=0,191 do
   local ar,rr,gg,bb=0,0,0,0
   for dy=-1,1 do for dx=-1,1 do
    local w=(dx==0 and 2 or 1)*(dy==0 and 2 or 1)/16
    local r,g,b,a=channels(original:getPixel(math.max(0,math.min(191,x+dx)),y+dy))
    ar=ar+a*w;rr=rr+r*a*w;gg=gg+g*a*w;bb=bb+b*a*w
   end end
   local blur=0
   if ar>8 then blur=pc.rgba(math.floor(rr/ar+0.5),math.floor(gg/ar+0.5),math.floor(bb/ar+0.5),math.floor(ar+0.5)) end
   local soft=mix(original:getPixel(x,y),blur,0.65)
   local t=math.min(1,(y-113)/2,(158-y)/4)
   base:drawPixel(x,y,mix(accepted:getPixel(x,y),soft,t))
  end end
 end
 local path=root..'assets/character/idle/soft_three_quarter_right/'..state..'/'
 local sprite=Sprite(192,192,ColorMode.RGB)
 sprite.layers[1].name='Approved soft Idle / preserved breathing'
 local sheet=Image(1152,192,ColorMode.RGB)
 for i=1,6 do
  if i>1 then sprite:newFrame() end
  local im=Image(192,192,ColorMode.RGB)
  for y=0,191 do for x=0,191 do im:drawPixel(x,y,base:getPixel(x,maps[state].rows[i][y+1])) end end
  local cel=sprite.layers[1]:cel(i)
  if cel then cel.image=im;cel.position=Point(0,0) else sprite:newCel(sprite.layers[1],i,im,Point(0,0)) end
  sprite.frames[i].duration=maps[state].durations[i]
  im:saveAs(path..string.format('idle_%02d.png',i))
  sheet:drawImage(im,Point((i-1)*192,0))
 end
 local tag=sprite:newTag(1,6);tag.name='idle_'..state
 sprite:saveAs(path..'idle_'..state..'.aseprite')
 sprite:saveCopyAs(path..'idle_'..state..'.gif')
 sheet:saveAs(path..'idle_'..state..'.png')
 print(state..': 6 frames, original timings preserved')
end
