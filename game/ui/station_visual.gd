extends Control
const Library=preload("res://gameplay/visual_library.gd")
var art=Library.new()
var model
var elapsed:=0.0

func _ready() -> void:
	custom_minimum_size=Vector2(480,220)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	model.changed.connect(queue_redraw)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	if not model.state["reduced_motion"]: elapsed+=delta
	queue_redraw()

func _draw() -> void:
	if not model: return
	var factor: float=minf(size.x/480,size.y/160)
	draw_set_transform(Vector2((size.x-480*factor)/2,0),0,Vector2.ONE*factor)
	var background: Dictionary=Library.catalog()["station-background"]
	draw_texture_rect_region(art.texture(background),Rect2(0,0,480,160),Library.region(background,Library.frame(background,elapsed,true)))
	draw_rect(Rect2(0,0,480,20),Color("111626"))
	draw_string(ThemeDB.fallback_font,Vector2(10,13),"ESTAÇÃO ZERO · %d LEMBRANÇAS" % model.state["memories"],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("ddb77e"))
	for slot in range(4):
		var id: String=model.state["layout"][slot]
		var level:=int(model.state["buildings"][id])
		var x:=slot*118+8
		var meta: Dictionary=Library.catalog()["building-"+id]
		draw_texture_rect_region(art.texture(meta),Rect2(x+4,20,100,100),Library.region(meta,Library.frame(meta,elapsed,true)),Color.WHITE if level>0 else Color(.5,.5,.5,.4))
		draw_string(ThemeDB.fallback_font,Vector2(x+2,137),model.definition("buildings",id)["name"]+" · "+str(level),HORIZONTAL_ALIGNMENT_LEFT,108,7,Color("e9eff8"))
		if model.state["building_memories"].has(id): draw_string(ThemeDB.fallback_font,Vector2(x+2,149),"Entrega lembrada",HORIZONTAL_ALIGNMENT_LEFT,108,6,Color("f7d879"))
	draw_set_transform(Vector2.ZERO)
