import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'bridge'))
from replay import replay

class ReplayTests(unittest.TestCase):
    def test_fixture_produces_three_distinct_states(self):
        data=json.loads((Path(__file__).parent/'fixtures/three-sessions.json').read_text())
        snapshot=replay(data,104)
        self.assertEqual([s['state'] for s in snapshot['sessions']],['working','waiting','completed'])
        self.assertEqual(snapshot['mode'],'replay')
        self.assertEqual(snapshot,replay(data,104))

if __name__=='__main__':unittest.main()
