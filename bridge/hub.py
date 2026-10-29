"""Provider-neutral session states for Agents Bar. No connection or file discovery."""
from collections import OrderedDict
from dataclasses import dataclass, field
import hashlib
import math

TYPES = {'started', 'activity', 'waiting', 'resumed', 'completed', 'failed', 'cancelled', 'disconnected'}
TERMINAL = {'completed', 'failed', 'cancelled'}


@dataclass
class Slot:
    provider: str
    session_id: str
    project: str
    state: str = 'disconnected'
    activity: str = 'none'
    turn_id: str = ''
    last_at: float = 0
    lifecycle_at: float = 0
    seen: OrderedDict = field(default_factory=OrderedDict)


class SessionHub:
    def __init__(self):
        self.slots = OrderedDict()

    def bind(self, provider, session_id, project):
        key = (provider, session_id)
        if key in self.slots:
            return
        if not provider or not session_id:
            raise ValueError('provider and sessionId required')
        if len(self.slots) >= 3:
            raise ValueError('three-session capacity reached')
        self.slots[key] = Slot(provider, session_id, str(project)[:40])

    def ingest(self, event):
        if not isinstance(event, dict):
            return False
        slot = self.slots.get((event.get('provider'), event.get('sessionId')))
        kind, event_id, at = event.get('type'), event.get('eventId'), event.get('at')
        if not slot or kind not in TYPES or not isinstance(event_id, str) or not event_id:
            return False
        if not isinstance(at, (int, float)) or isinstance(at, bool) or not math.isfinite(at) or at <= 0:
            return False
        if event_id in slot.seen or at < slot.last_at:
            return False
        turn_id = str(event.get('turnId') or '')
        if kind == 'started':
            if not turn_id or (turn_id == slot.turn_id and slot.state in TERMINAL):
                return False
            slot.turn_id, slot.state, slot.activity = turn_id, 'working', 'thinking'
        elif kind == 'disconnected':
            slot.state, slot.activity = 'disconnected', 'none'
        else:
            if not turn_id or turn_id != slot.turn_id or slot.state in TERMINAL:
                return False
            if kind == 'activity':
                if slot.state == 'waiting':
                    return False
                slot.state = 'working'
                slot.activity = 'tool' if event.get('activity') == 'tool' else 'thinking'
            elif kind in ('waiting', 'resumed'):
                slot.state = 'waiting' if kind == 'waiting' else 'working'
                slot.activity = 'none' if kind == 'waiting' else 'thinking'
            else:
                slot.state, slot.activity = kind, 'none'
        slot.last_at = at
        if kind != 'activity':
            slot.lifecycle_at = at
        slot.seen[event_id] = None
        while len(slot.seen) > 512:
            slot.seen.popitem(last=False)
        return True

    def snapshot(self, now):
        sessions = []
        for slot in self.slots.values():
            state = 'unknown' if slot.state == 'working' and now - slot.last_at > 120 else slot.state
            sessions.append({'provider':slot.provider, 'sessionId':slot.session_id, 'project':slot.project,
                             'state':state, 'activity':slot.activity if state == 'working' else 'none',
                             'turnId':slot.turn_id, 'lastEventAt':slot.last_at, 'lifecycleAt':slot.lifecycle_at,
                             'heartbeatAt':now})
        return {'schemaVersion':2, 'heartbeatAt':now, 'sessions':sessions}


def normalize_rpc(message, at):
    """Pure adapter for documented app-server notifications; never sends RPC calls."""
    if not isinstance(message, dict):
        return None
    method, p = message.get('method'), message.get('params', {})
    if not isinstance(p, dict) or not isinstance(p.get('threadId'), str):
        return None
    turn = p.get('turn', {})
    if not isinstance(turn, dict):
        turn = {}
    turn_id = p.get('turnId') or turn.get('id')
    kind, activity, item_id = None, 'none', ''
    if method == 'turn/started':
        kind = 'started'
    elif method == 'turn/completed':
        kind = {'completed':'completed', 'failed':'failed', 'interrupted':'cancelled'}.get(turn.get('status'))
    elif method in ('item/started', 'item/completed'):
        item = p.get('item', {})
        if not isinstance(item, dict) or not item.get('id'):
            return None
        tool_types = {'commandExecution', 'fileChange', 'mcpToolCall', 'webSearch', 'imageGeneration', 'dynamicToolCall'}
        if item.get('type') not in tool_types | {'reasoning', 'agentMessage'}:
            return None
        item_id = str(item['id'])
        kind = 'activity'
        activity = 'tool' if method == 'item/started' and item.get('type') in tool_types else 'thinking'
    if not kind or not turn_id:
        return None
    identity = '|'.join((p['threadId'],str(turn_id),str(method),kind,item_id))
    return {'eventId':hashlib.sha256(identity.encode()).hexdigest()[:24], 'provider':'codex',
            'sessionId':p['threadId'], 'turnId':str(turn_id), 'at':at, 'type':kind, 'activity':activity}
