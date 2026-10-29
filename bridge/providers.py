"""Read-only adapters. Only allowlisted metadata leaves the adapter; never prompts/code."""
import hashlib
import json
import math

PROVIDERS = {'codex', 'claude', 'cursor', 'antigravity', 'grok', 'generic'}


def count(value):
    return value if isinstance(value, int) and not isinstance(value, bool) and 0 <= value <= 10**12 else None


def usage(raw, cumulative=False):
    if not isinstance(raw, dict):
        return None
    incoming = count(raw.get('input_tokens', raw.get('inputTokens', raw.get('prompt_tokens'))))
    outgoing = count(raw.get('output_tokens', raw.get('outputTokens', raw.get('completion_tokens'))))
    total = count(raw.get('total_tokens', raw.get('totalTokens')))
    if total is None and incoming is not None and outgoing is not None:
        total = incoming + outgoing
    if total is None:
        return None
    return {'total': total, 'input': incoming, 'output': outgoing, 'cumulative': cumulative}


def activity(tool):
    tool = str(tool).lower()
    if any(word in tool for word in ('subagent', 'task', 'delegate', 'spawn_agent')):
        return 'reinforcement'
    if any(word in tool for word in ('edit', 'write', 'patch', 'replace')):
        return 'edit'
    if any(word in tool for word in ('bash', 'shell', 'command', 'terminal', 'exec')):
        return 'execute'
    if any(word in tool for word in ('read', 'view', 'search', 'grep', 'glob', 'list')):
        return 'read'
    return 'thinking'


def normalize(provider, raw, hook=None):
    if provider not in PROVIDERS or not isinstance(raw, dict):
        raise ValueError('Unsupported provider or payload')
    kind, action, tokens, turn, parent, context = None, 'thinking', None, '', '', None
    event = hook or raw.get('hook_event_name', '')
    session = raw.get('session_id', raw.get('conversation_id', raw.get('conversationId', '')))
    model = raw.get('model_id', raw.get('modelName', raw.get('model', '')))
    if isinstance(model, dict):
        model = model.get('id', '')
    project = ''  # Paths and email never cross the local boundary.
    if provider == 'codex' and not event:
        p = raw.get('params', {})
        if not isinstance(p, dict): raise ValueError('Invalid Codex params')
        session = p.get('threadId', '')
        method = raw.get('method')
        turn_data = p.get('turn', {})
        if not isinstance(turn_data, dict): raise ValueError('Invalid turn')
        turn = p.get('turnId', turn_data.get('id', '') if isinstance(turn_data, dict) else '')
        if method == 'turn/started': kind = 'started'
        elif method == 'turn/completed':
            kind = {'completed': 'completed', 'failed': 'failed', 'interrupted': 'cancelled'}.get(turn_data.get('status'))
        elif method == 'thread/tokenUsage/updated':
            token_data = p.get('tokenUsage', {})
            if not isinstance(token_data, dict): raise ValueError('Invalid token usage')
            tokens = usage(token_data.get('total'), True)
            kind = 'usage'
        elif method in ('item/commandExecution/requestApproval', 'item/fileChange/requestApproval'):
            kind = 'waiting'
        elif method in ('item/started', 'item/completed'):
            item = p.get('item', {})
            if not isinstance(item, dict): raise ValueError('Invalid item')
            kind = 'activity'
            action = activity({'fileChange':'edit', 'commandExecution':'command', 'collabAgentToolCall':'subagent'}.get(item.get('type'), item.get('type')))
        else: return None
    elif provider in ('codex', 'claude', 'cursor', 'antigravity'):
        turn = raw.get('generation_id', raw.get('turn_id', ''))
        event_map = {
            'SessionStart':'connected', 'sessionStart':'connected', 'SessionEnd':'disconnected', 'sessionEnd':'disconnected',
            'UserPromptSubmit':'started', 'beforeSubmitPrompt':'started',
            'PreToolUse':'activity', 'preToolUse':'activity', 'PostToolUse':'activity', 'postToolUse':'activity',
            'PostToolUseFailure':'activity', 'postToolUseFailure':'activity',
            'PermissionRequest':'waiting', 'SubagentStart':'activity', 'subagentStart':'activity',
            'SubagentStop':'activity', 'subagentStop':'activity', 'Stop':'completed', 'stop':'completed',
            'StopFailure':'failed', 'Notification':'waiting', 'PermissionDenied':'activity', 'Interrupt':'cancelled', 'PreInvocation':'activity', 'PostInvocation':'activity', 'statusline':'usage',
        }
        kind = event_map.get(event)
        if kind is None: return None
        if event == 'Notification' and raw.get('notification_type') != 'permission_prompt': return None
        if provider == 'cursor' and event == 'stop':
            kind = {'completed':'completed','aborted':'cancelled','error':'failed'}.get(raw.get('status'), 'idle')
        if provider == 'antigravity' and event == 'Stop':
            # Termination is not proof of success. Review is explicit in the game.
            kind = 'idle'
        call = raw.get('toolCall', {})
        if not isinstance(call, dict): raise ValueError('Invalid tool metadata')
        tool = raw.get('tool_name', call.get('name', ''))
        action = 'reinforcement' if event in ('SubagentStart','subagentStart') else activity(tool)
        if kind == 'usage':
            window = raw.get('context_window', {})
            if not isinstance(window, dict): raise ValueError('Invalid context metadata')
            tokens = usage({'input_tokens':window.get('total_input_tokens'), 'output_tokens':window.get('total_output_tokens')}, True)
            # Context-window fill is a separate signal from tokens processed by the session.
            percent = window.get('used_percentage')
            if isinstance(percent, (int, float)) and not isinstance(percent, bool) and 0 <= percent <= 100: context = round(percent, 1)
        # Hooks do not get permission overrides from this observer.
    elif provider == 'grok':
        session = raw.get('session_id', '')
        turn = raw.get('request_id', raw.get('id', ''))
        tokens = usage(raw.get('usage'))
        kind = 'usage'
    else:
        kind = raw.get('kind')
        action = raw.get('activity', 'thinking')
        turn = raw.get('turn_id', '')
        parent = raw.get('parent_session_id', '')
        tokens = usage(raw.get('usage'), bool(raw.get('cumulative', False)))
    if kind not in {'connected','started','activity','waiting','resumed','completed','failed','cancelled','idle','usage','disconnected'}:
        raise ValueError('Unsupported event')
    if not isinstance(session, str) or not 1 <= len(session) <= 128:
        raise ValueError('A session identifier is required')
    if action not in {'thinking','read','edit','execute','reinforcement'}: action = 'thinking'
    return {'provider':provider, 'sessionId':session, 'turnId':str(turn)[:128], 'type':kind,
            'activity':action, 'model':str(model)[:80], 'project':project,
            'parentSessionId':str(parent)[:128], 'usage':tokens, 'contextPercent':context}
