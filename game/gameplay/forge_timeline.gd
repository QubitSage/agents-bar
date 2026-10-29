extends RefCounted
## Saved, deterministic combat timeline. No Nodes, timers, IO or wall-clock rewards.
const Rules=preload("res://gameplay/battle.gd")
const Art=preload("res://gameplay/visual_library.gd")
const Boss=preload("res://gameplay/azhor.gd")
const APPROACH=0.42
const RETURN=0.28
const REACH=48.0
const SETTLE=1.35

static func fresh() -> Dictionary:
	return {"clock":0.0,"phase_time":0.0,"settle":0.0,"order":[],"action":{},"poses":{},"serial":0}

static func key(side: String,index: int) -> String:
	return side+":"+str(index)

static func home(side: String,index: int) -> float:
	return 145.0-index*54.0 if side=="allies" else 350.0+index*48.0

static func position(run: Dictionary,side: String,index: int) -> float:
	var base:=home(side,index)
	var timeline: Dictionary=run.get("timeline",{})
	var action: Dictionary=timeline.get("action",{})
	if action.is_empty() or action["side"]!=side or int(action["index"])!=index: return base
	var reach:=home(action["target_side"],int(action["target_index"]))+(-REACH if side=="allies" else REACH)
	if action["clip"] in ["defense"] or action.get("heal",false) or action.get("ranged",false): return base
	var time:=float(action["elapsed"])
	if time<APPROACH: return lerpf(base,reach,time/APPROACH)
	if time>APPROACH+float(action["duration"]):
		return lerpf(reach,base,clampf((time-APPROACH-float(action["duration"]))/RETURN,0,1))
	return reach

static func pose(run: Dictionary,side: String,index: int) -> Dictionary:
	var member: Dictionary=run[side][index]
	var timeline: Dictionary=run.get("timeline",fresh())
	var now:=float(timeline["clock"])
	var stored: Dictionary=timeline["poses"].get(key(side,index),{})
	if int(member["hp"])<=0: return {"clip":"death","time":maxf(0,now-float(stored.get("since",now)))}
	if run["phase"]=="result": return {"clip":"victory" if side=="allies" and run["result"]=="victory" else "idle","time":now}
	if run["phase"] in ["travel","rest"]: return {"clip":"walk" if side=="allies" else "idle","time":now}
	var action: Dictionary=timeline["action"]
	if not action.is_empty() and action["side"]==side and int(action["index"])==index:
		var time:=float(action["elapsed"])
		if time<APPROACH or time>APPROACH+float(action["duration"]): return {"clip":"idle" if action.get("ranged",false) or action["clip"]=="defense" or action.get("heal",false) else "walk","time":time}
		return {"clip":action["clip"],"time":time-APPROACH}
	if not stored.is_empty() and now-float(stored["since"])<Art.duration(Art.clip(member,stored["clip"])):
		return {"clip":stored["clip"],"time":now-float(stored["since"])}
	return {"clip":"idle","time":now}

static func mark(run: Dictionary,side: String,index: int,clip_name: String) -> void:
	run["timeline"]["poses"][key(side,index)]={"clip":clip_name,"since":run["timeline"]["clock"]}

static func choose_target(run: Dictionary,side: String) -> int:
	var candidates: Array=run[side]
	for i in range(candidates.size()):
		if int(candidates[i]["hp"])>0 and candidates[i]["id"]=="brasa": return i
	for i in range(candidates.size()):
		if int(candidates[i]["hp"])>0: return i
	return -1

static func start_round(run: Dictionary) -> void:
	var t: Dictionary=run["timeline"]
	run["round"]=int(run["round"])+1
	for side in ["allies","enemies"]:
		for i in range(run[side].size()):
			var unit: Dictionary=run[side][i]
			if int(unit["hp"])>0 and int(unit["poison"])>0:
				unit["hp"]=maxi(0,int(unit["hp"])-4)
				unit["poison"]=int(unit["poison"])-1
				mark(run,side,i,"death" if int(unit["hp"])==0 else "hurt")
			unit["exposed"]=maxi(0,int(unit["exposed"])-1)
			if int(unit["hp"])>0: t["order"].append({"side":side,"index":i,"speed":unit["speed"]})
	t["order"].sort_custom(func(a,b):
		if int(a["speed"])==int(b["speed"]): return a["side"]=="allies" and b["side"]!="allies"
		return int(a["speed"])>int(b["speed"])
	)

