extends SceneTree
const Model=preload("res://gameplay/model.gd")
const Store=preload("res://gameplay/save_store.gd")
var checks:=0
var failures:=0

func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		printerr("FAIL: "+message)

func finish(model) -> String:
	for i in range(6000):
		model.tick(1.0)
		if model.state["active"].get("phase")=="result":
			return str(model.state["active"]["result"])
	return "timeout"

func _initialize() -> void:
	for script_path in ["res://ui/game_window.gd","res://ui/battle_canvas.gd","res://ui/station_canvas.gd","res://audio/sound.gd"]:
		var compiled=load(script_path)
		check(compiled!=null and compiled.can_instantiate(),"UI compile only: "+script_path)
	var model:=Model.new()
	model.initialize("")
	check(model.content["missions"].size()==10,"ten missions")
	check(model.content["maps"].size()==3,"three maps")
	for group in ["characters","maps","enemies"]:
		for item in model.content[group]:
			var asset: String=item["asset"]+("-sheet" if group=="characters" else "")
			var image:=Image.load_from_file("res://assets/"+asset+".png")
			check(image!=null and not image.is_empty(),"asset present: "+asset)
	for mission in model.content["missions"]:
		check(not model.definition("maps",mission["map"]).is_empty(),"map reference")
		for wave in mission["waves"]:
			for enemy in wave:
				check(not model.definition("enemies",enemy).is_empty(),"enemy reference")
	check(not model.start_mission("storm-3"),"mission prerequisite")
	check(not model.select_team(["io","io"]),"duplicate party")
	check(not model.select_team(["io","brasa","luma"]),"initial capacity")
	check(model.start_mission("scrap-1"),"start first mission")
	check(not model.train("io"),"training blocked in combat")
	check(not model.select_team(["luma"]),"party locked in combat")
	model.toggle_expedition_pause()
	var before:=JSON.stringify(model.state["active"])
	model.tick(1)
	check(before==JSON.stringify(model.state["active"]),"paused battle unchanged")
	model.toggle_expedition_pause()
	check(finish(model)=="victory","starter victory")
	check(model.collect(),"collect rewards")
	check(not model.collect(),"cannot collect twice")
	check(model.state["materials"]["scrap"]==38,"first reward amount")
	check(model.equip("io","lens"),"equip earned relic")
	check(not model.equip("brasa","lens"),"unique relic ownership")
	check(model.start_mission("scrap-1"),"repeat mission")
	check(finish(model)=="victory","repeat victory")
	model.collect()
	check(model.state["inventory"].count("lens")==1,"no duplicate relic")
	var resources:=JSON.stringify(model.state["materials"])
	model.start_mission("scrap-2")
	check(model.retreat(),"retreat")
	model.collect()
	check(resources==JSON.stringify(model.state["materials"]),"retreat no resources")
	check(model.manual_milestone("Entrega de exemplo"),"manual milestone")
	check(model.resolve_milestone("manual-1",true),"accept milestone")
	check(not model.resolve_milestone("manual-1",true),"milestone dedup")
	check(model.state["memories"]==1 and resources==JSON.stringify(model.state["materials"]),"milestones only cosmetic")
	check(model.place_building("core",3) and model.state["layout"][3]=="core","swap station sockets")
	check(not model.place_building("core",4),"socket boundary")
	check(model.bind_memory("core","manual-1"),"attach accepted memory")
	check(not model.bind_memory("core","missing"),"unaccepted memory not bindable")
	model.manual_milestone("Parte A")
	model.manual_milestone("Parte B")
	check(model.combine_milestones("Entrega conjunta"),"combine pending milestones")
	check(model.state["memories"]==2 and model.state["pending_milestones"].is_empty(),"bundle awards one memory")
	check(not model.offer_milestone("manual-2","Parte A"),"bundle retains original dedup keys")
	check(model.build("core") and model.capacity()==3,"unlock third party slot")
	check(model.select_team(["io","brasa","luma"]),"full party")
	# Actual progression: spend only earned resources, retry with training.
	var attempts:=0
	for mission in model.content["missions"]:
		var won:=false
		for retry in range(30):
			attempts+=1
			model.start_mission(mission["id"])
			var outcome:=finish(model)
			model.collect()
			if outcome=="victory":
				won=true
				break
			model.start_mission("scrap-2")
			finish(model)
			model.collect()
			for id in ["io","brasa","luma"]:
				model.train(id)
			for id in ["workshop","greenhouse","core"]:
				model.build(id)
		check(won,"campaign completable: "+mission["id"])
		for id in ["io","brasa","luma"]:
			model.train(id)
		for id in ["workshop","greenhouse"]:
			model.build(id)
	print("Campaign attempts: ",attempts,"; final materials: ",model.state["materials"])
	check(model.valid_state(model.state),"valid generated state")
	var broken: Dictionary=model.state.duplicate(true)
	broken["materials"]["scrap"]=-1
	check(not model.valid_state(broken),"reject negative currency")
	broken=model.state.duplicate(true)
	broken["crew"]["io"]["level"]={}
	check(not model.valid_state(broken),"reject malformed level")
	broken=model.state.duplicate(true)
	broken["team"]=["unknown"]
	check(not model.valid_state(broken),"reject missing crew")
	broken=model.state.duplicate(true)
	broken["pending_milestones"]=[1]
	check(not model.valid_state(broken),"reject malformed journal entry")
	broken=model.state.duplicate(true)
	broken["buildings"]["core"]=99
	check(not model.valid_state(broken),"reject out of range building")
	# Combat boundaries, recovery and deterministic repeatability.
	var trial:=Model.new()
	trial.initialize("")
	trial.start_mission("scrap-1")
	var party: Array=trial.state["active"]["allies"]
	party[0]["shield"]=20
	var hp:=int(party[0]["hp"])
	Model.Battle.hurt(party[0],10)
	check(int(party[0]["hp"])==hp and int(party[0]["shield"])<20,"shield absorbs damage")
	for member in party:
		member["hp"]=0
	trial.state["active"]["phase"]="battle"
	check(finish(trial)=="defeat","dead party loses after death animation settles")
	trial.collect()
	check(trial.state["materials"]["scrap"]==20,"defeat awards nothing")
	trial.start_mission("scrap-1")
	trial.tick(86400)
	check(trial.state["active"]["ticks"]<=1 and float(trial.state["active"]["timeline"]["clock"])<=.25 and trial.state["active"]["round"]==0,"no offline catchup")
	broken=trial.state.duplicate(true)
	broken["active"]["wave"]=9
	check(not model.valid_state(broken),"reject invalid saved wave")
	broken=trial.state.duplicate(true)
	broken["active"].erase("phase")
	check(not model.valid_state(broken),"reject partial active battle")
	broken=trial.state.duplicate(true)
	broken["active"]["allies"][0]["max_hp"]=0
	check(not model.valid_state(broken),"reject invalid health")
	# Thousands of synthetic combat steps, bounded log and no native application.
	var simulated_ticks:=0
	for iteration in range(250):
		var simulated:=Model.new()
		simulated.initialize("")
		simulated.start_mission("scrap-1")
		var outcome:=finish(simulated)
		simulated_ticks+=int(simulated.state["active"]["ticks"])
		check(outcome=="victory" and simulated.state["active"]["log"].size()<=30,"stable combat replay %d" % iteration)
	print("Synthetic combat steps: ",simulated_ticks)
	# Save tests stay inside project scratch, never user://.
	var path: String="res://../tests/scratch/save-"+str(Time.get_ticks_usec())+".json"
	check(Store.save_state(path,model.state),"initial save")
	model.state["memories"]=2
	check(Store.save_state(path,model.state),"atomic replacement")
	check(Store.load_state(path)["state"]["memories"]==2,"roundtrip")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(Store.load_state(path).get("source")=="backup","backup recovery")
	file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string('{"schema":99}')
	file.close()
	check(Store.load_state(path).get("read_only",false),"future save protected")
	check(not Store.save_state(path,model.state),"future not overwritten")
	file=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema":1,"state":model.state}))
	file.close()
	check(Store.load_state(path).get("migrated",false),"v1 migration")
	model.start_mission("storm-3")
	model.tick(1)
	check(Store.save_state(path,model.state),"save active battle")
	var restored:=Model.new()
	restored.initialize(path)
	check(not restored.read_only and restored.state["active"]["mission_id"]=="storm-3","restore expedition")
	check(finish(restored)==finish(model),"resumed battle deterministic")
	var diagnostic_path: String=path+".diagnostic.json"
	model.manual_milestone("PRIVATE TITLE")
	check(model.export_diagnostic(diagnostic_path),"explicit diagnostic export")
	var report: String=FileAccess.get_file_as_string(diagnostic_path)
	check(not "PRIVATE TITLE" in report and not "sessionId" in report and not "turnId" in report,"diagnostic excludes personal text and identifiers")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(diagnostic_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path+".bak"))
	print("Gameplay: %d checks, %d failures" % [checks,failures])
	quit(0 if failures==0 else 1)
