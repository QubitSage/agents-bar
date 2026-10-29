extends SceneTree
const Model=preload("res://gameplay/model.gd")
const Gear=preload("res://gameplay/equipment.gd")
const Store=preload("res://gameplay/save_store.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL: "+message)
func equivalent(a: Variant,b: Variant) -> bool:
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))
func _initialize() -> void:
	var m:=Model.new();m.initialize("")
	check(Gear.valid(m.state.gear),"starter loadout valid")
	check(Gear.catalog().items.size()==24,"24 production items")
	for id in Gear.catalog().items:
		var item:=Gear.definition(id)
		var icon:=Image.load_from_file(item.icon)
		check(icon!=null and icon.get_size()==Vector2i(48,48),"48px icon "+id)
		if not str(item.get("requires","")).is_empty(): check(not m.definition("missions",item.requires).is_empty(),"existing unlock mission")
	var before:=JSON.stringify(m.state)
	check(not Gear.craft(m,"armor-01"),"locked recipe")
	check(not Gear.equip(m,"io","weapons-03"),"class compatibility")
	check(not Gear.equip(m,"io","armor-01"),"must own equipment")
	check(not Gear.unequip(m,"io","weapon"),"starter weapon required")
	check(JSON.stringify(m.state)==before,"rejected operations do not mutate progress")
	m.state.completed["scrap-1"]=1
	m.state.materials.scrap=15
	check(not Gear.craft(m,"armor-01"),"cannot overspend")
	m.state.materials.scrap=16
	check(Gear.craft(m,"armor-01") and m.state.materials.scrap==0,"craft exact balance once")
	check(not Gear.craft(m,"armor-01"),"no duplicate craft")
	var base: Array=m.team_stats()
	check(Gear.equip(m,"io","armor-01"),"equip crafted helmet")
	check(m.team_stats()[0].armor==base[0].armor+1,"bonus reaches battle stats")
	check(not Gear.equip(m,"brasa","armor-01"),"unique physical item across heroes")
	check(Gear.unequip(m,"io","helmet") and Gear.equip(m,"brasa","armor-01"),"transfer through unequip")
	check(m.team_stats()[0].armor==base[0].armor,"unequip removes bonus")
	m.start_mission("scrap-1")
	before=JSON.stringify(m.state)
	check(not Gear.unequip(m,"brasa","helmet") and not Gear.equip(m,"io","weapons-01") and not Gear.craft(m,"armor-02"),"equipment immutable during expedition")
	check(JSON.stringify(m.state)==before,"combat remains unchanged")
	var p: String="res://../tests/scratch/equipment-"+str(Time.get_ticks_usec())+".json"
	check(Store.save_state(p,m.state),"save equipped mid battle")
	var restored:=Model.new();restored.initialize(p)
	check(not restored.read_only and equivalent(restored.state.gear,m.state.gear) and equivalent(restored.state.active,m.state.active),"save preserves gear and current battle")
	m.retreat();m.collect()
	m.read_only=true
	check(not Gear.unequip(m,"brasa","helmet") and not Gear.craft(m,"armor-01"),"read only save protected")
	m.read_only=false
	for invalid in [null,{},[],{"owned":[],"equipped":{}}, {"owned":[42],"equipped":{"io":{},"brasa":{},"luma":{}}}]:
		check(not Gear.valid(invalid),"malformed equipment rejected")
	var broken: Dictionary=m.state.gear.duplicate(true);broken.owned.append("armor-01")
	check(not Gear.valid(broken),"duplicate ownership rejected")
	broken=m.state.gear.duplicate(true);broken.equipped.io.helmet="armor-01"
	check(not Gear.valid(broken),"double equipped save rejected")
	broken=m.state.gear.duplicate(true);broken.equipped.brasa.cape="armor-01"
	check(not Gear.valid(broken),"wrong slot rejected")
	# Migrate a real schema-2 envelope, not a hand-built new-version save.
	var legacy: Dictionary=m.state.duplicate(true);legacy.erase("gear");legacy.version=2
	var payload:=JSON.stringify(legacy)
	var f:=FileAccess.open(p,FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema":2,"payload":payload,"checksum":payload.sha256_text()}));f.close()
	restored=Model.new();restored.initialize(p)
	check(not restored.read_only and restored.state.version==4 and restored.state.gear==Gear.default_gear(),"v2 installs starter equipment without spending resources")
	check(equivalent(restored.state.materials,legacy.materials) and equivalent(restored.state.completed,legacy.completed),"migration preserves economy and campaign")
	check(Store.save_state(p,restored.state) and Store.decode(p).ok,"migrated save writes schema 4")
	for suffix in ["",".bak"]: DirAccess.remove_absolute(ProjectSettings.globalize_path(p+suffix))
	print("Equipment: %d checks, %d failures. Fictional data only."%[checks,failures]);quit(1 if failures else 0)
