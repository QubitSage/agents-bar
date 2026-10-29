import json
from pathlib import Path
import sys
import tempfile
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'bridge'))
from events import SessionState, epoch
from watch import Tail

def row(kind, second, turn='one', **extra):
    return {'type':'event_msg', 'timestamp':f'2026-10-26T12:00:{second:02d}Z',
            'payload':{'type':kind, 'turn_id':turn, **extra}}

class LifecycleTests(unittest.TestCase):
    def test_completed_turn_cannot_restart_from_late_duplicate(self):
        s=SessionState();s.consume(row('task_started',1));s.consume(row('task_complete',2))
        self.assertIsNone(s.consume(row('task_started',3)))
        self.assertEqual(s.state,'completed')
        self.assertEqual(s.turn_id,'one')

    def test_completion_without_start_retains_explicit_turn(self):
        s=SessionState();s.consume(row('task_complete',1,'selected-turn'))
        self.assertEqual(s.turn_id,'selected-turn')

    def test_success_requires_explicit_completion(self):
        s=SessionState();s.consume(row('task_started',1))
        s.consume(row('agent_message',2,message='Done!'))
        self.assertEqual(s.state,'working')
        s.consume(row('task_complete',3));self.assertEqual(s.state,'completed')

    def test_old_turn_completion_cannot_complete_new_turn(self):
        s=SessionState();s.consume(row('task_started',1,'one'));s.consume(row('task_started',2,'two'))
        self.assertIsNone(s.consume(row('task_complete',3,'one')))
        self.assertEqual(s.state,'working')

    def test_duplicates_and_out_of_order(self):
        s=SessionState();s.consume(row('task_started',2));s.consume(row('task_complete',4))
        s.consume(row('task_started',1));self.assertEqual(s.state,'completed')
        n=s.sequence;s.consume(row('task_complete',4));self.assertEqual(s.sequence,n)

    def test_failures_not_success(self):
        for kind,expected in [('turn_aborted','cancelled'),('task_failed','failed')]:
            s=SessionState();s.consume(row('task_started',1));s.consume(row(kind,2));self.assertEqual(s.state,expected)

    def test_silence_does_not_mean_success(self):
        s=SessionState();s.consume(row('task_started',1))
        now=epoch('2026-10-26T12:03:00Z')
        self.assertEqual(s.snapshot(now)['state'],'unknown')
        self.assertEqual(s.snapshot(now,False)['state'],'disconnected')

    def test_no_private_content_in_output(self):
        s=SessionState();event=s.consume(row('task_started',1,prompt='SECRET',token='SECRET'))
        self.assertNotIn('SECRET',json.dumps(event));self.assertNotIn('SECRET',json.dumps(s.snapshot(1)))

    def test_tail_partial_line_and_content_stripping(self):
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp)/'session.jsonl';data=json.dumps(row('task_started',1,message='PRIVATE')).encode()
            p.write_bytes(data[:20]);tail=Tail(p);self.assertEqual(tail.read(),[])
            with p.open('ab') as f:f.write(data[20:]+b'\n')
            rows=tail.read();self.assertEqual(len(rows),1);self.assertNotIn('PRIVATE',json.dumps(rows))
            self.assertEqual(tail.read(),[])
            p.write_bytes(b'{}\n');tail.read();self.assertTrue(tail.reset)

if __name__=='__main__':unittest.main()
