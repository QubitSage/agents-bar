extends SceneTree
const Model=preload("res://gameplay/model.gd")
const Boss=preload("res://gameplay/azhor.gd")
const Timeline=preload("res://gameplay/forge_timeline.gd")
const Art=preload("res://gameplay/visual_library.gd")
const App=preload("res://app.gd")
const Journey=preload("res://gameplay/agent_journey.gd")
var checks:=0
var failures:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)

func fixture():
	var model:=Model.new();model.initialize("");model.prepare_azhor_demo();return model

func action_fixture(round_number: int):
	var model=fixture();var run: Dictionary=model.state["active"]
	run["phase"]="battle";run["round"]=round_number;run["timeline"]=Timeline.fresh()
	run["timeline"]["order"]=[{"side":"enemies","index":0,"speed":2}]
	Timeline.start_action(run);return model

func finish(model) -> String:
	for i in range(10000):
		model.tick(.1)
		if model.state["active"]["phase"]=="result": return model.state["active"]["result"]
	return "timeout"

func _initialize() -> void:
	var locked:=Model.new();locked.initialize("")
	check(not locked.start_mission("storm-4"),"boss gated by final regional mission")
	locked.save_path="res://never-write-this.json"
	check(not locked.prepare_azhor_demo(),"demo cannot reset a persisted campaign")
	var model=fixture()
	check(model.valid_state(model.state),"demo generates valid campaign state")
	for n in range(Boss.PHASE_ONE.size()):
		var action_model=action_fixture(n+1)
		var run: Dictionary=action_model.state["active"]
		var action: Dictionary=run["timeline"]["action"]
		var name: String=Boss.PHASE_ONE[n]
		check(action["clip"]==name,"phase one choreography "+name)
		var meta:=Art.clip(run["enemies"][0],name)
		check(meta["id"]=="world-boss-09-azhor--"+name,"exact sprite clip "+name)
		check(Art.frame(meta,float(action["impact_at"])-Timeline.APPROACH+.00001,false)==int(Boss.MOVES[name]["frame"]),"impact aligned to declared frame "+name)
		var before: Array=run["allies"].map(func(unit): return unit["hp"])
		while float(action["elapsed"])+.011<float(action["impact_at"]): action_model.tick(.01)
		check(run["allies"].map(func(unit): return unit["hp"])==before,"no early damage "+name)
		action_model.tick(.02)
		check(action["applied"],"impact applied "+name)
		if name=="defense": check(run["enemies"][0]["shield"]==45,"boss shield")
		else:
			var changed:=0
			for i in range(before.size()):
				if run["allies"][i]["hp"]<before[i]: changed+=1
			check(changed==(3 if Boss.MOVES[name]["area"] else 1),"correct damage targets "+name)
		var after:=JSON.stringify(run)
		Timeline.impact(run)
		check(JSON.stringify(run)==after,"repeated impact cannot deal damage twice "+name)
		check(action_model.valid_state(action_model.state),"save accepts boss action "+name)
	var enemy: Dictionary=model.state["active"]["enemies"][0]
	enemy["hp"]=enemy["max_hp"]/2
	check(Boss.phase(enemy)==2 and Boss.next_clip(enemy,5)=="ultimate","second phase at half HP")
	check(Boss.power(enemy,"ultimate",true)>Boss.power(enemy,"ultimate",false),"enraged damage increases")
	# Persist before ultimate contact, reload and finish both without duplicated hits.
	var saved=action_fixture(7)
	var path:=ProjectSettings.globalize_path("res://../tests/scratch/azhor-save.json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	saved.save_path=path;saved.tick(.2)
	check(saved.persist(),"persist prepared ultimate")
	var resumed:=Model.new();resumed.initialize(path)
	check(not resumed.read_only and resumed.state["active"]["timeline"]["action"]["clip"]=="ultimate","reload ultimate phase")
	saved.save_path="";resumed.save_path=""
	check(finish(saved)==finish(resumed),"same result after ultimate reload")
	check(saved.state["active"]["allies"].map(func(u):return u["hp"])==resumed.state["active"]["allies"].map(func(u):return u["hp"]),"same HP after reload")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	# Death is 2.38 seconds, longer than the old generic settling delay.
	var dying=fixture();var run: Dictionary=dying.state["active"]
	run["phase"]="battle";run["timeline"]=Timeline.fresh();run["enemies"][0]["hp"]=0
	Timeline.mark(run,"enemies",0,"death")
	for i in range(20): dying.tick(.1)
	check(run["phase"]!="result","death not cut short after two seconds")
	check(finish(dying)=="victory","death finishes before victory")
	check(dying.collect() and not dying.collect(),"world boss rewards collected once")
	var victory=fixture();var seen: Dictionary={};var phases: Dictionary={}
	for i in range(10000):
		victory.tick(.1)
		var demo_run: Dictionary=victory.state["active"]
		phases[Boss.phase(demo_run["enemies"][0])]=true
		var demo_action: Dictionary=demo_run.get("timeline",{}).get("action",{})
		if demo_action.get("side")=="enemies": seen[demo_action["clip"]]=true
		if demo_run["phase"]=="result": break
	check(victory.state["active"].get("result")=="victory","endgame demonstration is winnable")
	check(seen.has("ultimate") and phases.has(1) and phases.has(2),"demo shows ultimate and both phases")
	# Bench heroes and stale/rebound session counters must not drive the party.
	var party:=Model.new();party.initialize("");party.state["session_bindings"]={"io":"one","luma":"bench"}
	check(party.journey_bindings()=={"io":"one"},"only active formation contributes")
	var journey:=Journey.new()
	var snapshot: Dictionary={"sessionId":"one","state":"working","workUnits":1,"totalTokens":0,"turnId":"t"}
	journey.update([snapshot],party.journey_bindings());snapshot["workUnits"]=2;journey.update([snapshot],party.journey_bindings())
	check(journey.credit==2,"new activity grants credit")
	journey.update([],party.journey_bindings());snapshot["workUnits"]=500;journey.update([snapshot],party.journey_bindings())
	check(journey.credit==2,"reconnection is a new baseline")
	journey.update([snapshot],{});journey.update([snapshot],party.journey_bindings())
	check(journey.credit==0,"rebind clears stale credit")
	check(App.tracking_plan({"plan":"pro","heartbeatAt":1100},1000)=="free","future heartbeat cannot retain Pro")
	check(App.tracking_plan({"plan":"pro","heartbeatAt":999},1000)=="pro","fresh plan snapshot")
	check(App.tracking_plan({"plan":"pro","heartbeatAt":900},1000)=="free","stale plan snapshot")
	print("AZHOR/tracking: %d checks, %d failures. No application/UI instantiated."%[checks,failures]);quit(1 if failures else 0)
