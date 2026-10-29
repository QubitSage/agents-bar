from pathlib import Path
import json,subprocess,sys
from PIL import Image
import numpy as np
root=Path(__file__).resolve().parent
jobs=json.loads((root/'generation-jobs.json').read_text(encoding='utf-8'))
if (root/'extra-jobs.json').exists():jobs+=json.loads((root/'extra-jobs.json').read_text(encoding='utf-8'))
if (root/'azhor-existing.json').exists():jobs+=json.loads((root/'azhor-existing.json').read_text(encoding='utf-8'))
only=sys.argv[1:] or None
for job in jobs:
    if only and job['id'] not in only:continue
    source=root/'sources'/f"{job['id']}.png"
    if not source.exists():continue
    done=root/'aseprite'/f"{job['id']}.aseprite"
    if done.exists() and done.stat().st_mtime>max(source.stat().st_mtime,Path(__file__).stat().st_mtime,(root/'scripts/assemble.lua').stat().st_mtime):continue
    im=Image.open(source)
    # Read-only alpha analysis locates real empty gutters, including uneven rows.
    rgba=np.asarray(im.convert('RGBA'))
    rgb=rgba[:,:,:3].astype(np.int16)
    hi=rgb.max(axis=2);lo=rgb.min(axis=2)
    mask=(rgba[:,:,3]>=220)&~((hi>248)&(lo<6)&((rgb.sum(axis=2)-hi-lo)<18))
    def cuts(projection, count):
        length=len(projection); step=length/count; result=[0]
        for k in range(1,count):
            ideal=k*step; low=max(result[-1]+8,int(ideal-step*.24)); high=min(length-8,int(ideal+step*.24))
            cut=min(range(low,high),key=lambda x: float(projection[max(0,x-2):x+3].sum())+abs(x-ideal)*.02)
            result.append(cut)
        return result+[length]
    ys=cuts(mask.sum(axis=1),job['rows']); bounds=[]
    for row in range(job['rows']):
        xs=cuts(mask[ys[row]:ys[row+1]].sum(axis=0),job['columns'])
        for col in range(job['columns']):bounds.append([xs[col],ys[row],xs[col+1]-xs[col],ys[row+1]-ys[row]])
    if job['id']=='companion-luma--combat':
        # The generated leaf beam crosses the cell gutter. Keep its whole arc,
        # exclude the adjacent figure, and use a clean kneeling recovery pose.
        bounds[6]=[618,343,530,310]
        bounds[7]=bounds[12].copy()
        job['exclude']={'7':{'xGreater':1000,'yGreater':474}}
    job['bounds']=bounds
    job['scale']=min((job['width']-16)/max(b[2] for b in bounds),(job['height']-16)/max(b[3] for b in bounds))
    if job['category'] in ['heroes','companions','enemies','bosses','npcs','world-boss']:
        # Normalize once per whole sheet using an upright ready pose; never fit
        # individual action frames or enlarge a fallen corpse.
        anchor=3 if job['id'].endswith('--combat') else 0
        b=bounds[anchor];ys0,xs0=np.nonzero(mask[b[1]:b[1]+b[3],b[0]:b[0]+b[2]])
        if len(ys0):
            target=160 if job['category']=='bosses' else 175 if job['category']=='world-boss' else 96
            if job['actor'] in ['enemy-copper-crab','enemy-sporeling']:target=72
            if job['actor']=='enemy-storm-wisp':target=80
            job['scale']=target/(int(ys0.max())-int(ys0.min())+1)
            minimum=288 if job['category'] in ['bosses','world-boss'] else 192
            job['width']=max(minimum,int(np.ceil((max(b[2] for b in bounds)*job['scale']+24)/16))*16)
            job['height']=max(minimum,int(np.ceil((max(b[3] for b in bounds)*job['scale']+32)/16))*16)
    job['sourceSize']=im.size
    (root/'qa'/f"{job['id']}-crop.json").write_text(json.dumps(dict(sourceSize=im.size,bounds=bounds,scale=job['scale']),indent=2))
    config=root/'scripts'/f"job-{job['id']}.json";config.write_text(json.dumps(job),encoding='utf-8')
    r=subprocess.run([r'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe','--batch','--noinapp','--script-param','root='+root.as_posix(),'--script-param','job='+config.as_posix(),'--script',str(root/'scripts/assemble.lua')],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
    print(r.stdout.strip(),r.stderr.strip(),flush=True)
    if r.returncode:raise RuntimeError(job['id'])
