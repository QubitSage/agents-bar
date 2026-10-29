"""Cross-language contract: provider metadata -> tracker -> Godot model, no UI."""
import json,subprocess,tempfile,unittest
from pathlib import Path
from tracking import Tracker
ROOT=Path(__file__).resolve().parents[1]
class PipelineTests(unittest.TestCase):
 def test_provider_snapshots_drive_only_linked_live_party(self):
  profiles=[]
  for provider in ['codex','claude','cursor','antigravity','grok','generic']:
   t=Tracker(':memory:')
   def event(n):
    if provider=='grok':return {'session_id':'fiction','request_id':f'response-{n}','usage':{'total_tokens':30}}
    if provider=='generic':return {'session_id':'fiction','turn_id':'turn','kind':'activity','activity':'edit'}
    return {'session_id':'fiction','turn_id':'turn','hook_event_name':'postToolUse' if provider=='cursor' else 'PostToolUse','tool_name':'Edit','tool_input':{'content':'DO NOT KEEP THIS'}}
   t.ingest(provider,event(1),'event-1',100);first=t.snapshot(100)
   t.ingest(provider,event(2),'event-2',102);second=t.snapshot(102)
   self.assertNotIn('DO NOT KEEP THIS',json.dumps(second))
   profiles.append({'provider':provider,'first':first,'second':second});t.db.close()
  with tempfile.TemporaryDirectory() as folder:
   path=Path(folder)/'profiles.json';path.write_text(json.dumps(profiles))
   result=subprocess.run([str(ROOT/'tools/godot/Godot_v4.7.2-stable_win64_console.exe'),'--headless','--path',str(ROOT/'game'),'--script','res://test_tracking_pipeline.gd','--log-file',str(Path(folder)/'pipeline.log'),'--',str(path)],capture_output=True,text=True,timeout=30)
   self.assertEqual(result.returncode,0,result.stdout+result.stderr)
   self.assertNotIn('SCRIPT ERROR',result.stderr);self.assertIn('42 checks, 0 failures',result.stdout)
