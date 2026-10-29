local root=app.params.root
local function read(p)local f=assert(io.open(p,'rb'));local v=json.decode(f:read('*a'));f:close();return v end
for _,a in ipairs(read(root..'/qa/roundtrip-list.json'))do
 local s=app.open(root..'/'..a.aseprite);local frames={}
 for f=1,#s.frames do local im=Image(s.width,s.height,ColorMode.RGB);im:drawSprite(s,f,Point(0,0));frames[#frames+1]=im end
 s:close()
 for f,im in ipairs(frames)do im:saveAs(root..'/qa/'..a.id..'-native-'..f..'.png')end
end
local page=Image(768,768,ColorMode.RGB)
local names=read(root..'/qa/contact-list.json')
for i,id in ipairs(names)do
 local s=app.open(root..'/sheets/'..id..'.png');local src=Image(s.width,s.height,ColorMode.RGB);src:drawSprite(s,1,Point(0,0));s:close()
 local out=Image(384,384,ColorMode.RGB);local scale=math.min(384/src.width,384/src.height)
 local w,h=math.floor(src.width*scale),math.floor(src.height*scale)
 for y=0,h-1 do for x=0,w-1 do out:drawPixel(x,y,src:getPixel(math.floor(x/scale),math.floor(y/scale)))end end
 local k=(i-1)%4;page:drawImage(out,Point((k%2)*384,math.floor(k/2)*384))
 if i%4==0 or i==#names then page:saveAs(root..'/qa/contact-'..math.ceil(i/4)..'.png');page=Image(768,768,ColorMode.RGB)end
end
print('Native roundtrip images and complete contact pages exported')
