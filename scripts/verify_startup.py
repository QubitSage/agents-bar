"""Explicitly authorized isolated headless UI smoke test; no personal saves or sessions."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--game',type=Path,default=ROOT/'game',help='Game folder to copy into the isolated fixture')
    args=parser.parse_args()
    runtime=ROOT/'runtime'
    runtime.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='startup-fixture-',dir=runtime) as directory:
        fixture=Path(directory)
        shutil.copytree(args.game,fixture/'game',ignore=shutil.ignore_patterns('.godot'))
        shutil.copyfile(ROOT/'game/test_startup.gd',fixture/'game/test_startup.gd')
        env=dict(os.environ,APPDATA=str(fixture/'appdata'),LOCALAPPDATA=str(fixture/'localappdata'),AGENTS_BAR_TEST_ROOT=str(fixture),AGENTS_BAR_DATA=str(fixture/'data'))
        for name,args in [('disconnected',[]),('demo',['--demo']),('azhor',['--demo-azhor'])]:
            log=runtime/f'startup-{name}.log'
            result=subprocess.run([str(ROOT/'tools/godot/Godot_v4.7.2-stable_win64.exe'),'--headless','--path',str(fixture/'game'),'--script','res://test_startup.gd','--log-file',str(log),'--',*args],env=env,capture_output=True,timeout=45)
            output=result.stdout.decode('utf-8',errors='replace')+result.stderr.decode('utf-8',errors='replace')
            text=log.read_text(encoding='utf-8') if log.exists() else output
            print(name,output)
            if result.returncode or 'ERROR:' in text or 'FAIL:' in text or '16 checks, 0 failures' not in text:
                raise SystemExit('Startup fixture failed: '+name)
        print('All three isolated HUD startup modes passed. No visible window or real session.')
if __name__=='__main__':main()
