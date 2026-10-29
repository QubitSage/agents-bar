import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from configure_tracking import windows_hook

class WindowsHookTests(unittest.TestCase):
    def test_wrapper_preserves_unicode_json_and_paths_with_spaces(self):
        with tempfile.TemporaryDirectory(prefix='agents bar ') as folder:
            target=Path(folder)
            receiver=target/'fixture receiver.py'
            receiver.write_text('import sys,json; value=json.load(sys.stdin); print(json.dumps(value))',encoding='utf-8')
            command=windows_hook(target,Path(sys.executable),receiver,target,'codex')
            self.assertIn('-File',command)
            raw={'session_id':'ficticia','text':'ação e coração','number':42}
            result=subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',str(target/'codex-observer.ps1')],input=json.dumps(raw,ensure_ascii=False).encode(),capture_output=True,timeout=10)
            self.assertEqual(result.returncode,0,result.stderr)
            self.assertEqual(json.loads(result.stdout),raw,ascii(result.stdout)+" expected "+ascii(raw))
