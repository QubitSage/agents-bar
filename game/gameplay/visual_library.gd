extends RefCounted

const ROOT="res://assets/v04/"
const ACTORS={"io":"hero-classic","brasa":"companion-brasa","luma":"companion-luma","scrap-drone":"enemy-brass-sentry","scrap-crab":"enemy-copper-crab","scrap-boss":"boss-rebocador","garden-spore":"enemy-sporeling","garden-vine":"enemy-root-warden","garden-boss":"boss-sylvan-heart","storm-spark":"enemy-storm-wisp","storm-warden":"enemy-storm-sentinel","storm-boss":"boss-storm-archon"}
static var entries: Dictionary={}
var textures: Dictionary={}

static func catalog() -> Dictionary:
	if entries.is_empty():
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"catalog.json"))
		if parsed is Dictionary: entries=parsed
	return entries

static func actor_id(member: Dictionary) -> String:
	if member.get("id")=="azhor": return "world-boss-09-azhor"
	return str(member.get("visual",ACTORS.get(str(member.get("id","io")),"hero-classic")))

static func clip(member: Dictionary,action: String) -> Dictionary:
	var id:=actor_id(member)
	if id=="world-boss-09-azhor":
		if action=="attack": action="attack_basic"
		if action=="special": action="ultimate"
	return catalog().get(id+"--"+action,catalog().get(id+"--idle",{}))

static func duration(meta: Dictionary) -> float:
	var total:=0.0
	for ms in meta.get("durations",[200]): total+=float(ms)/1000.0
	return maxf(.01,total)

static func frame(meta: Dictionary,seconds: float,loop: bool) -> int:
	var time:=maxf(0,seconds)
	var total:=duration(meta)
	if loop: time=fmod(time,total)
	var durations: Array=meta.get("durations",[200])
	for i in range(int(meta.get("frames",1))):
		time-=float(durations[i])/1000.0
		if time<0: return i
	return int(meta.get("frames",1))-1

static func region(meta: Dictionary,index: int) -> Rect2:
	var columns:=int(meta.get("columns",1))
	return Rect2((index%columns)*int(meta["width"]),(index/columns)*int(meta["height"]),int(meta["width"]),int(meta["height"]))

func texture(meta: Dictionary) -> Texture2D:
	var path: String=ROOT+str(meta["sheet"])
	if not textures.has(path):
		var image:=Image.load_from_file(path)
		if image: textures[path]=ImageTexture.create_from_image(image)
	return textures.get(path)

func atlas(id: String,index: int=0) -> AtlasTexture:
	var meta: Dictionary=catalog().get(id,{})
	if meta.is_empty(): return null
	var result:=AtlasTexture.new()
	result.atlas=texture(meta)
	result.region=region(meta,index)
	return result
