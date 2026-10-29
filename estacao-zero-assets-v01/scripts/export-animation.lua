local root='C:/Users/bruno/Desktop/All/Projetos/Tokens Bar-assets-v01/'
local sprites={}
for _,name in ipairs({'io-explorer','brasa-mechanic','luma-botanist'}) do table.insert(sprites,assert(app.open(root..'source/'..name..'.aseprite'))) end
local target=Sprite(432,144,ColorMode.RGB);target:setPalette(sprites[1].palettes[1])
for fi=1,24 do
 if fi>1 then target:newEmptyFrame() end
 local im=Image(432,144,ColorMode.RGB);im:clear(app.pixelColor.rgba(23,44,56,255))
 for i,s in ipairs(sprites) do
  local flat=Image(48,48,ColorMode.RGB);flat:drawSprite(s,fi)
  for p in flat:pixels() do local v=p();if app.pixelColor.rgbaA(v)>0 then
   for dy=0,2 do for dx=0,2 do im:drawPixel((i-1)*144+p.x*3+dx,p.y*3+dy,v) end end
  end end
 end
 local c=target.layers[1]:cel(fi);if c then c.image=im else target:newCel(target.layers[1],fi,im,Point(0,0)) end
 target.frames[fi].duration=sprites[1].frames[fi].duration
end
target:saveCopyAs(root..'exports/crew-animation.gif')
target:close();for _,s in ipairs(sprites) do s:close() end
