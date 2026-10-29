extends SceneTree
## Resources and in-memory models only. Never instantiate the application/UI.
const Model=preload("res://gameplay/model.gd")
const Timeline=preload("res://gameplay/forge_timeline.gd")
const Art=preload("res://gameplay/visual_library.gd")
var checks:=0
var failures:=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: "+message)

func fixture():
	var model:=Model.new()
	model.initialize("")
	model.start_mission("scrap-1")
	return model

func finish(model) -> String:
	for step in range(10000):
		model.tick(.05)
		if model.state["active"]["phase"]=="result": return model.state["active"]["result"]
	return "timeout"

func next_action(model) -> Dictionary:
	for step in range(200):
		model.tick(.02)
		var action: Dictionary=model.state["active"].get("timeline",{}).get("action",{})
		if not action.is_empty(): return action
	return {}

func saved_resume(model,label_text: String) -> void:
	var path: String=ProjectSettings.globalize_path("res://../tests/scratch/forge-"+label_text+".json")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	model.save_path=path
	check(model.persist(),"save "+label_text)
	var resumed:=Model.new()
	resumed.initialize(path)
	check(not resumed.read_only,"reload "+label_text)
	check(resumed.state["active"]["timeline"]["action"]["applied"]==model.state["active"]["timeline"]["action"]["applied"],"hit marker restored "+label_text)
	# Do not let the two memory simulations write over each other's fixture.
	model.save_path="";resumed.save_path=""
	check(finish(model)==finish(resumed),"same outcome after reload "+label_text)
	for i in range(model.state["active"]["allies"].size()):
		check(model.state["active"]["allies"][i]["hp"]==resumed.state["active"]["allies"][i]["hp"],"same remaining life "+label_text)
	check(model.collect() and resumed.collect(),"collect both simulations "+label_text)
	check(model.state["materials"]==resumed.state["materials"],"same rewards "+label_text)
	for id in model.state["crew"]:
		check(int(model.state["crew"][id]["xp"])==int(resumed.state["crew"][id]["xp"]),"same experience "+label_text+" "+id)
	resumed.save_path=path
	check(resumed.persist(),"persist collected result "+label_text)
	var collected:=Model.new()
	collected.initialize(path)
	check(not collected.read_only and collected.state["active"].is_empty() and not collected.collect(),"reload cannot claim twice "+label_text)
	for resource in resumed.state["materials"]:
		check(int(collected.state["materials"][resource])==int(resumed.state["materials"][resource]),"collected resources retained "+label_text+" "+resource)
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)

