-- Original Agents Bar campaign artwork. Batch only; no application UI.
local root=app.params['root'] or 'C:/Users/bruno/Desktop/All/Projetos/Tokens Bar/'
local out=root..'game/assets/'
local source=root..'art-source/'
app.fs.makeAllDirectories(source)
local hex={'172C38','254854','3E6B70','75989B','B8C8BC','E8DDC3','FFF0CC','784737','B96843','DC8B4E','F0B65A','6C8454','A7B874','D5DDA2','584B60','86C9B2'}
local colors={};local pal=Palette(17)
pal:setColor(0,Color{r=0,g=0,b=0,a=0})
for i,h in ipairs(hex) do
 local c=Color{r=tonumber(h:sub(1,2),16),g=tonumber(h:sub(3,4),16),b=tonumber(h:sub(5,6),16),a=255}
 colors[i]=app.pixelColor.rgba(c.red,c.green,c.blue,255);pal:setColor(i,c)
end
local function image(w,h) return Image(w,h,ColorMode.RGB) end
local function dot(im,x,y,c)
 x,y=math.floor(x),math.floor(y)
 if x>=0 and y>=0 and x<im.width and y<im.height then im:drawPixel(x,y,colors[c] or 0) end
end
local function rect(im,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do dot(im,xx,yy,c) end end
end
local function line(im,x,y,xx,yy,c)
 local dx,dy=math.abs(xx-x),math.abs(yy-y);local sx,sy=x<xx and 1 or -1,y<yy and 1 or -1;local e=dx-dy
 while true do dot(im,x,y,c);if x==xx and y==yy then break end;local q=2*e;if q>-dy then e=e-dy;x=x+sx end;if q<dx then e=e+dx;y=y+sy end end
end
local function oval(im,x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do if ((xx-x+.5)*2/w-1)^2+((yy-y+.5)*2/h-1)^2<=1 then dot(im,xx,yy,c) end end end
end
local function box(im,x,y,w,h,c,light)
 rect(im,x+2,y,w-4,h,1);rect(im,x,y+2,w,h-4,1)
 rect(im,x+2,y+2,w-4,h-4,c)
 if light then rect(im,x+3,y+2,w-6,2,light) end
end
local function save(im,name)
 im:saveAs(out..name..'.png')
 local s=Sprite(im.width,im.height,ColorMode.RGB);s:setPalette(pal);s.layers[1].name='Original pixel artwork'
 s.cels[1].image=im;s:saveAs(source..name..'.aseprite');s:close()
end
local function map(kind)
 local im=image(480,160);rect(im,0,0,480,160,1)
 -- Three intentionally different silhouettes and terrain motifs.
 for y=20,100,20 do rect(im,0,y,480,20,y<60 and 2 or 3) end
 for i=0,16 do
  local x=(i*83+17)%480;local y=12+(i*29)%65
  rect(im,x,y,1,1,4)
 end
 if kind=='scrap' then
  oval(im,350,14,45,45,9);oval(im,354,16,38,38,10)
  for i=0,7 do
   local x=i*71-15;local y=57+(i%3)*8
   rect(im,x,y,47,44,2);rect(im,x+4,y+7,5,23,3);rect(im,x+29,y-18,9,18,2)
   line(im,x+33,y-17,x+69,y+3,4);rect(im,x+10,y+8,12,3,11)
  end
  for i=0,5 do
   local x=i*96-25;line(im,x,82,x+41,102,8);line(im,x+41,102,x+96,82,8)
   box(im,x,99,74,20,8,9);rect(im,x+7,118,53,7,1)
   for j=0,3 do rect(im,x+7+j*15,106,6,3,9) end
  end
 elseif kind=='garden' then
  oval(im,355,18,35,35,13);oval(im,359,19,28,28,14)
  for i=0,3 do
   local x=i*150-30
   oval(im,x,38,122,98,2);oval(im,x+4,42,114,90,4);oval(im,x+8,46,106,82,3)
   line(im,x+61,42,x+61,119,4);line(im,x+20,56,x+61,119,4);line(im,x+102,56,x+61,119,4)
   for j=0,4 do
    local px=x+20+j*17;local py=81+(j%3)*7
    rect(im,px,py,3,42,12);oval(im,px-8,py+4,10,5,13);oval(im,px+2,py+13,12,6,12)
    oval(im,px-3,py-3,9,7,14)
   end
  end
 else
  for i=0,5 do
   local x=i*94-20;local y=34+(i%2)*16
   rect(im,x,y,26,79,2);rect(im,x+5,y-12,16,12,2);rect(im,x+11,y-28,4,24,4)
   rect(im,x+8,y+8,10,22,3);rect(im,x+9,y+11,8,9,16)
   line(im,x+12,y-25,x+48,y-5,4)
   for j=0,2 do line(im,x+12,y+10+j*17,x+45,y+28+j*17,3) end
  end
  for i=0,5 do oval(im,i*93-30,78+(i%2)*12,110,32,4);oval(im,i*93-26,83+(i%2)*12,100,27,3) end
  line(im,334,6,321,30,16);line(im,321,30,333,30,16);line(im,333,30,317,54,16)
 end
 rect(im,0,121,480,6,1);rect(im,0,122,480,2,kind=='garden' and 13 or 4)
 rect(im,0,127,480,33,2)
 for i=0,29 do
  local x=i*16;rect(im,x,128,15,9,3);rect(im,x+1,129,13,1,4)
  rect(im,x+7,142,2,18,1);dot(im,x+3,133,1)
 end
 save(im,'map-'..kind)
end
map('scrap');map('garden');map('storm')

local enemies={
 {'drone',9,11},{'crab',8,10},{'rebo',9,11},
 {'spore',12,14},{'vine',12,16},{'heart',12,14},
 {'spark',3,16},{'warden',4,16},{'archon',15,16}
}
for _,spec in ipairs(enemies) do
 local sheet=image(256,64)
 local sprite=Sprite(64,64,ColorMode.RGB);sprite:setPalette(pal);sprite.layers[1].name='Body and effects'
 for frame=1,4 do
  if frame>1 then sprite:newEmptyFrame() end
  local im=image(64,64);local k,c,h=spec[1],spec[2],spec[3];local bob=frame%2;local glow=frame==3 and 7 or h
  oval(im,12,53,40,5,1)
  if k=='drone' then
   box(im,17,22-bob,30,20,c,h);rect(im,9,29-bob,10,5,4);rect(im,45,29-bob,10,5,4)
   line(im,14,18-bob,14,37-bob,4);line(im,50,18-bob,50,37-bob,4)
   box(im,26,27-bob,12,9,1,4);rect(im,29,30-bob,6,3,glow)
   rect(im,25,43-bob,4,5+bob,10);rect(im,36,43-bob,4,5+bob,10)
  elseif k=='crab' then
   for i=0,2 do line(im,21,38+i*4,11-i*3,43+i*4,9);line(im,43,38+i*4,53+i*3,43+i*4,9) end
   box(im,17,29-bob,30,19,c,h);box(im,5,26+bob,13,13,9,10);box(im,46,26-bob,13,13,9,10)
   rect(im,23,25-bob,4,7,4);rect(im,37,25-bob,4,7,4);dot(im,24,26-bob,glow);dot(im,38,26-bob,glow)
  elseif k=='rebo' then
   box(im,11,20,42,29,c,h);box(im,17,10-bob,30,17,8,9);rect(im,23,15-bob,18,6,1);rect(im,26,16-bob,12,3,glow)
   box(im,6,46,18,10,2,4);box(im,40,46,18,10,2,4)
   box(im,2,26+bob,12,17,4,5);box(im,50,26-bob,12,17,4,5)
   line(im,51,23,56,8,4);line(im,56,8,43,8,4);line(im,43,8,43,15,4)
   for i=0,3 do rect(im,20+i*7,35,4,6,1) end
  elseif k=='spore' then
   rect(im,29,34-bob,7,19,12);oval(im,14,20-bob,37,23,1);oval(im,17,21-bob,31,17,c)
   for i=0,4 do rect(im,21+i*5,25+(i%2)*4-bob,3,3,h) end
   rect(im,27,38-bob,3,3,7);rect(im,36,38-bob,3,3,7)
   for i=0,3 do dot(im,13+i*11,12+(i+frame)%5,h) end
  elseif k=='vine' then
   box(im,20,30,26,24,3,4);rect(im,31,15-bob,4,30,12)
   oval(im,15,19-bob,20,9,12);oval(im,33,10-bob,20,12,13);oval(im,22,7-bob,15,13,12)
   box(im,25,24-bob,17,13,12,13);rect(im,28,28-bob,10,3,glow)
   line(im,21,38,9,31+bob,13);line(im,9,31+bob,7,23,13);line(im,44,39,54,29-bob,13)
  elseif k=='heart' then
   for i=0,4 do line(im,30,34,7+i*12,54,12);line(im,32,27,7+i*12,8+(i%2)*5,13) end
   oval(im,13,15-bob,39,36,1);oval(im,16,17-bob,33,31,12);oval(im,23,20-bob,20,24,13)
   oval(im,28,24-bob,11,15,glow);rect(im,28,32-bob,11,3,1)
   for i=0,3 do oval(im,10+i*13,14+(i%2)*29,9,7,14) end
  elseif k=='spark' then
   oval(im,21,23-bob,23,23,1);oval(im,24,26-bob,17,17,3);rect(im,29,29-bob,7,10,glow)
   for i=0,3 do
    local x=8+i*14;line(im,x,15+bob,x+8,20,16);line(im,x+8,20,x+3,25-bob,16)
   end
   line(im,17,38,10,43+bob,16);line(im,10,43+bob,19,48,16)
   line(im,47,36,56,42-bob,16);line(im,56,42-bob,49,49,16)
  elseif k=='warden' then
   box(im,20,17-bob,27,31,3,4);box(im,25,10-bob,17,15,4,5)
   rect(im,28,16-bob,10,4,glow);box(im,12,26,12,25,4,5);box(im,45,27,9,19,3,4)
   rect(im,24,47,7,8,4);rect(im,37,47,7,8,4);rect(im,28,29-bob,10,12,16)
  else
   for i=0,2 do
    box(im,4+i*5,20+i*5-bob,13,8,15,4);box(im,47-i*5,20+i*5-bob,13,8,15,4)
   end
   box(im,21,20-bob,25,28,15,4);box(im,25,9-bob,17,16,4,5)
   rect(im,28,15-bob,11,3,glow);rect(im,29,27-bob,9,14,16)
   rect(im,23,45,7,10,4);rect(im,38,45,7,10,4)
   line(im,22,7-bob,32,2+bob,16);line(im,32,2+bob,44,7-bob,16)
   line(im,6,41,13,48+bob,16);line(im,13,48+bob,5,54,16)
  end
  sheet:drawImage(im,Point((frame-1)*64,0))
  local existing=sprite.layers[1]:cel(frame)
  if existing then existing.image=im else sprite:newCel(sprite.layers[1],frame,im,Point(0,0)) end
  sprite.frames[frame].duration=.2
 end
 local tag=sprite:newTag(1,4);tag.name='idle'
 sprite:saveAs(source..'enemy-'..spec[1]..'.aseprite');sprite:close()
 sheet:saveAs(out..'enemy-'..spec[1]..'.png')
end
local icon=image(64,64)
box(icon,2,2,60,60,2,4)
rect(icon,9,47,46,7,3);rect(icon,9,47,46,2,4)
for i=0,2 do
 local x=12+i*15;local y=23+(i%2)*4
 box(icon,x,y,12,22,i==0 and 6 or (i==1 and 9 or 12),i==0 and 7 or (i==1 and 10 or 13))
 rect(icon,x+3,y+5,6,5,1);rect(icon,x+4,y+6,4,2,16)
 rect(icon,x+2,45,3,3,4);rect(icon,x+8,45,3,3,4)
end
rect(icon,30,9,4,4,11);rect(icon,31,15,2,4,11)
save(icon,'agents-bar-icon')
print('Agents Bar: 3 maps, 9 enemy sheets, app icon and editable Aseprite sources exported.')
