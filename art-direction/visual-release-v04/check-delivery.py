from pathlib import Path
import json,hashlib
from PIL import Image
import numpy as np
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
comparisons=[];errors=[];gif_count=0
for a in json.loads((root/'qa/roundtrip-list.json').read_text(encoding='utf-8')):
    sheet=Image.open(root/a['sheet']).convert('RGBA');w,h=a['width'],a['height']
    for f in range(a['frames']):
        x=f%a['columns']*w;y=f//a['columns']*h
        expected=np.array(sheet.crop((x,y,x+w,y+h)))
        actual=np.array(Image.open(root/'qa'/f"{a['id']}-native-{f+1}.png").convert('RGBA'))
        if actual.shape!=expected.shape:errors.append(a['id']+' dimensions');continue
        actual[actual[:,:,3]==0,:3]=0;expected[expected[:,:,3]==0,:3]=0
        equal=bool(np.array_equal(actual,expected));comparisons.append(dict(id=a['id'],frame=f+1,equal=equal))
        if not equal:errors.append(a['id']+' pixels')
for a in manifest['assets']:
    for field in ['aseprite','sheet']:
        if not (root/a[field]).exists():errors.append(a['id']+' missing '+field)
    if a['frames']>1 and a['category']!='hud':
        p=root/'previews'/f"{a['id']}.gif"
        if not p.exists():errors.append(a['id']+' missing GIF');continue
        im=Image.open(p);gif_count+=1
        if im.n_frames!=a['frames']:errors.append(a['id']+' GIF frame count')
        ds=[]
        for f in range(im.n_frames):im.seek(f);ds.append(im.info.get('duration',0))
        if ds!=a['durations']:errors.append(a['id']+' GIF durations')
result=dict(nativeComparisons=len(comparisons),allNativePixelsMatch=all(c['equal'] for c in comparisons),gifFilesChecked=gif_count,errors=errors,comparisons=comparisons)
(root/'qa/delivery-check.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in result.items() if k!='comparisons'}))
if errors:raise SystemExit(1)
