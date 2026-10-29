"""Copy the runtime subset of the approved visual library, without editing pixels."""
from pathlib import Path
import json, shutil
root=Path(__file__).resolve().parents[1]
source=root/'art-direction/visual-release-v04'
target=root/'game/assets/v04'
actors={'world-boss-09-azhor','hero-classic','companion-brasa','companion-luma','enemy-brass-sentry','enemy-copper-crab','boss-rebocador','enemy-sporeling','enemy-root-warden','boss-sylvan-heart','enemy-storm-wisp','enemy-storm-sentinel','boss-storm-archon'}
assets=json.loads((source/'manifest.json').read_text(encoding='utf-8'))['assets']
catalog={}
for asset in assets:
    if asset['actor'] not in actors and asset['category'] not in {'hud','scenes','station','buildings','effects','relics'}:continue
    dest=target/asset['sheet'];dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source/asset['sheet'],dest)
    catalog[asset['id']]=asset
for path in (source/'static').glob('ui-bar-*.png'):
    (target/'static').mkdir(exist_ok=True);shutil.copy2(path,target/'static'/path.name)
(target/'catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print(f'Imported {len(catalog)} visual entries into game/assets/v04')
