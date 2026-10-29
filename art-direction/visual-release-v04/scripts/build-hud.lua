local root=app.params.root
local old=root..'/../fantasy-kit-v03'
local function read(p)local f=assert(io.open(p,'rb'));local v=json.decode(f:read('*a'));f:close();return v end
local function write(p,v)local f=assert(io.open(p,'wb'));f:write(json.encode(v));f:close()end
local palettePath=root..'/sources/agents-bar-64.gpl'
local pal=Palette{fromFile=palettePath}
local function rect(im,x,y,w,h,c)for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and yy>=0 and xx<im.width and yy<im.height then im:drawPixel(xx,yy,c)end end end end
local function line(im,x0,y0,x1,y1,c)
 local dx,dy=math.abs(x1-x0),math.abs(y1-y0);local sx=x0<x1 and 1 or -1;local sy=y0<y1 and 1 or -1;local e=dx-dy
 while true do if x0>=0 and y0>=0 and x0<im.width and y0<im.height then im:drawPixel(x0,y0,c)end;if x0==x1 and y0==y1 then break end;local t=2*e;if t>-dy then e=e-dy;x0=x0+sx end;if t<dx then e=e+dx;y0=y0+sy end end
end
local function frame(w,h,state)
 local im=Image(w,h,ColorMode.INDEXED)
 local fill=state=='hover' and 30 or state=='pressed' and 1 or 2
 local edge=state=='disabled' and 4 or state=='focus' and 34 or state=='hover' and 27 or 25
 rect(im,4,1,w-8,h-2,1);rect(im,1,4,w-2,h-8,1)
 rect(im,4,2,w-8,h-4,edge);rect(im,2,4,w-4,h-8,edge)
 rect(im,5,4,w-10,h-8,fill);rect(im,4,5,w-8,h-10,fill)
 line(im,7,5,w-8,5,state=='pressed' and 3 or 5);line(im,6,h-6,w-7,h-6,1)
 for _,p in ipairs({{5,5},{w-6,5},{5,h-6},{w-6,h-6}}) do
  rect(im,p[1]-2,p[2]-2,5,5,24);rect(im,p[1]-1,p[2]-1,3,3,edge);im:drawPixel(p[1],p[2],state=='disabled' and 5 or 28)
 end
 return im
end
local controls={'play','pause','minimize','close','map','team','station','journal','victory','attention','disconnected','sound'}
local function icon(im,id,ox,oy,c)
 local function l(x,y,xx,yy)line(im,x+ox,y+oy,xx+ox,yy+oy,c)end
 local function r(x,y,w,h)rect(im,x+ox,y+oy,w,h,c)end
 if id=='play' then for x=0,8 do l(4+x,2+x,4+x,18-x)end
 elseif id=='pause' then r(4,3,4,15);r(12,3,4,15)
 elseif id=='minimize' then r(3,14,14,3)
 elseif id=='close' then for i=0,1 do l(4+i,4,16+i,16);l(16+i,4,4+i,16)end
 elseif id=='map' then l(2,4,7,2);l(7,2,13,5);l(13,5,18,2);l(2,4,2,17);l(7,2,7,16);l(13,5,13,18);l(18,2,18,16);l(2,17,7,16);l(7,16,13,18);l(13,18,18,16)
 elseif id=='team' then r(8,2,5,5);r(5,9,11,8);r(1,6,4,4);r(0,12,4,6);r(16,6,4,4);r(17,12,3,6)
 elseif id=='station' then l(1,9,10,1);l(10,1,19,9);r(4,9,13,9);rect(im,8+ox,12+oy,5,6,2)
 elseif id=='journal' then r(3,2,15,17);rect(im,6+ox,4+oy,10,13,2);l(8,7,14,7);l(8,10,14,10);l(8,13,12,13)
 elseif id=='victory' then l(3,10,8,16);l(8,16,18,3);l(3,11,8,17);l(8,17,19,3)
 elseif id=='attention' then l(10,1,1,18);l(1,18,19,18);l(19,18,10,1);r(9,6,3,7);r(9,15,3,2)
 elseif id=='disconnected' then l(2,2,18,18);l(3,2,19,18);l(5,12,2,15);l(2,15,5,18);l(5,18,8,15);l(13,2,17,6);l(17,6,14,9)
 elseif id=='sound' then r(2,7,5,7);l(7,7,11,3);l(11,3,11,18);l(11,18,7,14);l(15,5,18,8);l(18,8,18,13);l(18,13,15,16)
 end
