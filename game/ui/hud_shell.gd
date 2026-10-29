extends Control
## Bounded internal pages. No scroll containers, popup menus or child windows.
signal layout_changed(compact: bool,expanded: bool)
signal quit_requested
signal dimensions_requested(dimensions: Vector2i)
const Tutorial=preload("res://gameplay/tutorial.gd")
const Art=preload("res://gameplay/visual_library.gd")
const BattleCanvas=preload("res://ui/mission_canvas.gd")
const Equipment=preload("res://gameplay/equipment.gd")
const Forge=preload("res://gameplay/forge.gd")
const Station=preload("res://ui/station_visual.gd")
const View=preload("res://presentation.gd")
const Layout=preload("res://ui/hud_layout.gd")
const NAV=[["heroes","Heróis"],["inventory","Inventário"],["forge","Forja"],["map","Mapa"],["station","Estação"],["agents","Agentes"],["journal","Diário"],["settings","Menu"]]
var art=Art.new()
var model
var journey
var sessions: Array=[]
var history: Array=[]
var compact:=true
var selected: String="heroes"
var hero: String="io"
var relic: String="lens"
var region: String="scrap"
var mission_id: String="scrap-1"
var building: String="core"
var journal_id: String=""
var journal_mode: String="pending"
var usage_mode: String="sessions"
var memory_index:=0
var pages: Dictionary={}
var demo:=false
var plan: String="free"
var on_connect: Callable
var on_disconnect: Callable
var collector_active:=false
var settings_tab: String="window"
var confirmation: Callable
var confirmation_text: String=""
var return_panel: String="map"
var on_purchase: Callable
var on_license: Callable
var on_claude_hooks: Callable
var claude_hooks:=false
var gear_id: String="weapons-01"
var inventory_kind: String="relics"
var forge_kind: String="upgrade"
var context_labels: Dictionary={}
var formation: Control
var session_header: Label
var icon_cache: Dictionary={}
var mini: Control
var full: Control
var menu: Control
var header: Control
var navigation: Control
var actions: Control
var battle: Control
var status: Label
var resources: Label
var mini_status: Label
var agent_status: Label
var content_signature: String=""
var usage_values: Dictionary={}
var drafts: Dictionary={"journal":"","license":""}
var queued:=false
var dirty:=false
var left: Control
var right: Control
var width_input: LineEdit
var height_input: LineEdit
var resize_grip: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	# The app root is Node2D, so Control anchors do not inherit its viewport size.
	get_viewport().size_changed.connect(fit_viewport)
	fit_viewport()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	clip_contents=true
	var skin:=Theme.new();skin.default_font_size=13
	skin.set_color("font_color","Label",Color("ece4d0"))
	for state in [["normal",0],["hover",1],["pressed",2],["disabled",3],["focus",4]]:
		var box:=StyleBoxTexture.new();box.texture=art.atlas("ui-button",state[1])
		box.texture_margin_left=6;box.texture_margin_right=6;box.texture_margin_top=6;box.texture_margin_bottom=6
		box.set_content_margin_all(4)
		skin.set_stylebox(state[0],"Button",box)
	skin.set_color("font_color","Button",Color("ece4d0"))
	skin.set_color("font_disabled_color","Button",Color("737c88"))
	theme=skin
	var background:=Panel.new();background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter=MOUSE_FILTER_IGNORE;background.add_theme_stylebox_override("panel",frame("111a25","b09161"));add_child(background)
	mini=Control.new();add_child(mini)
	full=Control.new();add_child(full)
	header=Control.new();full.add_child(header)
	navigation=Control.new();full.add_child(navigation)
	menu=Control.new();menu.mouse_filter=MOUSE_FILTER_IGNORE;full.add_child(menu)
	battle=BattleCanvas.new();battle.model=model;full.add_child(battle)
	actions=Control.new();full.add_child(actions)
	status=txt(full,"",Rect2(),11)
	session_header=txt(full,"",Rect2(),11,"bfb4a1")
	resize_grip=txt(self,"◢",Rect2(),12,"dbb87b")
	resized.connect(schedule_rebuild)
	model.changed.connect(refresh)
	if not demo and not model.state["onboarded"] and model.state["completed"].is_empty(): selected="guide"
	rebuild();set_compact(true)

func fit_viewport() -> void:
	position=Vector2.ZERO
	size=get_viewport_rect().size

func frame(fill: String="242735",border: String="756448") -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color(fill);style.border_color=Color(border);style.set_border_width_all(1);return style

func place(control: Control,rect: Rect2) -> void:
	control.position=rect.position;control.size=rect.size

func clear(parent: Node) -> void:
	for child in parent.get_children(): parent.remove_child(child);child.queue_free()

func txt(parent: Control,text: String,rect: Rect2,font_size: int=13,color: String="ece4d0") -> Label:
	var node:=Label.new();node.text=text;node.add_theme_font_size_override("font_size",font_size);node.add_theme_color_override("font_color",Color(color))
	node.clip_text=true;node.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	node.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;node.mouse_filter=MOUSE_FILTER_IGNORE
	parent.add_child(node);place(node,rect);return node

func text_block(parent: Control,text: String,y: float,height: float=42) -> Label:
	var node:=txt(parent,text,Rect2(12,y,parent.size.x-24,height))
	node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.max_lines_visible=maxi(1,int(height/18));return node

