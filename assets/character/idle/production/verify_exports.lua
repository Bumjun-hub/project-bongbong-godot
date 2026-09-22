local root='C:/Users/USER/Documents/GitHub/project-bongbong-godot/assets/character/idle/'
local f=assert(io.open(root..'manifest.json'));local manifest=json.decode(f:read('*a'));f:close()
local report={ok=true,states={}}
for name,state in pairs(manifest.states) do
  local folder=root..state.directory..'/'
  local source=app.open(folder..state.source)
  assert(source.width==192 and source.height==192 and #source.frames==6,name..' source canvas/frame count')
  assert(#source.tags==1 and source.tags[1].name==name,name..' source tag')
  local sheet=Image{fromFile=folder..state.sheet}
  assert(sheet.width==1152 and sheet.height==192,name..' sheet size')
  local gif=app.open(folder..string.lower(name)..'.gif')
  local gifMs=0;for _,frame in ipairs(gif.frames) do gifMs=gifMs+math.floor(frame.duration*1000+0.5) end
  assert(gifMs==state.total_duration_ms,name..' GIF duration')
  local total=0;local exact=true
  for i,frame in ipairs(source.frames) do
    assert(math.floor(frame.duration*1000+0.5)==state.frames[i].duration_ms,name..' duration')
    total=total+math.floor(frame.duration*1000+0.5)
    local png=Image{fromFile=folder..string.lower(name)..string.format('_%02d.png',i)}
    assert(png.width==192 and png.height==192,name..' frame dimensions')
    local cel=source.layers[1]:cel(i)
    for y=0,191 do for x=0,191 do
      local c=png:getPixel(x,y);local a=app.pixelColor.rgbaA(c)
      local sx,sy=x-cel.position.x,y-cel.position.y
      local v=(sx>=0 and sy>=0 and sx<cel.image.width and sy<cel.image.height) and cel.image:getPixel(sx,sy) or 0
      if a>0 or app.pixelColor.rgbaA(v)>0 then assert(c==v,name..' Aseprite/PNG mismatch') end
      local s=sheet:getPixel(x+(i-1)*192,y)
      if a>0 or app.pixelColor.rgbaA(s)>0 then assert(c==s,name..' Sheet/PNG mismatch') end
    end end
  end
  assert(total==state.total_duration_ms,name..' total duration')
  report.states[name]={png_aseprite_sheet_exact=true,aseprite_frames=6,gif_frames=#gif.frames,total_duration_ms=total}
  source:close();gif:close()
end
f=assert(io.open(root..'production/export_validation.json','w'));f:write(json.encode(report));f:close()
print(json.encode(report))