end
local states={'normal','hover','pressed','disabled','focus'}
local entries={}
local function save(id,title,images,names,w,h,extra)
 local s=Sprite(w,h,ColorMode.INDEXED);s:setPalette(pal);s.transparentColor=0;s.layers[1].name='Interface'
 local strip=Image(w*#images,h,ColorMode.INDEXED)
 for i,im in ipairs(images)do if i>1 then s:newEmptyFrame(i)end;s.frames[i].duration=.2;s:newCel(s.layers[1],i,im,Point(0,0));s:newTag(i,i).name=names[i];strip:drawImage(im,Point((i-1)*w,0))end
 s:saveAs(root..'/aseprite/'..id..'.aseprite');pcall(function()s:close()end)
 pal=Palette{fromFile=palettePath};strip:saveAs{filename=root..'/sheets/'..id..'.png',palette=pal}
 images[1]:saveAs{filename=root..'/static/'..id..'.png',palette=pal}
 local meta={id=id,actor=id,title=title,category='hud',state='states',frames=#images,width=w,height=h,columns=#images,rows=1,states=names,durations={200,200,200,200,200},loop=false,sheet='sheets/'..id..'.png',aseprite='aseprite/'..id..'.aseprite',preview='static/'..id..'.png',nineSlice={left=10,top=10,right=10,bottom=10},method='Pixel-native Aseprite Lua UI geometry'}
 if extra then for k,v in pairs(extra)do meta[k]=v end end
 write(root..'/metadata/'..id..'.json',meta);entries[#entries+1]=meta
end
for _,id in ipairs(controls) do
 local images={};for _,st in ipairs(states)do local im=frame(40,40,st);icon(im,id,10,10,st=='disabled' and 4 or st=='hover' and 28 or 7);images[#images+1]=im end
 save('ui-control-'..id,id,images,states,40,40,{nineSlice=false})
end
for _,spec in ipairs({{'panel','Painel',256,144},{'tooltip','Tooltip',176,64},{'slot','Slot',48,48},{'portrait','Retrato',64,64},{'button','Botão',112,36},{'compact','Modo compacto',288,64}})do
 local images={};for _,st in ipairs(states)do images[#images+1]=frame(spec[3],spec[4],st)end
 save('ui-'..spec[1],spec[2],images,states,spec[3],spec[4])
end
for _,spec in ipairs({{'health','Vida',51,53},{'shield','Escudo',32,34},{'experience','Experiência',25,27},{'enemy-health','Vida do chefe',58,60},{'mission','Missão',39,41}})do
 local images={};local levels={100,75,50,25,0}
 for _,level in ipairs(levels)do
  local im=frame(192,20,'normal');rect(im,10,7,172,6,1)
  local length=math.floor(172*level/100);rect(im,10,7,length,6,spec[3]);rect(im,10,7,length,2,spec[4]);images[#images+1]=im
 end
 save('ui-bar-'..spec[1],spec[2],images,{'100','75','50','25','0'},192,20,{fillRect={x=10,y=7,width=172,height=6},nineSlice={left=10,top=7,right=10,bottom=7}})
 -- Separate blank frame and repeatable fill texture for a real dynamic meter.
 images[5]:saveAs{filename=root..'/static/ui-bar-'..spec[1]..'-empty.png',palette=pal}
 local fill=Image(8,6,ColorMode.INDEXED);rect(fill,0,0,8,6,spec[3]);rect(fill,0,0,8,2,spec[4]);fill:saveAs{filename=root..'/static/ui-bar-'..spec[1]..'-fill.png',palette=pal}
end
print('HUD: '..#entries..' native assets, 5 states each')