func btn(parent: Control,text: String,rect: Rect2,action: Callable,disabled: bool=false,active: bool=false) -> Button:
	var node:=Button.new();node.text=text;node.clip_text=true;node.disabled=disabled;node.pressed.connect(action)
	if active: node.add_theme_stylebox_override("normal",frame("364338","c3a26a"))
	parent.add_child(node);place(node,rect);return node

func wide(parent: Control,text: String,y: float,action: Callable,disabled: bool=false) -> Button:
	return btn(parent,text,Rect2(12,y,parent.size.x-24,28),action,disabled)

func field(parent: Control,key: String,placeholder: String,y: float,secret: bool=false) -> LineEdit:
	var node:=LineEdit.new();node.context_menu_enabled=false;node.placeholder_text=placeholder;node.text=drafts.get(key,"");node.secret=secret;node.max_length=160 if secret else 80
	parent.add_child(node);place(node,Rect2(12,y,parent.size.x-24,30))
	node.text_changed.connect(func(value): drafts[key]=value)
	node.focus_exited.connect(func(): if dirty: schedule_rebuild())
	return node

func pane(title: String,rect: Rect2) -> Control:
	var node:=Panel.new();node.add_theme_stylebox_override("panel",frame());node.clip_contents=true
	menu.add_child(node);place(node,rect)
	txt(node,title.to_upper(),Rect2(12,7,node.size.x-24,24),13,"dbb87b")
	return node

func portrait(parent: Control,id: String,rect: Rect2) -> void:
	var meta:=Art.clip({"id":id},"idle")
	if meta.is_empty(): return
	var texture:=art.atlas(meta["id"]);var bounds: Array=meta["alphaBounds"][0]
	texture.region=Rect2(bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1])
	var node:=TextureRect.new();node.texture=texture;node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter=MOUSE_FILTER_IGNORE;parent.add_child(node);place(node,rect)

func tabs(parent: Control,items: Array,value: String,y: float,action: Callable) -> void:
	var width: float=(parent.size.x-24-4*(items.size()-1))/maxi(1,items.size())
	for i in range(items.size()):
		var id: String=items[i][0]
		btn(parent,items[i][1],Rect2(12+i*(width+4),y,width,28),func(): action.call(id),false,id==value)

func hero_tabs(parent: Control,y: float=38) -> void:
	tabs(parent,[["io","Cavaleiro"],["brasa","Brasa"],["luma","Luma"]],hero,y,func(id): hero=id;schedule_rebuild())

func page_bar(parent: Control,key: String,count: int,y: float,capacity: int=4) -> void:
	var total:=Layout.page_count(count,capacity);var page:=clampi(int(pages.get(key,0)),0,total-1);pages[key]=page
	btn(parent,"‹",Rect2(12,y,32,26),func(): pages[key]=page-1;schedule_rebuild(),page==0)
	txt(parent,"%d / %d · %d registros"%[page+1,total,count],Rect2(50,y,parent.size.x-100,26),11)
	btn(parent,"›",Rect2(parent.size.x-44,y,32,26),func(): pages[key]=page+1;schedule_rebuild(),page+1>=total)

func busy() -> bool: return model.read_only or not model.state["active"].is_empty()
func costs(price: Dictionary) -> String:
	var parts: Array=[]
	for entry in [["scrap","sucata"],["cores","núcleos"],["seeds","sementes"]]:
		if int(price.get(entry[0],0))>0: parts.append("%d %s"%[price[entry[0]],entry[1]])
	return "Sem custo" if parts.is_empty() else " · ".join(parts)

func set_compact(value: bool) -> void:
	compact=value;mini.visible=value;full.visible=not value
	layout_changed.emit(compact,true);schedule_rebuild()

func open_panel(key: String) -> void:
	selected=key
	if compact: set_compact(false)
	schedule_rebuild()

func schedule_rebuild() -> void:
	if queued or not is_node_ready(): return
	queued=true;rebuild.call_deferred()

