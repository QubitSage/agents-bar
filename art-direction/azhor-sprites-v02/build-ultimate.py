from pathlib import Path
import subprocess, json, struct, hashlib
from PIL import Image

root = Path(__file__).resolve().parent
aseprite = r'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe'
lua = (root/'assemble-attack.lua').read_text(encoding='utf-8')
lua = lua.replace('attack_basic', 'ultimate')
lua = lua.replace('local bounds={{0,0,512,384},{530,0,490,384},{1030,0,460,384},{1480,0,568,384},{0,390,556,365},{570,390,474,365},{1050,390,468,365},{1540,390,508,365}}',
'''local bounds={{0,0,512,384},{512,0,512,384},{1024,0,512,384},{1536,0,512,416},{0,390,512,365},{512,416,524,339},{1040,416,496,339},{1536,416,512,339}}''')
lua = lua.replace('{260,150,130,80,110,120,150,380}', '{360,220,170,400,200,220,280,500}')
lua = lua.replace('288,208','288,256').replace('1152,416','1152,512').replace('y+oy<208','y+oy<256').replace('math.floor((f-1)/4)*208','math.floor((f-1)/4)*256').replace('288x208','288x256')
lua = lua.replace('local oy=f<=4 and 3 or 18', 'local oy=51\n  if f==4 then oy=5 elseif f==5 then oy=63 elseif f>5 then oy=76 end')
# The fifth generated pose has its eclipse clipped by the sheet row.
# Repair that effect with the complete eclipse from pose four, in Aseprite.
lua = lua.replace('  s:newCel(s.layers[1],f,img,Point(0,0))', '''  if f==5 then
    for y=0,59 do for x=0,81 do
      local c=source:getPixel(1700+x*2,y*2)
      if pc.rgbaA(c)>=220 then
        img:drawPixel(71+x,33+y,nearest(pc.rgbaR(c),pc.rgbaG(c),pc.rgbaB(c)))
      end
    end end
  end
  s:newCel(s.layers[1],f,img,Point(0,0))''')
(root/'assemble-ultimate.lua').write_text(lua,encoding='utf-8')
for args in [ ['--script-param','root='+root.as_posix(),'--script',str(root/'assemble-ultimate.lua')], [str(root/'ultimate.aseprite'),'--save-as',str(root/'ultimate.gif')]]:
    result=subprocess.run([aseprite,'--batch','--noinapp',*args],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
    print(result.stdout,result.stderr)
    if result.returncode: raise SystemExit(result.returncode)
im=Image.open(root/'ultimate.gif')
durations=[]; hashes=[]
for i in range(im.n_frames):
    im.seek(i); durations.append(im.info['duration']); hashes.append(hashlib.sha256(im.convert('RGBA').tobytes()).hexdigest())
report={'frames':im.n_frames,'distinct_frames':len(set(hashes)),'durations_ms':durations,'total_ms':sum(durations),'aseprite_header':struct.unpack('<I5H',(root/'ultimate.aseprite').read_bytes()[:14])}
(root/'ultimate-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report))
