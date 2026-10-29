from pathlib import Path
import json, subprocess
root=Path(__file__).resolve().parent
old=root.parent/'fantasy-kit-v03'
manifest=json.loads((old/'manifest.json').read_text(encoding='utf-8'))
actors=[a for a in manifest['assets'] if a['category'] in ['heroes','companions','enemies','bosses','npcs','world-boss']]
for d in ['sources','aseprite','sheets','previews','metadata','qa','static','scripts']:(root/d).mkdir(parents=True,exist_ok=True)
(root/'inventory.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
lua=['local out=app.params.root','local names='+json.dumps([str(old/a['png']).replace('\\','/') for a in actors]).replace('[','{').replace(']','}'), 'local sheet=Image(1536,1152,ColorMode.RGB)', 'for i,name in ipairs(names) do', ' local sprite=app.open(name)', ' local img=Image(sprite.width,sprite.height,ColorMode.RGB)', ' img:drawSprite(sprite,1,Point(0,0))', ' sprite:close()', ' local k=(i-1)%16', ' sheet:drawImage(img,Point((k%4)*384,math.floor(k/4)*288))', ' if i%16==0 or i==#names then sheet:saveAs(out.."/qa/references-"..math.ceil(i/16)..".png"); sheet=Image(1536,1152,ColorMode.RGB) end', 'end']
(root/'scripts/contact.lua').write_text('\n'.join(lua))
r=subprocess.run([r'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe','--batch','--noinapp','--script-param','root='+root.as_posix(),'--script',str(root/'scripts/contact.lua')],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
print(r.returncode,r.stdout,r.stderr)
print('\n'.join(str(i+1)+' '+a['id'] for i,a in enumerate(actors)))

