from pathlib import Path
import json,shutil
root=Path(__file__).resolve().parent
old=root.parent/'fantasy-kit-v03'
generated=Path(r'C:/Users/bruno/.codex/generated_images/01a17888-a104-77b2-895e-a212366b0849')
mapping={'attack_01_stomp':'exec-49ab2ca6-4219-4030-9e8a-863495ec8756.png','attack_02_tail':'exec-c00b47b1-27eb-4d9f-a7d5-16f077c432e8.png','attack_03_beam':'exec-e2adaada-09a0-45ab-b421-620a20ffb672.png','attack_04_barrage':'exec-65e4bc88-a690-4708-b04a-38728747e45a.png','defense':'exec-af7d0452-b563-41a3-9e2c-30dbb7f46cd8.png'}
jobs=[]
for state,file in mapping.items():
    ident='azhor--'+state
    shutil.copy2(generated/file,root/'sources'/f'{ident}.png')
    jobs.append(dict(id=ident,actor='world-boss-09-azhor',title='AZHOR',category='world-boss',states=[state],width=288,height=256,columns=4,rows=2,ms=[180,150,130,110,100,140,170,280]))
(root/'azhor-existing.json').write_text(json.dumps(jobs,indent=2))
preview=root.parent/'azhor-sprites-v02'
for state in ['attack_basic','ultimate']:
    ident='world-boss-09-azhor--'+state
    shutil.copy2(preview/f'{state}.aseprite',root/'aseprite'/f'{ident}.aseprite')
    shutil.copy2(preview/f'{state}-sheet.png',root/'sheets'/f'{ident}.png')
    shutil.copy2(preview/f'{state}.gif',root/'previews'/f'{ident}.gif')
    ms=[260,150,130,80,110,120,150,380] if state=='attack_basic' else [360,220,170,400,200,220,280,500]
    h=208 if state=='attack_basic' else 256
    meta=dict(id=ident,actor='world-boss-09-azhor',title='AZHOR',category='world-boss',state=state,width=288,height=h,columns=4,rows=2,frames=8,durations=ms,loop=False,pivot=dict(x=144,y=190 if h==208 else 236),events=[dict(frame=5,name='impact')],aseprite=f'aseprite/{ident}.aseprite',sheet=f'sheets/{ident}.png',gif=f'previews/{ident}.gif',method='Approved v02 poses preserved unchanged')
    (root/'metadata'/f'{ident}.json').write_text(json.dumps(meta))
assets=json.loads((root/'inventory.json').read_text(encoding='utf-8'))['assets']
for a in assets:
    if a['category'] not in ['terrain','props','relics']:continue
    shutil.copy2(old/a['aseprite'],root/'aseprite'/f"{a['id']}.aseprite")
    shutil.copy2(old/a['png'],root/'static'/f"{a['id']}.png")
    meta=dict(id=a['id'],actor=a['id'],title=a['title'],category=a['category'],state='static',frames=1,columns=1,rows=1,width=a['width'],height=a['height'],durations=[1000],loop=False,sheet=f"static/{a['id']}.png",aseprite=f"aseprite/{a['id']}.aseprite",method='Existing approved static asset preserved')
    (root/'metadata'/f"{a['id']}.json").write_text(json.dumps(meta,ensure_ascii=False),encoding='utf-8')
print('AZHOR previous pose sheets and 39 static assets preserved')
