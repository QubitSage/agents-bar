extends RefCounted

signal changed
signal cue(name: String)
const Battle=preload("res://gameplay/battle.gd")
const Store=preload("res://gameplay/save_store.gd")
const Equipment=preload("res://gameplay/equipment.gd")
const Timeline=preload("res://gameplay/forge_timeline.gd")
var content: Dictionary={}
var state: Dictionary={}
var save_path: String=""
var read_only:=false
var notice: String=""
var accumulator:=0.0
var autosave_ticks:=0

func defaults() -> Dictionary:
	return {"version":4,"materials":{"scrap":20,"cores":1,"seeds":0},"crew":{"io":{"level":1,"xp":0,"relic":""},"brasa":{"level":1,"xp":0,"relic":""},"luma":{"level":1,"xp":0,"relic":""}},"team":["io","brasa"],"buildings":{"core":1,"workshop":0,"greenhouse":0,"observatory":0},"completed":{},"inventory":[],"active":{},"claimed_runs":{},"next_run":1,"journal":[],"pending_milestones":[],"accepted_milestones":{},"next_milestone":1,"memories":0,"onboarded":false,"sound":false,"reduced_motion":false}

func initialize(path: String="user://progress.json") -> void:
	content=JSON.parse_string(FileAccess.get_file_as_string("res://content/game.json"))
	state=merge_defaults({})
	save_path=path
	if path.is_empty():
		return
	var loaded: Dictionary=Store.load_state(path)
	if loaded.get("ok",false):
		var imported: Dictionary=loaded["state"]
		if not valid_state(imported):
			read_only=true
			notice="O progresso precisa de revisão. O arquivo original foi preservado."
			return
		state=merge_defaults(imported)
		if loaded.get("source")=="backup":
			notice="Progresso recuperado do backup local."
		elif loaded.get("migrated",false):
			notice="Progresso atualizado para esta versão."
	else:
		read_only=bool(loaded.get("read_only",false))
		if read_only:
			notice="Não foi possível carregar o progresso. Seus arquivos foram preservados."

func merge_defaults(imported: Dictionary) -> Dictionary:
	var result:=defaults()
	result["layout"]=["core","workshop","greenhouse","observatory"]
	result["building_memories"]={}
	result["session_bindings"]={}
	result["expedition_mode"]="agents"
	result["gear"]=Equipment.default_gear()
	result["always_on_top"]=true
	result["claimed_through"]=0
	for key in result:
		if imported.has(key):
			if result[key] is Dictionary and imported[key] is Dictionary and key in ["materials","crew","buildings"]:
				result[key].merge(imported[key],true)
			else:
				result[key]=imported[key]
	for id in ["io","brasa","luma"]:
		if result["crew"].get(id) is Dictionary:
			var member: Dictionary={"level":1,"xp":0,"relic":"","forge":0}
			member.merge(result["crew"][id],true)
			result["crew"][id]=member
	for run_id in result["claimed_runs"]:
		var suffix: String=str(run_id).trim_prefix("run-")
		if str(run_id).begins_with("run-") and suffix.is_valid_int(): result["claimed_through"]=maxi(int(result["claimed_through"]),int(suffix))
	while result["claimed_runs"].size()>100: result["claimed_runs"].erase(result["claimed_runs"].keys()[0])
	result["version"]=4
	return result

func valid_number(value,minimum: int=0,maximum: int=100000000) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floor(float(value)) and float(value)>=minimum and float(value)<=maximum

