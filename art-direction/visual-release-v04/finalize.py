from pathlib import Path
import json,struct,hashlib,subprocess,collections,shutil,html,zipfile
from PIL import Image
import numpy as np
root=Path(__file__).resolve().parent
assets=[];issues=[]
labels={
'props':['Baú','Barril','Caixote','Estandarte','Lanterna','Banco','Bigorna','Mapa','Vaso medicinal','Cristal','Coluna quebrada','Placa de rota'],
'relics':['Lente de análise','Placa de proteção','Semente vítrea','Broto ancestral','Bobina de tempestade','Farol portátil','Sucata','Núcleo','Sementes'],
'terrain':[biome+' · '+part for biome in ['Forja','Jardim','Torres'] for part in ['Piso','Borda esquerda','Borda direita','Escada','Pilar','Ruína']]}
for path in sorted((root/'metadata').glob('*.json')):
    a=json.loads(path.read_text(encoding='utf-8'))
    if a['category'] in labels:a['title']=labels[a['category']][int(a['id'].split('-')[-1])-1]
    controlNames={'play':'Reproduzir','pause':'Pausar','minimize':'Recolher','close':'Fechar','map':'Mapa','team':'Equipe','station':'Estação','journal':'Diário','victory':'Vitória','attention':'Atenção','disconnected':'Desconectado','sound':'Som'}
    if a['id'].startswith('ui-control-'):a['title']=controlNames[a['id'][11:]]
    state=a['state'];a['events']=a.get('events',[])
    if state=='attack' or state.startswith('attack_'):a['events']=[dict(frame=5 if a['frames']==8 else 2,name='visual_impact')]
    elif state=='special':a['events']=[dict(frame=3,name='visual_release')]
    elif state=='ultimate':a['events']=[dict(frame=5,name='visual_release'),dict(frame=6,name='visual_impact')]
    elif state=='defense':a['events']=[dict(frame=2,name='guard_pose_start'),dict(frame=a['frames']-1,name='guard_pose_end')]
    native=root/a['aseprite'];sheet=root/a['sheet']
    if not native.exists() or not sheet.exists():issues.append({'id':a['id'],'issue':'missing artifact'});continue
    header=struct.unpack('<I5H',native.read_bytes()[:14]);size,magic,frames,w,h,depth=header
    if (magic,frames,w,h,depth)!=(0xA5E0,a['frames'],a['width'],a['height'],8):issues.append({'id':a['id'],'issue':'native header mismatch','header':header})
    im=Image.open(sheet).convert('RGBA');pixels=np.asarray(im)
    if im.size!=(a['columns']*w,a['rows']*h):issues.append({'id':a['id'],'issue':'sheet dimensions'})
    if set(np.unique(pixels[:,:,3]))-{0,255}:issues.append({'id':a['id'],'issue':'non-binary alpha'})
    hashes=[];bounds=[];empty=[]
    for f in range(a['frames']):
        cell=pixels[(f//a['columns'])*h:(f//a['columns']+1)*h,(f%a['columns'])*w:(f%a['columns']+1)*w]
        hashes.append(hashlib.sha256(cell.tobytes()).hexdigest())
        ys,xs=np.nonzero(cell[:,:,3])
        if len(xs):bounds.append([int(xs.min()),int(ys.min()),int(xs.max())+1,int(ys.max())+1])
        else:empty.append(f+1);bounds.append(None)
    a['uniqueFrames']=len(set(hashes));a['alphaBounds']=bounds;a['sha256']=hashlib.sha256(native.read_bytes()).hexdigest()
    if empty:issues.append({'id':a['id'],'issue':'empty frames','frames':empty})
    if a['frames']>1 and a['uniqueFrames']==1:issues.append({'id':a['id'],'issue':'all frames identical'})
    if len(a['durations'])<a['frames']:issues.append({'id':a['id'],'issue':'missing durations'})
    gif=root/'previews'/f"{a['id']}.gif"
    if gif.exists():a['gif']='previews/'+gif.name
    path.write_text(json.dumps(a,ensure_ascii=False,indent=2),encoding='utf-8');assets.append(a)
jobs=json.loads((root/'generation-jobs.json').read_text(encoding='utf-8'))+json.loads((root/'extra-jobs.json').read_text(encoding='utf-8'))+json.loads((root/'azhor-existing.json').read_text(encoding='utf-8'))
ids={a['id'] for a in assets}
for j in jobs:
    for state in j['states']:
        ident=j['actor']+'--'+state
        if ident not in ids:issues.append({'id':ident,'issue':'planned clip absent'})
counts=dict(collections.Counter(a['category'] for a in assets))
summary={'assets':len(assets),'nativeFiles':len(list((root/'aseprite').glob('*.aseprite'))),'characters':len({a['actor'] for a in assets if a['category'] in ['heroes','companions','enemies','bosses','world-boss','npcs']}),'animationClips':sum(a['frames']>1 and a['category']!='hud' for a in assets),'frames':sum(a['frames'] for a in assets),'categories':counts,'issues':issues}
manifest={'version':'v04','date':'2026-10-26','summary':summary,'palette':'64 indexed colors including transparency','assets':assets,'provenance':'Complete pose sheets generated with imagegen; raster assembly, palette conversion, native cels and UI in Aseprite batch. Ambient FX on separate layers.','limitations':['Generated details can vary between poses; small actor actions use four key poses.','Final game-scale readability, motion timing and runtime integration need validation in the next game stage.','Visual library only; no game mechanics, hitboxes or real session connection implemented here.']}
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
(root/'data.js').write_text('window.ASSETS='+json.dumps(assets,ensure_ascii=False)+';',encoding='utf-8')
(root/'qa/validation.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=False),flush=True)
if issues:raise SystemExit('Resolve validation issues before packaging')
sample=['hero-classic--attack','boss-04-furnace-executioner--special','world-boss-09-azhor--death','world-boss-09-azhor--ultimate','effects-steel--slash','environment-wild--foliage','scene-garden-1','ui-control-close','ui-bar-health','atlas-terrain-01','npc-artisan--work']
nativecheck=[a for a in assets if a['id'] in sample]
(root/'qa/roundtrip-list.json').write_text(json.dumps(nativecheck),encoding='utf-8')
# Contact pages for inspection of every generated motion/combat sheet.
sources=[j['id'] for j in jobs]
(root/'qa/contact-list.json').write_text(json.dumps(sources))
