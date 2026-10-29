"""Optional stdio MCP observer. Reporting is explicit; MCP cannot inspect all host usage."""
import argparse
import json
import sys
from hook import send

SCHEMA={'type':'object','properties':{'session_id':{'type':'string'},'turn_id':{'type':'string'},
        'kind':{'type':'string','enum':['started','activity','waiting','resumed','completed','failed','cancelled']},
        'activity':{'type':'string','enum':['thinking','read','edit','execute','reinforcement']}},
        'required':['session_id','kind'],'additionalProperties':False}


def dispatch(request,directory):
    method=request.get('method'); rid=request.get('id')
    if rid is None:return None
    result=None
    if method=='initialize': result={'protocolVersion':'2024-11-05','capabilities':{'tools':{}},'serverInfo':{'name':'agents-bar','version':'0.9.9'}}
    elif method=='ping':result={}
    elif method=='tools/list':result={'tools':[{'name':'report_activity','description':'Report your activity to the local Agents Bar game. Never send prompts, code, secrets or invented token counts. Optional cosmetic observer.','inputSchema':SCHEMA}]}
    elif method=='tools/call' and request.get('params',{}).get('name')=='report_activity':
        data=request['params'].get('arguments',{})
        if not isinstance(data,dict) or set(data)-set(SCHEMA['properties']) or not isinstance(data.get('session_id'),str) or not 1<=len(data['session_id'])<=128 or data.get('kind') not in SCHEMA['properties']['kind']['enum'] or ('activity' in data and data['activity'] not in SCHEMA['properties']['activity']['enum']) or ('turn_id' in data and (not isinstance(data['turn_id'],str) or len(data['turn_id'])>128)):
            return {'jsonrpc':'2.0','id':rid,'error':{'code':-32602,'message':'Unsupported fields'}}
        try:
            status=send('generic',data,directory)
            result={'content':[{'type':'text','text':json.dumps(status)}]}
        except (OSError,ValueError):result={'isError':True,'content':[{'type':'text','text':'Local collector unavailable. Continue your task normally.'}]}
    else:return {'jsonrpc':'2.0','id':rid,'error':{'code':-32601,'message':'Method not found'}}
    return {'jsonrpc':'2.0','id':rid,'result':result}


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--directory',required=True);a=p.parse_args()
    for line in sys.stdin:
        try:
            if len(line)>65536:continue
            response=dispatch(json.loads(line),a.directory)
            if response:print(json.dumps(response),flush=True)
        except (ValueError,TypeError,KeyError):pass
