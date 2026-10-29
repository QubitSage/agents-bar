extends Node2D
const DataPaths=preload("res://gameplay/data_paths.gd")
const Clock=preload("res://gameplay/session_clock.gd")
const Model=preload("res://gameplay/model.gd")
const Journey=preload("res://gameplay/agent_journey.gd")
const HUD=preload("res://ui/hud_shell.gd")
const View=preload("res://presentation.gd")
const WindowGeometry=preload("res://ui/window_geometry.gd")
const Layout=preload("res://ui/hud_layout.gd")
const Sound=preload("res://audio/sound.gd")
var model=Model.new()
var journey=Journey.new()
var hud
var state_path: String=""
var demo:=false
var azhor_demo:=false
var elapsed:=0.0
var poll_time:=0.0
var collector_pid:=0
var player
var api: Dictionary={}
var request: HTTPRequest
var pending_key: String=""
var geometry=WindowGeometry.new()
var geometry_clock:=0.0
var geometry_idle:=0.0

func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument=="--demo": demo=true
		if argument=="--demo-azhor": demo=true;azhor_demo=true
		if argument.begins_with("--state-file="): state_path=argument.trim_prefix("--state-file=")
	model.initialize("" if demo else "user://progress.json")
	if azhor_demo: model.prepare_azhor_demo()
	if FileAccess.file_exists("res://content/online.json"):
		var value=JSON.parse_string(FileAccess.get_file_as_string("res://content/online.json"))
		if value is Dictionary: api=value
	get_window().borderless=true;get_window().transparent=true;get_window().always_on_top=model.state["always_on_top"]
	get_window().close_requested.connect(_quit)
	_load_geometry()
	get_viewport().transparent_bg=true
	hud=HUD.new();hud.model=model;hud.journey=journey;hud.demo=demo
	hud.layout_changed.connect(_layout);hud.quit_requested.connect(_quit)
	hud.dimensions_requested.connect(_resize_window)
	hud.on_connect=_connect_collector;hud.on_disconnect=_disconnect_collector;hud.on_purchase=_purchase;hud.on_license=_activate;hud.on_claude_hooks=_claude_hooks
	add_child(hud)
	model.cue.connect(func(kind):
		if model.state["sound"]:
			if not is_instance_valid(player): player=Sound.new();add_child(player)
			player.play_cue(kind)
	)
	Engine.max_fps=30
	_poll()

func _screens() -> Array:
	var result: Array=[]
	if DisplayServer.get_name()=="headless": return result
	var primary:=DisplayServer.get_primary_screen()
	result.append(DisplayServer.screen_get_usable_rect(primary))
	for index in range(DisplayServer.get_screen_count()):
		if index!=primary: result.append(DisplayServer.screen_get_usable_rect(index))
	return result

func _window_rect() -> Rect2i:
	return Rect2i(get_window().position,get_window().size)

func _load_geometry() -> void:
	if demo or not FileAccess.file_exists("user://window.json"): return
	var file:=FileAccess.open("user://window.json",FileAccess.READ)
	if file and file.get_length()<=4096: geometry.import_data(JSON.parse_string(file.get_as_text()))

func _save_geometry() -> void:
	if demo or not geometry.pending_save: return
	var file:=FileAccess.open("user://window.json.tmp",FileAccess.WRITE)
	if not file: return
	file.store_string(JSON.stringify(geometry.export_data()));file.close()
	if DirAccess.rename_absolute("user://window.json.tmp","user://window.json")==OK: geometry.pending_save=false

func _window_scale() -> void:
	var minimum: Vector2i=Layout.MINI_MIN if hud.compact else Layout.FULL_MIN
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
	get_window().content_scale_size=minimum if get_window().size.x<minimum.x or get_window().size.y<minimum.y else Vector2i.ZERO

func _apply_rect(rect: Rect2i) -> void:
	var minimum: Vector2i=Layout.MINI_MIN if hud.compact else Layout.FULL_MIN
	get_window().min_size=Vector2i(mini(minimum.x,rect.size.x),mini(minimum.y,rect.size.y))
	get_window().size=rect.size
	get_window().position=rect.position
	_window_scale()

func _layout(compact: bool,_expanded: bool) -> void:
	if DisplayServer.get_name()=="headless": return
	var target: String="mini" if compact else "full"
	if geometry.mode==target: return
	var rect: Rect2i=geometry.change(compact,_window_rect(),_screens())
	get_window().unfocusable=false
	get_window().unresizable=false
	_apply_rect(rect)
	Engine.max_fps=15 if compact else 30