func valid_state(candidate: Dictionary) -> bool:
	if candidate.has("claimed_through") and not valid_number(candidate["claimed_through"]): return false
	if candidate.has("gear") and not Equipment.valid(candidate["gear"]): return false
	if candidate.has("expedition_mode") and not candidate["expedition_mode"] in ["agents","practice"]: return false
	if candidate.has("session_bindings"):
		if not candidate["session_bindings"] is Dictionary or candidate["session_bindings"].size()>3: return false
		for hero in candidate["session_bindings"]:
			if not hero in ["io","brasa","luma"] or not candidate["session_bindings"][hero] is String: return false
	if not candidate.get("materials") is Dictionary or not candidate.get("crew") is Dictionary:
		return false
	for key in ["buildings","completed","claimed_runs","accepted_milestones","active","building_memories"]:
		if candidate.has(key) and not candidate[key] is Dictionary:
			return false
	for key in ["team","inventory","journal","pending_milestones","layout"]:
		if candidate.has(key) and not candidate[key] is Array:
			return false
	var normalized:=merge_defaults(candidate)
	if normalized["layout"].size()!=4:
		return false
	for id in ["core","workshop","greenhouse","observatory"]:
		if normalized["layout"].count(id)!=1:
			return false
	for id in normalized["building_memories"]:
		var memory=normalized["building_memories"][id]
		if not id in normalized["layout"] or not memory is Dictionary or not memory.get("title") is String or not memory.get("id") is String:
			return false
	for key in ["scrap","cores","seeds"]:
		if not valid_number(normalized["materials"].get(key)):
			return false
	for id in ["io","brasa","luma"]:
		var member=normalized["crew"].get(id)
		if not member is Dictionary or not valid_number(member.get("level"),1,5) or not valid_number(member.get("xp",0)):
			return false
		if not valid_number(member.get("forge",0),0,5): return false
		var relic=member.get("relic","")
		if not relic is String or (not relic.is_empty() and (definition("relics",relic).is_empty() or not relic in normalized["inventory"])):
			return false
	for id in ["core","workshop","greenhouse","observatory"]:
		if not valid_number(normalized["buildings"].get(id),1 if id=="core" else 0,3):
			return false
	var team: Array=normalized["team"]
	if team.is_empty() or team.size()>(3 if int(normalized["buildings"]["core"])>=2 else 2):
		return false
	var unique: Dictionary={}
	for id in team:
		if not id is String or not id in ["io","brasa","luma"] or unique.has(id):
			return false
		unique[id]=true
	if normalized["inventory"].size()>6 or normalized["journal"].size()>100 or normalized["pending_milestones"].size()>20:
		return false
	unique={}
	for id in normalized["inventory"]:
		if not id is String or definition("relics",id).is_empty() or unique.has(id):
			return false
		unique[id]=true
	unique={}
	for member in normalized["crew"].values():
		if not member is Dictionary:
			return false
		var relic: String=str(member.get("relic",""))
		if not relic.is_empty():
			if unique.has(relic):
				return false
			unique[relic]=true
	for id in normalized["completed"]:
		if not id is String or definition("missions",id).is_empty() or not valid_number(normalized["completed"][id],1):
			return false
	for key in ["next_run","next_milestone","memories"]:
		if not valid_number(normalized[key],0 if key=="memories" else 1):
			return false
	if not valid_number(normalized["claimed_through"]) or int(normalized["next_run"])<=int(normalized["claimed_through"]): return false
	for key in ["onboarded","sound","reduced_motion","always_on_top"]:
		if not normalized[key] is bool:
			return false
	for item in normalized["pending_milestones"]+normalized["journal"]:
		if not item is Dictionary or not item.get("id") is String or not item.get("title") is String:
			return false
	for item in normalized["journal"]:
		if not item.get("result") is String:
			return false
	var active: Dictionary=normalized["active"]
	if active.is_empty():
		return true
	if not active.get("mission_id") is String:
		return false
	var mission:=definition("missions",active["mission_id"])
	if mission.is_empty() or not active.get("run_id") is String or not active.get("paused") is bool:
		return false
	if not active.get("phase") in ["travel","rest","battle","result"] or not active.get("result") in ["","victory","defeat","retreated"]:
		return false
	if (active["phase"]=="result") != (active["result"]!=""):
		return false
	if not valid_number(active.get("wave"),0,mission["waves"].size()-1) or not valid_number(active.get("round"),0,80):
		return false
	if not valid_number(active.get("ticks")) or not valid_number(active.get("delay"),0,3):
		return false
	if not active.get("log") is Array or active["log"].size()>30:
		return false
	for item in active["log"]:
		if not item is String:
			return false
	for group in ["allies","enemies"]:
		if not active.get(group) is Array or active[group].is_empty() or active[group].size()>3:
			return false
		for member in active[group]:
			if not member is Dictionary:
				return false
			if not member.get("id") is String or definition("characters" if group=="allies" else "enemies",member["id"]).is_empty():
				return false
			for field in ["name","asset","skill","side"]:
				if not member.get(field) is String:
					return false
			if member["side"]!=("ally" if group=="allies" else "enemy"):
				return false
			for field in ["hp","max_hp","attack","armor","speed","shield","poison","exposed"]:
				if not valid_number(member.get(field),1 if field=="max_hp" else 0,100000):
					return false
			if int(member["hp"])>int(member["max_hp"]):
				return false
	return Timeline.valid(active)

func persist() -> bool:
	if read_only:
		return false
	if save_path.is_empty():
		return true
	var ok:=Store.save_state(save_path,state)
	if not ok:
		notice="Não foi possível salvar. Mantenha o jogo aberto e tente novamente."
	return ok