func rebuild() -> void:
	queued=false
	if not is_instance_valid(menu): return
	dirty=false;usage_values.clear();context_labels.clear()
	place(mini,Rect2(Vector2.ZERO,size));place(full,Rect2(Vector2.ZERO,size))
	clear(mini);clear(header);clear(navigation);clear(menu);clear(actions)
	portrait(mini,hero,Rect2(12,12,48,mini.size.y-24))
	mini_status=txt(mini,"",Rect2(70,12,maxf(80,size.x-160),size.y-24),13)
	btn(mini,"Abrir",Rect2(size.x-80,14,66,size.y-28),func(): set_compact(false))
	var regions:=Layout.regions(size)
	place(header,regions.header);place(navigation,regions.navigation);place(battle,regions.battle);place(actions,regions.actions);place(status,regions.status)
	place(menu,Rect2(Vector2.ZERO,Vector2(maxf(size.x,884),maxf(size.y,600))))
	place(session_header,regions.session)
	formation=pane("Formação",regions.formation)
	formation_panel()
	txt(header,"⠿  AGENTS BAR"+(" · DEMO" if demo else ""),Rect2(0,0,195,28),14,"dbb87b")
	resources=txt(header,"",Rect2(200,0,header.size.x-340,28),12)
	btn(header,"Recolher",Rect2(header.size.x-132,0,94,28),func(): set_compact(true))
	btn(header,"×",Rect2(header.size.x-32,0,32,28),func(): quit_requested.emit())
	var nav_width: float=(navigation.size.x-4*(NAV.size()-1))/NAV.size()
	for i in range(NAV.size()):
		var key: String=NAV[i][0]
		btn(navigation,NAV[i][1],Rect2(i*(nav_width+4),0,nav_width,32),func(): open_panel(key),false,selected==key or (key=="settings" and selected=="pro"))
	left=pane({"heroes":"Herói","inventory":"Inventário","forge":"Forja","map":"Rotas","station":"Estação Zero","agents":"Conexões","journal":"Diário","settings":"Janela e preferências","guide":"Primeiros passos","support":"Ajuda","confirm":"Confirmar ação","pro":"Agents Bar Pro"}.get(selected,"Menu"),regions.left)
	right=pane({"heroes":"Equipamento e formação","inventory":"Equipamento","forge":"Receitas","map":"Expedição","station":"Construção","agents":"Uso e histórico","journal":"Revisão","settings":"Sobre e plano","guide":"Seu próximo passo","support":"Diagnóstico local","confirm":"Sua escolha","pro":"Uso e histórico"}.get(selected,"Detalhes"),regions.right)
	match selected:
		"heroes": heroes_panel();equipment_panel()
		"inventory": inventory_panel();relic_panel() if inventory_kind=="relics" else gear_detail()
		"forge": forge_panel();recipes_panel() if forge_kind=="upgrade" else gear_detail(true)
		"map": map_panel();detail_panel()
		"station": station_panel();building_panel()
		"agents": agents_panel();usage_panel()
		"journal": journal_panel();review_panel()
		"settings": settings_panel();about_panel()
		"guide": guide_panel()
		"support": support_panel()
		"confirm": confirmation_panel()
		"pro": pro_panel();usage_panel()
	var active: Dictionary=model.state["active"]
	btn(actions,"Retomar" if active.get("paused",false) else "Pausar",Rect2(0,0,86,28),func(): model.toggle_expedition_pause(),active.is_empty() or active.get("phase")=="result")
	btn(actions,"Retirar",Rect2(92,0,78,28),func(): ask_confirmation("Retirar a equipe encerra esta missão sem recompensa. Seus itens e recursos são preservados.",func(): model.retreat()),active.is_empty() or active.get("phase")=="result")
	btn(actions,"Recolher",Rect2(176,0,88,28),func():
		if model.collect(): journal_mode="history";open_panel("journal")
	,active.get("phase")!="result")
	agent_status=txt(actions,"",Rect2(278,0,actions.size.x-294,28),11,"a5b7ca")
	refresh(false)
	place(resize_grip,Rect2(size.x-17,size.y-17,12,12))
	queue_redraw()

func _draw() -> void:
	draw_line(size-Vector2(17,7),size-Vector2(7,17),Color("dbb87b"),1)
	draw_line(size-Vector2(12,7),size-Vector2(7,12),Color("dbb87b"),1)

func heroes_panel() -> void:
	hero_tabs(left)
	var member: Dictionary=model.definition("characters",hero);var owned: Dictionary=model.state["crew"][hero]
	portrait(left,hero,Rect2(18,78,88,110))
	item_icon(left,model.state["gear"]["equipped"][hero]["weapon"],Rect2(12,188,48,48))
	txt(left,member["name"],Rect2(132,80,left.size.x-144,26),19,"dbb87b")
	txt(left,member["role"]+" · nível %d"%owned["level"],Rect2(132,110,left.size.x-144,22))
	txt(left,"XP %d · Arma +%d"%[owned["xp"],owned.get("forge",0)],Rect2(132,138,left.size.x-144,22))
	txt(left,member["skill_name"],Rect2(132,164,left.size.x-144,22),12,"a6cbbb")
	var desc:=txt(left,member["description"],Rect2(62,190,left.size.x-74,48),12)
	desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;desc.max_lines_visible=3
	wide(left,"Treinar · "+costs(model.training_cost(hero)),left.size.y-42,func(): model.train(hero),busy() or not model.afford(model.training_cost(hero)))

func equipment_panel() -> void:
	var id: String=model.state["crew"][hero]["relic"]
	text_block(right,"RELÍQUIA EQUIPADA",38,22)
	text_block(right,"Nenhuma relíquia" if id.is_empty() else model.definition("relics",id)["name"],64,28)
	text_block(right,"Abra o inventário para escolher uma relíquia." if id.is_empty() else model.definition("relics",id)["description"],96,38)
	wide(right,"Abrir inventário",142,func(): open_panel("inventory"))
	var names: Array=[]
	for id_hero in model.state["team"]: names.append(model.definition("characters",id_hero)["name"])
	text_block(right,"FORMAÇÃO %d / %d\n%s"%[names.size(),model.capacity(),", ".join(names)],181,46)
	wide(right,"Remover da formação" if hero in model.state["team"] else "Adicionar à formação",right.size.y-42,func():
		var team: Array=model.state["team"].duplicate()
		if hero in team: team.erase(hero)
		else: team.append(hero)
		model.select_team(team)
	,busy() or (hero in model.state["team"] and model.state["team"].size()==1) or (not hero in model.state["team"] and model.state["team"].size()>=model.capacity()))

