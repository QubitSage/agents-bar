extends RefCounted
## Pure geometry shared by the HUD, window persistence and code-only checks.
const FULL_MIN=Vector2i(884,700)
const FULL_DEFAULT=Vector2i(984,760)
const MINI_MIN=Vector2i(320,84)
const MINI_DEFAULT=Vector2i(360,92)

static func regions(dimensions: Vector2) -> Dictionary:
	var w:=maxf(FULL_MIN.x,dimensions.x)
	var h:=maxf(FULL_MIN.y,dimensions.y)
	var body_h:=302.0+(h-FULL_MIN.y)*.2
	var battle_y:=78.0+body_h
	var side:=164.0
	var column: float=(w-side-34)/2
	return {"header":Rect2(8,8,w-16,28),"session":Rect2(8,42,w-16,24),
		"formation":Rect2(8,72,side,body_h),
		"left":Rect2(14+side,72,column,body_h),"right":Rect2(20+side+column,72,column,body_h),
		"battle":Rect2(8,battle_y,w-16,h-100-battle_y),"actions":Rect2(8,h-94,w-16,28),
		"navigation":Rect2(8,h-60,w-16,34),"status":Rect2(8,h-22,w-16,16)}

static func page_count(count: int,capacity: int=4) -> int:
	return maxi(1,ceili(float(maxi(0,count))/maxi(1,capacity)))

static func page_items(items: Array,page: int,capacity: int=4) -> Array:
	capacity=maxi(1,capacity)
	var start:=clampi(page,0,page_count(items.size(),capacity)-1)*capacity
	return items.slice(start,start+capacity)

static func resize_edge(point: Vector2,dimensions: Vector2) -> int:
	if not Rect2(Vector2.ZERO,dimensions).has_point(point): return -1
	var l:=point.x<7;var r:=point.x>=dimensions.x-7
	var t:=point.y<7;var b:=point.y>=dimensions.y-7
	if t: return 0 if l else 2 if r else 1
	if b: return 5 if l else 7 if r else 6
	return 3 if l else 4 if r else -1

static func fit(rect: Rect2i,work: Rect2i,minimum: Vector2i) -> Rect2i:
	var extent:=Vector2i(clampi(rect.size.x,mini(minimum.x,work.size.x),work.size.x),clampi(rect.size.y,mini(minimum.y,work.size.y),work.size.y))
	return Rect2i(Vector2i(clampi(rect.position.x,work.position.x,work.end.x-extent.x),clampi(rect.position.y,work.position.y,work.end.y-extent.y)),extent)

static func restore(rect: Rect2i,screens: Array,minimum: Vector2i) -> Rect2i:
	if screens.is_empty(): return rect
	var best: Rect2i=screens[0]
	var overlap: int=-1
	for screen: Rect2i in screens:
		var area:=rect.intersection(screen).get_area()
		if area>overlap: overlap=area;best=screen
	return fit(rect,best,minimum)

static func read_rect(raw: Variant,fallback: Rect2i) -> Rect2i:
	if not raw is Array or raw.size()!=4: return fallback
	for value in raw:
		if not (value is int or value is float) or not is_finite(float(value)) or absf(float(value))>100000: return fallback
	if raw[2]<=0 or raw[3]<=0: return fallback
	return Rect2i(int(raw[0]),int(raw[1]),int(raw[2]),int(raw[3]))

static func encode(rect: Rect2i) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
