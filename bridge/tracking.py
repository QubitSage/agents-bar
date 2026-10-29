"""Loopback-only local collector with transactional deduplication and bounded retention."""
import argparse
import hashlib
import hmac
import json
import os
from pathlib import Path
import secrets
import sqlite3
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from providers import normalize
from license import refresh as refresh_license, cached as cached_license

LIMIT = 65536


def plan_limits(claim,now):
    return (12,90) if claim and claim['exp']>now else (3,1)


class Tracker:
    def __init__(self, path, max_sessions=3, history_days=1):
        self.db = sqlite3.connect(path, check_same_thread=False)
        self.db.row_factory = sqlite3.Row
        self.lock = threading.RLock()
        self.max_sessions = max_sessions
        self.history_days = history_days
        self.db.executescript('''
        CREATE TABLE IF NOT EXISTS sessions (
          id TEXT PRIMARY KEY, provider TEXT, session TEXT, state TEXT, activity TEXT,
          turn_id TEXT, model TEXT, last_at REAL, lifecycle REAL, total INTEGER DEFAULT 0,
          highwater INTEGER DEFAULT 0, known INTEGER DEFAULT 0, work INTEGER DEFAULT 0);
        CREATE TABLE IF NOT EXISTS events (id TEXT PRIMARY KEY, session TEXT, at REAL, kind TEXT, delta INTEGER);
        CREATE INDEX IF NOT EXISTS events_time ON events(at);
        ''')
        if 'last_work' not in {row[1] for row in self.db.execute('PRAGMA table_info(sessions)')}:
            self.db.execute('ALTER TABLE sessions ADD COLUMN last_work REAL DEFAULT 0')
            self.db.commit()
        if 'context_pct' not in {row[1] for row in self.db.execute('PRAGMA table_info(sessions)')}:
            self.db.execute('ALTER TABLE sessions ADD COLUMN context_pct REAL')
            self.db.commit()

    def begin_connection(self):
        # Persist counters/deduplication, but do not resurrect activity from a previous process.
        with self.lock,self.db:
            self.db.execute("UPDATE sessions SET state='disconnected',activity='none'")

    def ingest(self, provider, payload, event_id, now=None, hook=None):
        now = time.time() if now is None else now
        if not isinstance(event_id, str) or not 1 <= len(event_id) <= 160: raise ValueError('Event ID required')
        event = normalize(provider, payload, hook)
        if event is None: return False
        key = hashlib.sha256((provider+':'+event['sessionId']).encode()).hexdigest()[:24]
        if provider == 'grok' and event['usage']:
            if not event['turnId']: raise ValueError('Response ID required for usage deduplication')
            event_id = 'response:'+event['turnId']
        event_id = key+':'+event_id
        with self.lock, self.db:
            if self.db.execute('SELECT 1 FROM events WHERE id=?', (event_id,)).fetchone(): return False
            s = self.db.execute('SELECT * FROM sessions WHERE id=?', (key,)).fetchone()
            active_ids=[row[0] for row in self.db.execute("SELECT id FROM sessions WHERE state != 'disconnected' AND last_at>? ORDER BY last_at DESC LIMIT ?",(now-120,self.max_sessions))]
            if len(active_ids)>=self.max_sessions and key not in active_ids:
                raise ValueError('Plan session limit reached')
            if s is None:
                active = self.db.execute("SELECT count(*) FROM sessions WHERE state != 'disconnected' AND last_at>?", (now-120,)).fetchone()[0]
                if active >= self.max_sessions: raise ValueError('Plan session limit reached')
                self.db.execute('INSERT INTO sessions(id,provider,session,state,activity,turn_id,model,last_at,lifecycle) VALUES (?,?,?,?,?,?,?,?,?)',
                                (key,provider,event['sessionId'],'idle','thinking','',event['model'],now,now))
                s = self.db.execute('SELECT * FROM sessions WHERE id=?',(key,)).fetchone()
            elif s['state']=='disconnected' or s['last_at']<=now-120:
                active=self.db.execute("SELECT count(*) FROM sessions WHERE id != ? AND state != 'disconnected' AND last_at>?",(key,now-120)).fetchone()[0]
                if active>=self.max_sessions:raise ValueError('Plan session limit reached')
            kind, state, action, turn = event['type'], s['state'], s['activity'], s['turn_id']
            terminal = state in ('completed','failed','cancelled')
            if kind == 'connected':
                state,action='idle','none'
            elif kind == 'started':
                turn = event['turnId'] or event_id
                if terminal and turn == s['turn_id']: return False
                state, action = 'working', 'thinking'
            elif kind == 'activity':
                if event['turnId'] and turn and event['turnId'] != turn: return False
                if terminal: return False
                state, action = 'working', event['activity']
                turn = turn or event['turnId'] or event_id
            elif kind == 'resumed': state = 'working'
            elif kind in ('waiting','completed','failed','cancelled','idle','disconnected'):
                if event['turnId'] and turn and event['turnId'] != turn: return False
                state, action = kind, 'none'
            if provider == 'grok' and event['usage']:
                state,action,turn='completed','none',event['turnId']
            tokens, delta, highwater, known = event['usage'], 0, s['highwater'], s['known']
            if tokens:
                known = 1
                if tokens['cumulative']:
                    # First cumulative reading is a baseline, never a historical reward burst.
                    delta = max(0,tokens['total']-highwater) if s['known'] else 0
                    highwater = max(highwater, tokens['total'])
                else:
                    delta = tokens['total']
            worked = kind == 'activity' and now-s['last_work'] >= 1
            work = s['work'] + int(worked)
            lifecycle = now if state != s['state'] or kind == 'started' else s['lifecycle']
            self.db.execute('UPDATE sessions SET state=?,activity=?,turn_id=?,model=?,last_at=?,lifecycle=?,total=total+?,highwater=?,known=?,work=? WHERE id=?',
                            (state,action,turn,event['model'] or s['model'],now,lifecycle,delta,highwater,known,work,key))
            if event.get('contextPercent') is not None: self.db.execute('UPDATE sessions SET context_pct=? WHERE id=?',(event['contextPercent'],key))
            self.db.execute('INSERT INTO events VALUES (?,?,?,?,?)',(event_id,key,now,kind,delta))
            if worked: self.db.execute('UPDATE sessions SET last_work=? WHERE id=?',(now,key))
            self.db.execute('DELETE FROM events WHERE at < ?', (now-self.history_days*86400,))
            self.db.execute('DELETE FROM sessions WHERE last_at < ?', (now-90*86400,))
        return True

    def snapshot(self, now=None):
        now = time.time() if now is None else now
        with self.lock, self.db:
            self.db.execute('DELETE FROM events WHERE at < ?', (now-self.history_days*86400,))
            rows = self.db.execute('SELECT * FROM sessions ORDER BY last_at DESC LIMIT ?', (self.max_sessions,)).fetchall()
            sessions = []
            for i,s in enumerate(rows):
                state = s['state']
                if state == 'working' and now-s['last_at'] > 120: state = 'unknown'
                sessions.append({'sessionId':s['id'],'provider':s['provider'],'project':s['provider'].title()+' · '+s['id'][:6],
                                 'state':state,'activity':s['activity'],'turnId':s['turn_id'],'model':s['model'],
                                 'lifecycleAt':s['lifecycle'],'heartbeatAt':now,'characterIndex':i%3,
                                 'usageKnown':bool(s['known']),'totalTokens':s['total'],'workUnits':s['work'],
                                 'contextPercent':s['context_pct'],'tokenScope':'session-observed'})
            daily = self.db.execute('SELECT CAST(at/86400 AS INTEGER) AS day,sum(delta) AS tokens,count(*) AS events FROM events GROUP BY day ORDER BY day DESC LIMIT ?', (self.history_days+1,)).fetchall()
        return {'schemaVersion':3,'mode':'live','source':'local-hooks','heartbeatAt':now,'sessions':sessions,'plan':'pro' if self.max_sessions==12 else 'free',
                'history':[dict(r) for r in daily], 'planLimits':{'sessions':self.max_sessions,'historyDays':self.history_days}}


