extends SceneTree
const App=preload("res://app.gd")
const Model=preload("res://gameplay/model.gd")
const Journey=preload("res://gameplay/agent_journey.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:
	var profiles=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	for profile in profiles:
		var m:=Model.new();m.initialize("");m.start_mission("scrap-1")
		var journey:=Journey.new()
		var first:=App.normalize_tracking(profile.first,100)
		var second:=App.normalize_tracking(profile.second,102)
		check(first.size()==1 and second.size()==1,profile.provider+" reaches game")
		m.state.session_bindings={"io":first[0].sessionId}
		journey.update(first,m.journey_bindings());check(journey.credit==0,"first reading is baseline")
		journey.update(second,m.journey_bindings());check(journey.credit>0 and journey.credit<=12,"new evidence earns bounded time")
		var before:=float(m.state.active.get("timeline",{}).get("clock",0));journey.advance(m,.1)
		check(float(m.state.active.timeline.clock)>before,"model advances without UI")
		before=float(m.state.active.timeline.clock)
		journey.update(App.normalize_tracking(profile.second,110),m.journey_bindings());journey.advance(m,.1)
		check(float(m.state.active.timeline.clock)==before,"stale data cannot advance")
		journey.update(second,{});check(journey.credit==0,"unlink drops credit")
		journey.update(second,m.journey_bindings());check(journey.credit==0,"rebind does not replay old rewards")
	print("Tracking pipeline: %d checks, %d failures. Synthetic provider snapshots; no application instantiated."%[checks,failures]);quit(1 if failures else 0)
