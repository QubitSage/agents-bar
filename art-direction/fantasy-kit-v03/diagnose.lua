print('Before loading')
local f,err=loadfile('C:/Users/bruno/Desktop/All/Projetos/Tokens Bar/art-direction/fantasy-kit-v03/build-assets.lua')
print('Loaded',f,err)
if f then local ok,result=xpcall(f,function(err) return tostring(err)..'\n'..debug.traceback() end);print('Result',ok,result) end