func relic_grid(parent: Control,craft: bool=false,start_y: int=42) -> void:
	var w: float=(parent.size.x-36)/3
	for i in range(model.content["relics"].size()):
		var item: Dictionary=model.content["relics"][i];var id: String=item["id"]
		var owned: bool=id in model.state["inventory"]
		var rect:=Rect2(12+(i%3)*(w+6),start_y+int(i/3)*74,w,68)
		btn(parent,"",rect,func(): relic=id;schedule_rebuild(),false,id==relic)
		item_icon(parent,"relics-%02d"%(i+1),Rect2(rect.position+Vector2(floor((w-48)/2),3),Vector2(48,48)),owned or craft)
		txt(parent,"Obtida" if owned else "Receita" if craft else "Bloqueada",Rect2(rect.position+Vector2(2,52),Vector2(w-4,12)),10)
	var chosen: Dictionary=model.definition("relics",relic)
	text_block(parent,chosen["name"],start_y+150,24)
	if craft: text_block(parent,chosen["description"],start_y+174,30)

func inventory_panel() -> void:
	tabs(left,[["relics","Relíquias"],["gear","Equipamento"]],inventory_kind,38,func(id): inventory_kind=id;schedule_rebuild())
	if inventory_kind=="relics":
		relic_grid(left,false,76)
	else:
		gear_grid(left,false)
	wide(left,"Ir para a Forja",left.size.y-42,func(): open_panel("forge"))

func relic_panel() -> void:
	hero_tabs(right)
	var item: Dictionary=model.definition("relics",relic)
	item_icon(right,"relics-%02d"%(["lens","plate","seed","bloom","coil","beacon"].find(relic)+1),Rect2(12,76,48,48))
	txt(right,item["name"],Rect2(70,76,right.size.x-82,30),13,"dbb87b")
	text_block(right,item["description"],127,30)
	var current: String=model.state["crew"][hero]["relic"]
	text_block(right,"Equipada: "+("nenhuma" if current.is_empty() else model.definition("relics",current)["name"]),152,38)
	wide(right,"Equipar" if relic in model.state["inventory"] else "Relíquia ainda não obtida",198,func(): model.equip(hero,relic),busy() or not relic in model.state["inventory"] or current==relic)
	var in_use:=false
	for member in model.state["crew"].values():
		if member["relic"]==relic: in_use=true
	var w: float=(right.size.x-30)/2
	btn(right,"Desequipar",Rect2(12,right.size.y-42,w,28),func(): model.equip(hero,""),busy() or current.is_empty())
	btn(right,"Reciclar · +4 sucata",Rect2(18+w,right.size.y-42,w,28),func(): Forge.recycle(model,relic),busy() or in_use or not relic in model.state["inventory"])

func forge_panel() -> void:
	tabs(left,[["upgrade","Aprimorar"],["craft","Fabricar"]],forge_kind,38,func(id): forge_kind=id;schedule_rebuild())
	if forge_kind=="craft":
		gear_grid(left,true);return
	hero_tabs(left,74)
	item_icon(left,model.state["gear"]["equipped"][hero]["weapon"],Rect2(30,124,48,48))
	var level:=int(model.state["crew"][hero].get("forge",0))
	txt(left,"Arma +%d / 5"%level,Rect2(106,116,left.size.x-118,30),19,"dbb87b")
	txt(left,"+2 ataque por melhoria",Rect2(106,151,left.size.x-118,26))
	text_block(left,costs(Forge.cost(model,hero)),196,30)
	wide(left,"Arma no máximo" if level>=5 else "Aprimorar arma",left.size.y-42,func(): Forge.upgrade(model,hero),busy() or level>=5 or not model.afford(Forge.cost(model,hero)))

func recipes_panel() -> void:
	relic_grid(right,true)
	var unlocked:=false
	for mission in model.content["missions"]:
		if mission.get("relic")==relic and model.state["completed"].has(mission["id"]): unlocked=true
	wide(right,"Já obtida" if relic in model.state["inventory"] else "Recriar · 24 sucata + 1 núcleo" if unlocked else "Conclua a missão desta relíquia",right.size.y-42,func(): Forge.craft(model,relic),busy() or not unlocked or relic in model.state["inventory"] or not model.afford({"scrap":24,"cores":1}))

func map_panel() -> void:
	tabs(left,[["scrap","Forja"],["garden","Jardins"],["storm","Tempestade"]],region,38,func(id):
		region=id
		for item in model.content["missions"]:
			if item["map"]==id: mission_id=item["id"];break
		schedule_rebuild())
	var index:=0
	for mission in model.content["missions"]:
		if mission["map"]!=region: continue
		var id: String=mission["id"]
		var prefix: String="✓ " if model.state["completed"].has(id) else "◇ " if not model.unlocked(id) else "› "
		btn(left,prefix+mission["name"],Rect2(12,78+index*36,left.size.x-24,30),func(): mission_id=id;schedule_rebuild(),false,id==mission_id);index+=1
	var agents: bool=model.state["expedition_mode"]=="agents"
	wide(left,"Modo: Agentes" if agents else "Modo: Livre / sem conexão",left.size.y-42,func(): model.state["expedition_mode"]="practice" if agents else "agents";model.commit(),busy())

func detail_panel() -> void:
	var mission: Dictionary=model.definition("missions",mission_id)
	text_block(right,mission["name"],38,30);text_block(right,mission["brief"],75,68)
	text_block(right,"RECOMPENSA\n"+costs(mission["rewards"])+" · %d XP"%mission["rewards"]["xp"],155,46)
	text_block(right,"%d encontros · %s"%[mission["waves"].size(),"Chefe mundial" if mission.get("world_boss",false) else "Chefe" if mission.get("boss",false) else "Expedição"],210,24)
	wide(right,"Equipe em missão" if busy() else "Iniciar expedição" if model.unlocked(mission_id) else "Rota bloqueada",right.size.y-42,func(): model.start_mission(mission_id),busy() or not model.unlocked(mission_id))

