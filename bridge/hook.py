"""Hook observer: stdin metadata -> authenticated localhost. Never controls tool permission."""
import argparse
import json
from pathlib import Path
import sys
import uuid
import urllib.request


def send(provider, payload, directory, hook=None):
    token=(Path(directory)/'collector-token.txt').read_text(encoding='ascii').strip()
    data=json.dumps({'provider':provider,'payload':payload,'hook':hook,'eventId':str(uuid.uuid4())}).encode()
    request=urllib.request.Request('http://127.0.0.1:43127/v1/events',data,{'Authorization':'Bearer '+token,'Content-Type':'application/json'})
    # Loopback observers must never inherit an external HTTP proxy.
    opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(request,timeout=1) as response: return json.load(response)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--provider',required=True);p.add_argument('--directory',required=True);p.add_argument('--hook')
    args=p.parse_args()
    try:
        raw=sys.stdin.buffer.read(65537)
        if len(raw)>65536: return
        send(args.provider,json.loads(raw),args.directory,args.hook)
    except (OSError,ValueError): pass  # Tracking failures must not interrupt an agent.


if __name__=='__main__': main()
