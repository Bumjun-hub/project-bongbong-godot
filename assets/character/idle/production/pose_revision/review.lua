local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local folder=root..'production/pose_revision/'
local images={Image{fromFile=folder..'pockets_before.png'},Image{fromFile=root..'pockets/idle_pockets_01.png'},Image{fromFile=folder..'arms_crossed_before.png'},Image{fromFile=root..'arms_crossed/idle_arms_crossed_01.png'}}
local out=Image(640,464,ColorMode.RGB)
local background=app.pixelColor.rgba(235,234,229,255)
out:clear(background)
for i,im in ipairs(images) do
 local cellX=((i-1)%2)*320;local cellY=math.floor((i-1)/2)*232
 for y=98,155 do for x=55,134 do
   local color=im:getPixel(x,y)
   if app.pixelColor.rgbaA(color)>127 then for dy=0,3 do for dx=0,3 do out:putPixel(cellX+(x-55)*4+dx,cellY+(y-98)*4+dy,color) end end end
 end end
end
out:saveAs(folder..'arms_before_after_4x.png')
