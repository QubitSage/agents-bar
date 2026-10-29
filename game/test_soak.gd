extends SceneTree
const Model=preload("res://gameplay/model.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:
	var started:=Time.get_ticks_msec()
	var m:=Model.new();m.initialize("");m.state.expedition_mode="practice"
	var runs:=0
	var largest:=0
	for step in range(115200):
		if m.state.active.is_empty(): m.start_mission("scrap-1")
		m.tick(.25)
		if m.state.active.get("phase")=="result":
			check(m.state.active.result=="victory" and m.collect(),"repeatable victory collection");runs+=1
		if step%3600==0:
			check(m.valid_state(m.state),"valid long-running progress")
			check(m.state.journal.size()<=100 and m.state.claimed_runs.size()<=100,"bounded history and receipts")
			largest=maxi(largest,JSON.stringify(m.state).length())
	check(runs>100,"crosses old unbounded receipt accumulation")
	check(largest<100000,"bounded save size under long repetition")
	print("Soak: %d checks, %d failures. Eight simulated hours, %d missions, max save %d bytes, core simulation %d ms. No UI or real-time desktop benchmark."%[checks,failures,runs,largest,Time.get_ticks_msec()-started])
	quit(1 if failures else 0)
