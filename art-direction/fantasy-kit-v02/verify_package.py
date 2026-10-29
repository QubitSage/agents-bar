from pathlib import Path
from PIL import Image
import json, hashlib, zipfile, re
root=Path(__file__).resolve().parent
manifest=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
for a in manifest['assets']:
    p=root/a['file']
    with Image.open(p) as im:
        im.load()
        a['width'],a['height']=im.size
        a['mode']=im.mode
        a['bytes']=p.stat().st_size
        a['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
        alpha=im.getchannel('A') if 'A' in im.getbands() else None
        a['hasTransparency']=bool(alpha and alpha.getextrema()[0]<255)
        a['alphaBounds']=list(alpha.getbbox()) if alpha else [0,0,im.width,im.height]
        a['productionReady']=False
        if a['category'] in ['scenes','station']:
            assert not a['hasTransparency'], a['id']
        else:
            assert a['hasTransparency'], a['id']
assert len(manifest['assets'])==38
assert sum(len(a.get('items',[])) for a in manifest['assets'])==75
(root/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
html=(root/'index.html').read_text(encoding='utf-8')
assert len(re.findall(r'<article class="card">',html))==38
for link in re.findall(r'(?:src|href)="([^"]+)"',html):
    if not link.startswith(('#','https:')):
        assert (root/link).is_file(), link
package=root.parent/'Agents-Bar-Fantasy-Kit-v02.zip'
files=[a['file'] for a in manifest['assets']]+['index.html','README.md','manifest.json','prompts.json','production-plan.json']
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
    for f in files:
        z.write(root/f,'Agents-Bar-Fantasy-Kit-v02/'+f)
with zipfile.ZipFile(package) as z:
    assert z.testzip() is None
    assert len(z.namelist())==43
report={'images':38,'atlasElements':75,'zipEntries':43,'archive':str(package),'archiveMiB':round(package.stat().st_size/1024/1024,1),'transparentImages':sum(a['hasTransparency'] for a in manifest['assets']),'opaqueBackgrounds':sum(not a['hasTransparency'] for a in manifest['assets']),'galleryLinks':'all present','runtimeIntegration':False,'visualAcceptance':'pending'}
(root/'verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))

