from pathlib import Path
import json,struct,hashlib,zipfile,re,html
from PIL import Image
root=Path(__file__).resolve().parent
m=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
assets=m['assets']
assert len(assets)==119,len(assets)
problems=[]
for a in assets:
    raw=(root/a['aseprite']).read_bytes()
    size,magic,frames,w,h,depth=struct.unpack_from('<I5H',raw)
    assert magic==0xA5E0 and size==len(raw),(a['id'],'aseprite header')
    assert (frames,w,h,depth)==(a['frames'],a['width'],a['height'],8),(a['id'],'header mismatch')
    # Parse frame and chunk boundaries, palette, layers and animation tags.
    pos=128;layers=[];tags=0;palette=False
    for fi in range(frames):
        frameSize,frameMagic,oldChunks,duration=struct.unpack_from('<I3H',raw,pos)
        assert frameMagic==0xF1FA and duration>0,(a['id'],'frame')
        chunks32=struct.unpack_from('<I',raw,pos+12)[0]
        count=chunks32 if oldChunks==0xffff else oldChunks
        cp=pos+16
        for _ in range(count):
            length,typ=struct.unpack_from('<IH',raw,cp)
            assert length>=6 and cp+length<=pos+frameSize
            if typ==0x2004: layers.append(typ)
            if typ==0x2018: tags+=struct.unpack_from('<H',raw,cp+6)[0]
            if typ==0x2019: palette=True
            cp+=length
        assert cp==pos+frameSize,(a['id'],'chunk length')
        pos+=frameSize
    assert pos==len(raw)
    assert len(layers)>=2 and tags>=1 and palette,(a['id'],'layers tags palette')
    with Image.open(root/a['png']) as im:
        im.load();assert im.size==(w,h)
        colors=im.convert('RGBA').getcolors(w*h)
        assert colors and len(colors)<=64,(a['id'],'colors')
        alpha=im.convert('RGBA').getchannel('A')
        assert set(alpha.tobytes()).issubset({0,255}),(a['id'],'alpha')
        a['usedColors']=len(colors)
        a['alphaBounds']=alpha.getbbox()
        if a['category'] not in ['scenes','station','atlases']:
            bbox=alpha.getbbox()
            assert bbox and bbox[0]>0 and bbox[1]>0 and bbox[2]<w and bbox[3]<h,(a['id'],'clipped')
    with Image.open(root/a['sheet']) as im:
        im.load();assert im.size==(w*frames,h)
        if frames>1:
            fingerprints={hashlib.sha256(im.crop((i*w,0,(i+1)*w,h)).tobytes()).hexdigest() for i in range(frames)}
            assert len(fingerprints)>=3,(a['id'],'no animation variation')
            a['distinctFrames']=len(fingerprints)
    metadata=json.loads((root/a['metadata']).read_text(encoding='utf-8'))
    assert len(metadata['frames'])==frames
    a['sha256']=hashlib.sha256(raw).hexdigest()
    a['layerCount']=len(layers)
m['verification']={'asepriteFiles':119,'nativeIndexed':True,'paletteEntries':64,'binaryAlpha':True,'frames':sum(a['frames'] for a in assets),'animatedActors':sum(a['kind']=='actor' for a in assets),'animatedEffects':sum(a['kind']=='effect' for a in assets),'gameIntegration':False}
(root/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(m['verification'],indent=2))

