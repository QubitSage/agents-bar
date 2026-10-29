extends RefCounted
const Layout=preload("res://ui/hud_layout.gd")
var rects: Dictionary={}
var mode: String=""
var last: Rect2i
var pending_save:=false

func import_data(data: Variant) -> void:
	if not data is Dictionary: return
	for key in ["mini","full"]:
		var rect:=Layout.read_rect(data.get(key),Rect2i())
		if rect.size.x>0 and rect.size.y>0: rects[key]=rect

func export_data() -> Dictionary:
	var data: Dictionary={}
	for key in rects: data[key]=Layout.encode(rects[key])
	return data

func observe(rect: Rect2i) -> bool:
	if mode.is_empty() or rect==last: return false
	last=rect;rects[mode]=rect;pending_save=true
	return true

func change(compact: bool,current: Rect2i,screens: Array) -> Rect2i:
	var target: String="mini" if compact else "full"
	if target==mode: return current
	if not mode.is_empty(): observe(current)
	var minimum: Vector2i=Layout.MINI_MIN if compact else Layout.FULL_MIN
	var extent: Vector2i=Layout.MINI_DEFAULT if compact else Layout.FULL_DEFAULT
	var fallback:=Rect2i(current.position,extent)
	if mode.is_empty() and not screens.is_empty():
		var work: Rect2i=screens[0]
		fallback.position=work.end-extent-Vector2i(8,8)
	var result:=Layout.restore(rects.get(target,fallback),screens,minimum)
	mode=target;last=result;rects[target]=result;pending_save=true
	return result

