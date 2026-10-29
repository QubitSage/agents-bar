"""Local pre-publication checks. Never contacts accounts or reads secrets."""
import argparse,base64,json,re,tomllib
from pathlib import Path
from urllib.parse import urlparse
ROOT=Path(__file__).resolve().parents[1]
REQUIRED=('windows_visual','windows_install_upgrade','real_providers','stripe_test_mode','cloud_deployment','publisher_signing','commercial_content')
def inspect(root):
 root=Path(root);missing=[]
 online=json.loads((root/'game/content/online.json').read_text(encoding='utf-8-sig'))
 server=tomllib.loads((root/'server/wrangler.toml').read_text(encoding='utf-8-sig'))
 def origin(value):
  p=urlparse(value)
  return p.scheme=='https' and p.hostname and not p.username and not p.password and not p.query and not p.fragment and p.path in ('','/') and 'configure' not in value.lower()
 for name in ['api_url','portal_url']:
  if not origin(online.get(name,'')):missing.append('online.'+name)
 variables=server.get('vars',{})
 if not origin(variables.get('PUBLIC_URL','')):missing.append('worker.PUBLIC_URL')
 if not re.fullmatch(r'price_[A-Za-z0-9]+',variables.get('STRIPE_PRICE_ID','')):missing.append('worker.STRIPE_PRICE_ID')
 if not re.fullmatch(r'[0-9a-fA-F-]{36}',server.get('d1_databases',[{}])[0].get('database_id','')):missing.append('worker.database_id')
 try:
  public=online['license_public_key'];n=public['n'];valid=public.get('e')=='AQAB' and 256<=len(base64.urlsafe_b64decode(n+'='*(-len(n)%4)))<=512 and not any(k in public for k in ['d','p','q'])
 except (KeyError,ValueError,TypeError):valid=False
 if not valid:missing.append('online.public_key')
 if all(origin(v) for v in [online.get('api_url',''),online.get('portal_url',''),variables.get('PUBLIC_URL','')]):
  hosts={urlparse(v).netloc for v in [online['api_url'],online['portal_url'],variables['PUBLIC_URL']]}
  if len(hosts)!=1:missing.append('billing.origins_match')
 approval=root/'docs/acceptance-1.0.json'
 evidence=json.loads(approval.read_text(encoding='utf-8-sig')) if approval.exists() else {}
 pending=[k for k in REQUIRED if not isinstance(evidence.get(k),dict) or evidence[k].get('status')!='passed' or not evidence[k].get('evidence')]
 return {'version':'0.9.12','publicReady':not missing and not pending,'missingConfiguration':missing,'pendingAcceptance':pending,'note':'Checks public configuration and recorded evidence, not accounts or payments. A passed record must refer to a real review.'}
def main():
 parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--public',action='store_true');parser.add_argument('--root',type=Path,default=ROOT);args=parser.parse_args();result=inspect(args.root);print(json.dumps(result,indent=2,ensure_ascii=False));return 1 if args.public and not result['publicReady'] else 0
if __name__=='__main__':raise SystemExit(main())
