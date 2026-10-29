"""Minimal, allowlisted lifecycle reducer. Never retain message/tool content."""
from dataclasses import dataclass
from datetime import datetime, timezone


def epoch(value):
    if not isinstance(value, str):
        return 0.0
    try:
        return datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()
    except (ValueError, OverflowError):
        return 0.0


@dataclass
class SessionState:
    state: str = 'unknown'
    turn_id: str = ''
    activity: str = 'none'
    last_event_at: float = 0.0
    lifecycle_at: float = 0.0
    sequence: int = 0

    def consume(self, row):
        if not isinstance(row, dict):
            return None
        payload = row.get('payload')
        if not isinstance(payload, dict):
            return None
        at = epoch(row.get('timestamp'))
        if at <= 0 or at < self.last_event_at:
            return None
        kind = payload.get('type')
        event = None
        incoming_turn = payload.get('turn_id') or payload.get('root_turn_id')
        if row.get('type') == 'event_msg':
            if kind == 'task_started':
                if incoming_turn == self.turn_id and self.state in ('working', 'completed', 'cancelled', 'failed'):
                    return None
                self.turn_id = str(incoming_turn or '')
                self.state, self.activity, event = 'working', 'thinking', 'turn.started'
            elif kind in ('task_complete', 'turn_aborted', 'task_failed'):
                if incoming_turn and self.turn_id and incoming_turn != self.turn_id:
                    return None
                if incoming_turn == self.turn_id and self.state in ('completed', 'cancelled', 'failed'):
                    return None
                next_state = {'task_complete':'completed', 'turn_aborted':'cancelled', 'task_failed':'failed'}[kind]
                if self.state == next_state:
                    return None
                self.turn_id = str(incoming_turn or self.turn_id)
                self.state, self.activity, event = next_state, 'none', 'turn.' + next_state
            elif kind == 'token_count' and self.state == 'working':
                self.last_event_at = at
                return None
        elif row.get('type') == 'response_item' and self.state == 'working':
            # Names, arguments, output, reasoning, messages and token counts are not retained.
            if kind in ('function_call', 'custom_tool_call'):
                self.activity, event = 'tool', 'activity.tool'
            elif kind in ('function_call_output', 'custom_tool_call_output'):
                self.activity, event = 'thinking', 'activity.thinking'
        if event is None:
            return None
        self.last_event_at = at
        self.sequence += 1
        if event.startswith('turn.'):
            self.lifecycle_at = at
        return {'type': event, 'state': self.state, 'activity': self.activity,
                'turnId': self.turn_id, 'at': at, 'sequence': self.sequence}

    def snapshot(self, now, connected=True):
        stale = self.state == 'working' and now - self.last_event_at > 120
        state = self.state if connected and not stale else ('unknown' if connected else 'disconnected')
        return {'state': state, 'activity': self.activity if state == 'working' else 'none',
                'turnId': self.turn_id, 'lastEventAt': self.last_event_at,
                'lifecycleAt': self.lifecycle_at, 'sequence': self.sequence,
                'stale': stale, 'connected': connected}
