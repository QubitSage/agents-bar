extends SceneTree
var failures:=0
var checks:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:
	# The runner copies the project and redirects APPDATA before starting Godot.
	if DisplayServer.get_name()!="headless" or not OS.get_user_data_dir().replace("\\","/").begins_with(OS.get_environment("AGENTS_BAR_TEST_ROOT").replace("\\","/")+"/"):
		printerr("FAIL: isolated headless test required");quit(1);return
	call_deferred("run")
func run() -> void:
	var app=load("res://main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	check(app.collector_pid==0 and app.state_path.is_empty(),"no collector or session file")
	check(app.hud!=null,"HUD instantiated")
	if app.hud==null: quit(1);return
	var hud=app.hud
	check(hud.size==root.get_visible_rect().size and hud.size.x>0 and hud.size.y>0,"HUD fills viewport")
	check(hud.mini.is_visible_in_tree() and not hud.full.visible,"compact HUD visible")
	root.size=Vector2i(984,760)
	root.content_scale_size=Vector2i(984,760)
	hud.set_compact(false)
	await process_frame
	check(hud.size==Vector2(984,760),"HUD follows viewport resize")
	for panel in ["guide","heroes","inventory","forge","map","station","agents","journal","settings","pro"]:
		hud.open_panel(panel)
		await process_frame
		await process_frame
		check(hud.full.is_visible_in_tree() and hud.menu.get_child_count()>0,"panel built: "+panel)
	hud.set_compact(true)
	await process_frame
	check(hud.mini.is_visible_in_tree(),"return to compact")
	app.queue_free()
	await process_frame
	print("Startup UI: %d checks, %d failures; isolated headless only."%[checks,failures])
	quit(1 if failures else 0)
