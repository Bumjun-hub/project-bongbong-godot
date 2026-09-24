local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/'
local f=io.open(root..'experiments/detail-match-01/mapping.json','r');local sets=json.decode(f:read('*a'));f:close()
local pc=app.pixelColor
local ref=Image{fromFile=root..sets[1].reference}
local function sample(x,y)
 if x<0 or y<0 or x>=191 or y>=191 then return nil end
 local ix,iy=math.floor(x),math.floor(y);local fx,fy=x-ix,y-iy;local ar,rr,gg,bb=0,0,0,0
 for dy=0,1 do for dx=0,1 do
  local p=ref:getPixel(ix+dx,iy+dy);local a=pc.rgbaA(p);local w=(dx==0 and 1-fx or fx)*(dy==0 and 1-fy or fy)
  ar=ar+a*w;rr=rr+pc.rgbaR(p)*a*w;gg=gg+pc.rgbaG(p)*a*w;bb=bb+pc.rgbaB(p)*a*w
 end end
 if ar<96 then return nil end
 return {rr/ar,gg/ar,bb/ar,ar}
end
local function median(a) table.sort(a);return a[math.floor(#a/2)+1] end
for _,s in ipairs(sets) do
 local sprite=Sprite(192,192,ColorMode.RGB);local sheet=Image(192*#s.frames,192,ColorMode.RGB);local repaired=0
 for i,frame in ipairs(s.frames) do
  local src=Image{fromFile=root..frame.source};local im=Image(src);local m=frame.affine
  for _,span in ipairs(frame.head) do for x=span[2],span[3] do
   local y=span[1];local c=sample(m[1]*x+m[2]*y+m[3],m[4]*x+m[5]*y+m[6]);local p=src:getPixel(x,y)
   if c then
    local use=true
    if s.name=='run_bouncy' then use=math.max(c[1],c[2],c[3])<175 and math.max(c[1],c[2],c[3])-math.min(c[1],c[2],c[3])<55 end
    if use then im:drawPixel(x,y,pc.rgba(math.floor(c[1]+.5),math.floor(c[2]+.5),math.floor(c[3]+.5),pc.rgbaA(p))) end
   end
  end end
  for kind,spans in pairs(frame.materials) do
   local mask={};for _,span in ipairs(spans) do for x=span[2],span[3] do mask[span[1]*192+x]=true end end
   for _,span in ipairs(spans) do for x=span[2],span[3] do
    local y=span[1];local rs,gs,bs={},{},{}
    for dy=-1,1 do for dx=-1,1 do if (dx~=0 or dy~=0) and mask[(y+dy)*192+x+dx] then
     local p=src:getPixel(x+dx,y+dy);table.insert(rs,pc.rgbaR(p));table.insert(gs,pc.rgbaG(p));table.insert(bs,pc.rgbaB(p))
    end end end
    if #rs>=6 then
     local r,g,b=median(rs),median(gs),median(bs);local p=src:getPixel(x,y)
     local dev=math.abs(pc.rgbaR(p)-r)+math.abs(pc.rgbaG(p)-g)+math.abs(pc.rgbaB(p)-b)
     local spread=(rs[#rs]-rs[1])+(gs[#gs]-gs[1])+(bs[#bs]-bs[1])
     if dev>28 and spread<105 then im:drawPixel(x,y,pc.rgba(r,g,b,pc.rgbaA(p)));repaired=repaired+1 end
    end
   end end
  end
  if i>1 then sprite:newFrame() end
  local cel=sprite.layers[1]:cel(i);if cel then cel.image=im;cel.position=Point(0,0) else sprite:newCel(sprite.layers[1],i,im,Point(0,0)) end
  sprite.frames[i].duration=frame.duration;im:saveAs(root..frame.output);sheet:drawImage(im,Point((i-1)*192,0))
 end
 sprite.layers[1].name='IDLE detail reference / tracked motion'
 local tag=sprite:newTag(1,#s.frames);tag.name=s.name
 sprite:saveAs(root..s.output..'/'..s.name..'.aseprite');sprite:saveCopyAs(root..s.output..'/'..s.name..'.gif');sheet:saveAs(root..s.output..'/'..s.name..'.png')
 print(s.name..': complete, isolated clothing pixels repaired '..repaired)
end