func station_panel() -> void:
	var scene:=Station.new();scene.model=model;left.add_child(scene);scene.custom_minimum_size=Vector2.ZERO;place(scene,Rect2(12,38,left.size.x-24,128))
	var index:=0;var w: float=(left.size.x-30)/2
	for item in model.content["buildings"]:
		var id: String=item["id"]
		btn(left,item["name"]+" · %d"%model.state["buildings"][id],Rect2(12+(index%2)*(w+6),178+int(index/2)*36,w,30),func(): building=id;schedule_rebuild(),false,id==building);index+=1

func building_panel() -> void:
	var item: Dictionary=model.definition("buildings",building)
	text_block(right,item["name"]+" · nível %d / 3"%model.state["buildings"][building],38,26)
	text_block(right,item["description"],69,40)
	wide(right,"Melhorar · "+costs(model.building_cost(building)),118,func(): model.build(building),busy() or model.state["buildings"][building]>=3 or not model.afford(model.building_cost(building)))
	var slots: Array=[["0","Encaixe 1"],["1","2"],["2","3"],["3","4"]]
	tabs(right,slots,str(model.state["layout"].find(building)),158,func(id):
		if not busy(): model.place_building(building,int(id)))
	var memories: Array=model.state["journal"].filter(func(entry): return entry.get("type")=="milestone" and entry.get("result")=="accepted")
	memory_index=clampi(memory_index,0,maxi(0,memories.size()-1))
	var memory: Dictionary={} if memories.is_empty() else memories[memory_index]
	btn(right,"‹",Rect2(12,200,28,28),func(): memory_index-=1;schedule_rebuild(),memory_index==0)
	var memory_label:=txt(right,"Sem lembranças" if memory.is_empty() else memory["title"],Rect2(46,192,right.size.x-92,50),12)
	memory_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;memory_label.max_lines_visible=3
	btn(right,"›",Rect2(right.size.x-40,200,28,28),func(): memory_index+=1;schedule_rebuild(),memory_index+1>=memories.size())
	wide(right,"Vincular lembrança",right.size.y-42,func(): model.bind_memory(building,memory["id"]),model.read_only or memory.is_empty() or model.state["buildings"][building]==0)

func agents_panel() -> void:
	hero_tabs(left)
	var half: float=(left.size.x-30)/2
	btn(left,"Desconectar coletor" if collector_active else "Ativar coletor",Rect2(12,76,half,28),func():
		if collector_active and on_disconnect.is_valid(): on_disconnect.call()
		elif on_connect.is_valid(): on_connect.call()
	)
	btn(left,"Remover hooks Claude" if claude_hooks else "Instalar hooks Claude",Rect2(18+half,76,half,28),func():
		if on_claude_hooks.is_valid(): on_claude_hooks.call(not claude_hooks)
	,busy())
	var visible_sessions:=Layout.page_items(sessions,int(pages.get("bindings",0)),3)
	for i in range(visible_sessions.size()):
		var session: Dictionary=visible_sessions[i];var id: String=session.get("sessionId","")
		var assigned: bool=model.state["session_bindings"].get(hero,"")==id
		var taken: bool=id in model.state["session_bindings"].values() and not assigned
		btn(left,("✓ " if assigned else "")+str(session.get("project",session.get("provider","Agente")))+" · "+View.label(session.get("state","unknown")),Rect2(12,112+i*34,left.size.x-24,28),func():
			model.state["session_bindings"][hero]=id;model.commit()
		,busy() or taken or id.is_empty(),assigned)
	if sessions.is_empty(): text_block(left,"Sem sessões. Ative o coletor e configure um hook ou MCP explícito.",114,80)
	page_bar(left,"bindings",sessions.size(),220,3)
	wide(left,"Desvincular "+model.definition("characters",hero)["name"],left.size.y-42,func(): model.state["session_bindings"][hero]="";model.commit(),busy() or str(model.state["session_bindings"].get(hero,"")).is_empty())

func usage_panel() -> void:
	tabs(right,[["sessions","Sessões"],["history","Histórico"]],usage_mode,38,func(id): usage_mode=id;schedule_rebuild())
	text_block(right,"● %s\n%s · %d sessões · %d dias"%[View.connection(collector_active,sessions),"PRO" if plan=="pro" else "GRÁTIS",12 if plan=="pro" else 3,90 if plan=="pro" else 1],68,36)
	var items: Array=history.filter(func(item): return item is Dictionary) if usage_mode=="history" else sessions
	var visible_items:=Layout.page_items(items,int(pages.get(usage_mode,0)),4)
	for i in range(visible_items.size()):
		var item: Dictionary=visible_items[i];var y:=106+i*34
		if usage_mode=="history":
			text_block(right,"%s · %d tokens · %d eventos"%[Time.get_date_string_from_unix_time(int(item.get("day",0))*86400),item.get("tokens",0),item.get("events",0)],y,30)
		else:
			var id: String=str(item.get("sessionId",""))
			usage_values[id]=txt(right,"",Rect2(12,y,right.size.x-24,30),11)
	if items.is_empty(): text_block(right,"Nenhum registro recebido.",110,60)
	page_bar(right,usage_mode,items.size(),right.size.y-42)

