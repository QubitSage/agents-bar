import json
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bridge'))
from multi_watch import MultiWatcher, load_config


class MultiWatchTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / 'tests' / 'scratch')
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def session(self, name, kind='task_started'):
        file = self.root / f'rollout-{name}.jsonl'
        row = {'type': 'event_msg', 'timestamp': '2026-10-26T15:00:00Z',
               'payload': {'type': kind, 'turn_id': 'turn-1', 'message': 'SECRET SHOULD NEVER BE RETAINED'}}
        file.write_text(json.dumps(row) + '\n', encoding='utf-8')
        return {'sessionId': name, 'file': str(file), 'label': name}

    def config(self, entries):
        file = self.root / 'chosen.json'
        file.write_text(json.dumps({'sessions': entries}), encoding='utf-8')
        return file

    def test_three_independent_sessions_and_sanitized_snapshot(self):
        entries = [self.session('a'), self.session('b', 'task_failed'), self.session('c', 'task_complete')]
        watcher = MultiWatcher(load_config(self.config(entries)))
        snapshot = watcher.poll(now=1793026801)
        self.assertEqual([s['state'] for s in snapshot['sessions']], ['working', 'failed', 'completed'])
        self.assertNotIn('SECRET', json.dumps(snapshot))
        self.assertNotIn(str(self.root), json.dumps(snapshot))
        self.assertEqual(watcher.poll(now=1793026802)['sessions'][0]['sequence'], 1)

    def test_missing_file_disconnects_only_that_slot(self):
        entries = [self.session('a'), self.session('b')]
        watcher = MultiWatcher(load_config(self.config(entries)))
        Path(entries[1]['file']).unlink()
        result = watcher.poll(now=1793026801)
        self.assertEqual([s['state'] for s in result['sessions']], ['working', 'disconnected'])

    def test_duplicate_session_rejected(self):
        entry = self.session('a')
        with self.assertRaises(ValueError):
            load_config(self.config([entry, entry]))

    def test_no_automatic_paths(self):
        for entries in [[], [{'sessionId': 'a', 'file': 'relative-a.jsonl'}], [self.session(str(i)) for i in range(4)]]:
            with self.assertRaises(ValueError):
                load_config(self.config(entries))

    def test_tail_budget_and_partial_line(self):
        entry = self.session('a')
        path = Path(entry['file'])
        path.write_bytes(b'x' * (2 * 1024 * 1024))
        watcher = MultiWatcher(load_config(self.config([entry])))
        watcher.poll()
        tail = watcher.entries[0][1]
        self.assertEqual(tail.offset, 1024 * 1024)
        self.assertLessEqual(len(tail.pending), 4 * 1024 * 1024)


if __name__ == '__main__':
    unittest.main()
