-- Agents Bar v03. Raster processing runs inside Aseprite, batch only.
local root=app.params["root"]
assert(root,"Missing root")
local function read(path) local f=assert(io.open(path,"rb"));local t=f:read("*a");f:close();return json.decode(t) end
local function write(path,value) local f=assert(io.open(path,"wb"));f:write(json.encode(value));f:close() end
local previous=root.."/masters/v02"
local old=read(previous.."/manifest.json").assets
local new=read(root.."/boss-prompts.json").assets
local hex={
"111626","22283F","38415D","56617F","7C8AA7","B3C0D8","E9EFF8",
"211D2D","36334F","514E70","706F91","9797B5","C4C5DB","F8F4F2",
"2E222B","50313B","78463E","A36545","C28C5A","DDB77E","F4DCAD",
"3F2B2B","6D442D","9A642D","C28C36","E7B84D","F7D879","FFF0B3",
"131D3A","1E315B","2B4F89","386DB7","5594D5","83B9EA","C5E4FA",
"172D2D","294B3E","416C4C","629158","91B669","BDDB8B","E8F3BF",
"142F41","20526A","307A91","48A5B6","71CED2","A8E9E7","E2FFFF",
"361C35","632C47","98415B","C35C70","E78390","F2ADB0","FFE0CF",
"211E40","3E326A","614A91","8A68B7","B78FD6","DAB9ED","F5E4FF"}
assert(#hex==63)
local pal=Palette(64);pal:setColor(0,Color{r=0,g=0,b=0,a=0})
local colors={}
for i,h in ipairs(hex) do
 local r,g,b=tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)
 pal:setColor(i,Color{r=r,g=g,b=b,a=255});colors[i]={r,g,b}
end
local pc=app.pixelColor
local cache={}
local function nearest(r,g,b)
 r,g,b=math.floor(r),math.floor(g),math.floor(b)
 local k=r*65536+g*256+b;if cache[k] then return cache[k] end
 local best,dist=1,1e12
 for i,c in ipairs(colors) do local d=2*(r-c[1])^2+4*(g-c[2])^2+3*(b-c[3])^2;if d<dist then best,dist=i,d end end
 cache[k]=best;return best
end
local function solid(c,opaque)
 if opaque then return true end
 if pc.rgbaA(c)<220 then return false end
 local r,g,b=pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c)
 -- Discard near-primary matte contamination, not legitimate colored ramps.
 local hi,lo=math.max(r,g,b),math.min(r,g,b)
 if hi>248 and lo<6 and (r+g+b-hi-lo)<18 then return false end
 return true
end
local function image(w,h) return Image(w,h,ColorMode.INDEXED) end
local function bounds(im,opaque)
 if opaque then return 0,0,im.width,im.height end
 local x0,y0,x1,y1=im.width,im.height,0,0
 for it in im:pixels() do if solid(it(),false) then
 x0=math.min(x0,it.x);y0=math.min(y0,it.y);x1=math.max(x1,it.x+1);y1=math.max(y1,it.y+1)
 end end
 assert(x1>x0 and y1>y0,"Empty source")
 return x0,y0,x1-x0,y1-y0
