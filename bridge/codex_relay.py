"""Transparent stdio relay for an app-server owned by the integrating client, never the desktop app."""
import argparse
import json
import subprocess
import sys
import threading
import queue
from hook import send


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--directory',required=True);parser.add_argument('--codex',default='codex')
    args=parser.parse_args()
    observations=queue.Queue(maxsize=256)
    def observe():
        while True:
            event=observations.get()
            try: send('codex',event,args.directory)
            except (OSError,ValueError): pass
            finally: observations.task_done()
    threading.Thread(target=observe,daemon=True).start()
    child=subprocess.Popen([args.codex,'app-server'],stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=sys.stderr,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    def forward_input():
        try:
            for line in sys.stdin.buffer:child.stdin.write(line);child.stdin.flush()
        except (OSError,BrokenPipeError):pass
        finally:child.stdin.close()
    threading.Thread(target=forward_input,daemon=True).start()
    try:
        for line in child.stdout:
            sys.stdout.buffer.write(line);sys.stdout.buffer.flush()
            try:
                event=json.loads(line)
                if isinstance(event,dict) and 'method' in event: observations.put_nowait(event)
            except (ValueError,OSError,queue.Full):pass
    finally:
        if child.poll() is None:child.terminate()
        child.wait()


if __name__=='__main__':main()
