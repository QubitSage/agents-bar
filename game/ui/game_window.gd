extends Window
signal compact_requested

const Canvas=preload("res://ui/mission_canvas.gd")
const StationCanvas=preload("res://ui/station_visual.gd")
const Library=preload("res://gameplay/visual_library.gd")
var art=Library.new()
var model
var tabs: TabContainer
var resources: Label
var status: Label
var progress: Label
var battle_log: Label
var collect_button: Button
var scene
var bindings: Array=[]
var rules: Array=[]
var selected_map: String="scrap"
var map_choice: OptionButton
var last_structure: String=""
const INK=Color("111626")
const CREAM=Color("e9eff8")

func _ready() -> void:
	title="Agents Bar · Estação Zero"
	size=Vector2i(960,760)
	min_size=Vector2i(800,640)
	borderless=false
	transparent=false
	transparent_bg=false
	always_on_top=false
	unfocusable=false
	close_requested.connect(hide)
	var theme_value:=Theme.new()
	theme_value.default_font_size=15
	theme_value.set_color("font_color","Label",CREAM)
	theme_value.set_color("font_color","Button",CREAM)
	var panel:=StyleBoxFlat.new()
	panel.bg_color=INK
	theme_value.set_stylebox("panel","TabContainer",panel)
	for type in ["Button","OptionButton"]:
		var normal:=StyleBoxFlat.new()
		normal.bg_color=Color("254854")
		normal.border_color=Color("75989b")
		normal.set_border_width_all(1)
		normal.content_margin_left=12
		normal.content_margin_right=12
		normal.content_margin_top=7
		normal.content_margin_bottom=7
		theme_value.set_stylebox("normal",type,normal)
		var hover: StyleBoxFlat=normal.duplicate()
		hover.bg_color=Color("3e6b70")
		theme_value.set_stylebox("hover",type,hover)
		theme_value.set_stylebox("focus",type,hover)
		for spec in [["normal",0],["hover",1],["pressed",2],["disabled",3],["focus",4]]:
			var pixel_style:=StyleBoxTexture.new()
			pixel_style.texture=art.atlas("ui-button",spec[1])
			pixel_style.texture_margin_left=10
			pixel_style.texture_margin_right=10
			pixel_style.texture_margin_top=10
			pixel_style.texture_margin_bottom=10
			pixel_style.content_margin_left=14
			pixel_style.content_margin_right=14
			pixel_style.content_margin_top=9
			pixel_style.content_margin_bottom=9
			theme_value.set_stylebox(spec[0],type,pixel_style)
	var background:=ColorRect.new()
	background.color=INK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin:=MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_"+side,18)
	margin.theme=theme_value
	add_child(margin)
	var root:=VBoxContainer.new()
	root.add_theme_constant_override("separation",10)
	margin.add_child(root)
	var header:=HBoxContainer.new()
	root.add_child(header)
	var title_label:=label(header,"AGENTS BAR  /  ESTAÇÃO ZERO",22)
	title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button(header,"Recolher no canto",func(): compact_requested.emit();hide())
	resources=label(root,"")
	status=label(root,"")
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	tabs=TabContainer.new()
	tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL
	root.add_child(tabs)
	model.changed.connect(refresh)
	rebuild()
	tabs.current_tab=0
	visibility_changed.connect(func():
		set_process(visible)
		if is_instance_valid(scene):
			scene.set_process(visible)
	)

func label(parent: Node,text: String,font_size: int=15) -> Label:
	var node:=Label.new()
	node.text=text
	node.add_theme_font_size_override("font_size",font_size)
	parent.add_child(node)
	return node

func bound(parent: Node,fn: Callable) -> Label:
	var node:=label(parent,fn.call())
	bindings.append([node,fn])
	return node

func button(parent: Node,text: String,action: Callable,disabled_rule: Callable=Callable()) -> Button:
	var node:=Button.new()
	node.text=text
	node.pressed.connect(action)
	parent.add_child(node)
	if disabled_rule.is_valid():
		rules.append([node,disabled_rule])
	return node

func page(title_text: String) -> VBoxContainer:
	var scroll:=ScrollContainer.new()
	scroll.name=title_text
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	tabs.add_child(scroll)
	var box:=VBoxContainer.new()
	box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",12)
	scroll.add_child(box)
	return box

func card(parent: Node) -> VBoxContainer:
	var panel:=PanelContainer.new()
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("203b47")
	style.content_margin_left=14
	style.content_margin_right=14
	style.content_margin_top=12
	style.content_margin_bottom=12
	panel.add_theme_stylebox_override("panel",style)
	parent.add_child(panel)
	var box:=VBoxContainer.new()
	box.add_theme_constant_override("separation",8)
	panel.add_child(box)
	return box

