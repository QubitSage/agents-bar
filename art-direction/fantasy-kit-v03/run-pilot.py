import subprocess,json
from pathlib import Path
root=Path(__file__).resolve().parent
exe=r"C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe"
args=[exe,"--batch","--script-param","root="+root.as_posix(),"--script-param","only=hero-classic","--script",str(root/"build-assets.lua")]
r=subprocess.run(args,cwd=str(root),capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
print(json.dumps({"code":r.returncode,"stdout":r.stdout,"stderr":r.stderr}))