func _resize_window(dimensions: Vector2i) -> void:
	if DisplayServer.get_name()=="headless": return
	var minimum: Vector2i=Layout.MINI_MIN if hud.compact else Layout.FULL_MIN
	var rect:=Layout.restore(Rect2i(get_window().position,dimensions),_screens(),minimum)
	_apply_rect(rect);geometry.observe(rect);hud.schedule_rebuild()

func _track_geometry(delta: float) -> void:
	if DisplayServer.get_name()=="headless" or get_window().mode==Window.MODE_MINIMIZED: return
	geometry_clock+=delta;geometry_idle+=delta
	if geometry_clock<0.2: return
	geometry_clock=0
	if geometry.observe(_window_rect()):
		geometry_idle=0;_window_scale()
	if geometry_idle>=0.8: _save_geometry()

func _process(delta: float) -> void:
	if get_window().always_on_top!=model.state["always_on_top"]: get_window().always_on_top=model.state["always_on_top"]
	if Clock.interrupted(delta):
		journey.baseline.clear();journey.sessions=[];journey.credit=0
		if not model.state["active"].is_empty() and model.state["active"].get("phase")!="result":
			model.state["active"]["paused"]=true;model.notice="Sessão retomada após interrupção. Confira a missão e clique Retomar.";model.commit()
		poll_time=0;_poll();return
	_track_geometry(delta)
	elapsed+=delta;poll_time+=delta
	if poll_time>=.5: poll_time=0;_poll()
	journey.advance(model,delta)
	hud.refresh(false)

func _poll() -> void:
	var incoming: Array=[]
	var now:=Time.get_unix_time_from_system()
	hud.plan="free";hud.history=[]
	if collector_pid>0 and not OS.is_process_running(collector_pid):
		collector_pid=0;state_path="";model.notice="O coletor encerrou. Ative novamente em Agentes."
	if demo:
		for i in range(3):
			incoming.append({"sessionId":"demo-%d"%i,"provider":["codex","claude","cursor"][i],"project":"Sessão fictícia %d"%(i+1),"state":"waiting" if int(elapsed)%24>=18 and i==0 else "working","activity":["read","edit","execute"][int(elapsed/3+i)%3],"turnId":"demo-turn","workUnits":int(elapsed/2),"usageKnown":i!=2,"totalTokens":int(elapsed*70),"lifecycleAt":now,"characterIndex":i})
		if model.state["session_bindings"].is_empty(): model.state["session_bindings"]={"io":"demo-0","brasa":"demo-1","luma":"demo-2"}
	elif not state_path.is_empty() and FileAccess.file_exists(state_path):
		var file:=FileAccess.open(state_path,FileAccess.READ)
		if file and file.get_length()<=524288:
			var data=JSON.parse_string(file.get_as_text())
			if data is Dictionary and (collector_pid==0 or int(data.get("collectorPid",0))==collector_pid):
				incoming=normalize_tracking(data,now)
				hud.history=data.get("history",[]) if data.get("history") is Array else []
				hud.plan=tracking_plan(data,now)
	hud.collector_active=collector_pid>0
	hud.sessions=incoming
	journey.update(incoming,model.journey_bindings())
	hud.refresh()

static func tracking_plan(data: Dictionary,now: float) -> String:
	var heartbeat:=View.safe_time(data.get("heartbeatAt"))
	return "pro" if data.get("plan")=="pro" and heartbeat>0 and absf(now-heartbeat)<=5 else "free"

static func normalize_tracking(data: Dictionary,now: float) -> Array:
	var sessions: Array=[]
	if not data.get("sessions") is Array: return sessions
	for raw in data["sessions"].slice(0,12):
		if not raw is Dictionary: continue
		var normalized:=View.normalize({"sessions":[raw],"heartbeatAt":data.get("heartbeatAt",0)},now)
		if normalized.is_empty(): continue
		var value: Dictionary=normalized[0]
		value["usageKnown"]=raw.get("usageKnown")==true
		for key in ["workUnits","totalTokens"]:
			var number=raw.get(key,0)
			value[key]=int(number) if (number is float or number is int) and is_finite(float(number)) and float(number)>=0 and float(number)<=1e12 else 0
		value["model"]=str(raw.get("model","")).left(80)
		var context=raw.get("contextPercent")
		value["contextPercent"]=float(context) if (context is float or context is int) and is_finite(float(context)) and float(context)>=0 and float(context)<=100 else -1.0
		sessions.append(value)
	return sessions

func _connect_collector() -> void:
	if demo: model.notice="Demonstração usa apenas sessões fictícias.";return
	var root:=ProjectSettings.globalize_path("res://..").simplify_path()
	var python:=root.path_join("tools/python/pythonw.exe")
	if not FileAccess.file_exists(python):
		model.notice="Python portátil ausente. Extraia novamente o pacote completo do Agents Bar.";return
	var directory:=DataPaths.tracking_root()
	if collector_pid==0 or not OS.is_process_running(collector_pid):
		collector_pid=OS.create_process(python,[root.path_join("bridge/tracking.py"),"--directory",directory])
	if collector_pid<=0: model.notice="Não foi possível iniciar o coletor local.";return
	state_path=directory.path_join("session-state.json")
	model.notice="Coletor local ativado. Configure os hooks seguindo docs/INTEGRATIONS.md; então vincule as sessões."