static func start_action(run: Dictionary) -> void:
	var t: Dictionary=run["timeline"]
	while not t["order"].is_empty():
		var entry: Dictionary=t["order"].pop_front()
		var side: String=entry["side"]
		var index:=int(entry["index"])
		var unit: Dictionary=run[side][index]
		if int(unit["hp"])<=0: continue
		var target_side: String="enemies" if side=="allies" else "allies"
		var target_index:=choose_target(run,target_side)
		if target_index<0: return
		var special: bool=int(run["round"])%3==0
		var clip_name: String="special" if special else "attack"
		if special and unit["skill"]=="shield": clip_name="defense"
		var heal: bool=special and unit["skill"]=="heal"
		var world_boss: bool=unit["id"]==Boss.ID
		if world_boss: clip_name=Boss.next_clip(unit,int(run["round"]))
		var meta:=Art.clip(unit,clip_name)
		var impact:=float(meta["durations"][0])/1000.0
		if clip_name=="special": impact+=float(meta["durations"][1])/1000.0
		if world_boss:
			impact=0
			for frame in range(int(Boss.MOVES[clip_name]["frame"])): impact+=float(meta["durations"][frame])/1000.0
		t["action"]={"side":side,"index":index,"target_side":target_side,"target_index":target_index,"clip":clip_name,"heal":heal,"elapsed":0.0,"duration":Art.duration(meta),"impact_at":APPROACH+impact,"applied":false}
		if world_boss:
			t["action"].merge({"ranged":Boss.MOVES[clip_name]["ranged"],"enraged":Boss.phase(unit)==2,"label":Boss.MOVES[clip_name]["name"]})
		t["serial"]=int(t["serial"])+1
		return

static func impact(run: Dictionary) -> void:
	var t: Dictionary=run["timeline"]
	var action: Dictionary=t["action"]
	if action.is_empty() or action.get("applied",false): return
	var unit: Dictionary=run[action["side"]][int(action["index"])]
	var target: Dictionary=run[action["target_side"]][int(action["target_index"])]
	action["applied"]=true
	if int(unit["hp"])<=0: return
	if unit["id"]==Boss.ID:
		if action["clip"]=="defense":
			unit["shield"]=mini(120,int(unit["shield"])+45)
			Rules.note(run,"AZHOR reforçou o bastião: +45 de escudo.")
		else:
			var targets: Array=[]
			if Boss.MOVES[action["clip"]]["area"]:
				for i in range(run[action["target_side"]].size()): targets.append(i)
			else: targets.append(int(action["target_index"]))
			for index in targets:
				var victim: Dictionary=run[action["target_side"]][index]
				if int(victim["hp"])<=0: continue
				var absorbed: bool=int(victim["shield"])>0
				var dealt:=Rules.hurt(victim,Boss.power(unit,action["clip"],action.get("enraged",false)))
				mark(run,action["target_side"],index,"death" if int(victim["hp"])<=0 else "defense" if absorbed else "hurt")
				Rules.note(run,"%s → %s: %d." % [action["label"],victim["name"],dealt])
		t["serial"]=int(t["serial"])+1
		return
	if action["clip"]=="defense":
		unit["shield"]=mini(40,int(unit["shield"])+22)
		Rules.note(run,str(unit["name"])+" preparou a defesa: +22 de escudo.")
	elif action["heal"]:
		var recipient: Dictionary=Rules.weakest(Rules.living(run[action["side"]]))
		var recovered:=mini(24,int(recipient["max_hp"])-int(recipient["hp"]))
		recipient["hp"]=int(recipient["hp"])+recovered
		Rules.note(run,"%s restaurou %d de vida." % [unit["name"],recovered])
	elif int(target["hp"])>0:
		# Contact is computed from the same reach and motion used by presentation.
		var distance:=absf(position(run,action["side"],int(action["index"]))-home(action["target_side"],int(action["target_index"])))
		if distance>REACH+1.0: return
		var power:=int(unit["attack"])
		if action["clip"]=="special": power=int(power*1.6)
		var shield_before:=int(target["shield"])
		var damage:=Rules.hurt(target,power)
		if unit["skill"]=="poison" and int(target["hp"])>0: target["poison"]=3
		mark(run,action["target_side"],int(action["target_index"]),"death" if int(target["hp"])<=0 else "defense" if shield_before>0 else "hurt")
		Rules.note(run,"%s → %s: %d%s." % [unit["name"],target["name"],damage," · bloqueio" if shield_before>0 else ""])
	t["serial"]=int(t["serial"])+1

