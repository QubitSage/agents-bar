"""Replay a chosen fixture offline. No calls to providers or session discovery."""
import argparse
import json
from pathlib import Path
from hub import SessionHub

def replay(data, now):
    hub=SessionHub()
    for binding in data['bindings']:
        hub.bind(binding['provider'],binding['sessionId'],binding['project'])
    for event in data['events']:
        if event['at']<=now:
            hub.ingest(event)
    result=hub.snapshot(now)
    result['mode']='replay'
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('fixture',type=Path)
    parser.add_argument('--at',type=float,required=True)
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(replay(json.loads(args.fixture.read_text(encoding='utf-8')),args.at),indent=2),encoding='utf-8')
