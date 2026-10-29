"""Explicitly selected local sessions only. No discovery or network connection."""
import argparse
import json
from pathlib import Path
import re
import time

from events import SessionState
from watch import Tail, atomic_json


def load_config(path):
    config_path = Path(path).resolve()
    if config_path.stat().st_size > 16384:
        raise ValueError('Connection configuration is too large')
    config = json.loads(config_path.read_text(encoding='utf-8-sig'))
    sessions = config.get('sessions') if isinstance(config, dict) else None
    if not isinstance(sessions, list) or not 1 <= len(sessions) <= 3:
        raise ValueError('Choose one to three sessions explicitly')
    selected, ids, paths = [], set(), set()
    for slot, entry in enumerate(sessions):
        if not isinstance(entry, dict):
            raise ValueError('Invalid session entry')
        session_id, filename = entry.get('sessionId'), entry.get('file')
        if not isinstance(session_id, str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,128}', session_id):
            raise ValueError('Invalid session identifier')
        if not isinstance(filename, str) or not Path(filename).is_absolute():
            raise ValueError('Select an absolute JSONL file path')
        source = Path(filename).resolve()
        if source.suffix.lower() != '.jsonl' or session_id not in source.name:
            raise ValueError('Selected file must belong to its session identifier')
        if session_id in ids or str(source).casefold() in paths:
            raise ValueError('Each session and file must appear only once')
        ids.add(session_id)
        paths.add(str(source).casefold())
        label = entry.get('label', f'Sessão {slot + 1}')
        if not isinstance(label, str):
            raise ValueError('Session label must be text')
        selected.append({'sessionId': session_id, 'file': source, 'label': label[:40]})
    return selected


class MultiWatcher:
    def __init__(self, selected):
        self.entries = [(entry, Tail(entry['file']), SessionState()) for entry in selected]

    def poll(self, now=None):
        now = time.time() if now is None else now
        snapshots = []
        for slot, (entry, tail, state) in enumerate(self.entries):
            connected = True
            try:
                rows = tail.read()
                if tail.reset:
                    state = SessionState()
                    self.entries[slot] = (entry, tail, state)
                for row in rows:
                    state.consume(row)
            except (OSError, ValueError):
                connected = False
            snapshot = state.snapshot(now, connected)
            snapshot.update({'sessionId': entry['sessionId'], 'provider': 'codex',
                             'project': entry['label'], 'characterIndex': slot,
                             'heartbeatAt': now, 'approvalDetection': False})
            snapshots.append(snapshot)
        return {'schemaVersion': 2, 'source': 'local-rollout-experimental',
                'mode': 'live', 'heartbeatAt': now, 'sessions': snapshots}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--seconds', type=float, default=0)
    args = parser.parse_args()
    try:
        watcher = MultiWatcher(load_config(args.config))
    except (OSError, ValueError) as exc:
        parser.error(str(exc))
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    started = time.monotonic()
    while not args.seconds or time.monotonic() - started < args.seconds:
        try:
            atomic_json(output / 'session-state.json', watcher.poll())
        except OSError:
            pass
        time.sleep(.5)


if __name__ == '__main__':
    main()