static func deaths_finished(run: Dictionary) -> bool:
	for side in ["allies","enemies"]:
		for i in range(run[side].size()):
			var unit: Dictionary=run[side][i]
			if int(unit["hp"])>0: continue
			var stored: Dictionary=run["timeline"]["poses"].get(key(side,i),{})
			# A legacy save may not include a death timestamp.
			if stored.is_empty(): continue
			if float(run["timeline"]["clock"])-float(stored["since"])<Art.duration(Art.clip(unit,"death")): return false
	return true

static func advance(run: Dictionary,content: Dictionary,delta: float) -> void:
	if run.is_empty() or run.get("paused",false) or run["phase"]=="result": return
	if not run.has("timeline"): run["timeline"]=fresh()
	var t: Dictionary=run["timeline"]
	var dt:=clampf(delta,0,.25)
	t["clock"]=float(t["clock"])+dt
	run["ticks"]=int(floor(float(t["clock"])))
	var mission:=Rules.find(content["missions"],run["mission_id"])
	if run["phase"] in ["travel","rest"]:
		t["phase_time"]=float(t["phase_time"])+dt
		if float(t["phase_time"])>=2.2:
			run["phase"]="battle";run["delay"]=0;t["phase_time"]=0.0
			Rules.note(run,"Encontro %d/%d · %s." % [int(run["wave"])+1,mission["waves"].size(),run["enemies"][0]["name"]])
		return
	var action: Dictionary=t["action"]
	if not action.is_empty():
		action["elapsed"]=float(action["elapsed"])+dt
		if not action["applied"] and float(action["elapsed"])>=float(action["impact_at"]): impact(run)
		if float(action["elapsed"])>=APPROACH+float(action["duration"])+RETURN: t["action"]={}
		return
	if Rules.living(run["allies"]).is_empty() or Rules.living(run["enemies"]).is_empty():
		t["settle"]=float(t["settle"])+dt
		if float(t["settle"])>=SETTLE and deaths_finished(run):
			Rules.finish_wave(run,content,mission)
			t["order"]=[];t["settle"]=0.0;t["phase_time"]=0.0
			if run["phase"]!="result": t["poses"]={}
		return
	if t["order"].is_empty():
		if int(run["round"])>=80:
			run["phase"]="result";run["result"]="defeat";return
		start_round(run)
	if not Rules.living(run["allies"]).is_empty() and not Rules.living(run["enemies"]).is_empty(): start_action(run)

static func valid(run: Dictionary) -> bool:
	if not run.has("timeline"): return true
	var t=run["timeline"]
	if not t is Dictionary: return false
	for field in ["clock","phase_time","settle","serial"]:
		if not (t.get(field) is float or t.get(field) is int) or not is_finite(float(t[field])) or float(t[field])<0: return false
	if not t.get("order") is Array or not t.get("poses") is Dictionary or not t.get("action") is Dictionary or t["order"].size()>6: return false
	for entry in t["order"]:
		if not entry is Dictionary or not entry.get("side") in ["allies","enemies"]: return false
		if not (entry.get("index") is int or entry.get("index") is float): return false
		if int(entry["index"])<0 or int(entry["index"])>=run[entry["side"]].size(): return false
	for p in t["poses"].values():
		if not p is Dictionary or not p.get("clip") in ["death","hurt","defense"]: return false
		if not (p.get("since") is float or p.get("since") is int) or not is_finite(float(p["since"])): return false
	var a: Dictionary=t["action"]
	if a.is_empty(): return true
	for prefix in ["","target_"]:
		if not a.get(prefix+"side") in ["allies","enemies"]: return false
		if not (a.get(prefix+"index") is int or a.get(prefix+"index") is float): return false
		if int(a[prefix+"index"])<0 or int(a[prefix+"index"])>=run[a[prefix+"side"]].size(): return false
	var is_boss: bool=run[a["side"]][int(a["index"])]["id"]==Boss.ID
	if not a.get("applied") is bool or not a.get("heal") is bool: return false
	if is_boss:
		if not Boss.MOVES.has(a.get("clip")) or not a.get("enraged") is bool or not a.get("ranged") is bool or not a.get("label") is String: return false
	else:
		if not a.get("clip") in ["attack","special","defense"]: return false
	for field in ["elapsed","duration","impact_at"]:
		if not (a.get(field) is int or a.get(field) is float) or not is_finite(float(a[field])) or float(a[field])<0 or float(a[field])>20: return false
	return true
