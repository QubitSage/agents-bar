import importlib.util,json,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('gate',ROOT/'scripts/release_gate.py');gate=importlib.util.module_from_spec(spec);spec.loader.exec_module(gate)
class ReleaseGateTests(unittest.TestCase):
 def make_fixture(self,root):
  (root/'game/content').mkdir(parents=True);(root/'server').mkdir();(root/'docs').mkdir()
  import base64
  config={'api_url':'https://game.example','portal_url':'https://game.example','license_public_key':{'e':'AQAB','n':base64.urlsafe_b64encode(b'1'*256).decode().rstrip('=')}}
  (root/'game/content/online.json').write_text(json.dumps(config))
  (root/'server/wrangler.toml').write_text('[vars]\nPUBLIC_URL="https://game.example"\nSTRIPE_PRICE_ID="price_fixture"\n[[d1_databases]]\ndatabase_id="11111111-1111-1111-1111-111111111111"\n')
  return config
 def test_unconfigured_release_cannot_pass_public_gate(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);config=self.make_fixture(root);config['api_url']=''
   (root/'game/content/online.json').write_text(json.dumps(config));result=gate.inspect(root)
   self.assertFalse(result['publicReady']);self.assertIn('online.api_url',result['missingConfiguration'])
 def test_public_settings_alone_do_not_claim_acceptance(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);self.make_fixture(root);result=gate.inspect(root)
   self.assertEqual(result['missingConfiguration'],[]);self.assertFalse(result['publicReady']);self.assertEqual(len(result['pendingAcceptance']),7)
 def test_private_key_in_client_and_origin_mismatch_are_rejected(self):
  with tempfile.TemporaryDirectory() as folder:
   root=Path(folder);config=self.make_fixture(root);config['license_public_key']['d']='DO-NOT-SHIP';config['portal_url']='https://different.example'
   (root/'game/content/online.json').write_text(json.dumps(config));result=gate.inspect(root)
   self.assertIn('online.public_key',result['missingConfiguration']);self.assertIn('billing.origins_match',result['missingConfiguration'])
