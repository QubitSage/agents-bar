"""Execute the real launcher against windowless argv recorders, never real agents."""
import base64,json,os,shutil,subprocess,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class LauncherTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.temp=tempfile.TemporaryDirectory(prefix='launcher espaço ',dir=ROOT/'runtime')
  cls.root=Path(cls.temp.name)
  cls.app=cls.root/'Agents Bar ç'
  cls.app.mkdir()
  shutil.copyfile(ROOT/'start.ps1',cls.app/'start.ps1')
  source=cls.root/'Recorder.cs'
  source.write_text('''using System; using System.IO; using System.Text;
class Recorder { static int Main(string[] args) {
string name=Path.GetFileNameWithoutExtension(System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName);
File.WriteAllLines(Path.Combine(Environment.GetEnvironmentVariable("ARGV_CAPTURE"),name+".txt"),Array.ConvertAll(args,x=>Convert.ToBase64String(Encoding.UTF8.GetBytes(x))));
return name=="python" ? 0 : int.Parse(Environment.GetEnvironmentVariable("ARGV_EXIT")??"0"); }}''')
  exe=cls.root/'Recorder.exe'
  subprocess.run([r'C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe','/nologo','/target:winexe','/out:'+str(exe),str(source)],check=True,capture_output=True)
  for name in ['tools/godot/Godot_v4.7.2-stable_win64.exe','tools/python/python.exe']:
   dest=cls.app/name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(exe,dest)
 @classmethod
 def tearDownClass(cls):cls.temp.cleanup()
 def invoke(self,*args,exit_code=0):
  for file in self.root.glob('*.txt'):file.unlink()
  result=subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',str(self.app/'start.ps1'),*args],env=dict(os.environ,ARGV_CAPTURE=str(self.root),ARGV_EXIT=str(exit_code)),capture_output=True,timeout=20)
  self.assertEqual(result.returncode==0,exit_code==0,result.stderr.decode(errors='replace'))
  def read(name):return [base64.b64decode(x).decode('utf-8') for x in (self.root/(name+'.txt')).read_text().splitlines()]
  game=read('Godot_v4.7.2-stable_win64')
  self.assertEqual(game[:4],['--path',str(self.app/'game'),'--log-file',str(self.app/'runtime/game.log')])
  return game,read('python') if (self.root/'python.txt').exists() else None
 def test_disconnected(self):
  game,bridge=self.invoke();self.assertEqual(len(game),4);self.assertIsNone(bridge)
 def test_demo(self):
  game,bridge=self.invoke('-Demo');self.assertEqual(game[4:],['--','--demo']);self.assertIsNone(bridge)
 def test_azhor(self):
  game,bridge=self.invoke('-AzhorDemo');self.assertEqual(game[4:],['--','--demo-azhor']);self.assertIsNone(bridge)
 def test_fictional_session_arguments(self):
  fixture=self.root/'fake sessão.jsonl';fixture.write_text('{}')
  game,bridge=self.invoke('-Connect','-SessionFile',str(fixture),'-ThreadId','fixture-only')
  self.assertEqual(bridge[:5],[str(self.app/'bridge/watch.py'),'--session-file',str(fixture),'--thread-id','fixture-only'])
  self.assertEqual(bridge[5],'--output-dir');self.assertEqual(game[4:],['--','--state-file='+str(Path(bridge[6])/'session-state.json')])
 def test_fictional_multi_arguments(self):
  fixture=self.root/'fake conexões.json';fixture.write_text('{}')
  game,bridge=self.invoke('-Connect','-ConnectionsFile',str(fixture))
  self.assertEqual(bridge[:4],[str(self.app/'bridge/multi_watch.py'),'--config',str(fixture),'--output-dir'])
  self.assertEqual(game[4:],['--','--state-file='+str(Path(bridge[4])/'session-state.json')])
 def test_failure_is_reported(self):
  self.invoke(exit_code=7)
