-- Aseprite batch production pass: deterministic crop, area sampling and shared palette.
local source=app.params["source"]
local root=app.params["root"]
assert(source and root,"source and root parameters are required")
app.fs.makeAllDirectories(root.."/game/assets/items/48")
app.fs.makeAllDirectories(root.."/game/assets/items/96")
app.fs.makeAllDirectories(root.."/art-source/items")
local colors={"101522","1d2435","303b52","4b5973","697e9c","8fa7bd","b5c8d6","d8e5e9","f5f5ed",
"382719","654323","8e602e","b08340","d3a44f","e8c67c","f3dea6","fff0c4",
"0a2347","113d73","1b5d9e","3182c4","54a5dc","80c9ea",
"0a474e","146b77","2495ad","40c4d7","83e9ed","c6fff0",
"1c321d","31552a","4a7436","6c9845","95b958","c6d582","e4e9b3",
"402734","633947","865058","b87466","dd9a78","f3bd8a",
"292346","443369","654995","8a69b8","b190d5","d6b4ef",
"35352e","55574b","7d7e6a","aba68d","d3cbb4"}
local palette=Palette(#colors+1);palette:setColor(0,Color{r=0,g=0,b=0,a=0})
local rgb={}
for i,h in ipairs(colors) do
 local r,g,b=tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)
 rgb[i]={r,g,b};palette:setColor(i,Color{r=r,g=g,b=b,a=255})
end
local function nearest(r,g,b)
 local best,dist=1,1e20
 for i,c in ipairs(rgb) do
  local d=2*(r-c[1])^2+3*(g-c[2])^2+(b-c[3])^2
  if d<dist then best=i;dist=d end
 end
 local c=rgb[best];return app.pixelColor.rgba(c[1],c[2],c[3],255)
end
local groups={"weapons","armor","relics","materials"}
local catalog={}
for _,group in ipairs(groups) do
 local original=Image{fromFile=source.."/"..group..".png"}
 assert(original and original.width==1536 and original.height==1024,"Unexpected source image")
 for index=0,5 do
  local id=group.."-"..string.format("%02d",index+1)
  local rx=(index%3)*512
  local ry=math.floor(index/3)*512;local rh=512
  if group=="weapons" then ry=index<3 and 0 or 480;rh=index<3 and 480 or 544 end
  local minx,miny,maxx,maxy=512,rh,-1,-1
  for y=0,rh-1 do for x=0,511 do
   if app.pixelColor.rgbaA(original:getPixel(rx+x,ry+y))>=160 then
    minx=math.min(minx,x);miny=math.min(miny,y);maxx=math.max(maxx,x);maxy=math.max(maxy,y)
   end
  end end
  assert(maxx>=minx,"Empty item "..id)
  local w,h=maxx-minx+1,maxy-miny+1
  local scale=math.min(40/w,40/h)
  local dw,dh=math.max(1,math.floor(w*scale+.5)),math.max(1,math.floor(h*scale+.5))
  local ox,oy=math.floor((48-dw)/2),math.floor((48-dh)/2)
  local result=Image(48,48,ColorMode.RGB)
  for y=0,dh-1 do for x=0,dw-1 do
   local sx0=math.floor(x*w/dw);local sx1=math.max(sx0,math.ceil((x+1)*w/dw)-1)
   local sy0=math.floor(y*h/dh);local sy1=math.max(sy0,math.ceil((y+1)*h/dh)-1)
   local r,g,b,n,total=0,0,0,0,0
   for sy=sy0,sy1 do for sx=sx0,sx1 do
    local pixel=original:getPixel(rx+minx+sx,ry+miny+sy);total=total+1
    if app.pixelColor.rgbaA(pixel)>=160 then
     r=r+app.pixelColor.rgbaR(pixel);g=g+app.pixelColor.rgbaG(pixel);b=b+app.pixelColor.rgbaB(pixel);n=n+1
    end
   end end
   if n>0 and n/total>=.22 then result:drawPixel(ox+x,oy+y,nearest(r/n,g/n,b/n)) end
  end end
  local clean=Image(result)
  for y=1,46 do for x=1,46 do
   if app.pixelColor.rgbaA(result:getPixel(x,y))>0 then
    local neighbours=0
    for dy=-1,1 do for dx=-1,1 do
     if (dx~=0 or dy~=0) and app.pixelColor.rgbaA(result:getPixel(x+dx,y+dy))>0 then neighbours=neighbours+1 end
    end end
    if neighbours==0 then clean:drawPixel(x,y,0) end
   end
  end end
  clean:saveAs(root.."/game/assets/items/48/"..id..".png")
  local big=Image(96,96,ColorMode.RGB)
  for y=0,95 do for x=0,95 do big:drawPixel(x,y,clean:getPixel(math.floor(x/2),math.floor(y/2))) end end
  big:saveAs(root.."/game/assets/items/96/"..id..".png")
  local sprite=Sprite(48,48,ColorMode.RGB);sprite:setPalette(palette)
  sprite.layers[1].name="Pixel artwork | "..id;sprite.cels[1].image=clean
  sprite:saveAs(root.."/art-source/items/"..id..".aseprite");sprite:close()
  catalog[#catalog+1]={id=id,group=group,source=group..".png",sourceRect={rx+minx,ry+miny,w,h},size=48,padding=4}
 end
end
local f=assert(io.open(root.."/art-source/items/export-report.json","w"))
f:write(json.encode{application=tostring(app.version),method="Aseprite Lua batch: alpha bounds, area reduction, shared 53-color palette, hard alpha, isolated-pixel cleanup",items=catalog});f:close()
print("Exported "..#catalog.." Aseprite sources, 48px and 96px PNGs")