def atomic(path, value):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(value,ensure_ascii=False),encoding='utf-8')
    os.replace(temporary,path)


def serve(directory, port=43127):
    directory = Path(directory).resolve(); directory.mkdir(parents=True,exist_ok=True)
    token_path = directory/'collector-token.txt'
    if not token_path.exists(): token_path.write_text(secrets.token_urlsafe(32),encoding='ascii')
    token = token_path.read_text(encoding='ascii').strip()
    tracker = Tracker(directory/'usage.sqlite3')
    config_path=Path(__file__).resolve().parents[1]/'game/content/online.json'
    config=json.loads(config_path.read_text(encoding='utf-8'))
    stopping=threading.Event()
    class Handler(BaseHTTPRequestHandler):
        def setup(self):
            super().setup()
            self.connection.settimeout(3)
        def log_message(self,*args): pass
        def do_POST(self):
            if self.path not in ('/v1/events','/v1/stop'): self.send_error(404); return
            if not hmac.compare_digest(self.headers.get('Authorization',''), 'Bearer '+token): self.send_error(401); return
            if self.headers.get('Origin'): self.send_error(403); return
            if self.path == '/v1/stop':
                self.send_response(200);self.send_header('Content-Length','0');self.end_headers()
                stopping.set();threading.Thread(target=server.shutdown,daemon=True).start();return
            try:
                length = int(self.headers.get('Content-Length','0'))
                if not 0 < length <= LIMIT: raise ValueError('Payload size')
                message = json.loads(self.rfile.read(length))
                with tracker.lock:
                    if stopping.is_set(): self.send_error(503);return
                    accepted = tracker.ingest(message['provider'],message['payload'],message['eventId'],hook=message.get('hook'))
                data = json.dumps({'accepted':accepted}).encode()
                self.send_response(200);self.send_header('Content-Type','application/json');self.send_header('Content-Length',str(len(data)));self.end_headers();self.wfile.write(data)
            except (ValueError,KeyError,TypeError,TimeoutError): self.send_error(400,'Invalid event')
    server = ThreadingHTTPServer(('127.0.0.1',port),Handler)
    tracker.begin_connection()
    # Read a valid cached claim before any retention pruning. Network renewal must
    # never stall snapshot heartbeats or discard Pro history while it is still valid.
    license_state={'claim':cached_license(directory,config)}
    def renew():
        while not stopping.is_set():
            try:
                claim=refresh_license(directory,config)
                with tracker.lock:license_state['claim']=claim
            except (OSError,ValueError):pass
            stopping.wait(60)
    def publish():
        while not stopping.is_set():
            with tracker.lock:
                tracker.max_sessions,tracker.history_days=plan_limits(license_state['claim'],time.time())
                snapshot=tracker.snapshot()
            snapshot['collectorPid']=os.getpid()
            try: atomic(directory/'session-state.json',snapshot)
            except OSError: pass  # Windows readers may briefly lock the previous snapshot.
            stopping.wait(.5)
    threading.Thread(target=renew,daemon=True).start()
    publisher=threading.Thread(target=publish,daemon=True);publisher.start()
    try:
        server.serve_forever(poll_interval=.2)
    finally:
        stopping.set();publisher.join(timeout=2)
        server.server_close()
        tracker.begin_connection()
        snapshot=tracker.snapshot();snapshot['collectorPid']=0;snapshot['stopped']=True
        try:atomic(directory/'session-state.json',snapshot)
        except OSError:pass
        with tracker.lock:tracker.db.close()


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory',required=True)
    parser.add_argument('--port',type=int,default=43127)
    args=parser.parse_args();serve(args.directory,args.port)
