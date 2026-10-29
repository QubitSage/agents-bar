"""Synthetic loopback-only HTTP test; never reads provider sessions."""
import json
import socket
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.error
import urllib.request
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

class CollectorHTTPTests(unittest.TestCase):
    def test_auth_privacy_dedup_and_invalid_payload(self):
        with tempfile.TemporaryDirectory() as folder:
            directory=Path(folder)
            with socket.socket() as probe:
                probe.bind(('127.0.0.1',0));port=probe.getsockname()[1]
            process=subprocess.Popen([sys.executable,str(ROOT/'bridge/tracking.py'),'--directory',folder,'--port',str(port)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
            try:
                for _ in range(150):
                    if (directory/'session-state.json').exists():break
                    if process.poll() is not None:self.fail('Fixture collector exited early')
                    time.sleep(.02)
                token=(directory/'collector-token.txt').read_text().strip()
                def post(value,auth=token,origin=None):
                    headers={'Content-Type':'application/json','Authorization':'Bearer '+auth}
                    if origin:headers['Origin']=origin
                    request=urllib.request.Request(f'http://127.0.0.1:{port}/v1/events',json.dumps(value).encode(),headers)
                    try:
                        with urllib.request.urlopen(request,timeout=3) as response:return response.status,json.load(response)
                    except urllib.error.HTTPError as error:
                        code=error.code;error.close();return code,None
                event={'provider':'codex','eventId':'fixture-1','payload':{'session_id':'fake-thread','turn_id':'fake-turn','hook_event_name':'UserPromptSubmit','prompt':'PRIVATE-FIXTURE'}}
                self.assertEqual(post(event,auth='wrong')[0],401)
                self.assertEqual(post(event,origin='https://example.test')[0],403)
                self.assertEqual(post(event),(200,{'accepted':True}))
                self.assertEqual(post(event),(200,{'accepted':False}))
                self.assertEqual(post({'provider':'codex','eventId':'bad','payload':{'params':{'turn':[]},'method':'turn/completed'}})[0],400)
                for _ in range(100):
                    snapshot=json.loads((directory/'session-state.json').read_text(encoding='utf-8'))
                    if snapshot['sessions']:break
                    time.sleep(.02)
                self.assertEqual(snapshot['sessions'][0]['state'],'working')
                self.assertEqual(snapshot['collectorPid'],process.pid)
                self.assertNotIn('PRIVATE-FIXTURE',json.dumps(snapshot))
                self.assertFalse(snapshot['sessions'][0]['usageKnown'])
            finally:
                process.terminate();process.wait(timeout=5)
