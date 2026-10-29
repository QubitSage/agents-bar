import json,socket,subprocess,sys,tempfile,time,unittest,urllib.request,urllib.error
from pathlib import Path
from unittest.mock import patch
from hook import send
from mcp_server import dispatch
ROOT=Path(__file__).resolve().parents[1]
class Lifecycle099Tests(unittest.TestCase):
 def test_authenticated_stop_flushes_and_releases_port(self):
  with tempfile.TemporaryDirectory() as folder:
   with socket.socket() as s:s.bind(('127.0.0.1',0));port=s.getsockname()[1]
   p=subprocess.Popen([sys.executable,str(ROOT/'bridge/tracking.py'),'--directory',folder,'--port',str(port)],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
   path=Path(folder)
   try:
    for _ in range(150):
     if (path/'session-state.json').exists():break
     time.sleep(.02)
    token=(path/'collector-token.txt').read_text()
    def post(route,body,auth=token,origin=None):
     h={'Content-Type':'application/json','Authorization':'Bearer '+auth}
     if origin:h['Origin']=origin
     req=urllib.request.Request(f'http://127.0.0.1:{port}/v1/'+route,json.dumps(body).encode(),h)
     return urllib.request.urlopen(req,timeout=3)
    with self.assertRaises(urllib.error.HTTPError) as error:post('stop',{},auth='bad')
    self.assertEqual(error.exception.code,401);error.exception.close()
    with post('events',{'provider':'generic','eventId':'one','payload':{'session_id':'fixture','kind':'activity'}}) as response:self.assertEqual(response.status,200)
    with post('stop',{}) as response:self.assertEqual(response.status,200)
    p.wait(timeout=5);self.assertEqual(p.returncode,0)
    snapshot=json.loads((path/'session-state.json').read_text(encoding='utf-8'))
    self.assertTrue(snapshot['stopped']);self.assertEqual(snapshot['collectorPid'],0)
    self.assertEqual(snapshot['sessions'][0]['state'],'disconnected')
    self.assertTrue((path/'usage.sqlite3').exists())
    with socket.socket() as probe:probe.bind(('127.0.0.1',port))
   finally:
    if p.poll() is None:p.terminate();p.wait(timeout=5)
 def test_observer_disables_environment_proxy(self):
  with tempfile.TemporaryDirectory() as folder:
   (Path(folder)/'collector-token.txt').write_text('fixture')
   with patch('hook.urllib.request.ProxyHandler') as proxy,patch('hook.urllib.request.build_opener') as build:
    build.return_value.open.return_value.__enter__.return_value.read.return_value=b'{"accepted":true}'
    self.assertEqual(send('generic',{'session_id':'a','kind':'activity'},folder),{'accepted':True});proxy.assert_called_once_with({})
 def test_mcp_rejects_invalid_arguments_before_local_request(self):
  for args in [{},{'session_id':'a','kind':'invented'},{'session_id':'a','kind':'activity','turn_id':{}},{'session_id':'a','kind':'activity','activity':'invented'}]:
   with patch('mcp_server.send') as sender:
    result=dispatch({'id':1,'method':'tools/call','params':{'name':'report_activity','arguments':args}},'unused')
    self.assertEqual(result['error']['code'],-32602);sender.assert_not_called()
