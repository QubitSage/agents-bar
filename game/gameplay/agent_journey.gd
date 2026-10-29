extends RefCounted
## Activity funds seconds of combat, not purchasable power. Never catches up offline.
var baseline: Dictionary={}
var sessions: Array=[]
var credit:=0.0
var reason: String="Conecte e vincule um agente"
var previous_bindings: Dictionary={}

func update(incoming: Array,bindings: Dictionary) -> void:
	if previous_bindings!=bindings:
		baseline.clear();credit=0;previous_bindings=bindings.duplicate(true)
	var present: Array=incoming.map(func(s): return str(s.get("sessionId","")))
	for id in baseline.keys():
		if not id in present: baseline.erase(id)
	sessions=[]
	for session in incoming:
		var id: String=str(session.get("sessionId",""))
		if not id in bindings.values(): continue
		sessions.append(session)
		var units:=int(session.get("workUnits",0))
		var tokens:=int(session.get("totalTokens",0))
		var turn: String=str(session.get("turnId",""))
		if baseline.has(id) and not baseline[id]["state"] in ["disconnected","unknown"]:
			var old: Dictionary=baseline[id]
			if session.get("state")=="working":
				credit=minf(12,credit+minf(6,maxi(0,units-int(old["units"]))*2))
				# Known usage gives a bounded pulse; unavailable counters never block work events.
				if session.get("usageKnown",false) and tokens>int(old["tokens"]): credit=minf(12,credit+1)
				if turn!=old["turn"]: credit=minf(12,credit+2)
			if session.get("state")=="completed" and (old["state"]!="completed" or turn!=old["turn"]): credit=minf(12,credit+6)
		baseline[id]={"units":units,"tokens":tokens,"turn":turn,"state":session.get("state")}

func advance(model,delta: float) -> void:
	if model.state["active"].is_empty(): reason="Equipe na estação";return
	if model.state["active"].get("paused",false): reason="Expedição pausada";return
	if model.state["active"].get("phase")=="result": reason="Resultado pronto para revisão";return
	if model.state.get("expedition_mode","agents")=="practice":
		reason="Expedição livre"
		model.tick(delta)
		return
	var working:=false
	var finished:=false
	var waiting:=false
	for session in sessions:
		working=working or session.get("state")=="working"
		finished=finished or session.get("state")=="completed"
		waiting=waiting or session.get("state")=="waiting"
	if not working and not finished:
		reason="Agente precisa de você" if waiting else "Aguardando atividade vinculada"
		return
	if credit<=0:
		reason="Aguardando próximo evento de trabalho"
		return
	var used:=minf(credit,clampf(delta,0,.25))
	credit-=used
	model.tick(used)
	reason="Trabalho movimentando a expedição"