func _initialize() -> void:
	for path in ["res://app.gd","res://ui/hud_shell.gd","res://main.gd","res://ui/game_window.gd","res://ui/mission_canvas.gd","res://ui/station_visual.gd"]:
		var script=load(path)
		check(script!=null and script.can_instantiate(),"compile only: "+path)
	for id in Art.catalog():
		var meta: Dictionary=Art.catalog()[id]
		var image:=Image.load_from_file(Art.ROOT+meta["sheet"])
		check(image!=null and not image.is_empty(),"runtime PNG "+id)
		if not image: continue
		check(image.get_width()==int(meta["width"])*int(meta["columns"]) and image.get_height()==int(meta["height"])*int(meta["rows"]),"sheet dimensions "+id)
		var last:=Art.region(meta,int(meta["frames"])-1)
		check(last.position.x>=0 and last.position.y>=0 and last.end.x<=image.get_width() and last.end.y<=image.get_height(),"last frame inside PNG "+id)
	for actor in ["io","brasa","scrap-drone","scrap-crab","scrap-boss"]:
		for state in ["idle","walk","attack","special","defense","hurt","death","victory"]:
			var clip:=Art.clip({"id":actor},state)
			check(clip["state"]==state or (actor=="scrap-boss" and state=="victory" and clip["state"]=="idle"),"animation "+actor+" "+state)
	var death:=Art.clip({"id":"scrap-boss"},"death")
	check(Art.frame(death,999,false)==int(death["frames"])-1,"death holds last pose")
	check(Art.frame(death,float(death["durations"][0])/1000+.001,false)==1,"frame duration boundary")
	# Exercise Resource property assignments without creating a Window or Control.
	var style:=StyleBoxTexture.new()
	style.texture_margin_left=10;style.texture_margin_right=10
	style.texture_margin_top=10;style.texture_margin_bottom=10
	check(style.texture_margin_left==10,"pixel theme margins supported")
	var model=fixture()
	var action:=next_action(model)
	check(not action.is_empty(),"first action begins")
	var run: Dictionary=model.state["active"]
	var target: Dictionary=run[action["target_side"]][int(action["target_index"])]
	var hp_before:=int(target["hp"])
	while float(action["elapsed"])+.02<float(action["impact_at"]): model.tick(.02)
	check(int(target["hp"])==hp_before and not action["applied"],"windup has no premature damage")
	model.toggle_expedition_pause()
	var paused:=JSON.stringify(run)
	model.tick(50)
	check(JSON.stringify(run)==paused,"pause freezes clock, position, action and HP")
	model.toggle_expedition_pause()
	while not action["applied"]: model.tick(.01)
	check(int(target["hp"])<hp_before,"damage arrives at contact")
	check(absf(Timeline.position(run,action["side"],int(action["index"]))-Timeline.home(action["target_side"],int(action["target_index"])))<=Timeline.REACH+.01,"impact within reach")
	var hp_after:=int(target["hp"])
	model.tick(.01)
	check(int(target["hp"])==hp_after,"same action cannot hit twice")
	saved_resume(model,"after-hit")
	model=fixture()
	next_action(model)
	model.tick(.1)
	saved_resume(model,"windup")
	model=fixture()
	var waves: Array=[]
	var saw_defense:=false
	var saw_death:=false
	var boss_death_started: float=-1
	for step in range(10000):
		model.tick(.05)
		run=model.state["active"]
		if not run["wave"] in waves: waves.append(run["wave"])
		if run["timeline"]["action"].get("clip")=="defense": saw_defense=true
		if int(run["enemies"][0]["hp"])==0:
			saw_death=true
			check(Timeline.pose(run,"enemies",0)["clip"]=="death","dead enemy displays death")
			if int(run["wave"])==2 and boss_death_started<0: boss_death_started=float(run["timeline"]["clock"])
		if run["phase"]=="result": break
	check(run["result"]=="victory" and waves==[0,1,2],"full three-encounter mission wins")
	check(saw_defense and saw_death,"defense and death occur in actual battle")
	check(float(run["timeline"]["clock"])-boss_death_started>=Art.duration(death),"boss death completes before victory")
	check(model.collect() and model.state["active"].is_empty(),"return to station clears active mission")
	check(model.state["materials"]["cores"]==2 and model.state["crew"]["io"]["xp"]==12,"core and XP awarded")
	model=fixture()
	model.tick(1000)
	check(float(model.state["active"]["timeline"]["clock"])==.25,"no offline catch-up burst")
	var legacy: Dictionary=model.state.duplicate(true)
	legacy["active"].erase("timeline")
	check(model.valid_state(legacy),"existing save without timeline stays valid")
	var broken: Dictionary=model.state.duplicate(true)
	broken["active"]["timeline"]["action"]={"side":"missing"}
	check(not model.valid_state(broken),"malformed saved action rejected")
	for unit in model.state["active"]["allies"]: unit["hp"]=1;unit["attack"]=1;unit["armor"]=0
	check(finish(model)=="defeat","weak party reaches defeat")
	var materials: Dictionary=model.state["materials"].duplicate()
	check(model.collect() and model.state["materials"]==materials,"defeat returns without reward")
	print("First mission: %d checks, %d failures. No application/UI instantiated." % [checks,failures])
	quit(1 if failures else 0)
