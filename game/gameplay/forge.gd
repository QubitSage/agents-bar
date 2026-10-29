extends RefCounted

static func cost(model,id: String) -> Dictionary:
	var level:=int(model.state["crew"].get(id,{}).get("forge",0))
	return {"scrap":8*(level+1),"cores":1 if level>=2 else 0,"seeds":0}

static func upgrade(model,id: String) -> bool:
	if model.read_only or not model.state["active"].is_empty() or not model.state["crew"].has(id): return false
	var level:=int(model.state["crew"][id].get("forge",0))
	if level>=5 or not model.afford(cost(model,id)): return false
	model.pay(cost(model,id))
	model.state["crew"][id]["forge"]=level+1
	model.notice="Arma aprimorada: +2 de ataque."
	model.commit()
	return true

static func craft(model,id: String) -> bool:
	if model.read_only or not model.state["active"].is_empty() or id in model.state["inventory"]: return false
	if model.definition("relics",id).is_empty(): return false
	var unlocked:=false
	for mission in model.content["missions"]:
		if mission.get("relic")==id and model.state["completed"].has(mission["id"]): unlocked=true
	var price: Dictionary={"scrap":24,"cores":1,"seeds":0}
	if not unlocked or not model.afford(price): return false
	model.pay(price);model.state["inventory"].append(id)
	model.notice="Relíquia recriada na Forja."
	model.commit()
	return true

static func recycle(model,id: String) -> bool:
	if model.read_only or not model.state["active"].is_empty() or not id in model.state["inventory"]: return false
	for member in model.state["crew"].values():
		if member["relic"]==id: return false
	model.state["inventory"].erase(id)
	model.state["materials"]["scrap"]=int(model.state["materials"]["scrap"])+4
	model.notice="Relíquia reciclada: +4 sucata. Pode recriá-la na Forja."
	model.commit()
	return true
