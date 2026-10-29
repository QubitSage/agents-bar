extends SceneTree

func _initialize() -> void:
	for path in ["res://app.gd","res://ui/hud_shell.gd","res://main.gd","res://ui/game_window.gd","res://ui/battle_canvas.gd","res://audio/sound.gd"]:
		var script=load(path)
		if script==null or not script.can_instantiate():
			printerr("Package script failed: "+path)
			quit(1)
			return
	var model=load("res://gameplay/model.gd").new()
	model.initialize("")
	for group in ["characters","maps","enemies"]:
		for item in model.content[group]:
			var asset: String=item["asset"]+("-sheet" if group=="characters" else "")
			var image:=Image.load_from_file("res://assets/"+asset+".png")
			if image==null or image.is_empty():
				printerr("Package missing asset: "+asset)
				quit(1)
				return
	model.start_mission("scrap-1")
	var library=load("res://gameplay/visual_library.gd")
	var count:=0
	for meta in library.catalog().values():
		var image:=Image.load_from_file(library.ROOT+meta["sheet"])
		if image==null or image.is_empty():
			printerr("Package missing v04 asset: "+meta["id"])
			quit(1)
			return
		count+=1
	# Full animated actions take longer than the old one-round-per-tick fixture.
	for tick in range(10000):
		model.tick(.05)
		if model.state["active"]["phase"]=="result":
			break
	if model.state["active"].get("result")!="victory" or not model.collect():
		printerr("Package campaign failed")
		quit(1)
		return
	var boss_model=load("res://gameplay/model.gd").new()
	boss_model.initialize("")
	if not boss_model.prepare_azhor_demo():
		printerr("Package AZHOR demo initialization failed");quit(1);return
	var ultimate_seen:=false
	for tick in range(10000):
		boss_model.tick(.1)
		if boss_model.state["active"].get("timeline",{}).get("action",{}).get("clip")=="ultimate": ultimate_seen=true
		if boss_model.state["active"]["phase"]=="result": break
	if boss_model.state["active"].get("result")!="victory" or not ultimate_seen:
		printerr("Package AZHOR demo failed");quit(1);return
	print("Portable package: scripts compiled, legacy references and %d v04 assets loaded; first mission and AZHOR completed in memory, ultimate observed. No application instantiated." % count)
	quit(0)
