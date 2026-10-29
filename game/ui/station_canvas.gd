extends Control
var model
var textures: Dictionary={}

func _ready() -> void:
	custom_minimum_size=Vector2(480,220)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	for id in ["map-garden","module-dock","module-workshop","module-greenhouse","module-observatory"]:
		textures[id]=ImageTexture.create_from_image(Image.load_from_file("res://assets/"+id+".png"))
	model.changed.connect(queue_redraw)

func _draw() -> void:
	if textures.is_empty():
		return
	var factor: float=minf(size.x/480,size.y/160)
	draw_set_transform(Vector2((size.x-480*factor)/2,0),0,Vector2.ONE*factor)
	draw_texture(textures["map-garden"],Vector2.ZERO)
	draw_rect(Rect2(0,0,480,20),Color("172c38"))
	draw_string(ThemeDB.fallback_font,Vector2(10,13),"ESTAÇÃO ZERO · %d LEMBRANÇAS" % model.state["memories"],HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("e8ddc3"))
	for slot in range(4):
		var id: String=model.state["layout"][slot]
		var level:=int(model.state["buildings"][id])
		var x:=slot*118+8
		draw_rect(Rect2(x,119,108,5),Color("75989b"))
		var texture: Texture2D=textures["module-"+("dock" if id=="core" else id)]
		var target_size: Vector2=texture.get_size()*minf(100.0/texture.get_width(),84.0/texture.get_height())
		draw_texture_rect(texture,Rect2(Vector2(x+54-target_size.x/2,118-target_size.y),target_size),false,Color.WHITE if level>0 else Color(0.5,0.5,0.5,0.35))
		var caption: String=model.definition("buildings",id)["name"]+" · "+str(level)
		draw_string(ThemeDB.fallback_font,Vector2(x+2,137),caption,HORIZONTAL_ALIGNMENT_LEFT,108,7,Color("e8ddc3"))
		if model.state["building_memories"].has(id):
			draw_rect(Rect2(x+6,142,7,6),Color("f0b65a"))
			draw_string(ThemeDB.fallback_font,Vector2(x+17,148),"Entrega lembrada",HORIZONTAL_ALIGNMENT_LEFT,90,6,Color("d5dda2"))
	for i in range(mini(24,int(model.state["memories"]))):
		var x:=12+i*19
		draw_rect(Rect2(x,28,1,6),Color("75989b"))
		draw_rect(Rect2(x-1,34,3,3),Color("f0b65a"))
	draw_set_transform(Vector2.ZERO)
