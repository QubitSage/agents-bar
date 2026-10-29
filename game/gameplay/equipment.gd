extends RefCounted
## Item rules are independent from the HUD and preserve existing saves.
static var _catalog: Dictionary={}
static func catalog() -> Dictionary:
	if _catalog.is_empty(): _catalog=JSON.parse_string(FileAccess.get_file_as_string("res://content/items.json"))
	return _catalog

static func definition(id: String) -> Dictionary:
	return catalog().get("items",{}).get(id,{})

static func default_gear() -> Dictionary:
	return {"owned":["weapons-01","weapons-03","weapons-05"],"equipped":{"io":{"weapon":"weapons-01"},"brasa":{"weapon":"weapons-03"},"luma":{"weapon":"weapons-05"}}}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or not value.get("owned") is Array or not value.get("equipped") is Dictionary: return false
	if value["owned"].size()>12 or value["equipped"].size()!=3: return false
	var seen: Dictionary={}
	for id in value["owned"]:
		if not id is String or definition(id).get("kind") not in ["weapon","armor"] or seen.has(id): return false
		seen[id]=true
	var used: Dictionary={}
	for hero in ["io","brasa","luma"]:
		var slots=value["equipped"].get(hero)
		if not slots is Dictionary or slots.size()>7 or not slots.has("weapon"): return false
		for slot in slots:
			var id=slots[slot]
			if not id is String or not id in value["owned"] or used.has(id): return false
			var item:=definition(id)
			if item.get("slot")!=slot or not hero in item.get("heroes",[]): return false
			used[id]=true
	return true

static func unlocked(model,id: String) -> bool:
	var item:=definition(id)
	return not item.is_empty() and (str(item.get("requires","")).is_empty() or model.state["completed"].has(item["requires"]))

static func equipped_by(model,id: String) -> String:
	for hero in model.state["gear"]["equipped"]:
		if id in model.state["gear"]["equipped"][hero].values(): return hero
	return ""

static func can_equip(model,hero: String,id: String) -> bool:
	var item:=definition(id)
	return not model.read_only and model.state["active"].is_empty() and hero in item.get("heroes",[]) and id in model.state["gear"]["owned"] and equipped_by(model,id) in ["",hero]

static func equip(model,hero: String,id: String) -> bool:
	if not can_equip(model,hero,id): return false
	model.state["gear"]["equipped"][hero][definition(id)["slot"]]=id
	model.notice="Equipamento atualizado.";model.commit();return true

static func unequip(model,hero: String,slot: String) -> bool:
	if model.read_only or not model.state["active"].is_empty() or slot=="weapon" or not model.state["gear"]["equipped"].has(hero): return false
	if not model.state["gear"]["equipped"][hero].has(slot): return false
	model.state["gear"]["equipped"][hero].erase(slot);model.commit();return true

static func craft(model,id: String) -> bool:
	var item:=definition(id)
	if model.read_only or not model.state["active"].is_empty() or item.get("kind") not in ["weapon","armor"] or id in model.state["gear"]["owned"] or not unlocked(model,id) or not model.afford(item.get("cost",{})): return false
	model.pay(item["cost"]);model.state["gear"]["owned"].append(id)
	model.notice="Fabricado: "+item["name"];model.commit();return true

static func bonuses(model,hero: String) -> Dictionary:
	var result: Dictionary={"hp":0,"attack":0,"armor":0,"speed":0}
	for id in model.state["gear"]["equipped"][hero].values():
		var stats: Dictionary=definition(id).get("stats",{})
		for key in result: result[key]+=int(stats.get(key,0))
	return result

