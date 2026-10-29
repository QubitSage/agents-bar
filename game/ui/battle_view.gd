extends RefCounted
## Screen framing is independent from combat rules and animation time.
const Library=preload("res://gameplay/visual_library.gd")
static var extents: Dictionary={}
static func geometry(size: Vector2) -> Dictionary:
	var scene:=Rect2(0,22,size.x,maxf(1,size.y-66))
	var width:=minf(size.x-64,960)
	var scale:=minf(scene.size.y/200.0,width/680.0)
	var origin:=Vector2(0,scene.position.y+scene.size.y*.88-176*scale)
	return {"scene":scene,"scale":scale,"origin":origin,"arena":Rect2((size.x-width)/2,scene.position.y,width,scene.size.y)}

static func background_crop(source: Rect2,destination: Vector2,ground: float) -> Rect2:
	var scale:=maxf(destination.x/source.size.x,destination.y/source.size.y)
	var visible:=destination/scale
	var y:=clampf(ground-destination.y*.88/scale,0,source.size.y-visible.y)
	return Rect2(source.position+Vector2((source.size.x-visible.x)/2,y),visible)

static func actor_scale(member: Dictionary,catalog: Dictionary) -> float:
	var actor:=Library.actor_id(member)
	if not extents.has(actor):
		var above:=1.0;var below:=1.0
		for meta: Dictionary in catalog.values():
			if meta.get("actor")!=actor: continue
			var pivot: float=meta.get("pivot",{}).get("y",float(meta["height"])*.94)
			for bounds: Array in meta.get("alphaBounds",[]):
				above=maxf(above,pivot-float(bounds[1]));below=maxf(below,float(bounds[3])-pivot)
		extents[actor]=Vector2(above,below)
	var bounds: Vector2=extents[actor]
	return minf(float(member.get("render_scale",.60))/.60,minf(168.0/bounds.x,12.0/bounds.y))