## Explicit, user-triggered edit of the Claude Code user settings through the backup-first merger.
func _claude_hooks(install: bool) -> void:
	if demo: model.notice="Demonstração não altera configurações.";return
	var root:=ProjectSettings.globalize_path("res://..").simplify_path()
	var python:=root.path_join("tools/python/python.exe")
	var profile:=OS.get_environment("USERPROFILE")
	if not FileAccess.file_exists(python) or profile.is_empty():
		model.notice="Python portátil ou pasta do usuário indisponível.";return
	var settings:=profile.path_join(".claude/settings.json")
	var ignored: Array=[]
	if install: OS.execute(python,[root.path_join("scripts/configure_tracking.py")],ignored,true)
	var args:=[root.path_join("scripts/claude_settings.py"),"--settings",settings,"--apply","--json"]
	if not install: args.append("--remove")
	var output: Array=[]
	var code:=OS.execute(python,args,output,true)
	var result=JSON.parse_string(str(output[0]).strip_edges().get_slice("\n",0)) if not output.is_empty() else null
	if code!=0 or not result is Dictionary or result.get("ok")!=true:
		model.notice="Não alterei o settings do Claude: arquivo ilegível ou erro. Nada foi gravado.";return
	hud.claude_hooks=bool(result.get("installed"))
	if not result.get("changed"): model.notice="Hooks do Claude já estavam "+("instalados." if install else "removidos.")
	else: model.notice=("Hooks instalados" if install else "Hooks removidos")+" no settings do Claude (backup criado). Reinicie as sessões abertas do Claude Code."

func _purchase() -> void:
	var url: String=api.get("portal_url","")
	if not url.begins_with("https://"):
		model.notice="Pro ainda não publicado. Servidor e cobrança precisam ser configurados.";return
	OS.shell_open(url)

func _activate(key: String) -> void:
	if demo: model.notice="Ativação indisponível na demonstração.";return
	var url: String=api.get("api_url","")
	if not url.begins_with("https://") or key.length()<20:
		model.notice="Configure o servidor Pro e informe uma chave válida.";return
	if is_instance_valid(request): model.notice="Ativação em andamento.";return
	pending_key=key
	request=HTTPRequest.new();request.timeout=15;add_child(request)
	request.request_completed.connect(func(result,code,_headers,_body):
		if result==HTTPRequest.RESULT_SUCCESS and code==200:
			var root:=DataPaths.tracking_root()
			DirAccess.make_dir_recursive_absolute(root)
			var file:=FileAccess.open(root.path_join("license-key.txt"),FileAccess.WRITE)
			if file: file.store_string(pending_key);model.notice="Chave salva. O coletor verificará a assinatura."
			else: model.notice="Não foi possível guardar a chave."
		else: model.notice="Assinatura não confirmada. Confira a chave e a conexão."
		pending_key="";request.queue_free();request=null
	)
	var error:=request.request(url.trim_suffix("/")+"/v1/license",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify({"key":key}))
	if error!=OK: pending_key="";request.queue_free();request=null;model.notice="Falha ao iniciar ativação."

func _quit() -> void:
	geometry.observe(_window_rect());_save_geometry()
	if not demo and not model.read_only and not model.persist(): return
	if collector_pid>0 and OS.is_process_running(collector_pid): OS.kill(collector_pid)
	get_tree().quit()

func _disconnect_collector() -> void:
	var previous:=collector_pid
	collector_pid=0;state_path="";journey.baseline.clear();journey.sessions=[];journey.credit=0
	model.notice="Coletor desconectado. O progresso e o histórico foram preservados.";_poll()
	if previous<=0 or not OS.is_process_running(previous): return
	var token_path:=DataPaths.tracking_root().path_join("collector-token.txt")
	var token:=FileAccess.get_file_as_string(token_path).strip_edges()
	var stop_request:=HTTPRequest.new();stop_request.timeout=2;add_child(stop_request)
	stop_request.request_completed.connect(func(_result,_code,_headers,_body): stop_request.queue_free())
	var error:=stop_request.request("http://127.0.0.1:43127/v1/stop",["Authorization: Bearer "+token],HTTPClient.METHOD_POST,"{}")
	if error!=OK: stop_request.queue_free()
	await get_tree().create_timer(2.5).timeout
	if OS.is_process_running(previous): OS.kill(previous)
