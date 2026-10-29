"""Call record_response in the application that already makes the xAI request. No API key needed here."""
from hook import send


def record_response(response,session_id,directory):
    if hasattr(response,'model_dump'):response=response.model_dump()
    if not isinstance(response,dict) or not response.get('id'):raise ValueError('Completed response ID required')
    try:
        return send('grok',{'session_id':session_id,'request_id':response['id'],'model':response.get('model',''),
                            'usage':response.get('usage',{})},directory)
    except OSError:
        return {'accepted':False,'reason':'collector_unavailable'}
