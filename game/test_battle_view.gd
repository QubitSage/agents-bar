extends SceneTree
const Camera=preload("res://ui/battle_view.gd")
const Layout=preload("res://ui/hud_layout.gd")
const Art=preload("res://gameplay/visual_library.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:
	var catalog:=Art.catalog()
	var cases: Array=[]
	for height in [700,760,820,1080]:
		for width in [884,984,1120,1920]:
			var size: Vector2=Layout.regions(Vector2(width,height))["battle"].size
			var view:=Camera.geometry(size)
			check(Rect2(Vector2.ZERO,size).encloses(view["scene"]),"scene contained")
			check(view["scene"].size.y>=154,"scene minimum height")
			check(view["arena"].size.x<=960,"combat spacing bounded on wide windows")
			check(view["scale"]<=view["arena"].size.x/680.0,"tall narrow windows keep party spacing")
			check(is_equal_approx(view["origin"].y+176*view["scale"],view["scene"].position.y+view["scene"].size.y*.88),"actors stay on the ground after resize")
			var hero_height: float=97*view["scale"]*Camera.actor_scale({"id":"io"},catalog)
			check(hero_height>=74,"hero remains readable")
			for meta: Dictionary in catalog.values():
				if meta.get("category")=="scenes":
					var source:=Art.region(meta,0)
					check(source.encloses(Camera.background_crop(source,view["scene"].size,float(meta.get("visualGroundY",126)))),"single backdrop crop stays in frame")
	for meta: Dictionary in catalog.values():
		if not meta.has("pivot"): continue
		var member: Dictionary={"visual":meta["actor"]}
		if meta["actor"]=="world-boss-09-azhor": member["render_scale"]=.46
		var scale:=Camera.actor_scale(member,catalog)
		for bounds: Array in meta["alphaBounds"]:
			check(176+(float(bounds[1])-float(meta["pivot"]["y"]))*scale>=8,"animation top contained: "+meta["id"])
			check(176+(float(bounds[3])-float(meta["pivot"]["y"]))*scale<=188,"animation feet contained: "+meta["id"])
	var full:=Layout.regions(Vector2(984,760))
	var view:=Camera.geometry(full["battle"].size)
	var data: Dictionary={"width":full["battle"].size.x,"height":full["battle"].size.y,"scale":view["scale"],"scene":[view["scene"].position.x,view["scene"].position.y,view["scene"].size.x,view["scene"].size.y],"arena":[view["arena"].position.x,view["arena"].size.x],"actors":[]}
	for member in [{"id":"io"},{"id":"brasa"},{"id":"luma"},{"id":"scrap-drone"},{"id":"azhor","render_scale":.46}]:
		var meta:=Art.clip(member,"idle")
		data["actors"].append({"meta":meta,"scale":Camera.actor_scale(member,catalog)})
	var bg: Dictionary=catalog["scene-scrap-1"]
	var crop:=Camera.background_crop(Art.region(bg,0),view["scene"].size,126)
	data["background"]={"meta":bg,"crop":[crop.position.x,crop.position.y,crop.size.x,crop.size.y]}
	var output:=OS.get_environment("AGENTS_BAR_PREVIEW_DATA")
	if not output.is_empty():
		var file:=FileAccess.open(output,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
	print("Battle framing: %d checks, %d failures."%[checks,failures])
	quit(1 if failures else 0)
