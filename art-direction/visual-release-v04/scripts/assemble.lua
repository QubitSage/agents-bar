local root=app.params.root
local function read(p) local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return json.decode(s) end
local function write(p,v) local f=assert(io.open(p,'wb'));f:write(json.encode(v));f:close() end
local job=read(app.params.job)
local palettePath=root..'/sources/agents-bar-64.gpl'
local pal=Palette{fromFile=palettePath}
local src=Image{fromFile=root..'/sources/'..job.id..'.png'}
local pc=app.pixelColor
local cache={};local colors={}
for i=1,#pal-1 do local c=pal:getColor(i);colors[i]={c.red,c.green,c.blue} end
local function nearest(r,g,b)
 r=math.floor(r);g=math.floor(g);b=math.floor(b)
 local key=r*65536+g*256+b;if cache[key] then return cache[key] end
 local best,d=1,1e12
 for i,c in ipairs(colors) do local v=2*(r-c[1])^2+4*(g-c[2])^2+3*(b-c[3])^2;if v<d then best,d=i,v end end
 cache[key]=best;return best
end
local function solid(c)
 if pc.rgbaA(c)<220 then return false end
 local r,g,b=pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c)
 local hi,lo=math.max(r,g,b),math.min(r,g,b)
 return not(hi>248 and lo<6 and r+g+b-hi-lo<18)
