from pathlib import Path
import json,struct
root=Path(__file__).resolve().parent
old=json.loads((root/'masters/v02/manifest.json').read_text(encoding='utf-8'))['assets']
new=json.loads((root/'boss-prompts.json').read_text(encoding='utf-8'))['assets']
titles={a['id']:a['title'] for a in old+new}
titles['boss-06-stained-glass-hydra']='A Hidra dos Juramentos'
origins={}
for a in old:
    for i,title in enumerate(a.get('items',[]),1):
        id=a['id']+'-'+str(i).zfill(2)
        titles[id]=title
        origins[id]=a['id']
assets=[]
for path in sorted((root/'aseprite').rglob('*.aseprite')):
    raw=path.read_bytes()
    _,_,frames,w,h,_=struct.unpack_from('<I5H',raw)
    id=path.stem;cat=path.parent.name
    stem=cat+'/'+id
    kind='actor' if frames==12 else 'effect' if frames==6 else 'static'
    assets.append(dict(id=id,title=titles[id],category=cat,width=w,height=h,frames=frames,aseprite='aseprite/'+stem+'.aseprite',png='png/'+stem+'.png',sheet='sheets/'+stem+'.png',metadata='metadata/'+stem+'.json',origin=origins.get(id,id),kind=kind,pivot=dict(x=w//2,y=h-12 if kind=='actor' else h//2)))
assert len(assets)==119
m=dict(version='v03',tool='Aseprite 1.3.18.6',paletteColors=64,assets=assets,notes=['AI bases; pixel processing and motion in Aseprite Lua','Idle/hit/burst are procedural motion studies','Articulated walk/attack and Godot integration pending'])
(root/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
print('Manifest:',len(assets),'Aseprite files')

