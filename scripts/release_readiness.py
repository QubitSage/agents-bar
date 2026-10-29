"""Inspect public project configuration only; never contact billing or inspect account credentials."""
import base64
import json
from pathlib import Path
import tomllib
from urllib.parse import urlparse

ROOT=Path(__file__).resolve().parents[1]


def https(value):
    parsed=urlparse(value)
    return parsed.scheme=='https' and bool(parsed.hostname) and 'CONFIGURE' not in value.upper()


def main():
    client=json.loads((ROOT/'game/content/online.json').read_text(encoding='utf-8'))
    server=tomllib.loads((ROOT/'server/wrangler.toml').read_text(encoding='utf-8'))
    missing=[]
    for key in ['api_url','portal_url']:
        if not https(client.get(key,'')):missing.append('game/content/online.json: '+key)
    public=client.get('license_public_key',{})
    try:
        n=public.get('n','');decoded=base64.urlsafe_b64decode(n+'='*(-len(n)%4))
        valid=public.get('e')=='AQAB' and 256<=len(decoded)<=512
    except (ValueError,TypeError):valid=False
    if not valid:missing.append('game/content/online.json: chave pública RSA')
    if not https(server.get('vars',{}).get('PUBLIC_URL','')):missing.append('server/wrangler.toml: PUBLIC_URL')
    price=server.get('vars',{}).get('STRIPE_PRICE_ID','')
    if not price.startswith('price_'):missing.append('server/wrangler.toml: STRIPE_PRICE_ID de teste')
    database=server.get('d1_databases',[{}])[0].get('database_id','')
    if not database or 'CONFIGURE' in database.upper():missing.append('server/wrangler.toml: database_id')
    print(json.dumps({'publicConfigurationReady':not missing,'missing':missing,
      'notVerified':['contas Cloudflare/Stripe','segredos no servidor','implantação HTTPS','pagamento/renovação/cancelamento em Stripe test mode','recuperação de licença e aceite comercial'],
      'note':'Este comando não faz deploy, não lê credenciais e não prova prontidão comercial.'},ensure_ascii=False,indent=2))


if __name__=='__main__':main()
