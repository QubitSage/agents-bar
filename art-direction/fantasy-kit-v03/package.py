from pathlib import Path
import json,zipfile,re
from PIL import Image
root=Path(__file__).resolve().parent
m=json.loads((root/'manifest.json').read_text(encoding='utf-8'))
for a in m['assets']:
    with Image.open(root/'qa'/(a['id']+'.png')) as im,Image.open(root/a['sheet']) as sheet:
        assert im.convert('RGBA').tobytes()==sheet.convert('RGBA').crop((0,0,a['width'],a['height'])).tobytes(),a['id']
    frame=2 if a['kind']=='effect' else 0
    with Image.open(root/a['png']) as im,Image.open(root/a['sheet']) as sheet:
        assert im.convert('RGBA').tobytes()==sheet.convert('RGBA').crop((frame*a['width'],0,(frame+1)*a['width'],a['height'])).tobytes(),a['id']+' poster'
m['verification']['asepriteReopened']=119
m['verification']['firstFrameRoundtripMatches']=119
m['verification']['staticPostersMatch']=119
(root/'manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),encoding='utf-8')
page=(root/'index.html').read_text(encoding='utf-8')
assert page.count('<article class="card"')==119
for link in re.findall(r'href="([^"]+)"',page):
    assert (root/link).is_file(),link
files=set()
for a in m['assets']:
    for key in ['aseprite','png','sheet','metadata']:
        files.add(a[key])
for folder in ['masters','palettes']:
    for p in (root/folder).rglob('*'):
        if p.is_file():files.add(p.relative_to(root).as_posix())
for name in ['README.md','BOSSES.md','index.html','manifest.json','boss-prompts.json','build-assets.lua','produce.py','catalog.py','verify.py','build-gallery.py','audit-aseprite.lua','package.py']:
    files.add(name)
package=root.parent/'Agents-Bar-Aseprite-v03.zip'
with zipfile.ZipFile(package,'w',zipfile.ZIP_DEFLATED) as z:
    for name in sorted(files):
        z.write(root/name,'Agents-Bar-Aseprite-v03/'+name)
with zipfile.ZipFile(package) as z:
    assert z.testzip() is None
    assert sum(n.endswith('.aseprite') for n in z.namelist())==119
report={**m['verification'],'archive':str(package),'archiveMiB':round(package.stat().st_size/1024/1024,1),'zipEntries':len(files),'galleryLinks':'all present'}
(root/'delivery-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))