func row(parent: Node) -> HBoxContainer:
	var result:=HBoxContainer.new()
	result.add_theme_constant_override("separation",10)
	parent.add_child(result)
	return result

func artwork(parent: Node,asset: String,portrait: bool=false) -> void:
	var visual: String=""
	for member in model.content["characters"]:
		if asset==member["asset"]+"-sheet": visual=Library.actor_id(member)+"--idle"
	if asset.begins_with("module-"): visual="building-"+("core" if asset=="module-dock" else asset.trim_prefix("module-"))
	if not visual.is_empty() and Library.catalog().has(visual):
		var texture:=art.atlas(visual)
		var meta: Dictionary=Library.catalog()[visual]
		if meta.has("alphaBounds"):
			var bounds: Array=meta["alphaBounds"][0]
			texture.region=Rect2(bounds[0],bounds[1],bounds[2]-bounds[0],bounds[3]-bounds[1])
		var view:=TextureRect.new()
		view.texture=texture
		view.custom_minimum_size=Vector2(96,96)
		view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(view)
		return
	var image:=Image.load_from_file("res://assets/"+asset+".png")
	if not image:
		return
	var control:=TextureRect.new()
	var texture:=ImageTexture.create_from_image(image)
	if portrait:
		var atlas:=AtlasTexture.new()
		atlas.atlas=texture
		atlas.region=Rect2(0,0,48,48)
		control.texture=atlas
	else:
		control.texture=texture
	control.custom_minimum_size=Vector2(96,96)
	control.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	control.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	parent.add_child(control)

func cost_text(cost: Dictionary) -> String:
	return "%d sucata · %d núcleos · %d sementes" % [cost.get("scrap",0),cost.get("cores",0),cost.get("seeds",0)]

func busy() -> bool:
	return model.read_only or not model.state["active"].is_empty()

func rebuild() -> void:
	var selected:=maxi(0,tabs.current_tab)
	bindings.clear()
	rules.clear()
	for child in tabs.get_children():
		tabs.remove_child(child)
		child.queue_free()
	make_missions(page("Expedições"))
	make_crew(page("Equipe"))
	make_station(page("Estação"))
	make_journal(page("Diário"))
	make_settings(page("Como jogar"))
	tabs.current_tab=mini(selected,4)
	refresh()

func perform(action: Callable) -> void:
	action.call()
	rebuild.call_deferred()

func make_missions(parent: VBoxContainer) -> void:
	button(parent,"Iniciar Primeiro Sinal · Forja",func(): perform(func(): model.start_mission("scrap-1")),func(): return busy())
	map_choice=OptionButton.new()
	for region in model.content["maps"]:
		map_choice.add_item(region["name"])
		if region["id"]==selected_map:
			map_choice.select(map_choice.item_count-1)
	map_choice.item_selected.connect(func(index):
		selected_map=model.content["maps"][index]["id"]
		rebuild.call_deferred()
	)
	parent.add_child(map_choice)
	scene=Canvas.new()
	scene.model=model
	scene.selected_map=selected_map
	scene.custom_minimum_size.y=420
	parent.add_child(scene)
	progress=label(parent,"")
	var actions:=row(parent)
	button(actions,"Pausar / retomar expedição",func(): model.toggle_expedition_pause(),func(): return model.read_only or model.state["active"].is_empty() or model.state["active"].get("phase")=="result")
	button(actions,"Retornar à estação",func(): perform(model.retreat),func(): return model.read_only or model.state["active"].is_empty() or model.state["active"].get("phase")=="result")
	collect_button=button(actions,"Receber recompensa e voltar",func():
		if model.collect():
			rebuild.call_deferred()
			tabs.set_deferred("current_tab",2)
	,func(): return model.read_only or model.state["active"].get("phase")!="result")
	battle_log=label(parent,"")
	battle_log.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for mission in model.content["missions"]:
		if mission["map"]!=selected_map:
			continue
		var box:=card(parent)
		var id: String=mission["id"]
		bound(box,func(): return mission["name"]+("  ·  CHEFE" if mission.get("boss",false) else "")+("  ✓" if model.state["completed"].has(id) else ""))
		var description:=label(box,mission["brief"])
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		label(box,"Nível sugerido %d  ·  %d encontros  ·  %s · %d XP" % [mission["recommended"],mission["waves"].size(),cost_text(mission["rewards"]),mission["rewards"]["xp"]],13)
		if mission.has("relic"):
			label(box,"Primeira vitória: "+model.definition("relics",mission["relic"])["name"],13)
		var launch:=button(box,"Enviar equipe",func(): perform(func(): model.start_mission(id)),func(): return busy() or not model.unlocked(id))
		if not model.unlocked(id):
			launch.text="Conclua "+model.definition("missions",mission["requires"])["name"]

