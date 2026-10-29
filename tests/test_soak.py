import unittest
from tracking import Tracker
class SoakTrackingTests(unittest.TestCase):
 def test_eight_hours_of_synthetic_three_agent_work(self):
  tracker=Tracker(':memory:')
  try:
   for second in range(0,28800,10):
    for hero in range(3):
     tracker.ingest('generic',{'session_id':f'fixture-{hero}','kind':'activity','usage':{'total_tokens':second*2},'cumulative':True},f'{hero}-{second}',100000+second)
    if second%1800==0:
     snapshot=tracker.snapshot(100000+second)
     self.assertEqual(len(snapshot['sessions']),3)
     self.assertTrue(all(s['state']=='working' for s in snapshot['sessions']))
   snapshot=tracker.snapshot(128800)
   self.assertEqual(sum(s['totalTokens'] for s in snapshot['sessions']),28790*2*3)
   self.assertEqual(tracker.db.execute('SELECT COUNT(*) FROM events').fetchone()[0],8640)
   tracker.begin_connection();self.assertTrue(all(s['state']=='disconnected' for s in tracker.snapshot(128801)['sessions']))
   self.assertEqual(tracker.snapshot(220000)['history'],[])
  finally:tracker.db.close()
