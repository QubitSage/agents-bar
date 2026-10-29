import copy
import json
import sys
import tempfile
import unittest
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'bridge')); sys.path.insert(0, str(ROOT / 'scripts'))
from providers import normalize
from tracking import Tracker
import claude_settings as cs

CMD = 'powershell.exe -File "X/integrations/claude-observer.ps1"'
SNIPPET = {'hooks': {name: [{'hooks': [{'type': 'command', 'command': CMD, 'timeout': 2}]}] for name in ['PreToolUse', 'Stop']}}
STATUS = {'statusLine': {'type': 'command', 'command': 'powershell.exe -File "X/integrations/claude-statusline-observer.ps1"'}}
OTHER = {'hooks': {'PreToolUse': [{'matcher': 'Bash', 'hooks': [{'type': 'command', 'command': 'my-linter'}]}]}, 'permissions': {'allow': ['Read']}}


class MergeTests(unittest.TestCase):
    def test_preserves_and_is_idempotent(self):
        once, report = cs.merge(OTHER, SNIPPET)
        self.assertEqual(once['permissions'], OTHER['permissions'])
        self.assertEqual(once['hooks']['PreToolUse'][0], OTHER['hooks']['PreToolUse'][0])
        self.assertEqual(report['added'], ['PreToolUse', 'Stop'])
        twice, report = cs.merge(once, SNIPPET)
        self.assertEqual(once, twice); self.assertEqual(report['added'], [])

    def test_remove_restores_original(self):
        merged, _ = cs.merge(OTHER, SNIPPET, STATUS)
        restored, removed = cs.remove(merged)
        self.assertEqual(restored, OTHER); self.assertIn('statusLine', removed)

    def test_never_replaces_existing_statusline(self):
        own = {'statusLine': {'type': 'command', 'command': 'my-bar'}}
        merged, report = cs.merge(own, SNIPPET, STATUS)
        self.assertEqual(merged['statusLine'], own['statusLine']); self.assertEqual(report['statusline'], 'skipped-existing')
        _, removed = cs.remove(merged); self.assertNotIn('statusLine', removed)

    def test_backup_written(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'settings.json'; path.write_text(json.dumps(OTHER))
            merged, _ = cs.merge(OTHER, SNIPPET)
            saved = cs.write(path, merged)
            self.assertEqual(json.loads(saved.read_text()), OTHER)
            self.assertEqual(json.loads(path.read_text()), merged)

    def test_input_not_mutated(self):
        before = copy.deepcopy(OTHER); cs.merge(OTHER, SNIPPET); self.assertEqual(before, OTHER)


class ClaudeFlowTests(unittest.TestCase):
    def setUp(self): self.t = Tracker(':memory:')
    def tearDown(self): self.t.db.close()
    def send(self, event, ident, now, **extra):
        raw = {'session_id': 'abc', 'hook_event_name': event, **extra}
        return self.t.ingest('claude', raw, ident, now)
    def state(self, now): return self.t.snapshot(now)['sessions'][0]

    def test_full_turn_single_completion(self):
        self.send('SessionStart', '1', 100); self.assertEqual(self.state(100)['state'], 'idle')
        self.send('UserPromptSubmit', '2', 101); self.assertEqual(self.state(101)['state'], 'working')
        self.send('PreToolUse', '3', 102, tool_name='Edit'); self.assertEqual(self.state(102)['activity'], 'edit')
        self.send('Notification', '4', 103, notification_type='permission_prompt'); self.assertEqual(self.state(103)['state'], 'waiting')
        self.send('PostToolUse', '5', 104, tool_name='Edit'); self.assertEqual(self.state(104)['state'], 'working')
        self.assertTrue(self.send('Stop', '6', 105)); done = self.state(105)
        self.assertEqual(done['state'], 'completed')
        self.send('PostToolUse', '7', 106, tool_name='Read')  # late event
        self.send('Stop', '8', 107)
        after = self.state(107)
        self.assertEqual(after['state'], 'completed'); self.assertEqual(after['turnId'], done['turnId'])
        self.assertEqual(after['lifecycleAt'], done['lifecycleAt'])  # no second completion signal
        self.send('UserPromptSubmit', '9', 108); self.assertNotEqual(self.state(108)['turnId'], done['turnId'])

    def test_idle_notification_ignored(self):
        self.assertIsNone(normalize('claude', {'session_id': 'a', 'notification_type': 'idle_prompt'}, 'Notification'))

    def test_context_is_separate_from_tokens(self):
        line = {'session_id': 'abc', 'context_window': {'total_input_tokens': 1000, 'total_output_tokens': 100, 'used_percentage': 42.26}}
        self.t.ingest('claude', line, 'a', 100, 'statusline'); self.t.ingest('claude', {**line, 'context_window': {'total_input_tokens': 1500, 'total_output_tokens': 200, 'used_percentage': 55}}, 'b', 101, 'statusline')
        s = self.state(102)
        self.assertEqual(s['contextPercent'], 55); self.assertEqual(s['totalTokens'], 600); self.assertEqual(s['tokenScope'], 'session-observed')
        self.assertTrue(s['usageKnown'])

    def test_no_context_means_unknown(self):
        self.send('SessionStart', '1', 100); s = self.state(100)
        self.assertIsNone(s['contextPercent']); self.assertFalse(s['usageKnown'])





class CliTests(unittest.TestCase):
    def run_cli(self, settings, *flags):
        import subprocess
        out = subprocess.run([sys.executable, '-I', str(ROOT / 'scripts/claude_settings.py'), '--settings', str(settings), '--json', *flags], capture_output=True, text=True)
        return out.returncode, (json.loads(out.stdout) if out.stdout.strip() else None)

    def test_json_install_remove_and_invalid(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'settings.json'; path.write_text(json.dumps(OTHER))
            code, result = self.run_cli(path, '--apply')
            self.assertEqual(code, 0); self.assertTrue(result['installed'] and result['written'] and result['backup'])
            self.assertEqual(self.run_cli(path, '--apply')[1]['changed'], False)
            code, result = self.run_cli(path, '--apply', '--remove')
            self.assertFalse(result['installed']); self.assertEqual(json.loads(path.read_text()), OTHER)
            path.write_text('{ not json'); before = path.read_text()
            code, result = self.run_cli(path, '--apply')
            self.assertEqual(code, 2); self.assertFalse(result['ok']); self.assertEqual(path.read_text(), before)

if __name__ == '__main__': unittest.main()
