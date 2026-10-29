extends SceneTree
const Model=preload("res://gameplay/model.gd")
const Forge=preload("res://gameplay/forge.gd")
const Journey=preload("res://gameplay/agent_journey.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:
	for path in ["res://app.gd","res://ui/hud_shell.gd"]:
		var code=load(path);check(code!=null and code.can_instantiate(),"compile "+path)
	var model:=Model.new();model.initialize("")
	var attack: int=model.team_stats()[0]["attack"]
	check(Forge.upgrade(model,"io"),"forge upgrade")
	check(model.team_stats()[0]["attack"]==attack+2,"forge adds two attack")
	check(model.state["materials"]["scrap"]==12,"forge exact cost")
	check(not Forge.upgrade(model,"io"),"forge cannot overspend")
	check(model.valid_state(model.state),"valid forge save")
	var bad: Dictionary=model.state.duplicate(true);bad["crew"]["io"]["forge"]=6
	check(not model.valid_state(bad),"forge cap save validation")
	model.start_mission("scrap-1")
	check(not Forge.upgrade(model,"io"),"forge blocked during combat")
	var journey:=Journey.new()
	model.state["session_bindings"]={"io":"a"}
	var session: Dictionary={"sessionId":"a","state":"working","workUnits":100,"totalTokens":10000,"usageKnown":true,"turnId":"one"}
	journey.update([session],model.state["session_bindings"])
	check(journey.credit==0,"no historical burst on connection")
	journey.advance(model,.1)
	check(not model.state["active"].has("timeline"),"idle without new work")
	session["workUnits"]=101;journey.update([session],model.state["session_bindings"])
	check(journey.credit==2,"work pulse grants two seconds")
	journey.advance(model,.1)
	check(model.state["active"]["timeline"]["clock"]>.09,"work advances combat")
	session["state"]="waiting";journey.update([session],model.state["session_bindings"])
	var before: float=model.state["active"]["timeline"]["clock"]
	journey.advance(model,1)
	check(model.state["active"]["timeline"]["clock"]==before,"approval freezes combat")
	session["state"]="working";session["totalTokens"]=999999;journey.update([session],model.state["session_bindings"])
	check(journey.credit<3,"token boost capped independent of volume")
	var credit:=journey.credit;journey.update([session],model.state["session_bindings"])
	check(journey.credit==credit,"same snapshot gives no repeated pulse")
	model.toggle_expedition_pause();journey.advance(model,.1)
	check(model.state["active"]["timeline"]["clock"]==before,"manual pause")
	model.toggle_expedition_pause();model.state["expedition_mode"]="practice";journey.update([],{});journey.advance(model,.1)
	check(model.state["active"]["timeline"]["clock"]>before,"free mode without agents")
	var smith:=Model.new();smith.initialize("")
	check(not Forge.craft(smith,"lens"),"cannot craft locked relic")
	smith.state["completed"]["scrap-1"]=1;smith.state["materials"]["scrap"]=100
	check(Forge.craft(smith,"lens"),"craft unlocked relic")
	check(smith.state["materials"]["scrap"]==76 and smith.state["materials"]["cores"]==0,"craft charges exact cost")
	check(not Forge.craft(smith,"lens"),"cannot duplicate unique relic")
	smith.equip("io","lens")
	check(not Forge.recycle(smith,"lens"),"cannot recycle equipped relic")
	smith.equip("io","")
	check(Forge.recycle(smith,"lens") and smith.state["materials"]["scrap"]==80,"recycle returns scrap")
	check(not Forge.recycle(smith,"lens"),"cannot recycle twice")
	var migrated:=smith.merge_defaults({})
	check(migrated["crew"]["io"]["forge"]==0 and migrated["expedition_mode"]=="agents","older saves gain safe defaults")
	print("HUD/game: %d checks, %d failures. No UI instantiated." % [checks,failures]);quit(1 if failures else 0)
