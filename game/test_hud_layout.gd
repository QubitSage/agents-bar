extends SceneTree
const Layout=preload("res://ui/hud_layout.gd")
const Geometry=preload("res://ui/window_geometry.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:
	for path in ["res://ui/hud_shell.gd","res://ui/mission_canvas.gd","res://app.gd"]:
		var script=load(path);check(script!=null and script.can_instantiate(),"compile "+path)
	for width in [884,984,1120,1366,1920]:
		for height in [700,760,820,1080]:
			var outer:=Rect2(0,0,width,height)
			var regions:=Layout.regions(Vector2(width,height))
			for key in regions:
				check(outer.encloses(regions[key]),"inside viewport "+key)
				for other in regions:
					if key!=other: check(not regions[key].intersects(regions[other]),"no overlap "+key+"/"+other)
			check(regions.left.size.y>=302 and regions.left.size.x>=343,"minimum content budget")
			check(regions.battle.size.x==width-16 and regions.battle.size.y>=220,"battle gets readable stage height")
	# No record is omitted or duplicated, including the last partial page.
	for count in [0,1,3,4,6,12,20,90,91,100]:
		for capacity in [3,4,6]:
			var items: Array=range(count)
			var visited: Array=[]
			for page in range(Layout.page_count(count,capacity)):
				var slice:=Layout.page_items(items,page,capacity)
				check(slice.size()<=capacity,"bounded rows")
				visited.append_array(slice)
			check(visited==items,"all records reachable exactly once")
			check(Layout.page_items(items,-1,capacity)==items.slice(0,capacity),"negative page recovery")
			check(Layout.page_items(items,999,capacity)==Layout.page_items(items,Layout.page_count(count,capacity)-1,capacity),"shrink page recovery")
	var size:=Vector2(920,640)
	var edges: Array=[Vector2(1,1),Vector2(460,1),Vector2(919,1),Vector2(1,320),Vector2(919,320),Vector2(1,639),Vector2(460,639),Vector2(919,639)]
	for i in range(edges.size()): check(Layout.resize_edge(edges[i],size)==i,"native resize edge "+str(i))
	for point in [Vector2(15,15),Vector2(400,300),Vector2(-1,30),Vector2(920,640)]:
		check(Layout.resize_edge(point,size)==-1,"content is not resize handle")
	var screens: Array=[Rect2i(0,0,1920,1040),Rect2i(-1920,-100,1920,1080)]
	var original:=Rect2i(-1800,40,1100,700)
	check(Layout.restore(original,screens,Layout.FULL_MIN)==original,"negative monitor coordinates retained")
	var disconnected:=Layout.restore(original,[screens[0]],Layout.FULL_MIN)
	check(screens[0].encloses(disconnected),"missing monitor recovers inside visible desktop")
	var tiny:=Rect2i(0,0,640,480)
	check(Layout.restore(original,[tiny],Layout.FULL_MIN)==tiny,"small monitor fits instead of overflowing")
	for raw in [null,{},[],[1,2,3],["1",2,3,4],[1,2,-3,4],[1,2,3,INF],[100001,0,1,1]]:
		check(Layout.read_rect(raw,original)==original,"invalid stored rectangle ignored")
	check(Layout.read_rect(Layout.encode(original),Rect2i())==original,"geometry roundtrip")
	var geometry:=Geometry.new()
	geometry.import_data({"full":Layout.encode(original),"mini":[100,100,360,92]})
	var mini:=geometry.change(true,Rect2i(),screens)
	check(mini==Rect2i(100,100,360,92),"stored compact startup")
	var moved:=Rect2i(-1600,180,420,100)
	check(geometry.observe(moved),"drag records new geometry")
	check(geometry.change(true,moved,screens)==moved,"same mode never resets position")
	var full:=geometry.change(false,moved,screens)
	check(full==original,"expand restores independent full geometry")
	var resized:=Rect2i(-1500,160,1250,780)
	geometry.observe(resized)
	check(geometry.change(true,resized,screens)==moved,"fold restores compact geometry")
	check(geometry.change(false,moved,screens)==resized,"expand keeps resized geometry")
	var reload_geometry:=Geometry.new();reload_geometry.import_data(geometry.export_data())
	check(reload_geometry.change(false,Rect2i(),screens)==resized,"restart retains full geometry")
	var source:=FileAccess.get_file_as_string("res://ui/hud_shell.gd")
	check(not source.contains("ScrollContainer") and not source.contains("OptionButton") and not source.contains("PopupMenu"),"no scrolling or external menu implementation")
	var rebuild_source:=source.substr(source.find("func rebuild()"),source.find("func _draw()")-source.find("func rebuild()"))
	check(not rebuild_source.contains("layout_changed.emit"),"data refresh cannot relocate window")
	print("HUD layout: %d checks, %d failures. Pure geometry and compilation only; no UI instantiated."%[checks,failures])
	quit(1 if failures else 0)

