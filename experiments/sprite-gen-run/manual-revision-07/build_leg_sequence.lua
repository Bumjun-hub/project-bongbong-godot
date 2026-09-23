local root="C:/Users/USER/Documents/GitHub/project-bongbong-godot/experiments/sprite-gen-run/manual-revision-07"
local spr=app.open(root.."/run_expression_candidate.aseprite")
local prior=app.open(root.."/backup-revision-06/run_cycle_8.aseprite")
assert(spr and prior,"Missing Run sources")
local pc=app.pixelColor

local function splice(target,source,dx,dy)
 local out=Image(target)
 for y=138,191 do
  for x=0,191 do
   local sx,sy=x-dx,y-dy
   local pixel=0
   if sx>=0 and sx<192 and sy>=0 and sy<192 then pixel=source:getPixel(sx,sy) end
   if y>=141 then
    out:drawPixel(x,y,pixel)
   else
    local oldpixel=target:getPixel(x,y)
    local r,g,b,a=pc.rgbaR(oldpixel),pc.rgbaG(oldpixel),pc.rgbaB(oldpixel),pc.rgbaA(oldpixel)
    -- Keep the target shirt hem and its outline above the new hip pixels.
    local shirt=a>64 and ((r>115 and r>g*1.35 and r>b*1.2) or (r<80 and g<80 and b<80))
    if not shirt then out:drawPixel(x,y,pixel) end
   end
  end
 end
 return out
end

-- Pull the clean front sneaker inward and up on frame 6 so it is a passing
-- step, rather than the same extended foot seen on frame 1.
local cel6=spr.layers[1]:cel(6)
local source6=cel6.image
local recovery=Image(source6)
for y=137,191 do
 for x=0,191 do
  local front=math.exp(-0.5*(((x-116)/19)^2+((y-165)/17)^2))
  local back=math.exp(-0.5*(((x-75)/16)^2+((y-158)/14)^2))
  local sx=math.floor(x-(-10*front+4*back)+0.5)
  local sy=math.floor(y-(-4*front+2*back)+0.5)
  local pixel=0
  if sx>=0 and sx<192 and sy>=0 and sy<192 then pixel=source6:getPixel(sx,sy) end
  recovery:drawPixel(x,y,pixel)
 end
end
cel6.image=recovery

-- Give the push-off its own passing pose instead of repeating frame 5's contact.
local cel7=spr.layers[1]:cel(7)
cel7.image=splice(cel7.image,prior.layers[1]:cel(3).image,-2,3)

local function remove_isolated(img)
 local visited={}
 local largest={}
 local function alpha(x,y) return pc.rgbaA(img:getPixel(x,y)) end
 for y=0,191 do
  for x=0,191 do
   local index=y*192+x+1
   if not visited[index] and alpha(x,y)>=64 then
    local queue={{x,y}}
    visited[index]=true
    local head=1
    while head<=#queue do
     local p=queue[head]
     head=head+1
     for _,n in ipairs({{p[1]-1,p[2]},{p[1]+1,p[2]},{p[1],p[2]-1},{p[1],p[2]+1}}) do
      local nx,ny=n[1],n[2]
      if nx>=0 and nx<192 and ny>=0 and ny<192 then
       local ni=ny*192+nx+1
       if not visited[ni] and alpha(nx,ny)>=64 then
        visited[ni]=true
        queue[#queue+1]={nx,ny}
       end
      end
     end
    end
    if #queue>#largest then largest=queue end
   end
  end
 end
 assert(#largest>9000,"Main Run silhouette unexpectedly fragmented")
 local keep={}
 for _,p in ipairs(largest) do
  for oy=-2,2 do
   for ox=-2,2 do
    local xx,yy=p[1]+ox,p[2]+oy
    if xx>=0 and xx<192 and yy>=0 and yy<192 then keep[yy*192+xx+1]=true end
   end
  end
 end
 local out=Image(img)
 for y=0,191 do
  for x=0,191 do
   if not keep[y*192+x+1] then out:drawPixel(x,y,0) end
  end
 end
 return out
end
for frame=1,8 do
 local cel=spr.layers[1]:cel(frame)
 cel.image=remove_isolated(cel.image)
end

local output=root.."/run_expression_legs_candidate.aseprite"
spr:saveCopyAs(output)
io.write("__RESULT__"..json.encode({success=true,data={savedTo=output}}))