func make_crew(parent: VBoxContainer) -> void:
	label(parent,"Prepare a expedição",21)
	bound(parent,func(): return "Equipe: %d/%d espaços · Formação e equipamentos mudam na estação." % [model.state["team"].size(),model.capacity()])
	for character in model.content["characters"]:
		var id: String=character["id"]
		var box:=card(parent)
		var heading:=row(box)
		artwork(heading,character["asset"]+"-sheet",true)
		bound(heading,func(): return "%s  ·  %s  ·  Nível %d · %d XP" % [character["name"],character["role"],model.state["crew"][id]["level"],model.state["crew"][id]["xp"]])
		label(box,character["description"])
		label(box,"A cada 3 rodadas: "+character["skill_name"],13)
		var actions:=row(box)
		button(actions,"Remover da equipe" if id in model.state["team"] else "Adicionar à equipe",func():
			var selection: Array=model.state["team"].duplicate()
			if id in selection:
				selection.erase(id)
			else:
				selection.append(id)
			perform(func(): model.select_team(selection))
		,func(): return busy() or (model.state["team"].size()==1 if id in model.state["team"] else model.state["team"].size()>=model.capacity()))
		button(actions,"Treinar · "+cost_text(model.training_cost(id)),func(): perform(func(): model.train(id)),func(): return busy() or int(model.state["crew"][id]["level"])>=5 or not model.afford(model.training_cost(id)))
		var equipment:=OptionButton.new()
		equipment.add_item("Sem relíquia")
		var choices: Array=[""]
		for relic in model.state["inventory"]:
			choices.append(relic)
			equipment.add_item(model.definition("relics",relic)["name"])
			for other in model.state["crew"]:
				if other!=id and model.state["crew"][other]["relic"]==relic:
					equipment.set_item_disabled(choices.size()-1,true)
		var current_index:=choices.find(model.state["crew"][id]["relic"])
		equipment.select(maxi(current_index,0))
		equipment.item_selected.connect(func(index): perform(func(): model.equip(id,choices[index])))
		box.add_child(equipment)
		rules.append([equipment,func(): return busy()])
		var relic: Dictionary=model.definition("relics",model.state["crew"][id]["relic"])
		if not relic.is_empty():
			label(box,"Relíquia: +%d vida · +%d ataque · +%d armadura" % [relic.get("hp",0),relic.get("attack",0),relic.get("armor",0)],13)

func make_station(parent: VBoxContainer) -> void:
	label(parent,"Um lar entre as nuvens",21)
	label(parent,"Melhorias afetam toda a equipe. Construa entre expedições.")
	var station:=StationCanvas.new()
	station.model=model
	parent.add_child(station)
	for building in model.content["buildings"]:
		var id: String=building["id"]
		var box:=card(parent)
		var heading:=row(box)
		artwork(heading,"module-"+("dock" if id=="core" else id))
		bound(heading,func(): return "%s · Nível %d/%d" % [building["name"],model.state["buildings"][id],building["max_level"]])
		label(box,building["description"])
		button(box,"Melhorar · "+cost_text(model.building_cost(id)),func(): perform(func(): model.build(id)),func(): return busy() or int(model.state["buildings"][id])>=int(building["max_level"]) or not model.afford(model.building_cost(id)))
		var placement:=OptionButton.new()
		for slot in range(4):
			placement.add_item("Encaixe %d" % (slot+1))
		placement.select(model.state["layout"].find(id))
		placement.item_selected.connect(func(slot): perform(func(): model.place_building(id,slot)))
		box.add_child(placement)
		rules.append([placement,func(): return busy()])
		var memory_ids: Array=[""]
		var memories:=OptionButton.new()
		memories.add_item("Vincular uma lembrança aceita…")
		for entry in model.state["journal"]:
			if entry.get("type")=="milestone" and entry["result"]=="accepted":
				memory_ids.append(entry["id"])
				memories.add_item(entry["title"])
		memories.item_selected.connect(func(index):
			if index>0:
				perform(func(): model.bind_memory(id,memory_ids[index]))
		)
		box.add_child(memories)
		rules.append([memories,func(): return model.read_only or int(model.state["buildings"][id])==0])
		if model.state["building_memories"].has(id):
			label(box,"Esta construção lembra: "+model.state["building_memories"][id]["title"],13)
	bound(parent,func(): return "Lembranças de trabalho: %d · Registros decorativos, sem bônus de combate." % model.state["memories"])