func commit() -> void:
	persist()
	changed.emit()

func definition(group: String,id: String) -> Dictionary:
	return Battle.find(content.get(group,[]),id)

func unlocked(mission_id: String) -> bool:
	var mission:=definition("missions",mission_id)
	return not mission.is_empty() and (mission["requires"]=="" or state["completed"].has(mission["requires"]))

func capacity() -> int:
	return 3 if int(state["buildings"]["core"])>=2 else 2

func journey_bindings() -> Dictionary:
	var result: Dictionary={}
	for id in state["team"]:
		var session: String=state["session_bindings"].get(id,"")
		if not session.is_empty(): result[id]=session
	return result

func prepare_azhor_demo() -> bool:
	# A demonstration must never overwrite a persisted campaign.
	if not save_path.is_empty(): return false
	state=merge_defaults({})
	state["team"]=["io","brasa","luma"]
	for id in state["buildings"]: state["buildings"][id]=3
	for id in state["crew"]: state["crew"][id].merge({"level":5,"forge":3},true)
	for mission in content["missions"]:
		if mission["id"]!="storm-4": state["completed"][mission["id"]]=1
	for relic in content["relics"]: state["inventory"].append(relic["id"])
	state["crew"]["io"]["relic"]="coil";state["crew"]["brasa"]["relic"]="plate";state["crew"]["luma"]["relic"]="seed"
	state["expedition_mode"]="practice"
	return start_mission("storm-4")

func team_stats() -> Array:
	var result: Array=[]
	for id in state["team"]:
		var member: Dictionary=definition("characters",str(id)).duplicate(true)
		var owned: Dictionary=state["crew"][id]
		var level:=int(owned["level"])
		member["hp"]=int(member["hp"])+(level-1)*14+int(state["buildings"]["greenhouse"])*10+(int(state["buildings"]["core"])-1)*8
		member["attack"]=int(member["attack"])+(level-1)*3+int(state["buildings"]["workshop"])*2
		member["attack"]+=int(owned.get("forge",0))*2
		member["armor"]=int(member["armor"])+(level-1)/2
		var gear_bonus:=Equipment.bonuses(self,str(id))
		for stat in gear_bonus: member[stat]=int(member.get(stat,0))+int(gear_bonus[stat])
		var relic:=definition("relics",str(owned.get("relic","")))
		for stat in ["hp","attack","armor"]:
			member[stat]=int(member[stat])+int(relic.get(stat,0))
		result.append(member)
	return result

func select_team(ids: Array) -> bool:
	if read_only or not state["active"].is_empty() or ids.is_empty() or ids.size()>capacity():
		return false
	var unique: Dictionary={}
	for id in ids:
		if not state["crew"].has(id) or unique.has(id):
			return false
		unique[id]=true
	state["team"]=ids.duplicate()
	commit()
	return true

func start_mission(id: String) -> bool:
	if read_only or not unlocked(id) or not state["active"].is_empty():
		return false
	var run:=Battle.create(content,definition("missions",id),team_stats())
	run["run_id"]="run-%d" % int(state["next_run"])
	state["next_run"]=int(state["next_run"])+1
	state["active"]=run
	accumulator=0.0
	notice="A expedição começou. Pode recolher a barra e acompanhar pelo canto."
	commit()
	cue.emit("depart")
	return true

func tick(delta: float) -> void:
	if read_only or state["active"].is_empty() or state["active"].get("paused",false) or state["active"].get("phase")=="result":
		return
	if definition("missions",state["active"]["mission_id"]).get("timed",false):
		var run: Dictionary=state["active"]
		var previous_phase: String=run["phase"]
		var serial:=int(run.get("timeline",{}).get("serial",0))
		Timeline.advance(run,content,delta)
		accumulator+=clampf(delta,0,.25)
		var notify: bool=previous_phase!=run["phase"] or serial!=int(run.get("timeline",{}).get("serial",0))
		if accumulator>=1:
			accumulator-=1;autosave_ticks+=1;notify=true
		if run["phase"]=="result":
			persist()
			cue.emit("victory" if run["result"]=="victory" else "defeat")
		elif autosave_ticks>=5:
			autosave_ticks=0
			persist()
		if notify: changed.emit()
		return
	# No wall-clock catch-up: suspend/closed time is not farmed for rewards.
	accumulator+=clampf(delta,0,1.0)
	if accumulator<1.0:
		return
	accumulator-=1.0
	Battle.step(state["active"],content)
	autosave_ticks+=1
	if state["active"].get("phase")=="result":
		persist()
		cue.emit("victory" if state["active"]["result"]=="victory" else "defeat")
	elif autosave_ticks>=5:
		autosave_ticks=0
		persist()
	changed.emit()

