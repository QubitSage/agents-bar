import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'bridge'))
from hub import SessionHub, normalize_rpc

def event(kind, second, session='a', turn='turn-a', **extra):
    return dict(eventId=f'{session}-{kind}-{second}',provider='codex',sessionId=session,turnId=turn,at=second,type=kind,**extra)

class HubTests(unittest.TestCase):
    def setUp(self):
        self.hub=SessionHub()
        for name in 'abc':self.hub.bind('codex',name,'Project '+name)

    def test_three_sessions_are_isolated(self):
        for name in 'abc':self.hub.ingest(event('started',1,name))
        self.hub.ingest(event('waiting',2,'b'));self.hub.ingest(event('failed',2,'c'))
        self.assertEqual([s['state'] for s in self.hub.snapshot(3)['sessions']],['working','waiting','failed'])

    def test_capacity_and_unknown_session(self):
        with self.assertRaises(ValueError):self.hub.bind('codex','d','four')
        self.assertFalse(self.hub.ingest(event('started',1,'unknown')))

    def test_deduplication_and_late_turn(self):
        start=event('started',1);self.assertTrue(self.hub.ingest(start));self.assertFalse(self.hub.ingest(start))
        self.hub.ingest(event('started',2,turn='new'))
        self.assertFalse(self.hub.ingest(event('completed',3)))
        self.assertEqual(self.hub.snapshot(3)['sessions'][0]['state'],'working')

    def test_waiting_requires_explicit_resume(self):
        self.hub.ingest(event('started',1));self.hub.ingest(event('waiting',2))
        self.assertFalse(self.hub.ingest(event('activity',3,activity='tool')))
        self.hub.ingest(event('resumed',4));self.assertEqual(self.hub.snapshot(4)['sessions'][0]['state'],'working')

    def test_terminal_not_overwritten_by_late_activity_or_duplicate_start(self):
        self.hub.ingest(event('started',1));self.hub.ingest(event('completed',2))
        self.assertFalse(self.hub.ingest(event('activity',3)))
        self.assertFalse(self.hub.ingest(event('started',4)))
        self.assertEqual(self.hub.snapshot(4)['sessions'][0]['state'],'completed')

    def test_silence_does_not_complete(self):
        self.hub.ingest(event('started',1));self.assertEqual(self.hub.snapshot(122)['sessions'][0]['state'],'unknown')

    def test_rejects_invalid_time(self):
        self.assertFalse(self.hub.ingest(event('started',float('nan'))))

    def test_rpc_keeps_only_lifecycle_metadata(self):
        msg={'method':'turn/completed','params':{'threadId':'a','turn':{'id':'turn-a','status':'failed','error':{'message':'SECRET'}}}}
        result=normalize_rpc(msg,3)
        self.assertEqual(result['type'],'failed');self.assertNotIn('SECRET',json.dumps(result))
        self.assertEqual(result['eventId'],normalize_rpc(msg,4)['eventId'])

    def test_unknown_rpc_status_not_success(self):
        msg={'method':'turn/completed','params':{'threadId':'a','turn':{'id':'x','status':'unexpected'}}}
        self.assertIsNone(normalize_rpc(msg,4))

    def test_unknown_content_not_retained(self):
        self.hub.ingest(event('started',1,prompt='SECRET'))
        self.assertNotIn('SECRET',json.dumps(self.hub.snapshot(2)))

    def test_reasoning_is_not_tool_execution(self):
        msg={'method':'item/started','params':{'threadId':'a','turnId':'turn-a','item':{'id':'r1','type':'reasoning','text':'SECRET'}}}
        result=normalize_rpc(msg,2)
        self.assertEqual(result['activity'],'thinking');self.assertNotIn('SECRET',json.dumps(result))

if __name__=='__main__':unittest.main()