## Context fill and tokens are separate signals; neither is account-wide consumption.
static func session_metrics(session: Dictionary) -> String:
	var context: float=float(session.get("contextPercent",-1))
	var parts: Array=["Contexto %d%%"%roundi(context) if context>=0 else "Contexto indisponível"]
	parts.append("%d tokens nesta sessão"%int(session.get("totalTokens",0)) if session.get("usageKnown",false) else "tokens indisponíveis")
	return " · ".join(parts)

func journal_items() -> Array:
	if journal_mode=="battle":
		var records: Array=[]
		var logs: Array=model.state["active"].get("log",[])
		for i in range(logs.size()-1,-1,-1): records.append({"id":str(i),"title":str(logs[i]),"result":"combate"})
		return records
	return model.state["pending_milestones"] if journal_mode=="pending" else model.state["journal"]

func journal_panel() -> void:
	tabs(left,[["pending","Revisar"],["history","Histórico"],["battle","Combate"]],journal_mode,38,func(id): journal_mode=id;journal_id="";schedule_rebuild())
	var items:=journal_items();var visible_items:=Layout.page_items(items,int(pages.get("journal_"+journal_mode,0)),4)
	for i in range(visible_items.size()):
		var item: Dictionary=visible_items[i];var id: String=str(item.get("id",i))
		btn(left,item["title"],Rect2(12,78+i*38,left.size.x-24,32),func(): journal_id=id;schedule_rebuild(),false,id==journal_id)
	if items.is_empty(): text_block(left,"Nenhuma entrega para revisar." if journal_mode=="pending" else "Suas expedições e entregas aparecerão aqui.",90,64)
	page_bar(left,"journal_"+journal_mode,items.size(),left.size.y-42)

func review_panel() -> void:
	field(right,"journal","Registrar uma entrega",38)
	wide(right,"Adicionar para revisão",75,func():
		if model.manual_milestone(drafts["journal"]): drafts["journal"]="";schedule_rebuild()
	,model.read_only)
	var items:=journal_items();var entry: Dictionary={}
	for i in range(items.size()):
		if str(items[i].get("id",i))==journal_id: entry=items[i];break
	text_block(right,"Selecione um registro ao lado." if entry.is_empty() else entry["title"],116,70)
	text_block(right,"A revisão registra uma lembrança na estação." if entry.is_empty() else "Estado: "+str(entry.get("result","aguardando revisão")),194,40)
	var w: float=(right.size.x-30)/2
	btn(right,"Aceitar",Rect2(12,right.size.y-42,w,28),func(): model.resolve_milestone(entry["id"],true),model.read_only or entry.is_empty() or journal_mode!="pending")
	btn(right,"Descartar",Rect2(18+w,right.size.y-42,w,28),func(): model.resolve_milestone(entry["id"],false),model.read_only or entry.is_empty() or journal_mode!="pending")

func settings_panel() -> void:
	tabs(left,[["window","Janela"],["preferences","Preferências"]],settings_tab,38,func(id): settings_tab=id;schedule_rebuild())
	if settings_tab=="preferences":
		for i in range(3):
			var key: String=["sound","reduced_motion","always_on_top"][i]
			wide(left,["Sons","Movimento reduzido","Sempre acima"][i]+": "+("ligado" if model.state[key] else "desligado"),80+i*42,func(): model.set_option(key,not model.state[key]))
		text_block(left,"Preferências salvas neste computador. Esc recolhe ou expande a barra.",214,58);return
	text_block(left,"Arraste pelo cabeçalho e redimensione pelas bordas.",78,42)
	tabs(left,[["884","884 × 700"],["984","984 × 760"],["1120","1120 × 820"]],"",128,func(id): dimensions_requested.emit(Vector2i(int(id),700 if id=="884" else 760 if id=="984" else 820)))
	width_input=LineEdit.new();width_input.context_menu_enabled=false;width_input.text=str(drafts.get("width",get_window().size.x));width_input.max_length=5;left.add_child(width_input);place(width_input,Rect2(12,174,90,30))
	height_input=LineEdit.new();height_input.context_menu_enabled=false;height_input.text=str(drafts.get("height",get_window().size.y));height_input.max_length=5;left.add_child(height_input);place(height_input,Rect2(110,174,90,30))
	width_input.text_changed.connect(func(value): drafts["width"]=value)
	height_input.text_changed.connect(func(value): drafts["height"]=value)
	btn(left,"Aplicar",Rect2(208,174,left.size.x-220,30),func():
		if width_input.text.is_valid_int() and height_input.text.is_valid_int(): dimensions_requested.emit(Vector2i(int(width_input.text),int(height_input.text)));drafts.erase("width");drafts.erase("height")
		else: model.notice="Informe largura e altura usando apenas números."
	)
	text_block(left,"Largura / altura · mínimo 884 × 700. O tamanho compacto é guardado separadamente.",220,64)

func about_panel() -> void:
	text_block(right,"AGENTS BAR · 0.9.11",38,30)
	text_block(right,"Jogo e histórico locais. Conexões só começam quando você ativa o coletor e configura um provedor.",76,60)
	wide(right,"Primeiros passos",152,func(): open_panel("guide"))
	wide(right,"Ajuda e diagnóstico",190,func(): open_panel("support"))
	wide(right,"Plano Pro e ativação",right.size.y-42,func(): open_panel("pro"))

