local root=app.params.root
local source=Image{fromFile=root..'/source/ultimate-master.png'}
local palette=Palette{fromFile=root..'/source/agents-bar-64.gpl'}
local pc=app.pixelColor
local cache={}
local function nearest(r,g,b)
  local key=r*65536+g*256+b
  if cache[key] then return cache[key] end
  local best,dist=1,math.huge
  for j=1,#palette-1 do
    local c=palette:getColor(j)
    local d=2*(r-c.red)^2+4*(g-c.green)^2+3*(b-c.blue)^2
    if d<dist then best,dist=j,d end
  end
  cache[key]=best return best
end
-- Hand-checked bounds isolate whole new poses. All frames share 1:2 scale.
local bounds={{0,0,512,384},{512,0,512,384},{1024,0,512,384},{1536,0,512,416},{0,390,512,365},{512,416,524,339},{1040,416,496,339},{1536,416,512,339}}
local durations={360,220,170,400,200,220,280,500}
local s=Sprite(288,256,ColorMode.INDEXED)
s:setPalette(palette) s.transparentColor=0
s.layers[1].name='Pose completa'
local atlas=Image(1152,512,ColorMode.INDEXED)
local frames={}
for f,b in ipairs(bounds) do
  if f>1 then s:newEmptyFrame(f) end
  s.frames[f].duration=durations[f]/1000
  local img=Image(288,256,ColorMode.INDEXED)
  local ox=math.floor((576-b[3])/4)
  local oy=51
  if f==4 then oy=5 elseif f==5 then oy=63 elseif f>5 then oy=76 end
  for y=0,math.floor(b[4]/2)-1 do
    for x=0,math.floor(b[3]/2)-1 do
      local r,g,bl,n=0,0,0,0
      for dy=0,1 do for dx=0,1 do
        local c=source:getPixel(b[1]+x*2+dx,b[2]+y*2+dy)
        if pc.rgbaA(c)>=220 then
          r=r+pc.rgbaR(c) g=g+pc.rgbaG(c) bl=bl+pc.rgbaB(c) n=n+1
        end
      end end
      if n>=2 and x+ox<288 and y+oy<256 then
        img:drawPixel(x+ox,y+oy,nearest(math.floor(r/n),math.floor(g/n),math.floor(bl/n)))
      end
    end
  end
  if f==5 then
    for y=0,59 do for x=0,81 do
      local c=source:getPixel(1700+x*2,y*2)
      if pc.rgbaA(c)>=220 then
        img:drawPixel(71+x,33+y,nearest(pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c)))
      end
    end end
  end
  s:newCel(s.layers[1],f,img,Point(0,0))
  frames[f]=img
  atlas:drawImage(img,Point(((f-1)%4)*288,math.floor((f-1)/4)*256))
end
s:newTag(1,8).name='ultimate'
s:saveAs(root..'/ultimate.aseprite')
pcall(function() s:close() end)
palette=Palette{fromFile=root..'/source/agents-bar-64.gpl'}
for f,img in ipairs(frames) do img:saveAs{filename=root..'/frames/ultimate-'..string.format('%02d',f)..'.png',palette=palette} end
atlas:saveAs{filename=root..'/ultimate-sheet.png',palette=palette}
print('ultimate: 8 complete pose cels, 288x256, 64-color palette')
