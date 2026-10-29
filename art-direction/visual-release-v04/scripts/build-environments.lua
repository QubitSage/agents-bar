local root=app.params.root
local function read(p)local f=assert(io.open(p,'rb'));local v=json.decode(f:read('*a'));f:close();return v end
local function write(p,v)local f=assert(io.open(p,'wb'));f:write(json.encode(v));f:close()end
local inventory=read(root..'/inventory.json').assets
local palettePath=root..'/sources/agents-bar-64.gpl'
local pal=Palette{fromFile=palettePath}
local function resized(im,w,h)
 local out=Image(w,h,ColorMode.INDEXED)
 for y=0,h-1 do for x=0,w-1 do out:drawPixel(x,y,im:getPixel(math.floor(x*im.width/w),math.floor(y*im.height/h)))end end
 return out
end
local function overlay(id,f,w,h)
 local meta=read(root..'/metadata/'..id..'.json')
 local sheet=Image{fromFile=root..'/'..meta.sheet}
 return resized(Image(sheet,Rectangle(((f-1)%meta.frames)*meta.width,0,meta.width,meta.height)),w,h)
end
local names={['scene-garden-1']='Sementes de luz',['scene-garden-2']='Raízes profundas',['scene-garden-3']='Coração da estufa', ['scene-scrap-1']='Primeiro sinal',['scene-scrap-2']='Ponte de cobre',['scene-scrap-3']='A última doca',['scene-storm-1']='Entre relâmpagos',['scene-storm-2']='Farol partido',['scene-storm-3']='Um novo horizonte',['station-background']='Estação Zero',['building-core']='Salão da guilda',['building-workshop']='Forja',['building-greenhouse']='Estufa',['building-observatory']='Observatório'}
for _,a in ipairs(inventory)do if a.category=='scenes' or a.category=='station' or a.category=='buildings' then
 local base=Image{fromFile=root..'/sources/baseline/'..a.png};local w,h=a.width,a.height
 local s=Sprite(w,h,ColorMode.INDEXED);s:setPalette(pal);s.transparentColor=0;s.layers[1].name='Cenário fixo';local fxLayer=s:newLayer();fxLayer.name='Elementos animados'
 local full=Image(w*4,h,ColorMode.INDEXED);local placement={}
 if a.category=='buildings' then
  if a.id=='building-workshop' then placement={{'environment-forge--smoke',92,5,24,48},{'environment-forge--flame',65,103,20,28}}
  elseif a.id=='building-greenhouse' then placement={{'environment-wild--fireflies',32,35,96,80}}
  elseif a.id=='building-observatory' then placement={{'environment-forge--beacon',54,0,48,56}}
  else placement={{'environment-forge--beacon',70,60,28,40}}end
 elseif a.id:find('garden') then placement={{'environment-wild--foliage',110,88,42,35},{'environment-wild--fireflies',170,14,140,90}}
 elseif a.id:find('storm') then placement={{'environment-wild--storm',245,0,100,92},{'environment-forge--beacon',387,28,32,48}}
 else placement={{'environment-forge--smoke',342,18,30,52},{'environment-forge--beacon',25,52,22,40}}end
 for f=1,4 do
  if f>1 then s:newEmptyFrame(f)end;s.frames[f].duration=.22;s:newCel(s.layers[1],f,base,Point(0,0))
  local fx=Image(w,h,ColorMode.INDEXED)
  for _,p in ipairs(placement)do fx:drawImage(overlay(p[1],f,p[4],p[5]),Point(p[2],p[3]))end
  s:newCel(fxLayer,f,fx,Point(0,0));local combined=Image(w,h,ColorMode.INDEXED);combined:drawImage(base,Point(0,0));combined:drawImage(fx,Point(0,0));full:drawImage(combined,Point((f-1)*w,0))
 end
 s:newTag(1,4).name='ambient';s:saveAs(root..'/aseprite/'..a.id..'.aseprite');pcall(function()s:close()end)
 pal=Palette{fromFile=palettePath};full:saveAs{filename=root..'/sheets/'..a.id..'.png',palette=pal};base:saveAs{filename=root..'/static/'..a.id..'.png',palette=pal}
 write(root..'/metadata/'..a.id..'.json',{id=a.id,actor=a.id,title=names[a.id],category=a.category,state='ambient',frames=4,width=w,height=h,columns=4,rows=1,durations={220,220,220,220},loop=true,aseprite='aseprite/'..a.id..'.aseprite',sheet='sheets/'..a.id..'.png',method='Static approved background plus separate hand-pose generated FX cels in Aseprite',layers={'Cenário fixo','Elementos animados'},placements=placement,visualGroundY=a.category~='buildings' and 126 or 148})
 print(a.id..': layered ambient loop')
end end
