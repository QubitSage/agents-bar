"""RS256 offline entitlement verifier using a pinned public RSA JWK. No third-party runtime."""
import base64
import hashlib
import hmac
import json
import math
import os
from pathlib import Path
import time
import urllib.request


def b64(value):
    if not isinstance(value,str) or len(value)>16384: raise ValueError('Invalid token segment')
    return base64.urlsafe_b64decode(value+'='*(-len(value)%4))


def verify(token,jwk,now=None):
    now=time.time() if now is None else now
    try:
        header,payload,signature=token.split('.')
        metadata=json.loads(b64(header))
        if not isinstance(metadata,dict): return None
        if metadata.get('alg')!='RS256': return None
        n=int.from_bytes(b64(jwk['n']),'big'); e=int.from_bytes(b64(jwk['e']),'big')
        size=(n.bit_length()+7)//8
        raw=b64(signature)
        if not 256<=size<=512 or len(raw)!=size or e!=65537: return None
        sig=int.from_bytes(raw,'big')
        if sig>=n:return None
        decoded=pow(sig,e,n).to_bytes(size,'big')
        digest=bytes.fromhex('3031300d060960864801650304020105000420')+hashlib.sha256((header+'.'+payload).encode('ascii')).digest()
        expected=b'\x00\x01'+b'\xff'*(size-len(digest)-3)+b'\x00'+digest
        if not hmac.compare_digest(decoded,expected): return None
        claim=json.loads(b64(payload))
        if not isinstance(claim,dict): return None
        if claim.get('aud')!='agents-bar' or claim.get('plan')!='pro':return None
        if type(claim.get('exp')) not in (int,float) or not math.isfinite(claim['exp']) or not now<claim['exp']<=now+86400+60:return None
        if type(claim.get('iat')) not in (int,float) or not math.isfinite(claim['iat']) or not now-86460<=claim['iat']<=now+60 or claim['exp']<=claim['iat'] or claim['exp']-claim['iat']>86460:return None
        if not isinstance(claim.get('sub'),str) or not claim['sub']:return None
        if claim.get('sessions')!=12 or claim.get('historyDays')!=90:return None
        return claim
    except (ValueError,KeyError,TypeError,OverflowError):return None


def cached(directory,config,now=None):
    try:
        token=(Path(directory)/'entitlement.jwt').read_text(encoding='ascii')[:16384]
        return verify(token,config.get('license_public_key',{}),now)
    except (OSError,ValueError):return None


def refresh(directory,config,now=None):
    directory=Path(directory); now=time.time() if now is None else now
    key_path=directory/'license-key.txt';cache=directory/'entitlement.jwt'
    existing=cached(directory,config,now)
    # A signed license is refreshed once per hour; network failure keeps only its remaining validity.
    if existing and now-existing['iat']<3600:return existing
    url=config.get('api_url','')
    if key_path.exists() and url.startswith('https://'):
        try:
            key=key_path.read_text(encoding='ascii').strip()
            request=urllib.request.Request(url.rstrip('/')+'/v1/license',json.dumps({'key':key}).encode(),{'Content-Type':'application/json'})
            with urllib.request.urlopen(request,timeout=8) as response: result=json.loads(response.read(32768))
            token=result.get('token',''); claim=verify(token,config.get('license_public_key',{}),now)
            if claim:
                temporary=cache.with_suffix('.tmp');temporary.write_text(token,encoding='ascii');os.replace(temporary,cache);return claim
        except (OSError,ValueError):pass
    return existing
