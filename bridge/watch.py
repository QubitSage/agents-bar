"""Read only one explicitly selected Codex rollout; write sanitized state locally."""
import argparse
import json
import os
from pathlib import Path
import time
from events import SessionState


class Tail:
    def __init__(self, path):
        self.path = Path(path)
        self.offset = 0
        self.pending = b''
        self.skip_long_line = False
        self.identity = None
        self.reset = False

    def read(self):
        stat = self.path.stat()
        identity = (stat.st_dev, stat.st_ino)
        self.reset = self.identity is not None and (identity != self.identity or stat.st_size < self.offset)
        if self.reset:
            self.offset, self.pending, self.skip_long_line = 0, b'', False
        self.identity = identity
        rows = []
        with self.path.open('rb') as stream:
            stream.seek(self.offset)
            # Drain in bounded chunks. Never save raw bytes outside this process.
            # At most 1 MiB per poll: large historical files cannot monopolize CPU/RAM.
            for _ in range(16):
                chunk = stream.read(65536)
                if not chunk:
                    break
                self.offset += len(chunk)
                parts = (self.pending + chunk).split(b'\n')
                self.pending = parts.pop()
                for raw in parts:
                    if self.skip_long_line:
                        self.skip_long_line = False
                        continue
                    try:
                        row = json.loads(raw)
                        if isinstance(row, dict):
                            # Drop all content fields before passing to the reducer.
                            p = row.get('payload', {})
                            if not isinstance(p, dict):
                                continue
                            rows.append({'type':row.get('type'), 'timestamp':row.get('timestamp'),
                                         'payload':{k:p[k] for k in ('type','turn_id','root_turn_id') if k in p}})
                    except (ValueError, UnicodeError):
                        pass
                if len(self.pending) > 4 * 1024 * 1024:
                    self.pending = b''
                    self.skip_long_line = True
        return rows


def atomic_json(path, value):
    tmp = path.with_suffix('.tmp')
    tmp.write_text(json.dumps(value, ensure_ascii=False), encoding='utf-8')
    for attempt in range(5):
        try:
            os.replace(tmp, path)
            return
        except PermissionError:
            time.sleep(.02 * (attempt + 1))
    raise PermissionError('Unable to replace local state snapshot')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--session-file', required=True)
    parser.add_argument('--thread-id', required=True)
    parser.add_argument('--output-dir', required=True)
    parser.add_argument('--seconds', type=float, default=0)
    args = parser.parse_args()
    session_path = Path(args.session_file).resolve()
    if session_path.suffix != '.jsonl' or args.thread_id not in session_path.name:
        parser.error('Select the JSONL file belonging to the specified thread')
    output = Path(args.output_dir).resolve()
    output.mkdir(parents=True, exist_ok=True)
    tail, state = Tail(session_path), SessionState()
    started = time.monotonic()
    event_file = output / 'events.jsonl'
    while not args.seconds or time.monotonic() - started < args.seconds:
        connected = True
        try:
            rows = tail.read()
            if tail.reset:
                state = SessionState()
            events = []
            for row in rows:
                event = state.consume(row)
                if event:
                    events.append(event)
            # Bounded diagnostic history; no raw payloads.
            if events:
                if event_file.exists() and event_file.stat().st_size > 1024 * 1024:
                    event_file.write_text('', encoding='utf-8')
                with event_file.open('a', encoding='utf-8') as log:
                    for event in events[-100:]:
                        log.write(json.dumps(event) + '\n')
        except (OSError, ValueError):
            connected = False
        now = time.time()
        snapshot = state.snapshot(now, connected)
        snapshot.update({'schemaVersion':1, 'provider':'codex', 'source':'local-rollout-experimental',
                         'sessionId':args.thread_id, 'project':'Agents Bar', 'heartbeatAt':now,
                         'approvalDetection':False, 'mode':'live'})
        try:
            atomic_json(output / 'session-state.json', snapshot)
        except OSError:
            pass
        time.sleep(.5)


if __name__ == '__main__':
    main()
