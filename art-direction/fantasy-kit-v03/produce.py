"""Run Aseprite's Lua production pipeline without opening its interface."""
from pathlib import Path
import subprocess,sys
root=Path(__file__).resolve().parent
exe=Path(sys.argv[1]) if len(sys.argv)>1 else Path(r'C:\Program Files (x86)\Steam\steamapps\common\Aseprite\Aseprite.exe')
with (root/'production.log').open('w',encoding='utf-8') as out:
    result=subprocess.run([str(exe),'--batch','--noinapp','--script-param','root='+root.as_posix(),'--script',str(root/'build-assets.lua')],cwd=root,stdout=out,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
print('Aseprite exit:',result.returncode)
print((root/'production.log').read_text(encoding='utf-8')[-1800:])
if result.returncode==0:
    subprocess.run([sys.executable,str(root/'catalog.py')],check=True)
sys.exit(result.returncode)
