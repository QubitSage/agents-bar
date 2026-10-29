extends RefCounted

static func find(items: Array, id: String) -> Dictionary:
	for item in items:
		if item.get("id")==id:
			return item
	return {}

static func unit(template: Dictionary, side: String) -> Dictionary:
	var result: Dictionary=template.duplicate(true)
	result["max_hp"]=int(result["hp"])
	result["side"]=side
	result["shield"]=0
	result["poison"]=0
	result["exposed"]=0
	return result

static func create(content: Dictionary, mission: Dictionary, party: Array) -> Dictionary:
	var allies: Array=[]
	for member in party:
		allies.append(unit(member,"ally"))
	var run: Dictionary={"mission_id":mission["id"],"allies":allies,"enemies":[],"wave":0,"round":0,"phase":"travel","delay":3,"result":"","log":["A equipe partiu para "+mission["name"]+"."],"paused":false,"ticks":0}
	load_wave(run,content,mission)
	return run

static func load_wave(run: Dictionary, content: Dictionary, mission: Dictionary) -> void:
	run["enemies"]=[]
	run["round"]=0
	for id in mission["waves"][int(run["wave"])]:
		run["enemies"].append(unit(find(content["enemies"],str(id)),"enemy"))

static func note(run: Dictionary, text: String) -> void:
	run["log"].append(text)
	if run["log"].size()>30:
		run["log"].pop_front()

static func living(units: Array) -> Array:
	return units.filter(func(member): return int(member["hp"])>0)

static func hurt(target: Dictionary, raw: int) -> int:
	var damage:=maxi(1,raw-int(target["armor"])+int(target.get("exposed",0)))
	var absorbed:=mini(int(target["shield"]),damage)
	target["shield"]=int(target["shield"])-absorbed
	damage-=absorbed
	var dealt:=mini(int(target["hp"]),damage)
	target["hp"]=maxi(0,int(target["hp"])-damage)
	return dealt

static func weakest(units: Array) -> Dictionary:
	var chosen: Dictionary=units[0]
	for member in units:
		if float(member["hp"])/float(member["max_hp"])<float(chosen["hp"])/float(chosen["max_hp"]):
			chosen=member
	return chosen

static func act(run: Dictionary, actor: Dictionary) -> void:
	var allies: Array=living(run["allies"])
	var enemies: Array=living(run["enemies"])
	if allies.is_empty() or enemies.is_empty() or int(actor["hp"])<=0:
		return
	var player: bool=actor["side"]=="ally"
	var target: Dictionary=enemies[0] if player else allies[0]
	if not player:
		for member in allies:
			if member["id"]=="brasa":
				target=member
	var skill: String=str(actor.get("skill","none"))
	var special: bool=int(run["round"])%3==0
	if special and skill=="heal":
		var recipient: Dictionary=weakest(allies if player else enemies)
		var heal:=mini(int(recipient["max_hp"])-int(recipient["hp"]),18+int(actor["attack"])/2)
		if heal>0:
			recipient["hp"]=int(recipient["hp"])+heal
			note(run,"%s recuperou %d de vida de %s." % [actor["name"],heal,recipient["name"]])
			return
	if special and skill=="shield":
		actor["shield"]=mini(40,int(actor["shield"])+18)
		note(run,str(actor["name"])+" ergueu um escudo.")
	if special and skill=="sonar":
		target["exposed"]=4
		note(run,"IO revelou um ponto fraco.")
	var power:=int(actor["attack"])
	if special and skill=="burst":
		power=int(power*1.6)
	var damage:=hurt(target,power)
	if skill=="poison" and int(target["hp"])>0:
		target["poison"]=3
	note(run,"%s → %s: %d." % [actor["name"],target["name"],damage])

static func finish_wave(run: Dictionary,content: Dictionary,mission: Dictionary) -> bool:
	if living(run["allies"]).is_empty():
		run["phase"]="result"
		run["result"]="defeat"
		note(run,"A equipe retornou para reparos. Nenhum material foi perdido.")
		return true
	if living(run["enemies"]).is_empty():
		if int(run["wave"])+1>=mission["waves"].size():
			run["phase"]="result"
			run["result"]="victory"
			note(run,"Missão concluída. Recolha a recompensa na estação.")
		else:
			run["wave"]=int(run["wave"])+1
			for member in run["allies"]:
				member["hp"]=mini(int(member["max_hp"]),int(member["hp"])+maxi(1,int(member["max_hp"])*20/100))
				member["poison"]=0
				member["shield"]=0
			load_wave(run,content,mission)
			run["phase"]="rest"
			run["delay"]=2
			note(run,"Rota segura. A equipe fez pequenos reparos.")
		return true
	return false

static func step(run: Dictionary,content: Dictionary) -> void:
	if run.is_empty() or run.get("paused",false) or run.get("phase")=="result":
		return
	var mission:=find(content["missions"],str(run["mission_id"]))
	run["ticks"]=int(run["ticks"])+1
	if run["phase"] in ["travel","rest"]:
		run["delay"]=int(run["delay"])-1
		if int(run["delay"])<=0:
			run["phase"]="battle"
			note(run,"Encontro %d de %d." % [int(run["wave"])+1,mission["waves"].size()])
		return
	run["round"]=int(run["round"])+1
	for member in run["allies"]+run["enemies"]:
		if int(member["poison"])>0 and int(member["hp"])>0:
			member["hp"]=maxi(0,int(member["hp"])-4)
			member["poison"]=int(member["poison"])-1
		member["exposed"]=maxi(0,int(member["exposed"])-1)
	if finish_wave(run,content,mission):
		return
	var order: Array=run["allies"]+run["enemies"]
	order.sort_custom(func(a,b):
		if int(a["speed"])==int(b["speed"]):
			return a["side"]=="ally" and b["side"]!="ally"
		return int(a["speed"])>int(b["speed"])
	)
	for actor in order:
		act(run,actor)
		if finish_wave(run,content,mission):
			return
	if int(run["round"])>=80:
		run["phase"]="result"
		run["result"]="defeat"
		note(run,"A equipe recuou após um confronto prolongado.")
