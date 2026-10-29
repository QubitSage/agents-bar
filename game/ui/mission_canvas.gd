extends Control
const Library=preload("res://gameplay/visual_library.gd")
const Timeline=preload("res://gameplay/forge_timeline.gd")
const Camera=preload("res://ui/battle_view.gd")
const Boss=preload("res://gameplay/azhor.gd")
var art=Library.new()
var model
var selected_map: String="scrap"
var elapsed:=0.0
var factor:=1.0
var origin:=Vector2.ZERO
var arena:=Rect2()
var view: Dictionary={}

func _ready() -> void:
	custom_minimum_size=Vector2.ZERO
	clip_contents=true
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not model.state["reduced_motion"] and not model.state["active"].get("paused",false): elapsed+=delta
	queue_redraw()

func world() -> void:
	draw_set_transform(origin,0,Vector2.ONE*factor)

func caption(text: String,at: Vector2,color: Color=Color("e9eff8"),font_size: int=12) -> void:
	draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func meter(name: String,at: Vector2,width: float,value: float) -> void:
	var meta: Dictionary=Library.catalog()["ui-bar-"+name]
	draw_texture_rect_region(art.texture(meta),Rect2(at,Vector2(width,9)),Library.region(meta,4))
	var fill: Texture2D=art.texture({"sheet":"static/ui-bar-"+name+"-fill.png"})
	draw_texture_rect(fill,Rect2(at+Vector2(width*10/192.0,3.15),Vector2(width*172/192.0*clampf(value,0,1),2.7)),false)

func actor(member: Dictionary,index: int,enemy: bool,run: Dictionary) -> void:
	var side: String="enemies" if enemy else "allies"
	var x:=Timeline.home(side,index)
	var clip_name: String="idle"
	var time:=elapsed
	if not run.is_empty():
		if run.has("timeline"):
			var pose:=Timeline.pose(run,side,index)
			clip_name=pose["clip"];time=float(pose["time"])
			x=Timeline.position(run,side,index)
			if run["phase"]=="result" and int(member["hp"])>0: time=elapsed
		else:
			clip_name="death" if int(member["hp"])<=0 else "victory" if run.get("result")=="victory" and not enemy else "attack" if run["phase"]=="battle" else "walk" if run["phase"] in ["travel","rest"] and not enemy else "idle"
	var meta:=Library.clip(member,clip_name)
	if meta.is_empty(): return
	var looping: bool=clip_name in ["idle","walk","victory"] or (not run.has("timeline") and clip_name!="death")
	var frame:=Library.frame(meta,0 if model.state["reduced_motion"] else time,looping)
	var pivot: Dictionary=meta.get("pivot",{"x":float(meta["width"])/2,"y":float(meta["height"])*.94})
	var scale_value:=Camera.actor_scale(member,Library.catalog())
	x=(arena.position.x+x/480.0*arena.size.x-origin.x)/factor
	var mirrored: bool=enemy and not member.get("faces_left",false)
	draw_set_transform(origin+Vector2(x,176)*factor,0,Vector2(-scale_value if mirrored else scale_value,scale_value)*factor)
	draw_texture_rect_region(art.texture(meta),Rect2(-float(pivot["x"]),-float(pivot["y"]),meta["width"],meta["height"]),Library.region(meta,frame))
	world()
	if enemy:
		meter("enemy-health",Vector2(x-26,190),52,float(member["hp"])/maxi(1,int(member.get("max_hp",member["hp"]))))
		caption(str(member["name"]),Vector2(x-35,186),Color("ddb77e"),11)

func _draw() -> void:
	if not model: return
	view=Camera.geometry(size)
	factor=view["scale"]
	origin=view["origin"]
	arena=view["arena"]
	draw_rect(Rect2(Vector2.ZERO,size),Color("111626"))
	var active: Dictionary=model.state["active"]
	var map_id: String=selected_map
	var mission: Dictionary={}
	if not active.is_empty():
		mission=model.definition("missions",active["mission_id"]);map_id=mission["map"]
	var scene_id: String=mission.get("scene","scene-"+map_id+"-1")
	var background: Dictionary=Library.catalog().get(scene_id,{})
	if not background.is_empty():
		var source:=Library.region(background,Library.frame(background,elapsed,true))
		var cropped:=Camera.background_crop(source,view["scene"].size,float(background.get("visualGroundY",126)))
		draw_texture_rect_region(art.texture(background),view["scene"],cropped)
	world()
	var allies: Array=model.team_stats() if active.is_empty() else active["allies"]
	for i in range(allies.size()): actor(allies[i],i,false,active)
	if not active.is_empty():
		for i in range(active["enemies"].size()): actor(active["enemies"][i],i,true,active)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0,0,size.x,22),Color(.04,.07,.12,.94))
	var objective: String=mission.get("name","ESTAÇÃO · Equipe pronta para partir")
	caption(objective,Vector2(8,15),Color("ddb77e"),12)
	var action: Dictionary=active.get("timeline",{}).get("action",{})
	if not action.is_empty() and not action.get("applied",true):
		caption(str(action.get("label","Preparando ação"))+" · %.1fs"%maxf(0,float(action["impact_at"])-float(action["elapsed"])),Vector2(size.x/2,15),Color("f7d879"),12)
	var base:=size.y-44
	draw_rect(Rect2(0,base,size.x,44),Color("111626"))
	var cell: float=size.x/4
	for i in range(allies.size()):
		var member: Dictionary=allies[i];var x:=i*cell+8
		caption(str(member["name"])+" · %d/%d HP"%[member["hp"],member.get("max_hp",member["hp"])],Vector2(x,base+14),Color("e9eff8"),12)
		meter("health",Vector2(x,base+19),cell-16,float(member["hp"])/maxi(1,int(member.get("max_hp",member["hp"]))))
		caption("Escudo %d"%member.get("shield",0),Vector2(x,base+40),Color("83b9ea"),10)
	var x:=3*cell+8
	if active.is_empty():
		caption("ESCOLHA UMA ROTA",Vector2(x,base+15),Color("ddb77e"),12)
		caption("Mapa → Iniciar expedição",Vector2(x,base+35),Color("a5b7ca"),11)
	else:
		var state: String="Pausado" if active["paused"] else {"travel":"A caminho","rest":"Avançando","battle":"Em combate","result":"Vitória · Recolher" if active["result"]=="victory" else "Retorno · Recolher"}.get(active["phase"],"")
		caption(state,Vector2(x,base+15),Color("ddb77e"),12)
		var detail: String="Encontro %d / %d"%[int(active["wave"])+1,mission["waves"].size()]
		if mission.get("world_boss",false):
			var boss: Dictionary=active["enemies"][0]
			detail="AZHOR · Fase %d · %d HP"%[Boss.phase(boss),boss["hp"]]
		caption(detail,Vector2(x,base+35),Color("a5b7ca"),11)
