from pathlib import Path
import json,subprocess,concurrent.futures
root=Path(__file__).resolve().parent
assets=json.loads((root/'manifest.json').read_text(encoding='utf-8'))['assets']
jobs=[a for a in assets if a['frames']>1 and a['category']!='hud']
def export(a):
    destination=root/'previews'/f"{a['id']}.gif"
    if destination.exists() and destination.stat().st_mtime>(root/a['aseprite']).stat().st_mtime:return
    result=subprocess.run([r'C:/Program Files (x86)/Steam/steamapps/common/Aseprite/Aseprite.exe','--batch','--noinapp',str(root/a['aseprite']),'--save-as',str(destination)],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
    if result.returncode:raise RuntimeError(a['id']+result.stderr)
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    for i,_ in enumerate(pool.map(export,jobs),1):
        if i%25==0:print(i,'/',len(jobs),flush=True)
print('GIF previews:',len(jobs))
