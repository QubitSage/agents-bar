extends Node2D

const View = preload("res://presentation.gd")
const Campaign = preload("res://gameplay/model.gd")
const GameWindow = preload("res://ui/game_window.gd")
const Sound = preload("res://audio/sound.gd")
const Library = preload("res://gameplay/visual_library.gd")
var art=Library.new()
var campaign=Campaign.new()
var game_window: Window
var sound_player: AudioStreamPlayer
var connection_started_at:=0.0
const NAMES := ["Cavaleiro","Brasa","Luma"]
const ASSETS := ["io-explorer","brasa-mechanic","luma-botanist"]
const INK := Color("111626")
const CREAM := Color("e9eff8")
var sheets: Array[Texture2D] = []
var clips: Array[Dictionary] = []
var platform: Texture2D
var sessions: Array = []
var animation_names := ["idle","idle","idle"]
var animation_times := [0.0,0.0,0.0]
var runtime := ""
var state_path := ""
var scale_factor := 2
var selected_monitor := 0
var paused := false
var demo := false
var compact := true
var clock := 0.0
var poll_elapsed := 0.0
var layout_elapsed := 0.0
var expanded_controls: Array[Control] = []
var compact_controls: Array[Control] = []
var hud_label: Label
var compact_title: Label
var compact_status: Label
var pause_button: Button
var scale_button: Button
var monitor_button: Button
var demo_button: Button

func _ready() -> void:
	connection_started_at=Time.get_unix_time_from_system()
	for asset in ASSETS:
		sheets.append(ImageTexture.create_from_image(Image.load_from_file("res://assets/%s-sheet.png" % asset)))
		clips.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s.json" % asset))["animations"])
	platform=ImageTexture.create_from_image(Image.load_from_file("res://assets/tile-platform.png"))
	runtime=ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(runtime)
	# Only explicitly supplied state files are read, never auto-discovered sessions.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--state-file="):
			state_path=argument.trim_prefix("--state-file=")
		elif argument=="--demo":
			demo=true
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	get_viewport().transparent_bg=true
	get_viewport().gui_embed_subwindows=false
	get_window().title="Agents Bar"
	if DisplayServer.get_name()!="headless":
		DisplayServer.set_icon(Image.load_from_file("res://assets/agents-bar-icon.png"))
	get_window().unfocusable=true
	get_window().close_requested.connect(_quit)
	_make_hud()
	campaign.initialize()
	campaign.changed.connect(_poll)
	campaign.cue.connect(func(kind):
		if campaign.state["sound"]:
			if not is_instance_valid(sound_player):
				sound_player=Sound.new()
				add_child(sound_player)
			sound_player.play_cue(kind)
	)
	_load_preferences()
	_apply_layout()
	_poll()

func _button(text: String, rect: Rect2, action: Callable, small: bool=false) -> Button:
	var button:=Button.new()
	button.text=text
	button.position=rect.position
	button.size=rect.size
	button.add_theme_font_size_override("font_size",8)
	button.add_theme_color_override("font_color",CREAM)
	button.focus_mode=Control.FOCUS_NONE
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("254854")
	style.border_color=Color("75989b")
	style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal",style)
	var hover: StyleBoxFlat=style.duplicate()
	hover.bg_color=Color("3e6b70")
	button.add_theme_stylebox_override("hover",hover)
	button.pressed.connect(action)
	add_child(button)
	if small:
		compact_controls.append(button)
	else:
		expanded_controls.append(button)
	return button

func _label(position: Vector2, font_size: int) -> Label:
	var control:=Label.new()
	control.position=position
	control.add_theme_font_size_override("font_size",font_size)
	control.add_theme_color_override("font_color",CREAM)
	control.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(control)
	return control

func _make_hud() -> void:
	hud_label=_label(Vector2(8,97),9)
	expanded_controls.append(hud_label)
	pause_button=_button("Pausar",Rect2(4,112,40,17),func():
		paused=not paused
		pause_button.text="Retomar" if paused else "Pausar"
		_update_frame_limit()
	)
	scale_button=_button("2x",Rect2(48,112,42,17),func():
		scale_factor=3 if scale_factor==2 else 2
		_apply_layout()
		_save_preferences()
	)
	monitor_button=_button("Tela 1",Rect2(94,112,44,17),func():
		selected_monitor=(selected_monitor+1)%maxi(DisplayServer.get_screen_count(),1)
		_dock()
		_save_preferences()
	)
	_button("Jogar",Rect2(142,112,44,17),_open_game)
	var minimize:=_button("Recolher",Rect2(190,112,62,17),func(): _set_compact(true))
	minimize.tooltip_text="Deixar Agents Bar no canto"
	_button("Sair",Rect2(256,112,58,17),_quit)
	compact_title=_label(Vector2(46,8),8)
	compact_status=_label(Vector2(46,24),8)
	compact_controls.append(compact_title)
	compact_controls.append(compact_status)
	var expand:=_button("+",Rect2(132,5,23,17),func(): _set_compact(false),true)
	expand.tooltip_text="Expandir Agents Bar"
	var play:=_button(">",Rect2(132,27,23,16),_open_game,true)
	play.tooltip_text="Abrir missões, equipe e estação"