func toggle_expedition_pause() -> void:
	if read_only or state["active"].is_empty():
		return
	state["active"]["paused"]=not state["active"].get("paused",false)
	commit()

func retreat() -> bool:
	if read_only or state["active"].is_empty() or state["active"].get("phase")=="result":
		return false
	state["active"]["phase"]="result"
	state["active"]["result"]="retreated"
	Battle.note(state["active"],"A equipe retornou por sua escolha, sem recompensa e sem penalidade.")
	commit()
	return true

func rewards() -> Dictionary:
	if state["active"].is_empty():
		return {}
	var result: Dictionary=definition("missions",str(state["active"]["mission_id"]))["rewards"].duplicate()
	result["scrap"]=int(result["scrap"])*(100+10*int(state["buildings"]["observatory"]))/100
	return result

func collect() -> bool:
	if read_only or state["active"].is_empty() or state["active"].get("phase")!="result":
		return false
	var run: Dictionary=state["active"]
	var run_id:=str(run["run_id"])
	var sequence: String=run_id.trim_prefix("run-")
	if not run_id.begins_with("run-") or not sequence.is_valid_int() or int(sequence)<=int(state["claimed_through"]) or state["claimed_runs"].has(run_id):
		return false
	var mission:=definition("missions",str(run["mission_id"]))
	var victory: bool=run["result"]=="victory"
	if victory:
		var reward:=rewards()
		for key in ["scrap","cores","seeds"]:
			state["materials"][key]=int(state["materials"][key])+int(reward[key])
		for member in run["allies"]:
			state["crew"][member["id"]]["xp"]=int(state["crew"][member["id"]].get("xp",0))+int(reward["xp"])
		if not state["completed"].has(mission["id"]) and mission.has("relic") and not mission["relic"] in state["inventory"]:
			state["inventory"].append(mission["relic"])
		state["completed"][mission["id"]]=int(state["completed"].get(mission["id"],0))+1
	state["claimed_runs"][run_id]=true
	state["claimed_through"]=int(sequence)
	while state["claimed_runs"].size()>100: state["claimed_runs"].erase(state["claimed_runs"].keys()[0])
	state["journal"].push_front({"type":"expedition","title":mission["name"],"result":run["result"],"id":run_id})
	if state["journal"].size()>100:
		state["journal"].resize(100)
	state["active"]={}
	notice="Recompensas guardadas na estação." if victory else "A equipe está pronta para uma nova tentativa."
	commit()
	return true

func afford(cost: Dictionary) -> bool:
	for key in cost:
		if int(state["materials"].get(key,0))<int(cost[key]):
			return false
	return true

func pay(cost: Dictionary) -> void:
	for key in cost:
		state["materials"][key]=int(state["materials"][key])-int(cost[key])

func training_cost(id: String) -> Dictionary:
	var level:=int(state["crew"][id]["level"])
	return {"scrap":12*level,"cores":level,"seeds":0}

func train(id: String) -> bool:
	if read_only or not state["crew"].has(id) or not state["active"].is_empty():
		return false
	if int(state["crew"][id]["level"])>=5:
		return false
	var cost:=training_cost(id)
	if not afford(cost):
		return false
	pay(cost)
	state["crew"][id]["level"]=int(state["crew"][id]["level"])+1
	commit()
	return true

func building_cost(id: String) -> Dictionary:
	var cost: Dictionary=definition("buildings",id)["cost"].duplicate()
	for key in cost:
		cost[key]=int(cost[key])*maxi(1,int(state["buildings"][id]))
	return cost

func build(id: String) -> bool:
	var template:=definition("buildings",id)
	if read_only or template.is_empty() or not state["active"].is_empty():
		return false
	if int(state["buildings"][id])>=int(template["max_level"]):
		return false
	var cost:=building_cost(id)
	if not afford(cost):
		return false
	pay(cost)
	state["buildings"][id]=int(state["buildings"][id])+1
	commit()
	return true

func equip(id: String,relic: String) -> bool:
	if read_only or not state["active"].is_empty() or not state["crew"].has(id):
		return false
	if not relic.is_empty() and not relic in state["inventory"]:
		return false
	for other in state["crew"]:
		if other!=id and not relic.is_empty() and state["crew"][other].get("relic","")==relic:
			return false
	state["crew"][id]["relic"]=relic
	commit()
	return true

