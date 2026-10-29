from pathlib import Path
import json,shutil
root=Path(__file__).resolve().parent
old=root.parent/'fantasy-kit-v03'
shutil.copy2(root.parent/'azhor-sprites-v02/source/agents-bar-64.gpl',root/'sources/agents-bar-64.gpl')
(root/'sources/references').mkdir(exist_ok=True)
assets=json.loads((root/'inventory.json').read_text(encoding='utf-8'))['assets']
for a in assets:
    dest=root/'sources/baseline'/a['png'];dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(old/a['png'],dest)
    if a['category'] in ['heroes','companions','enemies','bosses','npcs','world-boss']:shutil.copy2(old/a['png'],root/'sources/references'/Path(a['png']).name)
for name in ['assemble.lua','build-hud.lua','build-environments.lua']:
    p=root/'scripts'/name
    content=p.read_text(encoding='utf-8').replace("root..'/../azhor-sprites-v02/source/agents-bar-64.gpl'","root..'/sources/agents-bar-64.gpl'").replace("root..'/../fantasy-kit-v03/'..a.png","root..'/sources/baseline/'..a.png")
    p.write_text(content,encoding='utf-8')
print('Palette and baseline references included')