func _open_game() -> void:
	if not is_instance_valid(game_window):
		game_window=GameWindow.new()
		game_window.model=campaign
		game_window.compact_requested.connect(func(): _set_compact(true))
		add_child(game_window)
		game_window.visibility_changed.connect(_update_frame_limit)
	game_window.popup_centered()
	game_window.grab_focus()
	_update_frame_limit()

func _set_compact(value: bool) -> void:
	compact=value
	_apply_layout()
	_save_preferences()

func _apply_layout() -> void:
	get_window().content_scale_size=View.canvas_size(compact)
	for control in expanded_controls:
		control.visible=not compact
	for control in compact_controls:
		control.visible=compact
	_update_frame_limit()
	_dock()
	queue_redraw()

func _update_frame_limit() -> void:
	if is_instance_valid(game_window) and game_window.visible:
		Engine.max_fps=30
	else:
		Engine.max_fps=5 if paused else (15 if compact else 30)

func _dock() -> void:
	if DisplayServer.get_name()=="headless":
		return
	selected_monitor=clampi(selected_monitor,0,maxi(DisplayServer.get_screen_count()-1,0))
	var target: Rect2i=View.dock_rect(DisplayServer.screen_get_usable_rect(selected_monitor),scale_factor,compact)
	get_window().size=target.size
	get_window().position=target.position
	scale_button.text="%dx" % scale_factor
	monitor_button.text="Tela %d" % (selected_monitor+1)
	_update_region()

func _update_region() -> void:
	var polygon:=PackedVector2Array()
	if compact:
		polygon=PackedVector2Array([Vector2(0,0),Vector2(160,0),Vector2(160,48),Vector2(0,48)])
	else:
		polygon.append(Vector2(0,72))
		for x in [16,136,256]:
			polygon.append(Vector2(x,72))
			polygon.append(Vector2(x,16))
			polygon.append(Vector2(x+48,16))
			polygon.append(Vector2(x+48,72))
		polygon.append(Vector2(320,72))
		polygon.append(Vector2(320,132))
		polygon.append(Vector2(0,132))
	for i in range(polygon.size()):
		polygon[i]*=scale_factor
	get_window().mouse_passthrough_polygon=polygon

func _poll() -> void:
	var now:=Time.get_unix_time_from_system()
	sessions=[]
	if demo:
		var states:=["working","working","waiting","completed","failed","cancelled","idle"]
		for i in range(3):
			sessions.append({"sessionId":"demo-%d" % i,"state":states[(int(clock/4.0)+i)%states.size()],"activity":"tool" if i%2==0 else "thinking","project":["Oficina","Exploração","Estufa"][i],"characterIndex":i,"lifecycleAt":now})
	elif not state_path.is_empty() and FileAccess.file_exists(state_path):
		var snapshot_file:=FileAccess.open(state_path,FileAccess.READ)
		if snapshot_file and snapshot_file.get_length()<=524288:
			var parser:=JSON.new()
			if parser.parse(snapshot_file.get_as_text())==OK and parser.data is Dictionary:
				sessions=View.normalize(parser.data,now)
	while sessions.size()<3:
		sessions.append(View.empty_session(sessions.size()))
	if not demo and not state_path.is_empty():
		for session in sessions:
			if session.get("state")=="completed" and float(session.get("lifecycleAt",0))>=connection_started_at and not str(session.get("turnId","")).is_empty():
				var milestone_id: String="agent:"+str(session.get("provider","codex"))+":"+str(session["sessionId"])+":"+str(session["turnId"])
				campaign.offer_milestone.call_deferred(milestone_id,"Entrega concluída · "+str(session["project"]))
	var overview: Dictionary=View.summary(sessions)
	var prefix: String="DEMO" if demo else ("AO VIVO" if not state_path.is_empty() else "SEM CONEXÃO")
	hud_label.text="Agents Bar | %s | %s" % [prefix,overview["text"]]
	compact_title.text="Agents Bar"+(" · demo" if demo else "")
	compact_status.text=overview["text"]
	var expedition: Dictionary=campaign.state.get("active",{})
	if not expedition.is_empty():
		var phases: Dictionary={"travel":"Em expedição","rest":"Reparando","battle":"Em batalha","result":"Resultado pronto"}
		compact_status.text="Missão pausada" if expedition["paused"] else phases.get(expedition["phase"],"Em expedição")
		hud_label.text="Agents Bar | %s | %s" % [prefix,compact_status.text]
	for i in range(3):
		var next: String=View.animation(sessions[i],now,demo)
		if not demo and state_path.is_empty() and not expedition.is_empty():
			next="celebrate" if expedition.get("result")=="victory" else ("walk" if expedition["phase"]=="travel" else "work")
			if expedition["paused"] or expedition.get("result") in ["defeat","retreated"]:
				next="idle"
		if next!=animation_names[i]:
			animation_names[i]=next
			animation_times[i]=0.0