end
local function prune(im)
 local seen={};local w,h=im.width,im.height
 for y=0,h-1 do for x=0,w-1 do
 local key=y*w+x
 if not seen[key] and im:getPixel(x,y)>0 then
 local queue={{x,y}};local first=1;seen[key]=true
 while first<=#queue do
 local p=queue[first];first=first+1
 for dy=-1,1 do for dx=-1,1 do
 local xx,yy=p[1]+dx,p[2]+dy
 if xx>=0 and yy>=0 and xx<w and yy<h then local k=yy*w+xx
 if not seen[k] and im:getPixel(xx,yy)>0 then seen[k]=true;queue[#queue+1]={xx,yy} end
 end
 end end
 end
 if #queue<=2 then for _,p in ipairs(queue) do im:drawPixel(p[1],p[2],0) end end
 end
 end end
end
local function normalize(src,w,h,opaque,margin,keepParticles)
 local x0,y0,sw,sh=bounds(src,opaque)
 local dw,dh,ox,oy
 if opaque then dw,dh,ox,oy=w,h,0,0
 else
 local scale=math.min((w-2*margin)/sw,(h-2*margin)/sh)
 dw,dh=math.max(1,math.floor(sw*scale)),math.max(1,math.floor(sh*scale))
 ox,oy=math.floor((w-dw)/2),h-margin-dh
 end
 local out=image(w,h)
 for y=0,dh-1 do for x=0,dw-1 do
 local sx0=x0+math.floor(x*sw/dw);local sx1=x0+math.max(math.floor((x+1)*sw/dw)-1,math.floor(x*sw/dw))
 local sy0=y0+math.floor(y*sh/dh);local sy1=y0+math.max(math.floor((y+1)*sh/dh)-1,math.floor(y*sh/dh))
 local r,g,b,n,total=0,0,0,0,0
 for yy=sy0,sy1 do for xx=sx0,sx1 do
 local c=src:getPixel(math.min(xx,src.width-1),math.min(yy,src.height-1));total=total+1
 if solid(c,opaque) then r=r+pc.rgbaR(c);g=g+pc.rgbaG(c);b=b+pc.rgbaB(c);n=n+1 end
 end end
 if n>0 and (opaque or n/total>=0.50) then out:drawPixel(ox+x,oy+y,nearest(r/n,g/n,b/n)) end
 end end
 if not opaque and not keepParticles then prune(out) end
 return out
end
local function split(base)
 local body,light=image(base.width,base.height),image(base.width,base.height)
 for it in base:pixels() do local v=it();if v>0 then local c=colors[v]
 local lum=(c[1]*2+c[2]*4+c[3]*3)/9
 if lum>185 or (math.max(table.unpack(c))-math.min(table.unpack(c))>75 and lum>125) then light:drawPixel(it.x,it.y,v)
 else body:drawPixel(it.x,it.y,v) end
 end end
 return body,light
end
local function deform(src,compression,dx,flash,pulse)
 local out=image(src.width,src.height);local baseline=src.height-12
 for y=0,src.height-1 do for x=0,src.width-1 do
 local sy=y
 if y<baseline and compression>0 then sy=math.floor((y-compression)*baseline/(baseline-compression)) end
 local sx=x-dx
 if sy>=0 and sy<src.height and sx>=0 and sx<src.width then
 local v=src:getPixel(sx,sy)
 if v>0 then
 if flash then local c=colors[v];v=nearest(c[1]*.55+255*.45,c[2]*.55+240*.45,c[3]*.55+220*.45)
 elseif pulse then v=math.min(math.ceil(v/7)*7,v+1) end
 out:drawPixel(x,y,v)
 end
 end
 end end
 return out
end
local entries={}
local function save(base,a,kind)
 local category=a.category
 for _,sub in ipairs({"aseprite/","png/","sheets/","metadata/"}) do app.fs.makeAllDirectories(root.."/"..sub..category) end
 local stem=category.."/"..a.id
 local s=Sprite(base.width,base.height,ColorMode.INDEXED)
 s:setPalette(pal);s.transparentColor=0
 s.data=json.encode{origin="AI base; pixel processing and animation via Aseprite Lua",id=a.id,status="pixel-production-v03",animationMethod=kind=="actor" and "procedural idle and hit study" or kind=="effect" and "procedural burst" or "static"}
 local body,lights=split(base)
 local layer=s.layers[1];layer.name="Corpo e materiais"
 local lightLayer=s:newLayer();lightLayer.name="Luzes e detalhes"
 local frameCount=kind=="actor" and 12 or kind=="effect" and 6 or 1
 local sheet=image(base.width*frameCount,base.height)
 local frameData={}
 local idle={0,0,1,1,2,1,1,0}
 for f=1,frameCount do
 if f>1 then s:newEmptyFrame(f) end
 s.frames[f].duration=kind=="effect" and .075 or f>8 and .08 or .125
 local bi,li=body,lights
 if kind=="actor" then
 local compression=f<=8 and idle[f] or 0
 local dx=f<=8 and 0 or ({2,-1,1,0})[f-8]
 bi=deform(body,compression,dx,f==9 or f==10,false)
 li=deform(lights,compression,dx,f==9 or f==10,f==4 or f==5)
 elseif kind=="effect" then
 bi=image(base.width,base.height);li=image(base.width,base.height)
 local scale=({.55,.8,1,1.04,1.08,1.1})[f]
 for y=0,base.height-1 do for x=0,base.width-1 do
 local sx=math.floor((x-base.width/2)/scale+base.width/2)
 local sy=math.floor((y-base.height/2)/scale+base.height/2)
 if sx>=0 and sy>=0 and sx<base.width and sy<base.height and (f<=3 or ((x*13+y*7)%11)>((f-3)*2)) then
 bi:drawPixel(x,y,body:getPixel(sx,sy));li:drawPixel(x,y,lights:getPixel(sx,sy))
 end end end
 end
 if layer:cel(f) then s:deleteCel(layer,f) end
 s:newCel(layer,f,bi,Point(0,0));s:newCel(lightLayer,f,li,Point(0,0))
 sheet:drawImage(bi,Point((f-1)*base.width,0));sheet:drawImage(li,Point((f-1)*base.width,0))
 frameData[#frameData+1]={filename=a.id..'-'..(f-1),frame={x=(f-1)*base.width,y=0,w=base.width,h=base.height},rotated=false,trimmed=false,spriteSourceSize={x=0,y=0,w=base.width,h=base.height},sourceSize={w=base.width,h=base.height},duration=math.floor(s.frames[f].duration*1000)}
 end
 if kind=="actor" then s:newTag(1,8).name="idle";s:newTag(9,12).name="hit"
 elseif kind=="effect" then s:newTag(1,6).name="burst"
 else s:newTag(1,1).name="static" end
 local slice=s:newSlice(Rectangle(0,0,base.width,base.height));slice.name="asset"
 slice.pivot=Point(math.floor(base.width/2),kind=="actor" and base.height-12 or math.floor(base.height/2))
 local asp="aseprite/"..stem..".aseprite"
 s:saveAs(root.."/"..asp)
 local tags=kind=="actor" and {{name="idle",from=0,to=7,direction="forward"},{name="hit",from=8,to=11,direction="forward"}} or kind=="effect" and {{name="burst",from=0,to=5,direction="forward"}} or {{name="static",from=0,to=0,direction="forward"}}
 local skey={frame=0,bounds={x=0,y=0,w=base.width,h=base.height},pivot={x=math.floor(base.width/2),y=kind=="actor" and base.height-12 or math.floor(base.height/2)}}
 local meta={app="Aseprite Lua / Agents Bar",image=a.id..".png",format="I8",size={w=sheet.width,h=sheet.height},scale="1",frameTags=tags,layers={{name="Corpo e materiais"},{name="Luzes e detalhes"}},slices={{name="asset",keys={skey}}}}
 write(root.."/metadata/"..stem..".json",{frames=frameData,meta=meta})
 local entry={id=a.id,title=a.title,category=category,width=base.width,height=base.height,frames=frameCount,aseprite=asp,png="png/"..stem..".png",sheet="sheets/"..stem..".png",metadata="metadata/"..stem..".json",origin=a.sourceId or a.id,kind=kind,pivot={x=math.floor(base.width/2),y=kind=="actor" and base.height-12 or math.floor(base.height/2)}}
 entries[#entries+1]=entry
 pcall(function() s:close() end)
 sheet:saveAs{filename=root.."/sheets/"..stem..".png",palette=pal}
 base:saveAs{filename=root.."/png/"..stem..".png",palette=pal}
 print("SAVED "..a.id.." "..frameCount.." frames")
 return base
end
local function process(a,source,w,h,kind)
 local src=Image{fromFile=source}
 local opaque=a.category=="scenes" or a.category=="station"
 local base=normalize(src,w,h,opaque,kind=="actor" and 12 or 4,kind=="effect")
 return save(base,a,kind)
end
local only=app.params["only"]
local scope=app.params["scope"]
if scope then
 for _,entry in ipairs(read(root.."/manifest.json").assets) do
 if (scope=="atlases" and not entry.origin:match("^atlas")) or (scope~="atlases" and entry.origin~=scope) then entries[#entries+1]=entry end
 end
end
for _,a in ipairs(old) do
 if not scope and (not only or a.id==only) and a.category~="atlases" then
 local kind=({heroes=true,companions=true,npcs=true,enemies=true,bosses=true})[a.category] and "actor" or "static"
 local w,h=128,128
 if a.category=="bosses" then w,h=192,192
 elseif a.category=="scenes" or a.category=="station" then w,h=480,160
 elseif a.category=="buildings" then w,h=160,160 end
 process(a,previous.."/"..a.file,w,h,kind)
 end
end
if not only then
 if not scope then for _,a in ipairs(new) do process(a,root.."/masters/"..a.id..".png",a.width,a.height,"actor") end end
 for _,a in ipairs(old) do if a.category=="atlases" and (not scope or scope=="atlases" or scope==a.id) then
 local src=Image{fromFile=previous.."/"..a.file}
 local cols,rows=a.grid.columns,a.grid.rows
 local cw,ch=96,96
 local bases={}
 for i,title in ipairs(a.items) do
 local col,row=(i-1)%cols,math.floor((i-1)/cols)
 local x,y=math.floor(col*src.width/cols),math.floor(row*src.height/rows)
 local ex,ey=math.floor((col+1)*src.width/cols),math.floor((row+1)*src.height/rows)
 -- The generated sheets have uneven gutters: these boundaries were inspected.
 if a.id=="atlas-props" then
 local xs={0,.267,.530,.758,1};local ys={0,.400,.675,1}
 x,ex=math.floor(xs[col+1]*src.width),math.floor(xs[col+2]*src.width)
 y,ey=math.floor(ys[row+1]*src.height),math.floor(ys[row+2]*src.height)
 elseif a.id=="atlas-terrain" then
 local xs={0,.187,.355,.524,.688,.840,1}
 x,ex=math.floor(xs[col+1]*src.width),math.floor(xs[col+2]*src.width)
 end
 local crop=Image(src,Rectangle(x,y,ex-x,ey-y))
 local w,h=48,48
 if a.id=="atlas-controls" then w,h=32,32
 elseif a.id=="atlas-props" then w,h=64,64
 elseif a.id=="atlas-effects" then w,h=64,64
 elseif a.id=="atlas-terrain" then w,h=96,64
 elseif a.id=="atlas-hud" then
 if i<=4 then w,h=128,32 elseif i>=9 then w,h=96,40 else w,h=96,96 end
 end
 cw=math.max(cw,w+8);ch=math.max(ch,h+8)
 local aa={id=a.id.."-"..string.format("%02d",i),title=title,category=a.id:sub(7),sourceId=a.id}
 local base=normalize(crop,w,h,false,4,a.id=="atlas-effects")
 if a.id=="atlas-hud" and (i==5 or i==8 or i>=9) then
 local bb=base:shrinkBounds()
 for yy=bb.y+10,bb.y+bb.height-11 do for xx=bb.x+10,bb.x+bb.width-11 do
 if base:getPixel(xx,yy)==0 then base:drawPixel(xx,yy,30) end
 end end
 end
 save(base,aa,a.id=="atlas-effects" and "effect" or "static")
 bases[i]=base
 end
 local sheet=image(cols*cw,rows*ch)
 for i,base in ipairs(bases) do
 sheet:drawImage(base,Point(((i-1)%cols)*cw+math.floor((cw-base.width)/2),math.floor((i-1)/cols)*ch+math.floor((ch-base.height)/2)))
 end
 save(sheet,{id=a.id,title=a.title,category="atlases"},"static")
 end end
end
app.fs.makeAllDirectories(root.."/palettes")
pal:saveAs(root.."/palettes/agents-bar-64.gpl")
write(root.."/"..(only and "pilot-manifest.json" or "manifest.json"),{version="v03",tool=tostring(app.version),paletteColors=64,assets=entries,notes={"Generated source art processed in Aseprite batch","Idle/hit and burst are procedural motion studies, not articulated walk/attack animation","Godot integration and in-game acceptance pending"}})
print("COMPLETE "..#entries)

