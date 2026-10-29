local root='C:/Users/bruno/Desktop/All/Projetos/Tokens Bar-assets-v01/'
local names={'io-explorer','brasa-mechanic','luma-botanist'}
local log={}
for _,name in ipairs(names) do
 local s=assert(app.open(root..'source/'..name..'.aseprite'))
 assert(s.width==48 and s.height==48 and #s.frames==24 and #s.layers==3 and #s.tags==5,name)
 local sheet=Image{fromFile=root..'exports/'..name..'-sheet.png'}
 local metaFile=assert(io.open(root..'exports/'..name..'.json','r'));local meta=json.decode(metaFile:read('*a'));metaFile:close()
 assert(sheet.width==288 and sheet.height==240)
 local fi=1;local unique={}
 for _,tag in ipairs(s.tags) do
  local a=assert(meta.animations[tag.name])
  for _,r in ipairs(a.frames) do
   local flat=Image(48,48,ColorMode.RGB);flat:drawSprite(s,fi)
   assert(math.abs(s.frames[fi].duration-r.duration/1000)<0.002)
   local opaque,trans=0,0
   for p in flat:pixels() do
    assert(p()==sheet:getPixel(r.x+p.x,r.y+p.y),name..' mismatch '..fi)
    local alpha=app.pixelColor.rgbaA(p());assert(alpha==0 or alpha==255)
    if alpha==0 then trans=trans+1 else opaque=opaque+1 end
   end
   assert(opaque>0 and trans>0)
   unique[flat.bytes]=true
   fi=fi+1
  end
 end
 local n=0;for _ in pairs(unique) do n=n+1 end;assert(n>=12)
 table.insert(log,name..': OK, 24 frames / 5 tags / 3 layers; '..n..' distinct frames; atlas pixels and timings match, binary alpha.')
 s:close()
end
local s=assert(app.open(root..'source/world.aseprite'));assert(s.width==640 and s.height==192 and #s.layers==6);s:close()
table.insert(log,'world: OK, 640x192, six editable layers.')
local h=assert(app.open(root..'source/hud.aseprite'));assert(#h.slices==10);h:close()
local p=assert(app.open(root..'source/props.aseprite'));assert(#p.slices==12);p:close()
table.insert(log,'hud: 10 named slices; props: 12 named slices. OK.')
local f=assert(io.open(root..'scripts/validation.txt','w'));f:write(table.concat(log,'\n'));f:close()
