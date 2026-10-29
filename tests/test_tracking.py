import json
import sys
import tempfile
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'bridge'))
from providers import normalize, usage
from tracking import Tracker,plan_limits
from license import verify
from mcp_server import dispatch


class TrackingTests(unittest.TestCase):
    def setUp(self):self.tracker=Tracker(':memory:')
    def tearDown(self):self.tracker.db.close()
    def ingest(self,event,ident,now=100):return self.tracker.ingest('generic',event,ident,now)
    def test_all_providers(self):
        rows=[('codex',{'method':'turn/started','params':{'threadId':'a','turn':{'id':'b'}}},None,'started'),
          ('claude',{'session_id':'a','hook_event_name':'PreToolUse','tool_name':'Edit'},None,'activity'),
          ('cursor',{'conversation_id':'a','generation_id':'b','hook_event_name':'stop','status':'aborted'},None,'cancelled'),
          ('antigravity',{'conversationId':'a','toolCall':{'name':'view_file'}},'PostToolUse','activity'),
          ('grok',{'session_id':'a','request_id':'b','usage':{'prompt_tokens':10,'completion_tokens':3}},None,'usage')]
        for p,data,h,kind in rows:self.assertEqual(normalize(p,data,h)['type'],kind)
    def test_privacy(self):
        raw={'session_id':'a','hook_event_name':'PostToolUse','tool_name':'Write','tool_input':{'content':'SECRET'},'cwd':'PRIVATE/PATH','user_email':'PRIVATE@EMAIL','last_assistant_message':'SECRET'}
        self.tracker.ingest('claude',raw,'1',100)
        snapshot=json.dumps(self.tracker.snapshot(101))
        for forbidden in ['SECRET','PRIVATE','tool_input','last_assistant_message']:self.assertNotIn(forbidden,snapshot)
    def test_dedup_and_restart(self):
        with tempfile.TemporaryDirectory() as folder:
            path=str(Path(folder)/'test.sqlite')
            t=Tracker(path)
            event={'session_id':'a','kind':'started','turn_id':'one'}
            self.assertTrue(t.ingest('generic',event,'x',100));t.db.close()
            t=Tracker(path);self.assertFalse(t.ingest('generic',event,'x',101));t.db.close()
    def test_usage_baseline_and_monotonic(self):
        for i,total in enumerate([1000,1300,1300,900,1400]):
            self.ingest({'session_id':'a','kind':'usage','usage':{'total_tokens':total},'cumulative':True},str(i),100+i)
        self.assertEqual(self.tracker.snapshot(106)['sessions'][0]['totalTokens'],400)
    def test_unknown_usage_is_not_zero_claim(self):
        self.ingest({'session_id':'a','kind':'started'},'1')
        self.assertFalse(self.tracker.snapshot(101)['sessions'][0]['usageKnown'])
        self.assertIsNone(usage({'total_tokens':True}))
        self.assertIsNone(usage({'total_tokens':-1}))
    def test_limit(self):
        for i in range(3):self.ingest({'session_id':str(i),'kind':'started'},str(i))
        with self.assertRaises(ValueError):self.ingest({'session_id':'4','kind':'started'},'4')
        self.tracker.max_sessions=12
        self.assertTrue(self.ingest({'session_id':'4','kind':'started'},'4'))
    def test_stale_state(self):
        self.ingest({'session_id':'a','kind':'started'},'1',100)
        self.assertEqual(self.tracker.snapshot(250)['sessions'][0]['state'],'unknown')
    def test_old_turn_not_completed(self):
        self.ingest({'session_id':'a','kind':'started','turn_id':'2'},'1',100)
        self.assertFalse(self.ingest({'session_id':'a','kind':'completed','turn_id':'1'},'2',101))
        self.assertEqual(self.tracker.snapshot(102)['sessions'][0]['state'],'working')
    def test_terminal_late_activity(self):
        self.ingest({'session_id':'a','kind':'started','turn_id':'2'},'1',100)
        self.ingest({'session_id':'a','kind':'completed','turn_id':'2'},'2',101)
        self.assertFalse(self.ingest({'session_id':'a','kind':'activity','turn_id':'2'},'3',102))
    def test_history_retention(self):
        self.ingest({'session_id':'a','kind':'started'},'1',100)
        self.ingest({'session_id':'a','kind':'started'},'2',100000)
        self.assertEqual(self.tracker.db.execute('SELECT count(*) FROM events').fetchone()[0],1)
        self.assertEqual(self.tracker.snapshot(200000)['history'],[])
    def test_grok_response_id_deduplicates_new_delivery_ids(self):
        event={'session_id':'g','request_id':'response-1','usage':{'total_tokens':42}}
        self.assertTrue(self.tracker.ingest('grok',event,'delivery-1',100))
        self.assertFalse(self.tracker.ingest('grok',event,'delivery-2',101))
        self.assertEqual(self.tracker.snapshot(102)['sessions'][0]['totalTokens'],42)
    def test_token_events_do_not_starve_activity(self):
        self.ingest({'session_id':'a','kind':'activity'},'1',100)
        self.ingest({'session_id':'a','kind':'usage','usage':{'total_tokens':1}},'2',100.8)
        self.ingest({'session_id':'a','kind':'activity'},'3',101)
        self.assertEqual(self.tracker.snapshot(102)['sessions'][0]['workUnits'],2)
    def test_codex_native_hooks(self):
        for name,kind in [('UserPromptSubmit','started'),('PermissionRequest','waiting'),('Stop','completed'),('Interrupt','cancelled')]:
            event=normalize('codex',{'session_id':'a','turn_id':'b','hook_event_name':name})
            self.assertEqual(event['type'],kind)
            self.assertEqual(event['turnId'],'b')
    def test_malformed_nested_payloads(self):
        for raw in [{'method':'turn/completed','params':{'turn':[]}}, {'method':'thread/tokenUsage/updated','params':{'tokenUsage':[]}}]:
            with self.assertRaises(ValueError):normalize('codex',raw)
    def test_unsigned_license_rejected(self):
        self.assertIsNone(verify('eyJhbGciOiJub25lIn0.e30.',{'n':'AA','e':'AQAB'},100))
    def test_restart_disconnects_until_new_evidence(self):
        self.ingest({'session_id':'a','kind':'activity','usage':{'total_tokens':12}},'one',100)
        self.tracker.begin_connection()
        session=self.tracker.snapshot(101)['sessions'][0]
        self.assertEqual(session['state'],'disconnected')
        self.assertEqual(session['totalTokens'],12)
        self.assertFalse(self.ingest({'session_id':'a','kind':'activity'},'one',102))
        self.assertTrue(self.ingest({'session_id':'a','kind':'connected'},'two',103))
        self.assertEqual(self.tracker.snapshot(104)['sessions'][0]['state'],'idle')
        self.assertTrue(self.ingest({'session_id':'a','kind':'started','turn_id':'new'},'three',105))
        self.assertEqual(self.tracker.snapshot(106)['sessions'][0]['state'],'working')
    def test_pro_expires_without_waiting_for_network_renewal(self):
        self.assertEqual(plan_limits({'exp':1001},1000),(12,90))
        self.assertEqual(plan_limits({'exp':1001},1001),(3,1))
        self.assertEqual(plan_limits(None,1000),(3,1))
    def test_mcp_handshake_and_no_sensitive_fields(self):
        response=dispatch({'id':1,'method':'initialize'},'unused')
        self.assertEqual(response['result']['serverInfo']['name'],'agents-bar')
        bad=dispatch({'id':2,'method':'tools/call','params':{'name':'report_activity','arguments':{'session_id':'a','kind':'started','prompt':'secret'}}},'unused')
        self.assertIn('error',bad)


if __name__=='__main__':unittest.main()
