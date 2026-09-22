local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local src=Image{fromFile=root..'production/turn_default/pose_reference.png'}
local a=app.pixelColor.rgbaA
local x0,y0,x1,y1=src.width,src.height,0,0
for y=0,src.height-1 do for x=0,src.width-1 do
 if a(src:getPixel(x,y))>=128 then x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y) end
end end
local h=156;local w=math.floor((x1-x0+1)*h/(y1-y0+1)+0.5)
local dx=math.floor(95-w/2+0.5)
local pose=Image(192,192,ColorMode.RGB)
for y=0,h-1 do for x=0,w-1 do
 local sx=math.min(x1,x0+math.floor((x+0.5)*(x1-x0+1)/w))
 local sy=math.min(y1,y0+math.floor((y+0.5)*(y1-y0+1)/h))
 local c=src:getPixel(sx,sy)
 if a(c)<128 then c=0 else c=app.pixelColor.rgba(app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c),255) end
 pose:putPixel(dx+x,18+y,c)
end end
-- Remove detached 1-3 pixel export specks, without modifying the silhouette.
local visited={}
for y=0,191 do for x=0,191 do
 local key=y*192+x
 if not visited[key] and a(pose:getPixel(x,y))>0 then
  local queue={{x,y}};local cursor=1;visited[key]=true
  while cursor<=#queue do
   local p=queue[cursor];cursor=cursor+1
   for oy=-1,1 do for ox=-1,1 do
    local nx,ny=p[1]+ox,p[2]+oy
    if nx>=0 and nx<192 and ny>=0 and ny<192 then
     local nk=ny*192+nx
     if not visited[nk] and a(pose:getPixel(nx,ny))>0 then visited[nk]=true;queue[#queue+1]={nx,ny} end
    end
   end end
  end
  if #queue<=3 then for _,p in ipairs(queue) do pose:putPixel(p[1],p[2],0) end end
 end
end end
-- Check the two sole contact rows. Correct a possible 1px export alignment
-- difference only in the foot region; no sprite scaling is used for breathing.
local soles={-1,-1}
for side=1,2 do for y=158,191 do for x=(side==1 and 0 or 96),(side==1 and 95 or 191) do
 if a(pose:getPixel(x,y))>=128 then soles[side]=math.max(soles[side],y) end
end end end
for side=1,2 do
 local delta=173-soles[side]
 assert(delta>=0 and delta<=1,'Unexpected foot alignment; manual review required')
 if delta==1 then
  local old=Image(pose)
  for y=174,159,-1 do for x=(side==1 and 0 or 96),(side==1 and 95 or 191) do pose:putPixel(x,y,old:getPixel(x,y-1)) end end
 end
end
pose:saveAs(root..'production/turn_default/pose.png')
local enlarged=Image(768,768,ColorMode.RGB)
for y=0,767 do for x=0,767 do enlarged:putPixel(x,y,pose:getPixel(math.floor(x/4),math.floor(y/4))) end end
enlarged:saveAs(root..'production/turn_default/pose_4x.png')
print(json.encode({source_bounds={x0,y0,x1,y1},destination={dx,18,w,156},original_sole_rows=soles}))
