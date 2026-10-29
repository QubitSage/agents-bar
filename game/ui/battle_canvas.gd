extends Control

var model
var selected_map: String="scrap"
var textures: Dictionary={}
var clips: Dictionary={}
var elapsed:=0.0

func _ready() -> void:
	custom_minimum_size=Vector2(480,200)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for group in ["characters","enemies","maps"]:
		for item in model.content[group]:
			var asset: String=item["asset"]
			var filename: String=asset+("-sheet" if group=="characters" else "")
			var image:=Image.load_from_file("res://assets/%s.png" % filename)
			if image:
				textures[asset]=ImageTexture.create_from_image(image)
			if group=="characters":
				clips[asset]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/%s.json" % asset))["animations"]

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	if not model.state["reduced_motion"] and not model.state["active"].get("paused",false):
		elapsed+=delta
		queue_redraw()

func caption(text: String,at: Vector2,color: Color=Color("e8ddc3")) -> void:
	draw_string(ThemeDB.fallback_font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,7,color)

func actor(member: Dictionary,x: float,enemy: bool) -> void:
	var asset: String=member["asset"]
	var alive: bool=int(member["hp"])>0
	var tint:=Color.WHITE if alive else Color(0.5,0.5,0.5,0.5)
	if textures.has(asset):
		if enemy:
			var frame:=0 if model.state["reduced_motion"] else int(elapsed*5)%4
			draw_texture_rect_region(textures[asset],Rect2(x-32,60,64,64),Rect2(frame*64,0,64,64),tint)
		else:
			var animation: String="idle"
			var phase: String=model.state["active"].get("phase","")
			if phase=="battle":
				animation="work"
			elif phase=="travel":
				animation="walk"
			elif model.state["active"].get("result")=="victory":
				animation="celebrate"
			var frames: Array=clips[asset][animation]["frames"]
			var frame: Dictionary=frames[0 if model.state["reduced_motion"] else int(elapsed*5)%frames.size()]
			draw_texture_rect_region(textures[asset],Rect2(x-24,76,48,48),Rect2(frame["x"],frame["y"],48,48),tint)
	var max_hp:=maxi(1,int(member.get("max_hp",member["hp"])))
	draw_rect(Rect2(x-26,130,52,4),Color("172c38"))
	draw_rect(Rect2(x-26,130,52*float(member["hp"])/max_hp,4),Color("dc8b4e") if enemy else Color("a7b874"))
	caption(str(member["name"]),Vector2(x-26,57))
	caption("%d/%d" % [member["hp"],max_hp],Vector2(x-26,143))
	var effects: String=""
	if int(member.get("shield",0))>0:
		effects+="Escudo %d " % member["shield"]
	if int(member.get("poison",0))>0:
		effects+="Esporos"
	caption(effects,Vector2(x-26,153),Color("d5dda2"))

func _draw() -> void:
	if not model or textures.is_empty():
		return
	var scale_value: float=minf(size.x/480,size.y/160)
	draw_set_transform(Vector2((size.x-480*scale_value)/2,0),0,Vector2.ONE*scale_value)
	var active: Dictionary=model.state["active"]
	var map_id: String=selected_map
	if not active.is_empty():
		map_id=model.definition("missions",active["mission_id"])["map"]
	var map_asset: String=model.definition("maps",map_id)["asset"]
	if textures.has(map_asset):
		draw_texture(textures[map_asset],Vector2.ZERO)
	draw_rect(Rect2(0,0,480,19),Color(0.09,0.17,0.21,0.9))
	caption(model.definition("maps",map_id)["name"],Vector2(10,12))
	var allies: Array=model.team_stats() if active.is_empty() else active["allies"]
	for i in range(allies.size()):
		actor(allies[i],50+i*65,false)
	if not active.is_empty():
		for i in range(active["enemies"].size()):
			actor(active["enemies"][i],330+i*75,true)
		caption("Encontro %d  ·  Rodada %d" % [int(active["wave"])+1,active["round"]],Vector2(305,12))
	draw_set_transform(Vector2.ZERO)