func guide_panel() -> void:
	var step:=Tutorial.describe(model)
	text_block(left,"BEM-VINDO À FORTALEZA",38,28)
	var names: Array=["1 · Partir em modo Livre","2 · Acompanhar a missão","3 · Recolher o resultado","4 · Equipar e preparar a equipe"]
	for i in range(names.size()): text_block(left,names[i],84+i*34,28)
	wide(left,"Explorar por conta própria",left.size.y-42,func(): model.set_option("onboarded",true);open_panel("heroes"),model.read_only)
	text_block(right,step["title"],38,46)
	text_block(right,step["text"],92,124)
	wide(right,step["button"],right.size.y-42,func():
		if step["action"] in ["map","support"]: open_panel(step["action"])
		else:
			Tutorial.act(model,step["action"])
			if step["action"]=="finish": open_panel("forge")
			else: schedule_rebuild()
	)

func support_panel() -> void:
	text_block(left,"PRECISA DE AJUDA?",38,28)
	text_block(left,"Sem movimento? Confira o modo Livre/Agentes, a pausa e o vínculo de sessão. Tokens podem estar indisponíveis mesmo com atividade chegando.",80,96)
	wide(left,"Abrir conexões",192,func(): open_panel("agents"))
	wide(left,"Voltar ao guia",left.size.y-42,func(): open_panel("guide"))
	text_block(right,"Progresso: "+("protegido para revisão" if model.read_only else "gravação local ativa"),38,46)
	text_block(right,"O diagnóstico contém somente versão, contagens e estado do jogo. Não inclui conversas, títulos, chaves ou IDs de sessões.",92,90)
	wide(right,"Salvar diagnóstico local",196,func(): model.export_diagnostic())
	wide(right,"Recuperar backup",right.size.y-42,func(): ask_confirmation("Recuperar usa o último backup válido. O arquivo atual será preservado antes da troca.",func(): model.recover_backup()),not model.can_recover_backup())

func ask_confirmation(message: String,action: Callable) -> void:
	confirmation=action;confirmation_text=message;return_panel=selected;open_panel("confirm")

func confirmation_panel() -> void:
	text_block(left,confirmation_text,44,144)
	text_block(right,"Confira a ação antes de continuar.",44,60)
	wide(right,"Cancelar",right.size.y-82,func(): open_panel(return_panel))
	wide(right,"Confirmar",right.size.y-42,func():
		if confirmation.is_valid(): confirmation.call()
		open_panel(return_panel)
	)

func pro_panel() -> void:
	text_block(left,"US$ 2/mês · 12 sessões · 90 dias",38,28)
	text_block(left,"Mesmas regras de combate e formação de até 3 heróis. Publicação e cobrança ainda pendentes.",74,62)
	field(left,"license","Chave de ativação",150,true)
	wide(left,"Ativar assinatura",190,func(): if on_license.is_valid(): on_license.call(drafts["license"]))
	wide(left,"Assinar Pro",left.size.y-42,func(): if on_purchase.is_valid(): on_purchase.call())

func refresh(rebuild_if_needed: bool=true) -> void:
	if not is_instance_valid(resources): return
	resources.text=costs(model.state["materials"])
	status.text=("DEMO · " if demo else "")+model.notice
	var overview:=View.summary(sessions)
	agent_status.text=journey.reason
	session_header.text="● "+overview["text"]+"    |    "+("PRO · 12 sessões" if plan=="pro" else "GRÁTIS · 3 sessões")+"    |    "+("Modo Livre" if model.state["expedition_mode"]=="practice" else "Avanço por atividade")
	for id in context_labels:
		var bound: String=model.state["session_bindings"].get(id,"")
		var found: Array=sessions.filter(func(item): return item.get("sessionId")==bound)
		context_labels[id].text=View.label(found[0].get("state","unknown")) if not found.is_empty() else "Sem vínculo"
	mini_status.text="AGENTS BAR"+(" · DEMO" if demo else "")+"\n"+overview["text"]
	for session in sessions:
		var id: String=str(session.get("sessionId",""))
		if usage_values.has(id) and is_instance_valid(usage_values[id]):
			usage_values[id].text=str(session.get("provider","Agente")).to_upper()+" · "+View.label(session.get("state","unknown"))+"\n"+session_metrics(session)
	if not rebuild_if_needed: return
	var signature:=JSON.stringify([plan,model.state["buildings"],model.state["building_memories"],model.state["layout"],model.state["journal"],model.state["pending_milestones"],model.state["crew"],model.state["gear"],model.state["team"],model.state["materials"],model.state["inventory"],model.state["active"].get("phase",""),model.state["active"].get("paused",false),model.state["session_bindings"],model.state["expedition_mode"],model.state["sound"],model.state["reduced_motion"],model.state["always_on_top"],model.state["onboarded"],collector_active,sessions.map(func(s): return str(s.get("sessionId",""))+str(s.get("state",""))+str(s.get("project",""))),history])
	if rebuild_if_needed and signature!=content_signature:
		content_signature=signature
		if get_viewport().gui_get_focus_owner() is LineEdit: dirty=true
		else: schedule_rebuild()

