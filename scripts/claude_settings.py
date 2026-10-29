"""Merge or remove Agents Bar hooks in a Claude Code settings file without touching other entries.

Default is a dry run. --apply writes a timestamped backup first. Only hook entries whose command
references an Agents Bar observer script are ever added or removed; other keys are left as parsed.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import time

ROOT = Path(__file__).resolve().parents[1]
MARKERS = ('claude-observer.ps1', 'claude-statusline-observer.ps1')


def ours(entry):
    commands = [h.get('command', '') for h in entry.get('hooks', []) if isinstance(h, dict)] if isinstance(entry, dict) else []
    return any(marker in command for command in commands for marker in MARKERS)


def merge(settings, snippet, with_statusline=None):
    """Return (new_settings, report). Existing non-Agents-Bar hooks and statusLine are preserved."""
    result = json.loads(json.dumps(settings))
    report = {'added': [], 'kept': [], 'statusline': 'not-requested'}
    if not isinstance(result.get('hooks', {}), dict): raise ValueError('settings.hooks is not an object')
    hooks = result.setdefault('hooks', {})
    for event, entries in snippet['hooks'].items():
        current = hooks.get(event, [])
        if not isinstance(current, list): raise ValueError('hooks.' + event + ' is not a list')
        if any(ours(entry) for entry in current):
            report['kept'].append(event)
            hooks[event] = [entry for entry in current if not ours(entry)] + entries
        else:
            hooks[event] = current + entries
            report['added'].append(event)
    if with_statusline:
        if 'statusLine' in result and not ours({'hooks': [{'command': result['statusLine'].get('command', '')}]}):
            report['statusline'] = 'skipped-existing'  # Never replace the user's renderer.
        else:
            result['statusLine'] = with_statusline['statusLine']
            report['statusline'] = 'installed'
    return result, report


def remove(settings):
    result = json.loads(json.dumps(settings))
    removed = []
    for event in list(result.get('hooks', {})):
        entries = result['hooks'][event]
        kept = [entry for entry in entries if not ours(entry)]
        if len(kept) != len(entries): removed.append(event)
        if kept: result['hooks'][event] = kept
        else: del result['hooks'][event]
    if 'hooks' in result and not result['hooks']: del result['hooks']
    status = result.get('statusLine')
    if isinstance(status, dict) and ours({'hooks': [{'command': status.get('command', '')}]}):
        del result['statusLine']; removed.append('statusLine')
    return result, removed


def installed(settings):
    return any(ours(entry) for entries in settings.get('hooks', {}).values() if isinstance(entries, list) for entry in entries)


def write(path, value, backup=True):
    path = Path(path)
    saved = None
    if backup and path.exists():
        saved = path.with_name(path.name + '.agents-bar-' + time.strftime('%Y%m%d-%H%M%S') + '.bak')
        shutil.copy2(path, saved)
    temporary = path.with_suffix(path.suffix + '.tmp')
    temporary.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    os.replace(temporary, path)
    return saved


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--settings', required=True, help='Claude settings.json to modify (explicit; never discovered)')
    p.add_argument('--snippets', default=str(ROOT / 'integrations'))
    p.add_argument('--statusline', action='store_true', help='Also add the statusline observer if none is configured')
    p.add_argument('--remove', action='store_true')
    p.add_argument('--apply', action='store_true', help='Write changes (default: dry run)')
    p.add_argument('--json', action='store_true', help='Print a single machine-readable result line')
    args = p.parse_args()
    path = Path(args.settings)
    try:
        settings = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
        if not isinstance(settings, dict): raise ValueError('settings is not an object')
    except (OSError, ValueError) as error:
        print(json.dumps({'ok': False, 'error': 'unreadable: ' + type(error).__name__}) if args.json else 'Cannot read settings: ' + str(error))
        raise SystemExit(2)
    if args.remove:
        new, info = remove(settings)
    else:
        folder = Path(args.snippets)
        snippet = json.loads((folder / 'claude.settings.snippet.json').read_text(encoding='utf-8'))
        status = json.loads((folder / 'claude.statusline.snippet.json').read_text(encoding='utf-8')) if args.statusline else None
        new, info = merge(settings, snippet, status)
    saved = None
    written = bool(args.apply and new != settings)
    if written: saved = write(path, new)
    if args.json:
        print(json.dumps({'ok': True, 'changed': new != settings, 'written': written, 'backup': bool(saved), 'info': info, 'installed': installed(new)}))
        return
    print(json.dumps(info, indent=2))
    if new == settings: print('No changes.'); return
    if not args.apply: print('Dry run: nothing written. Use --apply to write (a backup is made first).'); return
    print('Written.' + (' Backup: ' + str(saved) if saved else ''))


if __name__ == '__main__': main()
