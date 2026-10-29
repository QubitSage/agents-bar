"""Installer checks use tiny fictional packages, no shortcut, app, or personal data."""
import hashlib,json,subprocess,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class DistributionTests(unittest.TestCase):
 def setUp(self):
  self.temp=tempfile.TemporaryDirectory(prefix='installer-');self.base=Path(self.temp.name);self.install=self.base/'installed app'
 def tearDown(self):self.temp.cleanup()
 def package(self,version='0.8.0'):
  root=self.base/('package '+version);root.mkdir()
  for name in ['start.ps1','Iniciar Agents Bar.cmd','install.ps1','installed-launcher.ps1','game/project.godot','tools/python/python.exe','tools/godot/Godot_v4.7.2-stable_win64.exe']:
   path=root/name;path.parent.mkdir(parents=True,exist_ok=True)
   path.write_bytes((ROOT/name).read_bytes() if name in ['install.ps1','installed-launcher.ps1'] else b'fixture only; never execute')
  data={'version':version,'files':[{'path':p.relative_to(root).as_posix(),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in root.rglob('*') if p.is_file()]}
  (root/'manifest.json').write_text(json.dumps(data));return root
 def run_installer(self,package,mode='Install',ok=True):
  result=subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',str(ROOT/'install.ps1'),'-PackageRoot',str(package),'-InstallRoot',str(self.install),'-Mode',mode,'-NoShortcut'],capture_output=True,text=True)
  self.assertEqual(result.returncode==0,ok,result.stderr[-1200:]);return result
 def test_install_update_rollback_preserve_data(self):
  p=self.package();self.run_installer(p,'Verify');self.run_installer(p)
  data=self.install/'data';data.mkdir();(data/'sentinel.txt').write_text('keep local history')
  self.run_installer(p) # Idempotent reinstall.
  v2=self.package('0.8.1');self.run_installer(v2)
  self.assertEqual(json.loads((self.install/'current.json').read_text(encoding='utf-8-sig')),{'current':'0.8.1','previous':'0.8.0'})
  self.run_installer(v2,'Rollback')
  self.assertEqual(json.loads((self.install/'current.json').read_text(encoding='utf-8-sig'))['current'],'0.8.0')
  self.assertEqual((data/'sentinel.txt').read_text(),'keep local history')
  self.assertTrue((self.install/'versions/0.8.1/start.ps1').exists())
 def test_corrupt_file_rejected_without_install(self):
  p=self.package();(p/'start.ps1').write_text('tampered');self.run_installer(p,ok=False);self.assertFalse((self.install/'current.json').exists())
 def test_extra_file_rejected(self):
  p=self.package();(p/'surprise.py').write_text('x');self.run_installer(p,ok=False)
 def test_traversal_rejected(self):
  p=self.package();m=json.loads((p/'manifest.json').read_text());m['files'][0]['path']='../outside.txt';(p/'manifest.json').write_text(json.dumps(m));self.run_installer(p,ok=False)
 def test_duplicate_rejected(self):
  p=self.package();m=json.loads((p/'manifest.json').read_text());m['files'].append(m['files'][0]);(p/'manifest.json').write_text(json.dumps(m));self.run_installer(p,ok=False)
 def test_missing_runtime_rejected(self):
  p=self.package();(p/'tools/python/python.exe').unlink();self.run_installer(p,ok=False)
 def test_rollback_requires_previous(self):
  p=self.package();self.run_installer(p);self.run_installer(p,'Rollback',ok=False)
 def test_bad_version_rejected(self):
  p=self.package();m=json.loads((p/'manifest.json').read_text());m['version']='../escape';(p/'manifest.json').write_text(json.dumps(m));self.run_installer(p,ok=False)

 def test_uninstall_keeps_data_and_unknown_files(self):
  p=self.package();self.run_installer(p)
  data=self.install/'data';data.mkdir();(data/'history.txt').write_text('preserve')
  unknown=self.install/'versions/0.8.0/my-notes.txt';unknown.write_text('also preserve')
  self.run_installer(p,'Uninstall')
  self.assertFalse((self.install/'current.json').exists());self.assertFalse((self.install/'versions/0.8.0/start.ps1').exists())
  self.assertEqual((data/'history.txt').read_text(),'preserve');self.assertEqual(unknown.read_text(),'also preserve')
 def test_uninstall_refuses_modified_program_before_deleting(self):
  p=self.package();self.run_installer(p);changed=self.install/'versions/0.8.0/start.ps1';changed.write_text('modified')
  self.run_installer(p,'Uninstall',ok=False);self.assertEqual(changed.read_text(),'modified');self.assertTrue((self.install/'current.json').exists())
 def test_path_alias_with_backslash_rejected(self):
  p=self.package();m=json.loads((p/'manifest.json').read_text());m['files'].append(dict(m['files'][-1],path=m['files'][-1]['path'].replace('/',chr(92))));(p/'manifest.json').write_text(json.dumps(m));self.run_installer(p,ok=False)
