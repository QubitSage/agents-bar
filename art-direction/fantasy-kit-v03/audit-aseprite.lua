local root=app.params["root"]
local f=assert(io.open(root.."/manifest.json","rb"));local m=json.decode(f:read("*a"));f:close()
local results={}
app.fs.makeAllDirectories(root.."/qa")
for _,a in ipairs(m.assets) do
 local s=Sprite{fromFile=root.."/"..a.aseprite}
 assert(s.width==a.width and s.height==a.height and #s.frames==a.frames,a.id)
 assert(#s.layers==2 and #s.tags>=1,a.id.." layers")
 local render=Image(s)
 -- Persist the actual first frame rendered from the editable source for comparison.
 local out=root.."/qa/"..a.id..".png"
 render:saveAs{filename=out,palette=s.palettes[1]}
 pcall(function() s:close() end)
 results[#results+1]=a.id
end
print("REOPENED "..#results)

