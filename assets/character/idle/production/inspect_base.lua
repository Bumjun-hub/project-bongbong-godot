local root = 'C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/'
local src = Image{fromFile=root..'source/bongbong_sd17_base.png'}
local out = Image(768,768,ColorMode.RGB)
for y=0,767 do for x=0,767 do out:putPixel(x,y,src:getPixel(math.floor(x/4),math.floor(y/4))) end end
out:saveAs(root..'idle/production/base_4x.png')
local counts={}
for y=113,150 do for x=62,128 do local c=src:getPixel(x,y); if app.pixelColor.rgbaA(c)>127 then counts[c]=(counts[c] or 0)+1 end end end
local entries={};for c,n in pairs(counts) do entries[#entries+1]={c=c,n=n} end
table.sort(entries,function(a,b)return a.n>b.n end)
for i=1,math.min(30,#entries) do local c=entries[i].c;print(string.format('%d,%d,%d = %d',app.pixelColor.rgbaR(c),app.pixelColor.rgbaG(c),app.pixelColor.rgbaB(c),entries[i].n)) end
