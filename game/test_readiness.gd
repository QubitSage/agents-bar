extends SceneTree
const Model=preload("res://gameplay/model.gd")
const Guide=preload("res://gameplay/tutorial.gd")
const Clock=preload("res://gameplay/session_clock.gd")
const Store=preload("res://gameplay/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+label)
func finish(model) -> void:
	for i in range(5000):
		model.tick(.25)
		if model.state.active.get("phase")=="result": return
func _initialize() -> void:
	var m:=Model.new();m.initialize("")
	check(Guide.describe(m).action=="start","first run offers real first mission")
	check(Guide.act(m,"start") and m.state.expedition_mode=="practice","explicit guide action starts free mode")
	check(not Guide.act(m,"start"),"cannot duplicate active mission")
	check(Guide.describe(m).action=="map","guide follows expedition")
	finish(m);check(Guide.describe(m).action=="collect","result requires explicit collection")
	check(Guide.act(m,"collect") and not Guide.act(m,"collect"),"guide collects only once")
	check(Guide.describe(m).action=="equip","first relic available")
	check(Guide.act(m,"equip") and m.state.crew.io.relic=="lens","guide equips real relic")
	check(Guide.describe(m).action=="finish" and Guide.act(m,"finish") and m.state.onboarded,"guide completion persists")
	m.read_only=true;check(Guide.describe(m).action=="support" and not Guide.act(m,"start"),"read only recovery route")
	m.read_only=false;m.set_option("always_on_top",false);check(not m.state.always_on_top,"topmost optional")
	for dt in [0.0,.033,.25,1.0,5.0]:check(not Clock.interrupted(dt),"normal time")
	for dt in [-1.0,6.0,86400.0,INF,NAN]:check(Clock.interrupted(dt),"interruption detection")
	var legacy: Dictionary=m.state.duplicate(true);legacy.erase("claimed_through");legacy.erase("always_on_top")
	for n in range(1,251):legacy.claimed_runs["run-%d"%n]=true
	var migrated:=m.merge_defaults(legacy)
	check(migrated.claimed_through==250 and migrated.claimed_runs.size()==100 and migrated.always_on_top,"bounded legacy migration")
	var bad: Dictionary=m.state.duplicate(true);bad.claimed_through={};check(not m.valid_state(bad),"malformed watermark rejected safely")
	m.state.next_run=251;m.state.claimed_through=250;m.start_mission("scrap-1");finish(m)
	var old_run: Dictionary=m.state.active.duplicate(true);check(m.collect(),"new run collect")
	m.state.active=old_run;m.state.claimed_runs.clear();check(not m.collect(),"watermark prevents replay even after pruning")
	m.state.active={}
	var path: String="res://../tests/scratch/recovery-099-"+str(Time.get_ticks_usec())+".json"
	check(Store.save_state(path,m.state),"write original fixture")
	m.state.memories=7;check(Store.save_state(path,m.state),"write newer fixture and backup")
	var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string("corrupt");f.close()
	# Backup can be used explicitly for a semantically invalid but checksummed primary.
	var invalid: Dictionary=m.state.duplicate(true);invalid.materials.scrap=-1
	check(Store.save_state(path,invalid),"logical corruption fixture")
	var repaired:=Model.new();repaired.initialize(path)
	check(repaired.read_only and repaired.can_recover_backup(),"offer recovery only with valid backup")
	check(repaired.recover_backup() and not repaired.read_only and repaired.state.memories==0,"recover last valid backup")
	check(Store.decode(path).ok,"restored primary valid")
	f=FileAccess.open(path,FileAccess.WRITE);f.store_string('{"schema":99}');f.close()
	repaired=Model.new();repaired.initialize(path);check(not repaired.can_recover_backup(),"future version never downgraded")
	var folder:=DirAccess.open(ProjectSettings.globalize_path("res://../tests/scratch"))
	for name in folder.get_files():
		if name.begins_with(path.get_file()):folder.remove(name)
	print("Readiness 0.9.9: %d checks, %d failures; no UI."%[checks,failures]);quit(1 if failures else 0)