end
local W,H=job.width,job.height
local function prune(im)
 local seen,components={},{};local largest=0
 for yy=0,H-1 do for xx=0,W-1 do
  local k=yy*W+xx
  if not seen[k] and im:getPixel(xx,yy)>0 then
   local q={{xx,yy}};seen[k]=true;local first=1
   while first<=#q do local p=q[first];first=first+1
    for dy=-1,1 do for dx=-1,1 do local x,y=p[1]+dx,p[2]+dy;local key=y*W+x
     if x>=0 and y>=0 and x<W and y<H and not seen[key] and im:getPixel(x,y)>0 then seen[key]=true;q[#q+1]={x,y}end
    end end
   end
   components[#components+1]=q;largest=math.max(largest,#q)
  end
 end end
 for _,q in ipairs(components)do if #q<math.max(3,largest*.009)then for _,p in ipairs(q)do im:drawPixel(p[1],p[2],0)end end end
end
local defaultDur={idle={240,220,240,260},walk={130,130,130,130},attack={220,80,120,220},special={260,190,160,300},defense={160,200,150,200},hurt={80,110,150,180},death={200,170,220,600},victory={180,200,260,220},rage={180,180,250,250},jump={180,100,200,200},sit={200,200,200,400},chew={220,180,160,220},watch={250,300,300,250},easter_egg={350,450,250,500},work={220,130,180,260},greet={200,200,240,200},chest_open={200,140,200,500}}
local rows=job.rows;local columns=job.columns
local images={};local clips={};local frame=0
local master=Sprite(W,H,ColorMode.INDEXED);master:setPalette(pal);master.transparentColor=0;master.layers[1].name='Poses completas'
local full=Image(W*columns,H*rows,ColorMode.INDEXED)
for idx=0,columns*rows-1 do
 local row=math.floor(idx/columns);local col=idx%columns
 local box=job.bounds and job.bounds[idx+1] or {math.floor(col*src.width/columns),math.floor(row*src.height/rows),math.floor(src.width/columns),math.floor(src.height/rows)}
 local scale=job.scale or math.min((W-16)/(src.width/columns),(H-16)/(src.height/rows))
 local dw,dh=math.floor(box[3]*scale),math.floor(box[4]*scale)
 local ox=math.floor((W-dw)/2);local oy=math.floor((H-dh)/2)
 local im=Image(W,H,ColorMode.INDEXED)
 for y=0,dh-1 do for x=0,dw-1 do
   local sx=box[1]+math.floor(x/scale);local sy=box[2]+math.floor(y/scale)
   local r,g,b,n=0,0,0,0
   for dy=0,1 do for dx=0,1 do
    local c=src:getPixel(math.min(sx+dx,src.width-1),math.min(sy+dy,src.height-1))
    local rule=job.exclude and job.exclude[tostring(idx+1)]
    local excluded=rule and sx+dx>rule.xGreater and sy+dy>rule.yGreater
    if solid(c) and not excluded then r=r+pc.rgbaR(c);g=g+pc.rgbaG(c);b=b+pc.rgbaB(c);n=n+1 end
   end end
   if n>=2 and x+ox>=0 and y+oy>=0 and x+ox<W and y+oy<H then im:drawPixel(x+ox,y+oy,nearest(r/n,g/n,b/n)) end
 end end
 local state=job.states[math.min(row+1,#job.states)]
 if #job.states==1 then state=job.states[1] end
 if job.category~='effects' and job.category~='environment-fx' and state~='jump' then
  prune(im)
  local bottom=0
  for yy=0,H-1 do for xx=0,W-1 do if im:getPixel(xx,yy)>0 then bottom=math.max(bottom,yy)end end end
  local dy=math.floor(H*.94)-bottom
  local aligned=Image(W,H,ColorMode.INDEXED);aligned:drawImage(im,Point(0,dy));im=aligned
 end
 images[#images+1]=im
 full:drawImage(im,Point(col*W,row*H))
 local dur=job.ms and job.ms[idx+1] or (defaultDur[state] or {140,140,140,160})[col+1]
 frame=frame+1;if frame>1 then master:newEmptyFrame(frame) end
 master.frames[frame].duration=dur/1000
 master:newCel(master.layers[1],frame,im,Point(0,0))
end
local per=#images/#job.states
for n,state in ipairs(job.states) do master:newTag((n-1)*per+1,n*per).name=state end
master:saveAs(root..'/aseprite/'..job.id..'.aseprite');pcall(function()master:close()end)
pal=Palette{fromFile=palettePath}
full:saveAs{filename=root..'/sheets/'..job.id..'.png',palette=pal}
for n,state in ipairs(job.states) do
 local id=job.actor..'--'..state
 local clip=Sprite(W,H,ColorMode.INDEXED);clip:setPalette(pal);clip.transparentColor=0;clip.layers[1].name='Pose completa'
 local strip=Image(W*per,H,ColorMode.INDEXED);local ms={}
 for f=1,per do
  local i=(n-1)*per+f;local im=images[i]
  local dur=job.ms and job.ms[i] or (defaultDur[state] or {140,140,140,160})[((f-1)%4)+1]
  ms[f]=dur
  if f>1 then clip:newEmptyFrame(f) end
  clip.frames[f].duration=dur/1000;clip:newCel(clip.layers[1],f,im,Point(0,0));strip:drawImage(im,Point((f-1)*W,0))
 end
 clip:newTag(1,per).name=state
 local slice=clip:newSlice(Rectangle(0,0,W,H));slice.name='frame';slice.pivot=Point(math.floor(W/2),math.floor(H*.94))
 clip:saveAs(root..'/aseprite/'..id..'.aseprite');pcall(function()clip:close()end)
 pal=Palette{fromFile=palettePath};strip:saveAs{filename=root..'/sheets/'..id..'.png',palette=pal}
 local loop=state=='idle' or state=='walk' or state=='work' or state=='chew' or state=='watch' or job.category=='environment-fx' or state=='banner' or state=='lantern'
 local events={}
 if state=='attack' or state=='special' then events={{frame=2,name='impact'}} elseif state=='death' then events={{frame=per,name='finished'}} end
 local meta={id=id,actor=job.actor,title=job.title,category=job.category,state=state,width=W,height=H,frames=per,columns=per,rows=1,durations=ms,loop=loop,pivot={x=math.floor(W/2),y=math.floor(H*.94)},events=events,aseprite='aseprite/'..id..'.aseprite',sheet='sheets/'..id..'.png',source='sources/'..job.id..'.png',method='Generated complete poses; Aseprite indexed cels and exports'}
 write(root..'/metadata/'..id..'.json',meta)
end
print(job.id..': '..#images..' cels / '..#job.states..' clips')