func offer_milestone(id: String,title: String) -> bool:
	if read_only or id.is_empty() or state["accepted_milestones"].has(id):
		return false
	for pending in state["pending_milestones"]:
		if pending["id"]==id:
			return false
	if state["pending_milestones"].size()>=20:
		return false
	state["pending_milestones"].append({"id":id,"title":title.strip_edges().left(80)})
	commit()
	return true

func manual_milestone(title: String) -> bool:
	if read_only or title.strip_edges().is_empty():
		return false
	var id: String="manual-%d" % int(state["next_milestone"])
	state["next_milestone"]=int(state["next_milestone"])+1
	return offer_milestone(id,title)

func resolve_milestone(id: String,accept: bool) -> bool:
	if read_only or state["accepted_milestones"].has(id):
		return false
	for i in range(state["pending_milestones"].size()):
		var item: Dictionary=state["pending_milestones"][i]
		if item["id"]==id:
			state["pending_milestones"].remove_at(i)
			# Remember both decisions so repeated provider events cannot resurface.
			state["accepted_milestones"][id]=accept
			if accept:
				state["memories"]=int(state["memories"])+1
				state["journal"].push_front({"type":"milestone","title":item["title"],"result":"accepted","id":id})
				if state["journal"].size()>100:
					state["journal"].resize(100)
			commit()
			return true
	return false

func set_option(key: String,value: bool) -> void:
	if not read_only and key in ["sound","reduced_motion","onboarded","always_on_top"]:
		state[key]=value
		commit()

func export_diagnostic(path: String="user://diagnostics/diagnostic.json") -> bool:
	var report: Dictionary={"appVersion":"0.9.11","engineVersion":Engine.get_version_info()["string"],"saveReadOnly":read_only,"completedMissionCount":state["completed"].size(),"pendingMilestoneCount":state["pending_milestones"].size(),"phase":state["active"].get("phase","station"),"journalEntryCount":state["journal"].size()}
	var absolute:=ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file:=FileAccess.open(absolute,FileAccess.WRITE)
	if not file:
		notice="Não foi possível salvar o diagnóstico."
		changed.emit()
		return false
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	notice="Diagnóstico sem conversas ou títulos salvo em "+absolute
	changed.emit()
	return true

func place_building(id: String,slot: int) -> bool:
	if read_only or not state["active"].is_empty() or not id in state["layout"] or slot<0 or slot>=4:
		return false
	var previous: int=state["layout"].find(id)
	var displaced: String=state["layout"][slot]
	state["layout"][slot]=id
	state["layout"][previous]=displaced
	commit()
	return true

func bind_memory(building: String,milestone: String) -> bool:
	if read_only or not state["buildings"].has(building) or int(state["buildings"][building])==0:
		return false
	for entry in state["journal"]:
		if entry["id"]==milestone and entry.get("type")=="milestone" and entry["result"]=="accepted":
			state["building_memories"][building]={"id":milestone,"title":entry["title"]}
			commit()
			return true
	return false

func combine_milestones(title: String) -> bool:
	if read_only or title.strip_edges().is_empty() or state["pending_milestones"].size()<2:
		return false
	for entry in state["pending_milestones"]:
		state["accepted_milestones"][entry["id"]]=true
	var id: String="bundle-%d" % int(state["next_milestone"])
	state["next_milestone"]=int(state["next_milestone"])+1
	state["pending_milestones"].clear()
	state["memories"]=int(state["memories"])+1
	state["journal"].push_front({"type":"milestone","title":title.strip_edges().left(80),"id":id,"result":"accepted"})
	if state["journal"].size()>100:
		state["journal"].resize(100)
	commit()
	return true

func can_recover_backup() -> bool:
	if save_path.is_empty() or Store.decode(save_path).get("error")=="future": return false
	var backup:=Store.decode(save_path+".bak")
	return read_only and backup.get("ok",false) and valid_state(backup.get("state",{}))

func recover_backup() -> bool:
	if not can_recover_backup(): return false
	var restored: Dictionary=merge_defaults(Store.decode(save_path+".bak")["state"])
	var absolute:=ProjectSettings.globalize_path(save_path)
	var archive:=absolute+".before-recovery-"+str(Time.get_unix_time_from_system()).replace(".","-")
	if FileAccess.file_exists(save_path) and DirAccess.copy_absolute(absolute,archive)!=OK: return false
	# Preserve the good backup even if the original envelope is logically invalid.
	if DirAccess.copy_absolute(absolute+".bak",archive+".good-backup")!=OK: return false
	if not Store.save_state(save_path,restored): return false
	state=restored;read_only=false;notice="Backup recuperado. O arquivo anterior foi preservado.";changed.emit();return true
