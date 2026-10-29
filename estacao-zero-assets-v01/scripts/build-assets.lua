-- Estacao Zero: original pixel assets authored through the Aseprite Lua API.
local root = 'C:/Users/bruno/Desktop/All/Projetos/Tokens Bar-assets-v01/'
local out = root .. 'exports/'
local pc = app.pixelColor
local hex = {'172C38','254854','3E6B70','75989B','B8C8BC','E8DDC3','FFF0CC','784737','B96843','DC8B4E','F0B65A','6C8454','A7B874','D5DDA2','584B60','86C9B2'}
local C = {}
local palette = Palette(#hex+1)
palette:setColor(0,Color{r=0,g=0,b=0,a=0})
for i,h in ipairs(hex) do
 local r,g,b=tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)
 C[i]=pc.rgba(r,g,b,255); palette:setColor(i,Color{r=r,g=g,b=b,a=255})
end
local function img(w,h) return Image(w,h,ColorMode.RGB) end
local function dot(im,x,y,c)
 x,y=math.floor(x),math.floor(y)
 if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,C[c] or 0) end
end
local function rect(im,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do dot(im,xx,yy,c) end end
end
local function line(im,x0,y0,x1,y1,c)
 local dx,dy=math.abs(x1-x0),math.abs(y1-y0)
 local sx,sy=x0<x1 and 1 or -1,y0<y1 and 1 or -1
 local e=dx-dy
 while true do
  dot(im,x0,y0,c); if x0==x1 and y0==y1 then break end
  local q=2*e; if q>-dy then e=e-dy; x0=x0+sx end; if q<dx then e=e+dx; y0=y0+sy end
 end
end
local function ellipse(im,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do
  if ((xx-x+0.5)/w*2-1)^2+((yy-y+0.5)/h*2-1)^2<=1 then dot(im,xx,yy,c) end
 end end
end
local function box(im,x,y,w,h,c,hl)
 rect(im,x+2,y,w-4,h,1);rect(im,x,y+2,w,h-4,1)
 rect(im,x+2,y+1,w-4,h-2,c);rect(im,x+1,y+2,w-2,h-4,c)
 if hl then line(im,x+3,y+1,x+w-4,y+1,hl);line(im,x+1,y+3,x+1,y+h-4,hl) end
end
local function blit(dst,src,x,y) dst:drawImage(src,Point(x,y)) end
local function scale(src,n)
 local dst=img(src.width*n,src.height*n)
 for p in src:pixels() do local v=p();if v~=0 then for dy=0,n-1 do for dx=0,n-1 do dst:drawPixel(p.x*n+dx,p.y*n+dy,v) end end end end
 return dst
end
local function write(name,data)
 local f=assert(io.open(root..name,'w')); f:write(data); f:close()
end
local function saveImage(im,name) im:saveAs(out..name..'.png') end
local function makeSprite(name,w,h,layers,frames)
 local s=Sprite(w,h,ColorMode.RGB);s:setPalette(palette)
 local first=s.layers[1];first.name=layers[1]
 for i=2,#layers do local l=s:newLayer();l.name=layers[i] end
 for i=2,frames do s:newEmptyFrame() end
 return s
end
local function cel(s,li,fi,im)
 local existing=s.layers[li]:cel(fi)
 if existing then existing.image=im else s:newCel(s.layers[li],fi,im,Point(0,0)) end
end
local function static(name,im)
 local s=makeSprite(name,im.width,im.height,{'art'},1);cel(s,1,1,im)
 s:saveAs(root..'source/'..name..'.aseprite');saveImage(im,name);s:close()
end
local function plant(im,x,y,n)
 rect(im,x,y,2,n,12)
 for j=0,n-3,4 do ellipse(im,x-4,y+j,5,3,13);ellipse(im,x+1,y+j+2,5,3,12) end
 dot(im,x,y,14)
end
local function panelLines(im,x,y,w,h)
 line(im,x,y,x+w,y,3);line(im,x+w,y,x+w,y+h,1)
 dot(im,x+2,y+2,4);dot(im,x+w-2,y+2,4)
end

-- Character animation: 48 x 48, fixed anchor (24,44), independent body / gear / FX.
local anims={{name='idle',n=4,ms=220},{name='walk',n=6,ms=110},{name='work',n=4,ms=160},{name='wait',n=4,ms=280},{name='celebrate',n=6,ms=120}}
local characters={}
local function robot(kind,state,k)
 local body,gear,fx=img(48,48),img(48,48),img(48,48)
 local walk=state=='walk';local work=state=='work';local wait=state=='wait';local cheer=state=='celebrate'
 local bob=walk and ({0,-1,-1,0,-1,-1})[k] or (state=='idle' and (k==3 and -1 or 0) or 0)
 if cheer then bob=({0,-2,-5,-5,-2,0})[k] end
 local shift=walk and ({-2,-1,1,2,1,-1})[k] or 0
 local base=kind==1 and 6 or (kind==2 and 9 or 12)
 local light=kind==1 and 7 or (kind==2 and 10 or 13)
 local shade=kind==1 and 4 or (kind==2 and 8 or 2)
 local wide=kind==2 and 2 or 0
 -- Moving hips, feet, and alternating strides retain a stable floor.
 box(body,16-shift,35+bob,6,8,shade,base);box(body,26+shift,35+bob,6,8,shade,base)
 rect(body,14-shift,41+bob,9,3,1);rect(body,25+shift,41+bob,9,3,1)
 line(body,15-shift,41+bob,21-shift,41+bob,4);line(body,26+shift,41+bob,32+shift,41+bob,4)
 box(body,15-wide,24+bob,19+wide*2,14,shade,base)
 rect(body,17-wide,26+bob,15+wide*2,8,base);line(body,18,26+bob,28,26+bob,light)
 box(body,20,29+bob,7,5,2,3);dot(body,22,31+bob,11);dot(body,24,31+bob,16)
 rect(body,21,22+bob,8,3,1)
 if kind==1 then
  ellipse(body,13,9+bob,24,18,1);ellipse(body,14,10+bob,22,16,base)
  rect(body,18,10+bob,13,2,light);ellipse(body,24,13+bob,12,11,1)
  rect(body,26,15+bob,7,6,2);rect(body,29,16+bob,2,4,7)
  if state=='idle' and k==4 then rect(body,29,16+bob,2,4,2);rect(body,29,18+bob,3,1,7) end
  box(gear,9,25+bob,6,11,8,9);line(gear,16,8+bob,16,4+bob,4);rect(gear,15,2+bob,3,3,11)
  rect(gear,13,17+bob,3,5,4);dot(gear,14,18+bob,7)
 elseif kind==2 then
  box(body,14,12+bob,23,14,shade,base);rect(body,16,12+bob,18,3,light)
  box(body,22,16+bob,13,7,1,3);rect(body,27,18+bob,3,3,11)
  box(gear,8,25+bob,7,12,8,9);rect(gear,9,22+bob,4,4,2);rect(gear,10,20+bob,2,3,4)
  rect(gear,16,27+bob,3,7,8);rect(gear,31,27+bob,3,7,8)
 else
  box(body,16,12+bob,19,15,2,12);rect(body,18,13+bob,14,3,13)
  box(body,23,17+bob,10,7,1,3);rect(body,27,19+bob,2,3,14)
  box(gear,6,15+bob,10,22,2,4);box(gear,7,13+bob,8,17,3,4)
  plant(gear,10,17+bob,10);line(gear,8,15+bob,8,24+bob,5)
  rect(gear,6,29+bob,10,6,12);line(gear,7,30+bob,14,30+bob,13)
 end
 local armY=28+bob+(walk and (shift>0 and -1 or 1) or 0)
 box(body,11-wide,armY,6,9,shade,base)
 if cheer then
  box(body,32+wide,19+bob,6,10,base,light);rect(body,33+wide,17+bob,4,4,4)
 elseif wait then
  box(body,32+wide,23+bob,6,8,base,light);box(gear,35,19+bob,5,7,2,4);dot(gear,37,21+bob,11)
 else
  box(body,32+wide,armY-(work and k%2 or 0),6,9,base,light);rect(body,33+wide,armY+7,4,3,4)
 end
 if work then
  if kind==1 then
   box(gear,36,29+bob,8,6,2,4);rect(gear,39,30+bob,3,2,16)
   line(fx,44,27+k,46,27+k,16);dot(fx,46,25+k,5)
  elseif kind==2 then
   local ty=({23,20,27,27})[k];rect(gear,38,ty,2,12,4);box(gear,35,ty,9,5,2,4)
   if k>=3 then dot(fx,44,38,11);line(fx,43,34,45,32,11);dot(fx,47,36,7) end
  else
   box(gear,36,31+bob,7,6,9,10);line(gear,42,32+bob,45,29+bob,4)
   if k%2==0 then dot(fx,45,33,16);dot(fx,46,36,16);dot(fx,47,39,16) end
  end
 end
 if wait and k%2==1 then box(fx,34,3,9,10,6,7);rect(fx,38,5,1,3,8);dot(fx,38,9,8) end
 if cheer and k>1 and k<6 then
  local d=k%2;line(fx,8,9-d,8,13-d,11);line(fx,6,11-d,10,11-d,11)
  dot(fx,39,7+d,16);dot(fx,42,12+d,7)
 end
 return {body,gear,fx}
end
for kind,name in ipairs({'io-explorer','brasa-mechanic','luma-botanist'}) do
 local n=0;for _,a in ipairs(anims) do n=n+a.n end
 local s=makeSprite(name,48,48,{'body','equipment','effects'},n)
 local sheet=img(48*6,48*5);local fi=1;local meta={name=name,width=48,height=48,pivot={x=24,y=44},direction='right',animations={}}
 characters[kind]={}
 for row,a in ipairs(anims) do
  local frames={};local start=fi
  for k=1,a.n do
   local ls=robot(kind,a.name,k);local flat=img(48,48)
   for li,im in ipairs(ls) do cel(s,li,fi,im);blit(flat,im,0,0) end
   s.frames[fi].duration=a.ms/1000;blit(sheet,flat,(k-1)*48,(row-1)*48)
   table.insert(frames,{x=(k-1)*48,y=(row-1)*48,w=48,h=48,duration=a.ms})
   if k==1 then characters[kind][a.name]=flat end
   fi=fi+1
  end
  local tag=s:newTag(start,fi-1);tag.name=a.name
  meta.animations[a.name]={loop=true,frames=frames}
 end
 s:saveAs(root..'source/'..name..'.aseprite');saveImage(sheet,name..'-sheet')
 write('exports/'..name..'.json',json.encode(meta));s:close()
end

-- Independently reusable building modules, all sharing the same floor baseline.
local modules={}
local function module(name,w,h,draw)
 local im=img(w,h);draw(im);modules[name]=im;static(name,im)
end
module('module-workshop',128,112,function(im)
 box(im,12,26,104,82,4,5);rect(im,15,37,98,68,6)
 rect(im,20,21,88,8,1);rect(im,24,18,80,9,4);rect(im,27,17,74,3,5)
 rect(im,10,40,108,5,1);rect(im,11,40,106,2,3)
 for _,x in ipairs({21,98}) do rect(im,x,25,6,81,2);line(im,x+1,26,x+1,104,3);for y=30,102,12 do dot(im,x+3,y,4) end end
 box(im,48,54,35,53,1,3);rect(im,51,58,29,48,8);rect(im,53,59,25,45,9)
 rect(im,54,62,23,3,10);rect(im,57,74,17,2,8);rect(im,57,87,17,2,8)
 box(im,7,53,37,7,8,10);line(im,12,59,12,77,1);line(im,40,59,40,77,1)
 box(im,14,66,25,22,2,4);rect(im,17,69,19,15,3);line(im,27,69,27,83,1)
 box(im,83,63,12,24,2,3);for y=67,82,4 do line(im,86,y,92,y,1) end
 ellipse(im,55,29,20,20,1);ellipse(im,57,31,16,16,3);ellipse(im,59,33,12,12,11);line(im,59,34,64,34,7)
 rect(im,105,9,7,21,1);rect(im,106,10,5,19,8);rect(im,103,8,11,4,4)
 box(im,76,7,22,12,2,4);for x=80,92,4 do line(im,x,10,x,16,1) end
 box(im,29,9,19,11,8,9);plant(im,36,0,10)
 rect(im,11,106,107,6,1);line(im,13,107,115,107,4)
 box(im,53,50,25,6,2,3);rect(im,58,52,15,2,11)
end)
module('module-greenhouse',112,96,function(im)
 box(im,6,18,100,73,2,4);rect(im,10,28,92,52,3)
 rect(im,16,15,80,5,1);rect(im,19,13,74,5,4);line(im,22,13,90,13,5)
 for x=12,92,20 do
  rect(im,x,25,16,50,2);rect(im,x+1,26,14,47,3)
  line(im,x+3,29,x+3,49,5);line(im,x+5,28,x+8,28,5)
  box(im,x,66,17,14,8,9);plant(im,x+7,38+(x%3),29)
 end
 for x=8,104,24 do rect(im,x,23,3,61,4);line(im,x,26,x,79,5) end
 rect(im,5,78,102,5,1);rect(im,6,79,100,2,4)
 box(im,6,84,100,10,2,4);for x=14,98,14 do rect(im,x,87,7,3,3) end
 plant(im,31,6,16);plant(im,76,5,14)
end)
module('module-observatory',80,128,function(im)
 box(im,17,67,50,58,4,5);rect(im,22,73,40,49,6)
 for _,x in ipairs({22,56}) do rect(im,x,74,4,48,2);line(im,x,75,x,119,3) end
 box(im,31,94,21,30,2,3);box(im,34,98,15,12,1,3);rect(im,37,100,9,8,11)
 box(im,10,64,64,9,8,10);line(im,13,58,13,64,3);line(im,70,58,70,64,3);line(im,13,58,70,58,3)
 rect(im,38,45,7,19,2);line(im,39,46,39,62,4)
 -- Stepped parabolic dish, side-on and deliberately low resolution.
 for y=0,27 do local w=math.floor(9+y*1.3);rect(im,17+math.floor(y*.35),18+y,w,1,1);rect(im,19+math.floor(y*.35),19+y,math.max(1,w-4),1,y<5 and 10 or 8) end
 line(im,25,24,58,40,9);line(im,42,40,63,19,4);box(im,60,15,6,6,9,11)
 rect(im,12,5,2,58,4);rect(im,11,0,4,6,10);line(im,7,24,19,24,2);dot(im,12,1,7)
 rect(im,15,123,54,5,1)
end)
module('module-dock',96,48,function(im)
 rect(im,2,33,92,7,1);rect(im,3,33,90,3,4);rect(im,8,40,5,8,2);rect(im,82,40,5,8,2)
 for x=13,80,10 do rect(im,x,36,5,2,11) end
 box(im,28,17,48,16,6,7);rect(im,36,12,25,6,6);rect(im,40,11,18,3,7)
 box(im,47,15,21,10,2,4);line(im,51,16,61,16,5)
 rect(im,23,25,13,5,8);rect(im,72,25,10,5,8);rect(im,33,31,7,2,2);rect(im,64,31,7,2,2)
end)
module('tile-platform',32,24,function(im)
 rect(im,0,0,32,24,1);rect(im,0,1,32,3,5);rect(im,0,4,32,5,4);rect(im,0,10,32,9,2)
 line(im,0,9,31,9,1);panelLines(im,1,12,28,5);rect(im,3,20,7,4,3);rect(im,23,20,6,4,3)
end)

-- Props: fixed 32 px cells, named slices and separate PNGs.
local props=img(32*6,32*2);local propsMeta={cellSize=32,items={}}
local propNames={'crate','battery','planter','terminal','pipe-elbow','beacon','toolbox','ore','sapling','cargo','cable','antenna'}
for i,name in ipairs(propNames) do
 local im=img(32,32)
 if name=='crate' then box(im,5,9,23,22,8,10);rect(im,9,13,15,14,9);line(im,9,13,23,26,8);rect(im,14,10,4,20,10)
 elseif name=='battery' then box(im,10,7,14,24,2,4);rect(im,13,4,8,3,4);for y=12,24,5 do rect(im,13,y,8,3,16) end
 elseif name=='planter' then box(im,5,21,24,10,8,9);plant(im,12,6,17);plant(im,23,11,12)
 elseif name=='terminal' then box(im,5,7,23,17,2,4);rect(im,8,10,17,10,1);line(im,10,13,17,13,16);line(im,10,16,22,16,3);rect(im,15,24,4,5,4);rect(im,9,29,17,2,2)
 elseif name=='pipe-elbow' then rect(im,4,6,9,21,1);rect(im,6,7,5,18,8);rect(im,8,21,21,8,1);rect(im,10,22,18,5,9);rect(im,3,5,11,4,4);rect(im,26,20,4,10,4)
 elseif name=='beacon' then box(im,10,23,14,8,2,4);rect(im,15,10,4,13,4);box(im,12,5,10,9,8,11);rect(im,14,7,6,5,11);line(im,15,7,17,7,7)
 elseif name=='toolbox' then box(im,4,15,25,16,8,9);box(im,11,10,11,7,2,4);rect(im,13,12,7,3,0);line(im,5,21,27,21,1);rect(im,15,20,4,5,4)
 elseif name=='ore' then ellipse(im,5,18,12,12,2);ellipse(im,13,11,15,19,3);line(im,18,13,15,20,4);line(im,20,14,23,22,16)
 elseif name=='sapling' then box(im,10,24,15,7,8,9);plant(im,17,5,20)
 elseif name=='cargo' then box(im,3,8,27,23,2,4);rect(im,7,12,19,14,3);rect(im,14,9,5,21,4);rect(im,11,17,10,7,1);rect(im,13,19,6,3,11)
 elseif name=='cable' then for x=3,28 do local y=math.floor(14+10*math.sin((x-3)/25*math.pi));dot(im,x,y,1);dot(im,x,y+1,3) end;rect(im,2,9,3,7,4);rect(im,27,9,3,7,4)
 else rect(im,15,4,3,24,4);rect(im,8,28,17,3,2);line(im,7,13,26,13,3);line(im,11,8,22,8,3);rect(im,14,2,5,4,11) end
 local x,y=((i-1)%6)*32,math.floor((i-1)/6)*32;blit(props,im,x,y);saveImage(im,'prop-'..name)
 table.insert(propsMeta.items,{name=name,x=x,y=y,w=32,h=32,pivot={x=16,y=31}})
end
local ps=makeSprite('props',192,64,{'props'},1);cel(ps,1,1,props)
for _,v in ipairs(propsMeta.items) do local sl=ps:newSlice(Rectangle(v.x,v.y,32,32));sl.name=v.name;sl.pivot=Point(16,31) end
ps:saveAs(root..'source/props.aseprite');ps:close();saveImage(props,'props');write('exports/props.json',json.encode(propsMeta))

-- HUD: sparse chrome; labels remain live text in the application.
local hud=img(256,128);local ui={}
local function uiItem(name,x,y,w,h,draw,inset)
 local im=img(w,h);draw(im);blit(hud,im,x,y);saveImage(im,'ui-'..name)
 table.insert(ui,{name=name,x=x,y=y,w=w,h=h,nineSlice=inset})
end
uiItem('panel',0,0,96,48,function(im) box(im,0,0,96,48,2,4);rect(im,4,4,88,40,1);line(im,7,8,88,8,3);dot(im,7,39,8);dot(im,88,39,8) end,6)
uiItem('button-default',104,0,64,20,function(im) box(im,0,0,64,20,2,4);rect(im,3,3,58,13,3);line(im,4,16,59,16,1) end,4)
uiItem('button-hover',176,0,64,20,function(im) box(im,0,0,64,20,3,5);rect(im,3,3,58,13,4);line(im,4,16,59,16,2) end,4)
uiItem('button-active',104,24,64,20,function(im) box(im,0,0,64,20,8,10);rect(im,3,4,58,13,9);line(im,4,3,59,3,8) end,4)
uiItem('button-disabled',176,24,64,20,function(im) box(im,0,0,64,20,1,2);rect(im,3,3,58,13,2) end,4)
uiItem('progress-track',0,56,96,10,function(im) box(im,0,0,96,10,2,3);rect(im,3,3,90,4,1) end,3)
uiItem('progress-fill',104,56,64,4,function(im) rect(im,0,0,64,4,9);rect(im,0,0,64,1,11);rect(im,0,3,64,1,8) end,1)
uiItem('tooltip',0,72,96,40,function(im) box(im,0,0,96,35,6,7);line(im,4,31,91,31,4);for y=35,39 do rect(im,16+y-35,y,10-2*(y-35),1,6) end end,nil)
uiItem('portrait-frame',104,72,40,40,function(im) box(im,0,0,40,40,2,4);rect(im,4,4,32,32,1);rect(im,3,3,6,2,11) end,5)
uiItem('notification',152,72,96,32,function(im) box(im,0,0,96,32,2,4);rect(im,3,3,3,26,11);rect(im,10,4,81,24,1) end,6)
local hs=makeSprite('hud',256,128,{'components'},1);cel(hs,1,1,hud)
for _,v in ipairs(ui) do local sl=hs:newSlice(Rectangle(v.x,v.y,v.w,v.h));sl.name=v.name;if v.nineSlice then local n=v.nineSlice;sl.center=Rectangle(n,n,v.w-2*n,v.h-2*n) end end
hs:saveAs(root..'source/hud.aseprite');hs:close();saveImage(hud,'hud');write('exports/hud.json',json.encode({items=ui,notes='Text-free components. Use live accessible text. Pixel-perfect integer scaling.'}))

-- Twelve 16x16 interface icons.
local icons=img(16*12,16)
local iconNames={'explore','build','plant','energy','inventory','pause','play','check','attention','settings','sound','close'}
for i,name in ipairs(iconNames) do
 local im=img(16,16)
 if i==1 then ellipse(im,2,2,9,9,4);ellipse(im,4,4,5,5,1);line(im,10,10,14,14,6);line(im,9,10,13,14,6)
 elseif i==2 then line(im,4,12,11,5,6);line(im,5,13,12,6,6);rect(im,8,2,6,4,4);rect(im,11,2,3,7,4)
 elseif i==3 then plant(im,7,2,12)
 elseif i==4 then for y=2,8 do rect(im,9-math.floor(y/2),y,4,1,11) end;for y=8,13 do rect(im,11-math.floor(y/2),y,3,1,11) end
 elseif i==5 then box(im,2,5,12,9,9,10);line(im,3,9,12,9,1);rect(im,7,8,2,3,6)
 elseif i==6 then rect(im,4,3,3,10,6);rect(im,10,3,3,10,6)
 elseif i==7 then for x=4,11 do local d=math.min(x-4,11-x);rect(im,x,3+math.floor((x-4)/2),1,10-(x-4),13) end
 elseif i==8 then line(im,3,8,6,11,13);line(im,6,11,13,4,13);line(im,3,9,6,12,13);line(im,6,12,13,5,13)
 elseif i==9 then rect(im,7,2,3,8,11);rect(im,7,12,3,2,11)
 elseif i==10 then ellipse(im,3,3,10,10,4);rect(im,6,1,4,14,4);rect(im,1,6,14,4,4);ellipse(im,5,5,6,6,1)
 elseif i==11 then rect(im,2,6,4,5,6);for x=6,9 do rect(im,x,6-(x-6),1,5+(x-6)*2,6) end;line(im,12,4,14,6,4);line(im,14,6,14,10,4);line(im,14,10,12,12,4)
 else line(im,4,4,12,12,6);line(im,4,12,12,4,6) end
 blit(icons,im,(i-1)*16,0);saveImage(im,'icon-'..name)
end
static('icons',icons);write('exports/icons.json',json.encode({cellSize=16,names=iconNames}))

-- World in editable depth layers; preview is 640x192 native pixels.
local sky,far,ground,buildings,decor,crew=img(640,192),img(640,192),img(640,192),img(640,192),img(640,192),img(640,192)
rect(sky,0,0,640,192,3);rect(sky,0,112,640,80,4);ellipse(sky,527,18,23,23,6)
for _,p in ipairs({{30,28,70},{192,14,90},{408,39,60},{565,72,53}}) do
 rect(sky,p[1],p[2]+9,p[3],5,5);rect(sky,p[1]+12,p[2]+5,p[3]-30,5,5);rect(sky,p[1]+22,p[2],18,7,5)
end
for i=0,9 do local x=i*74-16;local y=68+(i*17)%42
 rect(far,x,y,52,18,2);rect(far,x+13,y-14,9,16,2);rect(far,x+25,y-23,6,23,2)
 for d=0,22 do rect(far,x+math.floor(d*.65),y+18+d,52-math.floor(d*1.5),1,2) end
end
for x=0,608,32 do blit(ground,modules['tile-platform'],x,145) end
for x=15,615,80 do rect(ground,x,168,8,9,2);line(ground,x+1,169,x+1,178,3) end
blit(buildings,modules['module-observatory'],35,17);blit(buildings,modules['module-workshop'],191,33)
blit(buildings,modules['module-greenhouse'],366,49);blit(buildings,modules['module-dock'],522,105)
for _,p in ipairs({{0,125,114},{2,334,114},{4,482,114},{8,170,114},{9,116,114},{10,100,158},{10,300,158},{10,470,158}}) do
 local source=Image(props,Rectangle((p[1]%6)*32,math.floor(p[1]/6)*32,32,32));blit(decor,source,p[2],p[3])
end
blit(crew,characters[1].idle,149,101);blit(crew,characters[2].work,304,101);blit(crew,characters[3].idle,480,101)
local scene=img(640,192);local ws=makeSprite('world',640,192,{'sky','distant-islands','platform','buildings','props','crew'},1)
for i,im in ipairs({sky,far,ground,buildings,decor,crew}) do cel(ws,i,1,im);blit(scene,im,0,0) end
ws:saveAs(root..'source/world.aseprite');ws:close();saveImage(scene,'world');saveImage(scale(scene,2),'world-preview-2x')
saveImage(sky,'world-layer-sky');saveImage(far,'world-layer-distant');saveImage(ground,'world-layer-platform')

-- Presentation contact sheet, native palette, no interpolation.
local board=img(640,384);rect(board,0,0,640,384,1);blit(board,scene,0,0)
for kind=1,3 do
 for j,state in ipairs({'idle','walk','work','wait','celebrate'}) do blit(board,characters[kind][state],16+(kind-1)*208+(j-1)*37,202) end
end
blit(board,hud,16,256);blit(board,props,304,256);blit(board,icons,304,336)
for i=1,#C do rect(board,16+(i-1)*15,371,12,6,i) end
saveImage(scale(board,2),'asset-board-2x')
palette:saveAs(root..'source/estacao-zero.gpl')
write('manifest.json',json.encode({version='0.1.0',authoring='Aseprite Lua API',palette=hex,characters=3,framesPerCharacter=24,characterSize=48,world={w=640,h=192},moduleCount=5,props=propsMeta.items,hud=ui,icons=iconNames,animations=anims,status='Initial editable pixel art kit; concept image is separate; not an integrated Windows application.'}))
write('scripts/build-complete.txt','OK — '..tostring(app.version)..' — 3 characters, 72 animation frames, world, 5 modules, 12 props, 12 HUD icons, 10 UI components.')