func _process(delta: float) -> void:
	campaign.tick(delta)
	if not paused and not campaign.state.get("reduced_motion",false):
		clock+=delta
		for i in range(3):
			animation_times[i]+=delta
	poll_elapsed+=delta
	layout_elapsed+=delta
	if poll_elapsed>=0.5:
		poll_elapsed=0.0
		_poll()
	if layout_elapsed>=2.0:
		layout_elapsed=0.0
		_dock()
	queue_redraw()

func _draw_character(index: int, position: Vector2) -> void:
	var member: Dictionary=campaign.definition("characters",["io","brasa","luma"][index])
	if not member.is_empty():
		var animation: String={"work":"attack","celebrate":"victory"}.get(animation_names[index],animation_names[index])
		var meta:=Library.clip(member,animation)
		if not meta.is_empty():
			var frame:=Library.frame(meta,float(animation_times[index]),true)
			var pivot: Dictionary=meta.get("pivot",{"x":float(meta["width"])/2,"y":float(meta["height"])*.94})
			draw_set_transform(position+Vector2(24,44),0,Vector2(.42,.42))
			draw_texture_rect_region(art.texture(meta),Rect2(-float(pivot["x"]),-float(pivot["y"]),meta["width"],meta["height"]),Library.region(meta,frame))
			draw_set_transform(Vector2.ZERO)
			return
	if clips.size()<=index:
		return
	var frames: Array=clips[index][animation_names[index]]["frames"]
	var total:=0.0
	for frame in frames:
		total+=float(frame["duration"])/1000.0
	var remaining:=fmod(float(animation_times[index]),total)
	var current: Dictionary=frames[0]
	for frame in frames:
		current=frame
		remaining-=float(frame["duration"])/1000.0
		if remaining<0:
			break
	draw_texture_rect_region(sheets[index],Rect2(position,Vector2(48,48)),Rect2(current["x"],current["y"],48,48))

func _draw() -> void:
	if sessions.is_empty():
		return
	var overview: Dictionary=View.summary(sessions)
	var signal_color:=Color("a7b874") if overview["state"]=="working" else Color("f0b65a")
	if overview["state"] in ["disconnected","unknown","failed","cancelled"]:
		signal_color=Color("b96843")
	if compact:
		draw_rect(Rect2(0,0,160,48),INK)
		draw_rect(Rect2(0,0,160,48),Color("75989b"),false,1)
		draw_rect(Rect2(0,0,3,48),signal_color)
		_draw_character(int(overview["characterIndex"]),Vector2(0,0))
	else:
		for i in range(10):
			draw_texture(platform,Vector2(i*32,72))
		draw_rect(Rect2(0,96,320,36),INK)
		draw_line(Vector2(0,96),Vector2(320,96),Color("75989b"))
		for i in range(3):
			var x:=16+i*120
			_draw_character(i,Vector2(x,28))
			draw_string(ThemeDB.fallback_font,Vector2(x+3,24),NAMES[i],HORIZONTAL_ALIGNMENT_LEFT,48,7,CREAM)
			draw_circle(Vector2(x+24,80),2,Color("a7b874") if sessions[i]["state"]=="working" else Color("f0b65a"))

func _load_preferences() -> void:
	var path:=runtime.path_join("preferences.json")
	if FileAccess.file_exists(path):
		var data=JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary:
			scale_factor=clampi(int(data.get("scale",2)),2,3)
			selected_monitor=int(data.get("monitor",0))
			compact=bool(data.get("compact",true))

func _save_preferences() -> void:
	var file:=FileAccess.open(runtime.path_join("preferences.json"),FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"scale":scale_factor,"monitor":selected_monitor,"compact":compact}))

func _quit() -> void:
	if not campaign.read_only and not campaign.persist():
		_open_game()
		return
	_save_preferences()
	get_tree().quit()
