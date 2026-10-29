extends RefCounted

const STATES := ["working","waiting","completed","failed","cancelled","idle","unknown","disconnected"]
const PRIORITY := {"failed":8,"waiting":7,"working":6,"completed":5,"cancelled":4,"unknown":3,"disconnected":2,"idle":1}

static func canvas_size(compact: bool) -> Vector2i:
	return Vector2i(160,48) if compact else Vector2i(320,132)

static func dock_rect(usable: Rect2i, factor: int, compact: bool) -> Rect2i:
	var size := canvas_size(compact)*clampi(factor,2,3)
	var x := usable.end.x-size.x-12 if compact else usable.position.x+(usable.size.x-size.x)/2
	return Rect2i(Vector2i(maxi(x,usable.position.x),maxi(usable.end.y-size.y-4,usable.position.y)),size)

static func label(state: String) -> String:
	var labels := {"working":"Trabalhando","waiting":"Precisa de você","completed":"Concluído","failed":"Falha na tarefa","cancelled":"Cancelado","idle":"Em descanso","unknown":"Sem sinal recente","disconnected":"Sem conexão"}
	return labels.get(state,"Sem conexão")

static func empty_session(index: int) -> Dictionary:
	return {"sessionId":"","state":"disconnected","activity":"none","project":"","characterIndex":index}

static func normalize(payload: Dictionary, now: float) -> Array:
	var result: Array = []
	var candidates = payload.get("sessions",[payload])
	if not candidates is Array:
		return result
	for raw in candidates.slice(0,3):
		if not raw is Dictionary:
			continue
		var state := str(raw.get("state","disconnected"))
		if not state in STATES:
			state="unknown"
		var heartbeat := safe_time(raw.get("heartbeatAt",payload.get("heartbeatAt",0)))
		if heartbeat<=0 or now-heartbeat>5 or heartbeat>now+5:
			state="disconnected"
		var lifecycle := safe_time(raw.get("lifecycleAt",0))
		if lifecycle>now+5:
			lifecycle=0
		result.append({"sessionId":str(raw.get("sessionId","")).left(128),"provider":str(raw.get("provider","codex")).left(32),"turnId":str(raw.get("turnId","")).left(128),"state":state,"activity":str(raw.get("activity","none")).left(20),"project":str(raw.get("project","")).left(40),"lifecycleAt":lifecycle,"characterIndex":result.size()})
	return result

static func safe_time(value) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return maxf(0,float(value))
	return 0.0

static func summary(sessions: Array) -> Dictionary:
	var best := empty_session(0)
	var priority := -1
	var working := 0
	for session in sessions:
		if str(session.get("sessionId","" )).is_empty():
			continue
		if session.get("state")=="working":
			working+=1
		var current := int(PRIORITY.get(session.get("state"),0))
		if current>priority:
			priority=current
			best=session
	var text := label(str(best["state"]))
	if best["state"]=="working" and working>1:
		text="%d trabalhando" % working
	return {"state":best["state"],"text":text,"characterIndex":int(best.get("characterIndex",0))}

## Honest connection line: never says "working" without a live session reporting it.
static func connection(active: bool, sessions: Array) -> String:
	if not active:
		return "Desconectado"
	var real: Array = sessions.filter(func(item): return not str(item.get("sessionId","")).is_empty())
	if real.is_empty():
		return "Coletor ativo · aguardando eventos"
	var states: Array = real.map(func(item): return str(item.get("state","")))
	if "waiting" in states:
		return "Aguardando sua permissão"
	if "working" in states:
		return "Funcionando"
	if "unknown" in states or "disconnected" in states:
		return "Sem informação suficiente"
	return "Conectado · em descanso"

static func animation(session: Dictionary, now: float, is_demo: bool) -> String:
	match session.get("state","disconnected"):
		"working": return "work" if session.get("activity")=="tool" else "walk"
		"waiting": return "wait"
		"completed": return "celebrate" if is_demo or now-float(session.get("lifecycleAt",0))<6 else "idle"
	return "idle"