func make_journal(parent: VBoxContainer) -> void:
	label(parent,"Memórias da estação",21)
	var entry:=LineEdit.new()
	entry.placeholder_text="Uma entrega que você quer registrar (opcional)"
	entry.max_length=80
	parent.add_child(entry)
	button(parent,"Registrar marco para revisar",func(): perform(func(): model.manual_milestone(entry.text)),func(): return model.read_only or entry.text.strip_edges().is_empty())
	button(parent,"Aceitar pendentes como uma entrega",func(): perform(func(): model.combine_milestones(entry.text)),func(): return model.read_only or entry.text.strip_edges().is_empty() or model.state["pending_milestones"].size()<2)
	entry.text_changed.connect(func(_text): refresh())
	for pending in model.state["pending_milestones"]:
		var box:=card(parent)
		label(box,pending["title"])
		var actions:=row(box)
		button(actions,"Aceitar lembrança",func(): perform(func(): model.resolve_milestone(pending["id"],true)))
		button(actions,"Descartar",func(): perform(func(): model.resolve_milestone(pending["id"],false)))
	if model.state["journal"].is_empty():
		label(parent,"Seu diário começa com a primeira expedição ou marco aceito.")
	var translations: Dictionary={"victory":"Vitória","defeat":"Retorno para reparos","retreated":"Retirada","accepted":"Lembrança aceita"}
	for item in model.state["journal"]:
		label(parent,"%s · %s" % [translations.get(item["result"],item["result"]),item["title"]])

func make_settings(parent: VBoxContainer) -> void:
	label(parent,"Bem-vindo à Estação Zero",23)
	for paragraph in [
		"1. Em Expedições, envie o Cavaleiro e Brasa para Primeiro Sinal. O combate automático mostra preparação, aproximação, impacto e recuperação de cada golpe.",
		"Atravesse três encontros: Vigia de Latão, Caranguejo de Cobre e Rebocador. A morte termina antes do próximo encontro. Na vitória, receba núcleo, sucata e XP e volte à estação.",
		"2. Recolha o resultado. Use sucata e núcleos para treinar a equipe ou melhorar a estação. Repetir missões também rende materiais.",
		"3. Melhore o Núcleo para o nível 2 e adicione Luma à equipe. Equipe as relíquias conquistadas e avance pelas três regiões.",
		"Escudos absorvem dano; esporos causam dano por rodada. A equipe faz reparos entre encontros. Derrota e retirada não gastam materiais.",
		"A expedição continua no cantinho enquanto o app está aberto. Pausar a animação da barra não pausa o combate; use Pausar expedição. Fechar o app salva e interrompe a missão.",
		"O jogo funciona sem IA ou conexão. Demonstração usa sessões fictícias. Nenhum arquivo ou conversa é descoberto automaticamente e tokens não geram recompensas.",
		"Progresso é salvo localmente com backup. A barra não captura teclado; esta janela recebe foco apenas quando você a abre."
	]:
		var paragraph_label:=label(parent,paragraph)
		paragraph_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for option in [["sound","Sons suaves de partida e resultado"],["reduced_motion","Reduzir movimentos"]]:
		var toggle:=CheckButton.new()
		toggle.text=option[1]
		toggle.button_pressed=model.state[option[0]]
		toggle.toggled.connect(func(value): model.set_option(option[0],value))
		parent.add_child(toggle)
	button(parent,"Entendi · começar a explorar",func():
		model.set_option("onboarded",true)
		tabs.current_tab=0
	)
	label(parent,"Versão 0.4.0 alpha · Biblioteca visual v04 · Sem conta, compras ou telemetria",13)
	button(parent,"Salvar diagnóstico local",func(): model.export_diagnostic())

func refresh() -> void:
	if not is_instance_valid(resources):
		return
	var signature:=JSON.stringify([model.state["team"],model.state["crew"],model.state["buildings"],model.state["inventory"],model.state["pending_milestones"],model.state["journal"],model.state["layout"],model.state["building_memories"]])
	if not last_structure.is_empty() and signature!=last_structure:
		last_structure=signature
		rebuild.call_deferred()
		return
	last_structure=signature
	resources.text=cost_text(model.state["materials"])+"   |   %d/9 missões concluídas" % model.state["completed"].size()
	status.text=model.notice
	for binding in bindings:
		binding[0].text=binding[1].call()
	for rule in rules:
		rule[0].disabled=rule[1].call()
	var active: Dictionary=model.state["active"]
	collect_button.text="Receber recompensa e voltar" if active.get("result")=="victory" else "Voltar à estação"
	if active.is_empty():
		progress.text="Equipe na estação · Escolha uma missão abaixo."
		battle_log.text=""
	else:
		var phases: Dictionary={"travel":"Em viagem","rest":"Fazendo reparos","battle":"Em batalha","result":"Expedição encerrada"}
		progress.text=model.definition("missions",active["mission_id"])["name"]+" · "+phases.get(active["phase"],"")+(" · PAUSADA" if active["paused"] else "")
		var lines: Array=active["log"].slice(maxi(0,active["log"].size()-3))
		battle_log.text="\n".join(lines)
	if is_instance_valid(scene):
		scene.queue_redraw()
