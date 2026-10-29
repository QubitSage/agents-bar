"""Build a private portable alpha from an explicit allowlist. Never launch it."""
import hashlib
import argparse
import json
from pathlib import Path
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--final', action='store_true', help='Build the final reviewed code revision separately from the first candidate')
args = parser.parse_args()
VERSION = '0.9.12'
NAME = f'AgentsBar-{VERSION}-win64' + ('-final' if args.final else '')
DEST = ROOT / 'release' / NAME
ARCHIVE = ROOT / 'release' / (NAME + '.zip')


def copy_file(source, relative):
    target = DEST / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)


def main():
    if DEST.exists() or ARCHIVE.exists():
        raise SystemExit('Release already exists. Choose a new release name; existing builds are preserved.')
    DEST.mkdir(parents=True)
    for name in ['app.gd', 'main.gd', 'main.tscn', 'project.godot', 'presentation.gd']:
        copy_file(ROOT / 'game' / name, Path('game') / name)
    for folder in ['assets', 'content', 'gameplay', 'ui', 'audio']:
        for source in sorted((ROOT / 'game' / folder).rglob('*')):
            if source.is_file() and source.suffix in {'.png', '.json', '.gd'}:
                copy_file(source, source.relative_to(ROOT))
    for source in sorted((ROOT / 'bridge').glob('*.py')):
        copy_file(source, source.relative_to(ROOT))
    for source in sorted((ROOT / 'licenses').glob('*')):
        if source.is_file():
            copy_file(source, source.relative_to(ROOT))
    for name in ['start.ps1', 'Iniciar Agents Bar.cmd', 'Demonstrar Agents Bar.cmd', 'Demonstrar AZHOR.cmd', 'CREDITS.md', 'install.ps1', 'installed-launcher.ps1', 'Instalar ou atualizar.cmd']:
        copy_file(ROOT / name, name)
    copy_file(ROOT / 'docs' / f'RELEASE-{VERSION}.md', 'LEIA-ME.md')
    copy_file(ROOT / 'docs' / 'CONNECTIONS.md', 'docs/CONNECTIONS.md')
    copy_file(ROOT / 'docs' / 'MANUAL-TESTS.md', 'docs/MANUAL-TESTS.md')
    for name in ['INTEGRATIONS.md','GAMEPLAY-0.6.md','INFRASTRUCTURE.md','HUD-0.8.md','GAMEPLAY-0.8.md','DISTRIBUTION-0.9.9.md','VERIFY-0.9.9.md','QUICKSTART-0.9.9.md','ACCEPTANCE-0.9.9.md','PRIVACY-DATA-FLOW.md']:
        copy_file(ROOT / 'docs' / name, Path('docs')/name)
    copy_file(ROOT/'scripts/configure_tracking.py','scripts/configure_tracking.py')
    copy_file(ROOT/'scripts/claude_settings.py','scripts/claude_settings.py')
    copy_file(ROOT/'Preparar integracoes.cmd','Preparar integracoes.cmd')
    for source in sorted((ROOT/'tools/python').rglob('*')):
        if source.is_file() and '__pycache__' not in source.parts:
            copy_file(source,source.relative_to(ROOT))
    engine = Path('tools/godot/Godot_v4.7.2-stable_win64.exe')
    copy_file(ROOT / engine, engine)
    manifest = {'version': VERSION, 'kind': 'private-release-candidate', 'files': []}
    for file in sorted(DEST.rglob('*')):
        if file.is_file():
            manifest['files'].append({'path': file.relative_to(DEST).as_posix(), 'bytes': file.stat().st_size,
                                      'sha256': hashlib.sha256(file.read_bytes()).hexdigest()})
    (DEST / 'manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    with zipfile.ZipFile(ARCHIVE, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for file in sorted(DEST.rglob('*')):
            if file.is_file():
                archive.write(file, Path(NAME) / file.relative_to(DEST))
    with zipfile.ZipFile(ARCHIVE) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError('Archive integrity failed: ' + bad)
    print(json.dumps({'folder': str(DEST), 'zip': str(ARCHIVE), 'files': len(manifest['files']),
                      'zipBytes': ARCHIVE.stat().st_size,
                      'zipSha256': hashlib.sha256(ARCHIVE.read_bytes()).hexdigest()}, indent=2))


if __name__ == '__main__':
    main()