func item_icon(parent: Control,id: String,rect: Rect2,owned: bool=true) -> void:
	var path: String=Equipment.definition(id).get("icon","")
	if path.is_empty(): return
	if not icon_cache.has(id):
		var data:=Image.load_from_file(path)
		if data: icon_cache[id]=ImageTexture.create_from_image(data)
	if not icon_cache.has(id): return
	var node:=TextureRect.new();node.texture=icon_cache[id]
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;node.mouse_filter=MOUSE_FILTER_IGNORE
	node.modulate=Color.WHITE if owned else Color(.55,.55,.55,.6)
	parent.add_child(node);place(node,rect)

func formation_panel() -> void:
	for i in range(3):
		var id: String=["io","brasa","luma"][i]
		var y:=38+i*72
		btn(formation,"",Rect2(8,y,formation.size.x-16,66),func(): hero=id;schedule_rebuild(),false,id==hero)
		portrait(formation,id,Rect2(12,y+6,40,51))
		txt(formation,model.definition("characters",id)["name"],Rect2(57,y+7,formation.size.x-64,20),12,"dbb87b")
		txt(formation,"Nível %d"%model.state["crew"][id]["level"]+(" · ✓" if id in model.state["team"] else ""),Rect2(57,y+27,formation.size.x-64,17),10)
		context_labels[id]=txt(formation,"",Rect2(57,y+45,formation.size.x-64,17),9,"a5b7ca")
	text_block(formation,"%d / %d na formação"%[model.state["team"].size(),model.capacity()],formation.size.y-36,22)

func gear_grid(parent: Control,craft: bool) -> void:
	var items: Array=[]
	for id in Equipment.catalog()["items"]:
		if Equipment.definition(id).get("kind") in ["weapon","armor"]: items.append(id)
	var subset:=Layout.page_items(items,int(pages.get("gear",0)),6)
	var w: float=(parent.size.x-36)/3
	for i in range(subset.size()):
		var id: String=subset[i];var owned: bool=id in model.state["gear"]["owned"]
		var rect:=Rect2(12+(i%3)*(w+6),76+int(i/3)*70,w,66)
		btn(parent,"",rect,func(): gear_id=id;schedule_rebuild(),false,id==gear_id)
		item_icon(parent,id,Rect2(rect.position+Vector2(floor((w-48)/2),2),Vector2(48,48)),owned or (craft and Equipment.unlocked(model,id)))
		txt(parent,"Obtido" if owned else "Fabricar" if Equipment.unlocked(model,id) else "Bloqueado",Rect2(rect.position+Vector2(2,51),Vector2(w-4,12)),9)
	page_bar(parent,"gear",items.size(),218,6)
	if craft: text_block(parent,Equipment.definition(gear_id)["name"],parent.size.y-40,26)

func gear_detail(craft: bool=false) -> void:
	hero_tabs(right)
	var item:=Equipment.definition(gear_id)
	item_icon(right,gear_id,Rect2(12,78,48,48))
	txt(right,item["name"],Rect2(68,78,right.size.x-80,40),12,"dbb87b")
	var values: Array=[]
	for key in item["stats"]: values.append({"hp":"vida","attack":"ataque","armor":"armadura","speed":"velocidade"}[key]+" +"+str(item["stats"][key]))
	text_block(right," · ".join(values) if not values.is_empty() else "Arma de classe · aprimorável na Forja",128,36)
	var owner:=Equipment.equipped_by(model,gear_id)
	var info: String="Equipado por "+model.definition("characters",owner)["name"] if not owner.is_empty() else item["description"]
	text_block(right,info,169,44)
	if craft:
		text_block(right,costs(item["cost"]),216,24)
		wide(right,"Já obtido" if gear_id in model.state["gear"]["owned"] else "Fabricar" if Equipment.unlocked(model,gear_id) else "Conclua "+str(model.definition("missions",item["requires"]).get("name","a missão indicada")),right.size.y-42,func(): Equipment.craft(model,gear_id),busy() or gear_id in model.state["gear"]["owned"] or not Equipment.unlocked(model,gear_id) or not model.afford(item["cost"]))
	else:
		var compatible: bool=hero in item["heroes"]
		var w: float=(right.size.x-30)/2
		btn(right,"Equipar" if compatible else "Outra classe",Rect2(12,right.size.y-42,w,28),func(): Equipment.equip(model,hero,gear_id),not Equipment.can_equip(model,hero,gear_id))
		btn(right,"Desequipar",Rect2(18+w,right.size.y-42,w,28),func(): Equipment.unequip(model,hero,item["slot"]),busy() or owner!=hero or item["slot"]=="weapon")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		var edge:=Layout.resize_edge(event.position,size)
		if edge>=0:
			DisplayServer.window_start_resize(edge);get_viewport().set_input_as_handled();return
		var drag_area:=Rect2(8,8,size.x-96,size.y-16) if compact else Rect2(8,8,size.x-156,28)
		if drag_area.has_point(event.position):
			DisplayServer.window_start_drag();get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var edge:=Layout.resize_edge(event.position,size)
		var shape:=Input.CURSOR_ARROW
		if edge in [0,7]: shape=Input.CURSOR_FDIAGSIZE
		elif edge in [2,5]: shape=Input.CURSOR_BDIAGSIZE
		elif edge in [1,6]: shape=Input.CURSOR_VSIZE
		elif edge in [3,4]: shape=Input.CURSOR_HSIZE
		Input.set_default_cursor_shape(shape)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		set_compact(not compact);get_viewport().set_input_as_handled()

