local root=assert(app.params['root'])
local count=0
for _,group in ipairs({'weapons','armor','relics','materials'}) do
 for n=1,6 do
  local id=group..'-'..string.format('%02d',n)
  local s=Sprite{fromFile=root..'/art-source/items/'..id..'.aseprite'}
  local actual=Image(48,48,ColorMode.RGB);actual:drawSprite(s,1)
  local png=Image{fromFile=root..'/game/assets/items/48/'..id..'.png'}
  local big=Image{fromFile=root..'/game/assets/items/96/'..id..'.png'}
  assert(s.width==48 and s.height==48 and #s.frames==1 and #s.layers==1,id..' source')
  for y=0,47 do for x=0,47 do
   local c=actual:getPixel(x,y);local a=app.pixelColor.rgbaA(c)
   assert(c==png:getPixel(x,y),id..' roundtrip')
   assert(a==0 or a==255,id..' alpha')
   if x<4 or x>43 or y<4 or y>43 then assert(a==0,id..' padding') end
   for dy=0,1 do for dx=0,1 do assert(big:getPixel(x*2+dx,y*2+dy)==c,id..' exact 2x') end end
  end end
  s:close();count=count+1
 end
end
print('PASS '..count..' editable sources: exact PNG roundtrip, hard alpha, 4px padding, nearest 2x')
